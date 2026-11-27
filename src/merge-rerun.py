#!/usr/bin/env python3
"""
Put repeated tests into a round.

Usage: merge-rerun.py <round dir> <rerun dir> ["reason"]

A rerun is a run made with RERUN_LIST (see run-all.sh): some tests of a round, repeated on the same machine
because something disturbed them the first time. This script replaces those tests in the round:

  - results.json / results.csv: the repeated tests replace the original ones (same service, scenario and
    parameters). meta.rerun records what was replaced and why.
  - test_log.csv: the original rows go to superseded/test_log.csv, the rerun's rows are added.
  - <test>_summary.txt and k6/<test>.json: the originals go to superseded/, the rerun's take their place.
  - superseded/results.json: the original results of the replaced tests, kept for anyone who wants to see
    what was replaced.
  - stats/*.csv: the rerun's samples are appended (they are later in time, so each test still finds its
    own window). stats/environment-rerun.json is the rerun's environment.
  - resource_usage.json / .md and <stamp>_all.md are rebuilt from the merged data.

Then run generate-report.py on the round. Nothing is deleted: every original file of a replaced test is in
superseded/.
"""
import csv
import json
import os
import shutil
import sys
from collections import defaultdict

GITHUB_BASE = 'https://github.com/NpgsqlRest/pg_function_load_tests'

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

CSV_COLUMNS = ['scenario', 'tag', 'vus', 'records', 'depth', 'sizeKb', 'duration', 'requests', 'rps',
               'latencyAvg', 'latencyMed', 'latencyP90', 'latencyP95', 'latencyP99', 'latencyMax',
               'dataReceivedBytes', 'dataSentBytes', 'failed', 'rpsHold']


def result_key(r):
    return (r['tag'], r['scenario'], r['vus'], r.get('records'), r.get('depth'), r.get('sizeKb'))


def log_key(row):
    return (row['tag'], row['script'], row['params'])


def load_results(run_dir):
    data = json.load(open(os.path.join(run_dir, 'results.json')))
    return data.get('meta', {}), data['results']


def read_log(run_dir):
    with open(os.path.join(run_dir, 'test_log.csv')) as f:
        reader = csv.DictReader(f)
        return reader.fieldnames, list(reader)


def write_log(path, fieldnames, rows):
    with open(path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, lineterminator='\n')
        w.writeheader()
        w.writerows(rows)


def write_results_csv(path, results):
    with open(path, 'w', newline='') as f:
        w = csv.writer(f, quoting=csv.QUOTE_NONNUMERIC, lineterminator='\n')
        w.writerow(CSV_COLUMNS)
        for r in results:
            lat = r.get('latency') or {}
            flat = dict(r, latencyAvg=lat.get('avg', r.get('avgLatency')), latencyMed=lat.get('med'),
                        latencyP90=lat.get('p90'), latencyP95=lat.get('p95'), latencyP99=lat.get('p99'),
                        latencyMax=lat.get('max'))
            w.writerow(['' if flat.get(c) is None else flat[c] for c in CSV_COLUMNS])


def resource_usage(run_dir, log_rows):
    """Peak and average memory and average CPU per service, over its test windows only (as run-benchmark.sh)."""
    windows = defaultdict(list)
    for row in log_rows:
        windows[row['tag']].append((int(row['start_epoch']), int(row['end_epoch'])))
    usage = {}
    stats_dir = os.path.join(run_dir, 'stats')
    for name in sorted(os.listdir(stats_dir)):
        if not name.endswith('_stats.csv'):
            continue
        service = name[:-len('_stats.csv')]
        spans = sorted(windows.get(service, []))
        peak = total_mem = total_cpu = count = 0
        with open(os.path.join(stats_dir, name)) as f:
            next(f, None)
            for line in f:
                parts = line.split(',')
                try:
                    t, cpu, mem = int(parts[0]), float(parts[1]), float(parts[2])
                except (ValueError, IndexError):
                    continue
                if any(s <= t <= e for s, e in spans):
                    peak = max(peak, mem)
                    total_mem += mem
                    total_cpu += cpu
                    count += 1
        usage[service] = ({'peakMemMb': round(peak, 2), 'avgMemMb': round(total_mem / count, 2),
                           'avgCpu': round(total_cpu / count, 2)} if count else
                          {'peakMemMb': 0, 'avgMemMb': 0, 'avgCpu': 0})
    return usage


def write_resource_usage(run_dir, usage):
    with open(os.path.join(run_dir, 'resource_usage.json'), 'w') as f:
        json.dump(usage, f, indent=2)
        f.write('\n')
    lines = ['# Resource Usage Summary', '',
             "Memory and CPU usage per service, measured ONLY during that service's test windows",
             '(idle periods are excluded via test_log.csv).', '',
             '| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |',
             '|---------|----------------:|----------------:|------------:|']
    for service, u in usage.items():
        lines.append(f"| {service} | {u['peakMemMb']:.2f} | {u['avgMemMb']:.2f} | {u['avgCpu']:.2f} |")
    with open(os.path.join(run_dir, 'resource_usage.md'), 'w') as f:
        f.write('\n'.join(lines) + '\n')


def write_all_md(path, stamp, profile, results):
    """The per-combination tables that run-all.sh writes (<stamp>_all.md), from the merged results."""
    blob = f'{GITHUB_BASE}/blob/{stamp}/src/_k6/results/{stamp}'
    tree = f'{GITHUB_BASE}/tree/{stamp}/src'
    out = ['# Benchmark Results', '', 'Results are grouped by concurrency level and payload size, sorted by requests per second (highest first).',
           '', f'**Profile:** {profile}', f'**Timestamp:** {stamp}', '']
    plans = [('perf-test', ('vus', 'records'), 'Data Type Serialization (perf_test)', '{vus} Virtual Users, {records} Records'),
             ('minimal', ('vus',), 'Minimal Baseline', '{vus} Virtual Users'),
             ('post', ('vus', 'records'), 'POST Body Parsing', '{vus} Virtual Users, {records} Records'),
             ('nested', ('vus', 'depth'), 'Nested JSON Serialization', '{vus} Virtual Users, Depth {depth}'),
             ('large', ('vus', 'sizeKb'), 'Large Payload', '{vus} Virtual Users, {sizeKb}KB Payload'),
             ('params', ('vus',), 'Many Parameters (20 params)', '{vus} Virtual Users'),
             ('table-get', ('vus',), 'Table: One Row by Primary Key', '{vus} Virtual Users'),
             ('table-list', ('vus',), 'Table: One Page of a List (20 rows)', '{vus} Virtual Users'),
             ('table-insert', ('vus',), 'Table: Insert Returning the Row', '{vus} Virtual Users')]
    for scenario, group, title, heading in plans:
        rows = [r for r in results if r['scenario'] == scenario]
        out += ['', '---', '', f'## {title}', '']
        if not rows:
            out.append('_No results for this scenario_')
            continue
        large = scenario == 'large'
        for combo in sorted({tuple(r.get(g) for g in group) for r in rows}):
            out.append('')
            out.append('### ' + heading.format(**dict(zip(group, combo))))
            if large:
                out.append('| Framework | Requests/s | Avg Latency | Total Requests | Data Received | Summary | Source |')
                out.append('|-----------|----------:|------------:|---------------:|--------------:|---------|--------|')
            else:
                out.append('| Framework | Requests/s | Avg Latency | Total Requests | Summary | Source |')
                out.append('|-----------|----------:|------------:|---------------:|---------|--------|')
            subset = [r for r in rows if tuple(r.get(g) for g in group) == combo]
            for r in sorted(subset, key=lambda r: -r['rps']):
                cells = [r['tag'], f"{r['rps']:.2f}/s", f"{r['avgLatency']:.2f}ms", str(int(r['requests']))]
                if large:
                    cells.append(f"{(r.get('dataReceivedBytes') or 0) / 1048576:.2f}MB")
                cells += [f"[summary]({blob}/{r['summaryFile']})", f"[source]({tree}/{r['tag']})"]
                out.append('| ' + ' | '.join(cells) + ' |')
    with open(path, 'w') as f:
        f.write('\n'.join(out) + '\n')


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    base_dir, rerun_dir = sys.argv[1].rstrip('/'), sys.argv[2].rstrip('/')
    reason = sys.argv[3] if len(sys.argv) > 3 else ''

    meta, results = load_results(base_dir)
    rerun_meta, rerun_results = load_results(rerun_dir)
    if any(r.get('stamp') == rerun_meta.get('stamp') for r in meta.get('reruns', [])):
        sys.exit(f"rerun {rerun_meta.get('stamp')} is already merged into this round")

    new = {result_key(r): r for r in rerun_results}
    unknown = [k for k in new if k not in {result_key(r) for r in results}]
    if unknown:
        sys.exit(f'{len(unknown)} rerun result(s) match no test of the round, for example {unknown[0]}: nothing merged')

    superseded_dir = os.path.join(base_dir, 'superseded')
    os.makedirs(os.path.join(superseded_dir, 'k6'), exist_ok=True)

    # results
    replaced = [r for r in results if result_key(r) in new]
    merged = [new.get(result_key(r), r) for r in results]
    for r in replaced:
        for sub, name in (('', r['summaryFile']), ('k6', r['summaryFile'].replace('_summary.txt', '.json'))):
            src = os.path.join(base_dir, sub, name)
            if os.path.isfile(src):
                shutil.move(src, os.path.join(superseded_dir, sub, name))
    for r in rerun_results:
        for sub, name in (('', r['summaryFile']), ('k6', r['summaryFile'].replace('_summary.txt', '.json'))):
            src = os.path.join(rerun_dir, sub, name)
            if os.path.isfile(src):
                shutil.copy2(src, os.path.join(base_dir, sub, name))
    old_path = os.path.join(superseded_dir, 'results.json')
    old = json.load(open(old_path)) if os.path.isfile(old_path) else []
    for r in replaced:
        r['supersededBy'] = rerun_meta.get('stamp')
    with open(old_path, 'w') as f:
        json.dump(old + replaced, f, indent=2)
        f.write('\n')

    # test log
    fieldnames, base_log = read_log(base_dir)
    rerun_fields, rerun_log = read_log(rerun_dir)
    rerun_keys = {log_key(row) for row in rerun_log}
    kept = [row for row in base_log if log_key(row) not in rerun_keys]
    moved = [row for row in base_log if log_key(row) in rerun_keys]
    fieldnames = fieldnames + [c for c in rerun_fields if c not in fieldnames]
    old_log = os.path.join(superseded_dir, 'test_log.csv')
    previous = read_log(superseded_dir)[1] if os.path.isfile(old_log) else []
    write_log(old_log, fieldnames, previous + moved)
    merged_log = kept + rerun_log
    write_log(os.path.join(base_dir, 'test_log.csv'), fieldnames, merged_log)

    # resource samples: append (the rerun is later in time)
    for sub in ('stats', os.path.join('stats', 'infra')):
        src_dir = os.path.join(rerun_dir, sub)
        if not os.path.isdir(src_dir):
            continue
        for name in os.listdir(src_dir):
            if not name.endswith('_stats.csv'):
                continue
            dst = os.path.join(base_dir, sub, name)
            with open(os.path.join(src_dir, name)) as f:
                lines = f.readlines()[1:]
            if os.path.isfile(dst):
                with open(dst, 'a') as f:
                    f.writelines(lines)
    env = os.path.join(rerun_dir, 'stats', 'environment.json')
    if os.path.isfile(env):
        shutil.copy2(env, os.path.join(base_dir, 'stats', f"environment-rerun-{rerun_meta.get('stamp')}.json"))

    meta.setdefault('reruns', []).append({
        'stamp': rerun_meta.get('stamp'),
        'tests': len(rerun_results),
        'reason': reason,
        'replaced': [{'tag': r['tag'], 'scenario': r['scenario'], 'vus': r['vus'], 'records': r.get('records'),
                      'depth': r.get('depth'), 'sizeKb': r.get('sizeKb'), 'rpsBefore': r['rps'],
                      'failedBefore': r.get('failed')} for r in replaced],
    })
    with open(os.path.join(base_dir, 'results.json'), 'w') as f:
        json.dump({'meta': meta, 'results': merged}, f, indent=2)
        f.write('\n')
    write_results_csv(os.path.join(base_dir, 'results.csv'), merged)
    write_resource_usage(base_dir, resource_usage(base_dir, merged_log))
    stamp = meta.get('stamp') or os.path.basename(base_dir)
    write_all_md(base_dir + '_all.md', stamp, meta.get('profile', ''), merged)

    print(f"{len(rerun_results)} test(s) of rerun {rerun_meta.get('stamp')} merged into {base_dir}")
    print(f"the originals are in {superseded_dir}")
    print(f"now run: python3 generate-report.py {base_dir}")


if __name__ == '__main__':
    main()
