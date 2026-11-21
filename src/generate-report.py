#!/usr/bin/env python3
"""
Generate blog-ready analysis views from a benchmark run's results.json.

Usage:
    python3 generate-report.py _k6/results/<stamp>

Reads:
    <dir>/results.json        (written by run-all.sh)
    <dir>/resource_usage.json (optional, written by run-benchmark.sh)
    <dir>/test_log.csv        (optional, exit codes / aborts)

    <dir>/stats/*.csv, stats/infra/*.csv, stats/environment.json (optional, written by run-benchmark.sh)

Writes:
    <dir>/report.md - pivot matrices with medals, scaling factors,
                      cross-scenario summary, resource usage, LOC table.
    <dir>/results_extended.csv - results.csv plus, per test: the k6 exit code, CPU and memory of the
                      service, CPU of PostgreSQL and of the load generator, and which of the three was
                      at its limit (needs test_log.csv with the params column and the stats files).

The report is generated purely from the recorded dataset, so views can be
tweaked and regenerated at any time without re-running the benchmark.
"""

import csv
import json
import os
import re
import sys
from collections import defaultdict

MEDALS = ['🥇', '🥈', '🥉']

# Reference combos used for the cross-scenario summary (mirrors the blog's picks).
# Adjust freely and regenerate.
REFERENCE = {
    'minimal': lambda r: r['vus'] == 100,
    'post': lambda r: r['vus'] == 50 and r.get('records') == 10,
    'nested': lambda r: r['vus'] == 50 and r.get('depth') == 1,
    'large': lambda r: r['vus'] == 25 and r.get('sizeKb') == 100,
    'params': lambda r: r['vus'] == 50,
    'table-get': lambda r: r['vus'] == 50,
    'table-list': lambda r: r['vus'] == 50,
    'table-insert': lambda r: r['vus'] == 50,
}

# Scenarios other than perf-test, in the order they are reported.
OTHER_SCENARIOS = ['minimal', 'post', 'nested', 'large', 'params', 'table-get', 'table-list', 'table-insert']

# Source files counted for the lines-of-code table (service dir -> globs).
LOC_EXTENSIONS = ('.py', '.js', '.ts', '.go', '.rs', '.java', '.php', '.cs', '.sql')
LOC_CONFIG_ONLY = {'postgrest': ('postgrest.conf',), 'npgsqlrest': ('appsettings.json',)}


def display_name(tag):
    """Turn a service tag into a friendly display name."""
    known = {
        'django-app': 'Django',
        'fastapi-app': 'FastAPI',
        'fastify-app': 'Fastify',
        'express-app': 'Express',
        'bun-app': 'Bun',
        'deno-app': 'Deno',
        'go-app': 'Go',
        'rust-app': 'Actix-web',
        'axum-app': 'Axum',
        'swoole-php-app': 'Swoole PHP',
        'postgrest': 'PostgREST',
        'net10-minapi-ef-jit': '.NET 10 EF',
        'net10-minapi-dapper-jit': '.NET 10 Dapper',
        'net11-minapi-ef-jit': '.NET 11 EF',
        'net11-minapi-dapper-jit': '.NET 11 Dapper',
        'net11-minapi-npgsql-jit': '.NET 11 Npgsql',
        'gin-app': 'Gin',
        'nestjs-app': 'NestJS',
        'postgraphile': 'PostGraphile',
        'hasura': 'Hasura',
        'npgsqlrest-routine-aot': 'NpgsqlRest Routine AOT',
        'npgsqlrest-routine-jit': 'NpgsqlRest Routine JIT',
        'npgsqlrest-file-aot': 'NpgsqlRest SQL Files AOT',
        'npgsqlrest-file-jit': 'NpgsqlRest SQL Files JIT',
    }
    m = re.match(r'^(.*?)(?:-v[\d.]+)?$', tag)
    base = m.group(1) if m else tag
    name = known.get(base, base)
    ver = tag[len(base):].lstrip('-v') if tag != base else ''
    # java25-spring-boot special case
    if 'spring-boot' in tag:
        name, ver = 'Spring Boot', tag.split('-v')[-1]
    # laravel-v13.43.0-octane-app: the version is in the middle, because Laravel (Symfony) answers 400 to a
    # Host name whose last label is a number, and the Host name is the docker service name
    if 'octane' in tag:
        name, ver = 'Laravel Octane', tag.split('-v')[-1].split('-')[0]
    return f'{name} {ver}'.strip() if ver else name


def fmt(v):
    if v is None or v == '':
        return ''
    if isinstance(v, float):
        return f'{v:,.0f}' if v >= 100 else f'{v:,.2f}'
    return f'{v:,}'


def combo_label(r):
    parts = [f"{r['vus']}vu"]
    if r.get('records') is not None:
        parts.append(f"{r['records']}rec")
    if r.get('depth') is not None:
        parts.append(f"d{r['depth']}")
    if r.get('sizeKb') is not None:
        parts.append(f"{r['sizeKb']}kb")
    return '/'.join(parts)


def combo_sort_key(r):
    return (r['vus'], r.get('records') or 0, r.get('depth') or 0, r.get('sizeKb') or 0)


def medal(rank):
    return MEDALS[rank] + ' ' if rank < len(MEDALS) else ''


def pivot_table(rows, sort_col=None):
    """Framework x combo matrix with medals for top 3 per column."""
    combos = sorted({combo_label(r): combo_sort_key(r) for r in rows}.items(), key=lambda kv: kv[1])
    combo_names = [c for c, _ in combos]
    by_tag = defaultdict(dict)
    invalid = set()
    for r in rows:
        by_tag[r['tag']][combo_label(r)] = r['rps']
        if r.get('invalid'):
            invalid.add((r['tag'], combo_label(r)))

    # Rank per column for medals
    ranks = {}
    for c in combo_names:
        vals = sorted(((by_tag[t].get(c) or 0), t) for t in by_tag)
        vals.reverse()
        for i, (_, t) in enumerate(vals):
            ranks[(t, c)] = i

    sort_by = sort_col if sort_col in combo_names else combo_names[-1]
    tags = sorted(by_tag, key=lambda t: -(by_tag[t].get(sort_by) or 0))

    out = ['| Framework | ' + ' | '.join(combo_names) + ' |',
           '|-----------|' + '|'.join(['---:'] * len(combo_names)) + '|']
    for t in tags:
        cells = []
        for c in combo_names:
            v = by_tag[t].get(c)
            if (t, c) in invalid:
                cells.append('failed')   # more than 1% of its requests failed: not a result (see Test Completion)
            else:
                cells.append(f'{medal(ranks[(t, c)])}{fmt(v)}' if v is not None else '—')
        out.append(f'| {display_name(t)} | ' + ' | '.join(cells) + ' |')
    return '\n'.join(out)


def scaling_table(rows):
    """perf-test at fixed records: framework x VU progression + scaling factor."""
    recs = min(r['records'] for r in rows)
    subset = [r for r in rows if r['records'] == recs]
    vus = sorted({r['vus'] for r in subset})
    by_tag = defaultdict(dict)
    for r in subset:
        by_tag[r['tag']][r['vus']] = r['rps']

    tags = sorted(by_tag, key=lambda t: -(by_tag[t].get(vus[-1]) or 0))
    out = [f'Scaling at {recs} record(s): requests/s per VU level.',
           '',
           'Scaling = the best level divided by the 1 VU level.',
           '',
           '| Framework | ' + ' | '.join(f'{v} VU' for v in vus) + ' | Scaling |',
           '|-----------|' + '|'.join(['---:'] * (len(vus) + 1)) + '|']
    for t in tags:
        base = by_tag[t].get(vus[0])
        peak = max((v for v in by_tag[t].values() if v), default=None)
        factor = f'**{peak / base:.1f}x**' if base and peak else '—'
        cells = [fmt(by_tag[t].get(v)) or '—' for v in vus]
        out.append(f'| {display_name(t)} | ' + ' | '.join(cells) + f' | {factor} |')
    return '\n'.join(out)


def cross_scenario_table(results):
    """Framework x scenario at reference combos (the blog's 'new scenarios' view)."""
    scenarios = [s for s in OTHER_SCENARIOS if any(r['scenario'] == s for r in results)]
    by_tag = defaultdict(dict)
    invalid = set()
    ref_desc = {}
    for s in scenarios:
        subset = [r for r in results if r['scenario'] == s and REFERENCE[s](r)]
        if not subset:  # fallback: highest-VU combo
            subset = [r for r in results if r['scenario'] == s]
            top = max(combo_sort_key(r) for r in subset)
            subset = [r for r in subset if combo_sort_key(r) == top]
        ref_desc[s] = combo_label(subset[0])
        for r in subset:
            by_tag[r['tag']][s] = r['rps']
            if r.get('invalid'):
                invalid.add((r['tag'], s))

    ranks = {}
    for s in scenarios:
        vals = sorted(((by_tag[t].get(s) or 0), t) for t in by_tag)
        vals.reverse()
        for i, (_, t) in enumerate(vals):
            ranks[(t, s)] = i

    tags = sorted(by_tag, key=lambda t: -(by_tag[t].get(scenarios[0]) or 0))
    out = ['| Framework | ' + ' | '.join(s.capitalize() for s in scenarios) + ' |',
           '|-----------|' + '|'.join(['---:'] * len(scenarios)) + '|']
    for t in tags:
        cells = []
        for s in scenarios:
            v = by_tag[t].get(s)
            if (t, s) in invalid:
                cells.append('failed')
            else:
                cells.append(f'{medal(ranks[(t, s)])}{fmt(v)}' if v is not None else '—')
        out.append(f'| {display_name(t)} | ' + ' | '.join(cells) + ' |')
    out.append('')
    out.append('Reference combos: ' + ', '.join(f'{s.capitalize()} = {ref_desc[s]}' for s in scenarios) + '.')
    return '\n'.join(out)


def latency_table(results, scenario='perf-test'):
    """Latency percentiles at the heaviest combo of a scenario."""
    subset = [r for r in results if r['scenario'] == scenario and r.get('latency')]
    if not subset:
        return None
    top = max(combo_sort_key(r) for r in subset)
    subset = [r for r in subset if combo_sort_key(r) == top]
    subset.sort(key=lambda r: r['latency'].get('med') or 1e12)
    out = [f'Latency distribution at {combo_label(subset[0])} (ms).',
           '',
           '| Framework | avg | med | p90 | p95 | p99 | max |',
           '|-----------|----:|----:|----:|----:|----:|----:|']
    for r in subset:
        l = r['latency']
        cells = [f"{(l.get(k) or 0):,.1f}" for k in ('avg', 'med', 'p90', 'p95', 'p99', 'max')]
        out.append(f'| {display_name(r["tag"])} | ' + ' | '.join(cells) + ' |')
    return '\n'.join(out)


def resource_table(path):
    if not os.path.isfile(path):
        return None
    data = json.load(open(path))
    rows = sorted(data.items(), key=lambda kv: kv[1].get('peakMemMb') or 0)
    out = ['| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |',
           '|---------|----------------:|----------------:|------------:|']
    for name, s in rows:
        out.append(f"| {display_name(name)} | {s.get('peakMemMb', 0):,.1f} | {s.get('avgMemMb', 0):,.1f} | {s.get('avgCpu', 0):,.2f} |")
    return '\n'.join(out)


K6_EXIT = {
    '99': 'a threshold was crossed (p99 >= 1 s, or 1% failed requests)',
    '105': 'interrupted',
    '107': 'script error',
    '108': 'aborted',
}


def aborts_table(path, extended=None):
    """Tests that did not end with exit code 0, with what the exit code means and, when the extended rows are
    there, the numbers that decide which it was: failed requests (an abort) or p99 (the latency objective)."""
    if not os.path.isfile(path):
        return None
    bad = []
    with open(path) as f:
        for row in csv.DictReader(f):
            if row.get('exit_code') not in (None, '', '0'):
                bad.append(row)
    if not bad:
        return 'Every test ended with exit code 0: no threshold was crossed, nothing was aborted.'
    by_window = {(e['tag'], e.get('_start')): e for e in (extended or [])}
    counts = defaultdict(int)
    for row in bad:
        counts[row['exit_code']] += 1
    out = [', '.join(f"{n} test(s) with exit code {c}: {K6_EXIT.get(c, 'see the k6 documentation')}" for c, n in sorted(counts.items())) + '.',
           '',
           'Exit code 99 with zero failed requests means the latency objective (p99 < 1 s) was missed; the test ran to its end and its numbers are valid.',
           '',
           '| Service | Test | Exit code | Failed requests | p99 (ms) |',
           '|---------|------|----------:|----------------:|---------:|']
    for row in bad:
        e = by_window.get((row['tag'], row.get('start_epoch')))
        test = combo_label(e) + ' ' + e['scenario'] if e else (row.get('params') or row['script'])
        failed = e.get('failed', '') if e else ''
        p99 = f"{e['latency']['p99']:,.0f}" if e and e.get('latency', {}).get('p99') is not None else ''
        out.append(f"| {display_name(row['tag'])} | {test} | {row['exit_code']} | {failed} | {p99} |")
    return '\n'.join(out)


SCRIPT_SCENARIO = {
    'script.js': 'perf-test',
    'scenarios/minimal-baseline.js': 'minimal',
    'scenarios/post-body.js': 'post',
    'scenarios/nested-json.js': 'nested',
    'scenarios/large-payload.js': 'large',
    'scenarios/many-params.js': 'params',
    'scenarios/table-get.js': 'table-get',
    'scenarios/table-list.js': 'table-list',
    'scenarios/table-insert.js': 'table-insert',
}


def read_stats(path):
    """[(epoch, cpu_percent, mem_mb)] from a stats csv written by run-benchmark.sh."""
    rows = []
    if not os.path.isfile(path):
        return rows
    with open(path) as f:
        for row in csv.DictReader(f):
            try:
                rows.append((int(row['timestamp']), float(row['cpu_percent'] or 0), float(row['mem_usage_mb'] or 0)))
            except (ValueError, KeyError):
                continue
    return rows


def window(stats, start, end):
    """avg cpu, peak cpu, avg mem, peak mem of the samples inside [start, end]; None when there are none."""
    inside = [(c, m) for t, c, m in stats if start <= t <= end]
    if not inside:
        return None
    cpus = [c for c, _ in inside]
    mems = [m for _, m in inside]
    return (sum(cpus) / len(cpus), max(cpus), sum(mems) / len(mems), max(mems))


def cpuset_cores(cpuset):
    """"4-7" -> 4, "0,1" -> 2, "" -> None."""
    if not cpuset:
        return None
    n = 0
    for part in cpuset.split(','):
        if '-' in part:
            a, b = part.split('-')
            n += int(b) - int(a) + 1
        else:
            n += 1
    return n


# A component whose average CPU over a test is at least this share of the cores it may use is "at its limit".
LIMIT_SHARE = 0.85


def extend_results(run_dir, results):
    """Join every result with its test_log row (by service and k6 parameters) and with the resource samples of
    its time window. Returns the extended rows, and writes results_extended.csv. Without a params column in
    test_log.csv (runs before November 2026) nothing can be joined and the list is empty."""
    log_path = os.path.join(run_dir, 'test_log.csv')
    if not os.path.isfile(log_path):
        return [], None
    env = {}
    env_path = os.path.join(run_dir, 'stats', 'environment.json')
    if os.path.isfile(env_path):
        try:
            env = json.load(open(env_path))
        except ValueError:
            env = {}
    cores = {c.get('service'): cpuset_cores(c.get('cpuset', '')) for c in env.get('containers', [])}
    host_cpus = (env.get('host') or {}).get('cpus')

    log = {}
    with open(log_path) as f:
        for row in csv.DictReader(f):
            if not row.get('params'):
                continue
            params = dict(kv.split('=', 1) for kv in row['params'].split(';') if '=' in kv)
            key = (row['tag'], SCRIPT_SCENARIO.get(row['script']), params.get('TARGET'),
                   params.get('RECORDS'), params.get('DEPTH'), params.get('SIZE_KB'))
            log[key] = row
    if not log:
        return [], env

    stats_dir = os.path.join(run_dir, 'stats')
    pg = read_stats(os.path.join(stats_dir, 'infra', 'postgres_stats.csv'))
    k6 = read_stats(os.path.join(stats_dir, 'infra', 'k6_stats.csv'))
    service_stats = {}

    def text(v):
        return None if v is None else str(v)

    extended = []
    for r in results:
        # scenarios that take no RECORDS parameter still record a records value in their result: try both
        candidates = [
            (r['tag'], r['scenario'], text(r['vus']), text(r.get('records')), text(r.get('depth')), text(r.get('sizeKb'))),
            (r['tag'], r['scenario'], text(r['vus']), None, text(r.get('depth')), text(r.get('sizeKb'))),
        ]
        row = next((log[k] for k in candidates if k in log), None)
        e = dict(r)
        if row:
            start, end = int(row['start_epoch']), int(row['end_epoch'])
            e['_start'] = row['start_epoch']
            e['exitCode'] = row['exit_code']
            # PostgreSQL's own numbers for the test (pg_stat_statements, see run-all.sh)
            for src, dst in (('pg_calls', 'pgCalls'), ('pg_exec_ms', 'pgExecMs'), ('pg_rows', 'pgRows'), ('pg_connections', 'pgConnections')):
                try:
                    e[dst] = float(row[src]) if src == 'pg_exec_ms' else int(row[src])
                except (KeyError, TypeError, ValueError):
                    pass
            if e.get('pgCalls') and e.get('pgExecMs') is not None:
                e['pgExecMsPerCall'] = e['pgExecMs'] / e['pgCalls']
                lat = (r.get('latency') or {}).get('avg')
                if lat:
                    # the share of an average request's time that PostgreSQL spent executing its statement
                    e['dbTimeShare'] = min(1.0, e['pgExecMsPerCall'] / lat)
            # the rest of what k6 measured, from the complete summary of the test
            k6_path = os.path.join(run_dir, 'k6', str(r.get('summaryFile', '')).replace('_summary.txt', '.json'))
            if os.path.isfile(k6_path):
                try:
                    metrics = json.load(open(k6_path)).get('metrics', {})
                    waiting = metrics.get('http_req_waiting', {}).get('values', {})
                    e['ttfbAvg'], e['ttfbP99'] = waiting.get('avg'), waiting.get('p(99)')
                    checks = metrics.get('checks', {}).get('values', {})
                    if checks.get('passes') is not None:
                        total = checks.get('passes', 0) + checks.get('fails', 0)
                        e['checksPassed'] = checks['passes'] / total if total else None
                except (ValueError, OSError):
                    pass
            if r['tag'] not in service_stats:
                service_stats[r['tag']] = read_stats(os.path.join(stats_dir, f"{r['tag']}_stats.csv"))
            for name, stats in (('svc', service_stats[r['tag']]), ('pg', pg), ('k6', k6)):
                w = window(stats, start, end)
                if w:
                    e[f'{name}CpuAvg'], e[f'{name}CpuPeak'], e[f'{name}MemAvgMb'], e[f'{name}MemPeakMb'] = w
            # which of the three ran out of CPU: the cores each may use come from its cpuset
            limits = []
            for name, service in (('service', r['tag']), ('postgres', 'postgres'), ('k6', 'test')):
                avg = e.get({'service': 'svcCpuAvg', 'postgres': 'pgCpuAvg', 'k6': 'k6CpuAvg'}[name])
                n = cores.get(service) or host_cpus
                if avg is not None and n and avg >= LIMIT_SHARE * 100 * n:
                    limits.append(name)
            e['atLimit'] = '+'.join(limits)
            if e.get('svcCpuAvg'):
                e['rpsPerCore'] = r['rps'] / (e['svcCpuAvg'] / 100)
        extended.append(e)

    columns = ['scenario', 'tag', 'vus', 'records', 'depth', 'sizeKb', 'duration', 'requests', 'rps',
               'latencyAvg', 'latencyMed', 'latencyP90', 'latencyP95', 'latencyP99', 'latencyMax',
               'dataReceivedBytes', 'dataSentBytes', 'failed', 'exitCode',
               'svcCpuAvg', 'svcCpuPeak', 'svcMemAvgMb', 'svcMemPeakMb', 'pgCpuAvg', 'pgCpuPeak',
               'k6CpuAvg', 'k6CpuPeak', 'atLimit', 'rpsPerCore',
               'rpsHold', 'ttfbAvg', 'ttfbP99', 'checksPassed',
               'pgCalls', 'pgExecMs', 'pgRows', 'pgConnections', 'pgExecMsPerCall', 'dbTimeShare']
    with open(os.path.join(run_dir, 'results_extended.csv'), 'w', newline='') as f:
        w = csv.writer(f, quoting=csv.QUOTE_NONNUMERIC)
        w.writerow(columns)
        for e in extended:
            lat = e.get('latency') or {}
            flat = dict(e, latencyAvg=lat.get('avg'), latencyMed=lat.get('med'), latencyP90=lat.get('p90'),
                        latencyP95=lat.get('p95'), latencyP99=lat.get('p99'), latencyMax=lat.get('max'))
            w.writerow(['' if flat.get(c) is None else (round(flat[c], 4) if isinstance(flat[c], float) else flat[c]) for c in columns])
    return extended, env


def limit_section(extended):
    """Which component was out of CPU in each test. A benchmark of services is only about the services where
    the service is the one at its limit; where the database or the load generator is, the test measures those."""
    measured = [e for e in extended if 'atLimit' in e and e.get('svcCpuAvg') is not None]
    if not measured:
        return None
    total = len(measured)
    counts = defaultdict(int)
    for e in measured:
        counts[e['atLimit'] or 'none'] += 1
    order = sorted(counts.items(), key=lambda kv: -kv[1])
    out = [f'A component is "at its limit" in a test when its average CPU over the test was at least '
           f'{int(LIMIT_SHARE * 100)}% of the cores it may use. Of {total} tests with resource samples:',
           '',
           '| At its limit | Tests | Share |', '|--------------|------:|------:|']
    names = {'none': 'nothing (latency or the concurrency level set the pace)', 'service': 'the service under test',
             'postgres': 'PostgreSQL', 'k6': 'the load generator'}
    for key, n in order:
        label = ' and '.join(names.get(k, k) for k in key.split('+'))
        out.append(f'| {label} | {n} | {100 * n / total:.0f}% |')
    by_scenario = defaultdict(lambda: defaultdict(int))
    for e in measured:
        for part in (e['atLimit'] or 'none').split('+'):
            by_scenario[e['scenario']][part] += 1
    out += ['', '| Scenario | Tests | Service | PostgreSQL | Load generator | Nothing |',
            '|----------|------:|--------:|-----------:|---------------:|--------:|']
    for s in sorted(by_scenario):
        n = sum(1 for e in measured if e['scenario'] == s)
        c = by_scenario[s]
        out.append(f"| {s} | {n} | {c['service']} | {c['postgres']} | {c['k6']} | {c['none']} |")
    out += ['', 'Read a throughput number as a statement about a service only in tests where the service was at its '
                'limit and neither PostgreSQL nor the load generator was. `results_extended.csv` has the column `atLimit` for every test.']
    return '\n'.join(out)


def efficiency_table(extended):
    """Requests per second for each CPU core the service actually used, at the perf-test reference test."""
    perf = [e for e in extended if e['scenario'] == 'perf-test' and e.get('rpsPerCore')]
    if not perf:
        return None
    vus = sorted({e['vus'] for e in perf})
    ref_vus = 100 if 100 in vus else vus[-1]
    recs = min(e['records'] for e in perf)
    rows = [e for e in perf if e['vus'] == ref_vus and e['records'] == recs]
    rows.sort(key=lambda e: -e['rpsPerCore'])
    out = [f'perf-test at {ref_vus} VU, {recs} record(s). CPU cores used = average CPU of the service during the test / 100.',
           '',
           '| Framework | Requests/s | CPU cores used | Requests/s per core | Peak memory (MB) |',
           '|-----------|-----------:|---------------:|--------------------:|-----------------:|']
    for i, e in enumerate(rows):
        out.append(f"| {display_name(e['tag'])} | {fmt(e['rps'])} | {e['svcCpuAvg'] / 100:.2f} | {medal(i)}{fmt(e['rpsPerCore'])} | {e.get('svcMemPeakMb', 0):,.0f} |")
    return '\n'.join(out)


def memory_table(extended):
    """Peak memory of each service per scenario: the highest value in any test of that scenario."""
    rows = [e for e in extended if e.get('svcMemPeakMb')]
    if not rows:
        return None
    scenarios = [s for s in ['perf-test'] + OTHER_SCENARIOS if any(e['scenario'] == s for e in rows)]
    peak = defaultdict(dict)
    for e in rows:
        peak[e['tag']][e['scenario']] = max(peak[e['tag']].get(e['scenario'], 0), e['svcMemPeakMb'])
    tags = sorted(peak, key=lambda t: max(peak[t].values()))
    ranks = {}
    for s in scenarios:
        ordered = sorted((peak[t][s], t) for t in peak if s in peak[t])
        for i, (_, t) in enumerate(ordered):
            ranks[(t, s)] = i
    out = ['Peak memory in MB of the service container during the tests of each scenario (the highest of all its',
           'concurrency levels and sizes), sampled once a second. Memory is what `docker stats` reports: the',
           "container's memory without the file cache the kernel can drop. Lowest first; medals for the three lowest.",
           '',
           '| Framework | ' + ' | '.join(scenarios) + ' | Highest |',
           '|-----------|' + '|'.join(['---:'] * (len(scenarios) + 1)) + '|']
    for t in tags:
        cells = [f"{medal(ranks[(t, s)])}{peak[t][s]:,.0f}" if s in peak[t] else '—' for s in scenarios]
        out.append(f"| {display_name(t)} | " + ' | '.join(cells) + f" | {max(peak[t].values()):,.0f} |")
    return '\n'.join(out)


def database_time_table(extended):
    """Per scenario at its reference test: how much of a request's time PostgreSQL spent executing."""
    rows = [e for e in extended if e.get('pgExecMsPerCall') is not None and not e.get('invalid')]
    if not rows:
        return None
    scenarios = [s for s in OTHER_SCENARIOS if any(e['scenario'] == s for e in rows)]
    cell = defaultdict(dict)
    for s in scenarios:
        subset = [e for e in rows if e['scenario'] == s and REFERENCE[s](e)]
        if not subset:
            top = max(combo_sort_key(e) for e in rows if e['scenario'] == s)
            subset = [e for e in rows if e['scenario'] == s and combo_sort_key(e) == top]
        for e in subset:
            cell[e['tag']][s] = e
    if not cell:
        return None
    out = ['For each scenario at its reference test: milliseconds PostgreSQL spent executing one statement of the',
           'service (pg_stat_statements: total execution time / calls), and in brackets that time as a share of the',
           "average request latency k6 measured. The rest of a request's time is the service, the driver, the",
           'network between the containers and waiting for a connection. Planning time is not included.',
           '',
           '| Framework | ' + ' | '.join(scenarios) + ' | Connections |',
           '|-----------|' + '|'.join(['---:'] * (len(scenarios) + 1)) + '|']
    for t in sorted(cell, key=display_name):
        cells = []
        for s in scenarios:
            e = cell[t].get(s)
            if not e:
                cells.append('—')
            else:
                share = f" ({e['dbTimeShare'] * 100:.0f}%)" if e.get('dbTimeShare') is not None else ''
                cells.append(f"{e['pgExecMsPerCall']:.3f}{share}")
        conns = [e['pgConnections'] for e in cell[t].values() if e.get('pgConnections') is not None]
        out.append(f"| {display_name(t)} | " + ' | '.join(cells) + f" | {max(conns) if conns else '—'} |")
    out.append('')
    out.append('Connections: the most connections the service held open at the end of any of these tests.')
    return '\n'.join(out)


def footprint_table(run_dir):
    """Image size, time to the first answer and idle memory (stats/services.csv, measure-services.sh)."""
    path = os.path.join(run_dir, 'stats', 'services.csv')
    if not os.path.isfile(path):
        return None
    rows = list(csv.DictReader(open(path)))
    if not rows:
        return None

    def num(v):
        try:
            return float(v)
        except (TypeError, ValueError):
            return None
    rows.sort(key=lambda r: num(r.get('idleMemMb')) if num(r.get('idleMemMb')) is not None else 1e12)
    out = ['Measured once per service before the tests: the size of its image, the time from restarting its container',
           'to its first correct answer, and its memory ten seconds after that answer, before any load. Lowest idle',
           'memory first.',
           '',
           '| Framework | Idle memory (MB) | First answer after (ms) | Image (MB) |',
           '|-----------|-----------------:|------------------------:|-----------:|']
    for r in rows:
        idle, start, image = num(r.get('idleMemMb')), num(r.get('startupMs')), num(r.get('imageMb'))
        out.append(f"| {display_name(r['service'])} | " + ' | '.join(
            '—' if v is None else f'{v:,.0f}' for v in (idle, start, image)) + ' |')
    return '\n'.join(out)


def environment_section(env):
    if not env:
        return None
    host = env.get('host') or {}
    out = [f"- Started: {env.get('startedUtc', '?')} (UTC), commit `{(env.get('gitCommit') or '?')[:12]}`"
           + (' with uncommitted changes' if env.get('gitDirty') else ''),
           f"- Host: {host.get('cpuModel', '?')}, {host.get('cpus', '?')} CPUs, {host.get('memoryMb', '?')} MB, {host.get('os', '?')}, kernel {host.get('kernel', '?')}",
           f"- Docker {host.get('docker', '?')}, Compose {host.get('compose', '?')}, PostgreSQL {env.get('postgres', '?')}, {env.get('k6', '?')}",
           '',
           '| Container | Image | CPU set |', '|-----------|-------|---------|']
    for c in sorted(env.get('containers', []), key=lambda c: c.get('service') or ''):
        out.append(f"| {c.get('service')} | `{c.get('image')}` ({(c.get('imageId') or '')[7:19]}) | {c.get('cpuset') or 'all'} |")
    return '\n'.join(out)


def loc_table(src_dir, tags):
    """Lines of code per service (source files; config-only services count their config)."""
    counts = {}
    for tag in sorted(set(tags)):
        d = os.path.join(src_dir, tag)
        if not os.path.isdir(d):
            continue
        total = 0
        config_only = next((exts for k, exts in LOC_CONFIG_ONLY.items() if tag.startswith(k)), None)
        for root, dirs, files in os.walk(d):
            dirs[:] = [x for x in dirs if x not in ('node_modules', 'obj', 'bin', 'target', '__pycache__')]
            for fn in files:
                if config_only:
                    if fn not in config_only:
                        continue
                elif not fn.endswith(LOC_EXTENSIONS) or fn == 'Cargo.lock':
                    continue
                try:
                    with open(os.path.join(root, fn), errors='ignore') as f:
                        total += sum(1 for line in f if line.strip())
                except OSError:
                    pass
        # SQL Files services also ship the shared raw queries
        if tag.startswith('npgsqlrest-file'):
            sql_dir = os.path.join(src_dir, '_sql_files')
            if os.path.isdir(sql_dir):
                for fn in os.listdir(sql_dir):
                    if fn.endswith('.sql'):
                        with open(os.path.join(sql_dir, fn), errors='ignore') as f:
                            total += sum(1 for line in f if line.strip())
        counts[tag] = total
    out = ['| Framework | Lines of Code |', '|-----------|--------------:|']
    for tag, n in sorted(counts.items(), key=lambda kv: kv[1]):
        suffix = (' (config + the SQL files)' if tag.startswith('npgsqlrest-file')
                  else ' (config only)' if any(tag.startswith(k) for k in LOC_CONFIG_ONLY) else '')
        out.append(f'| {display_name(tag)} | {n}{suffix} |')
    return '\n'.join(out)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    run_dir = sys.argv[1].rstrip('/')
    data_path = os.path.join(run_dir, 'results.json')
    if not os.path.isfile(data_path):
        sys.exit(f'error: {data_path} not found (produced by run-all.sh)')

    data = json.load(open(data_path))
    meta = data.get('meta', {})
    results = data.get('results', data if isinstance(data, list) else [])
    # A test in which more than 1% of the requests failed is not a throughput result: errors are answered
    # faster than work is done. It is shown as "failed" and ranks last (rps 0), never with a number.
    for r in results:
        if r.get('requests') and (r.get('failed') or 0) > 0.01 * r['requests']:
            r['invalid'] = True
            r['rpsReported'] = r['rps']
            r['rps'] = 0.0
    src_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(run_dir))))

    sections = []
    stamp = meta.get('stamp', os.path.basename(run_dir))
    sections.append(f'# Benchmark Report {stamp}\n')
    sections.append(f"**Profile:** {meta.get('profile', '?')} · **Ramp:** {meta.get('ramp', '?')} · "
                    f"**Warmup:** {meta.get('warmup', '?')} · **Sleep between tests:** {meta.get('sleepBetween', '?')}s · "
                    f"**Tests:** {len(results)}\n")
    sections.append('All throughput values are requests/s. 🥇🥈🥉 mark the top three per column.\n')

    perf = [r for r in results if r['scenario'] == 'perf-test']
    if perf:
        sections.append('## Data Type Serialization (perf-test)\n')
        vus_ref = sorted({r['vus'] for r in perf})
        ref_col = None
        for r in perf:
            if r['vus'] == (100 if 100 in vus_ref else vus_ref[-1]) and r['records'] == 1:
                ref_col = combo_label(r)
                break
        sections.append('### Throughput matrix\n')
        sections.append(pivot_table(perf, sort_col=ref_col) + '\n')
        sections.append('### Scaling behavior\n')
        sections.append(scaling_table(perf) + '\n')
        lat = latency_table(results, 'perf-test')
        if lat:
            sections.append('### Latency under heaviest load\n')
            sections.append(lat + '\n')

    others = [s for s in OTHER_SCENARIOS if any(r['scenario'] == s for r in results)]
    if others:
        sections.append('## Cross-Scenario Summary\n')
        sections.append(cross_scenario_table(results) + '\n')
        titles = {'minimal': 'Minimal Baseline', 'post': 'POST Body Parsing',
                  'nested': 'Nested JSON', 'large': 'Large Payload', 'params': 'Many Parameters',
                  'table-get': 'Table: One Row by Primary Key', 'table-list': 'Table: One Page of a List',
                  'table-insert': 'Table: Insert Returning the Row'}
        for s in others:
            sections.append(f'## {titles[s]} ({s})\n')
            sections.append(pivot_table([r for r in results if r['scenario'] == s]) + '\n')

    res = resource_table(os.path.join(run_dir, 'resource_usage.json'))
    if res:
        sections.append('## Resource Usage (during test windows only)\n')
        sections.append(res + '\n')

    extended, env = extend_results(run_dir, results)
    if extended:
        print(f"wrote {os.path.join(run_dir, 'results_extended.csv')}")
    limit = limit_section(extended)
    if limit:
        sections.append('## What Was at Its Limit\n')
        sections.append(limit + '\n')
    footprint = footprint_table(run_dir)
    if footprint:
        sections.append('## Service Footprint\n')
        sections.append(footprint + '\n')
    database = database_time_table(extended)
    if database:
        sections.append('## Time in PostgreSQL\n')
        sections.append(database + '\n')
    memory = memory_table(extended)
    if memory:
        sections.append('## Memory by Scenario\n')
        sections.append(memory + '\n')
    efficiency = efficiency_table(extended)
    if efficiency:
        sections.append('## Throughput per CPU Core\n')
        sections.append(efficiency + '\n')

    aborts = aborts_table(os.path.join(run_dir, 'test_log.csv'), extended)
    if aborts:
        sections.append('## Test Completion\n')
        sections.append(aborts + '\n')

    tags = {r['tag'] for r in results}
    loc = loc_table(src_dir, tags)
    sections.append('## Lines of Code\n')
    sections.append(loc + '\n')

    environment = environment_section(env)
    if environment:
        sections.append('## Run Environment\n')
        sections.append(environment + '\n')

    out_path = os.path.join(run_dir, 'report.md')
    with open(out_path, 'w') as f:
        f.write('\n'.join(sections))
    print(f'wrote {out_path}')


if __name__ == '__main__':
    main()
