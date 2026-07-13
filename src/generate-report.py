#!/usr/bin/env python3
"""
Generate blog-ready analysis views from a benchmark run's results.json.

Usage:
    python3 generate-report.py _k6/results/<stamp>

Reads:
    <dir>/results.json        (written by run-all.sh)
    <dir>/resource_usage.json (optional, written by run-benchmark.sh)
    <dir>/test_log.csv        (optional, exit codes / aborts)

Writes:
    <dir>/report.md - pivot matrices with medals, scaling factors,
                      cross-scenario summary, resource usage, LOC table.

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
}

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
    for r in rows:
        by_tag[r['tag']][combo_label(r)] = r['rps']

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
    scenarios = [s for s in ['minimal', 'post', 'nested', 'large', 'params'] if any(r['scenario'] == s for r in results)]
    by_tag = defaultdict(dict)
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


def aborts_table(path):
    if not os.path.isfile(path):
        return None
    bad = []
    with open(path) as f:
        for row in csv.DictReader(f):
            if row.get('exit_code') not in (None, '', '0'):
                bad.append(row)
    if not bad:
        return 'No aborted or failed tests. Every result row represents a completed run.'
    out = ['| Service | Script | Exit code |', '|---------|--------|----------:|']
    for row in bad:
        out.append(f"| {display_name(row['tag'])} | {row['script']} | {row['exit_code']} |")
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
        suffix = ' (config only)' if any(tag.startswith(k) for k in LOC_CONFIG_ONLY) else ''
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

    others = [s for s in ['minimal', 'post', 'nested', 'large', 'params'] if any(r['scenario'] == s for r in results)]
    if others:
        sections.append('## Cross-Scenario Summary\n')
        sections.append(cross_scenario_table(results) + '\n')
        titles = {'minimal': 'Minimal Baseline', 'post': 'POST Body Parsing',
                  'nested': 'Nested JSON', 'large': 'Large Payload', 'params': 'Many Parameters'}
        for s in others:
            sections.append(f'## {titles[s]} ({s})\n')
            sections.append(pivot_table([r for r in results if r['scenario'] == s]) + '\n')

    res = resource_table(os.path.join(run_dir, 'resource_usage.json'))
    if res:
        sections.append('## Resource Usage (during test windows only)\n')
        sections.append(res + '\n')

    aborts = aborts_table(os.path.join(run_dir, 'test_log.csv'))
    if aborts:
        sections.append('## Test Completion\n')
        sections.append(aborts + '\n')

    tags = {r['tag'] for r in results}
    loc = loc_table(src_dir, tags)
    sections.append('## Lines of Code\n')
    sections.append(loc + '\n')

    out_path = os.path.join(run_dir, 'report.md')
    with open(out_path, 'w') as f:
        f.write('\n'.join(sections))
    print(f'wrote {out_path}')


if __name__ == '__main__':
    main()
