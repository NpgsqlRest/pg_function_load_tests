#!/usr/bin/env python3
"""
Compare two benchmark runs: what changed between two rounds, service by service.

Usage:
    python3 compare-runs.py _k6/results/<old-stamp> _k6/results/<new-stamp>

Reads results.json of both runs and writes <new-dir>/comparison.md and <new-dir>/comparison.csv.

Services are matched by name without the version ("django-app-v6.0.7" and "django-app-v6.1.3" are the same
service), tests by scenario and parameters. A service that has the SAME version in both runs (for example
NpgsqlRest 3.21.0 kept as it was) is a control: it did not change, so its difference between the two runs is
what the machine, PostgreSQL, the load generator and the method changed. The comparison prints the controls
first, and every other difference should be read against them.
"""

import csv
import importlib.util
import json
import os
import re
import statistics
import sys
from collections import defaultdict

_spec = importlib.util.spec_from_file_location('report', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'generate-report.py'))
report = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(report)


def base_and_version(tag):
    if 'octane' in tag:  # laravel-v13.43.0-octane-app: version in the middle (see generate-report.py)
        return 'laravel-octane-app', tag.split('-v')[-1].split('-')[0]
    m = re.match(r'^(.*?)(?:-v([\d.]+))?$', tag)
    return m.group(1), (m.group(2) or '')


def load(run_dir):
    data = json.load(open(os.path.join(run_dir, 'results.json')))
    results = data.get('results', data if isinstance(data, list) else [])
    # (base name, version) -> {test key: rps}
    by_service = defaultdict(dict)
    for r in results:
        key = (r['scenario'], r['vus'], r.get('records'), r.get('depth'), r.get('sizeKb'))
        by_service[base_and_version(r['tag'])][key] = r
    return data.get('meta', {}), by_service


def pick_pairs(old, new):
    """Pairs (old service, new service) to compare. Same name and version first (controls). Otherwise the newest
    version of a name in the new run against the newest version of that name in the old run."""
    def version_key(v):
        return tuple(int(x) for x in v.split('.') if x.isdigit())
    pairs = []
    for base in sorted({b for b, _ in new}):
        new_versions = sorted((v for b, v in new if b == base), key=version_key)
        old_versions = sorted((v for b, v in old if b == base), key=version_key)
        if not old_versions:
            continue
        for v in new_versions:
            if v in old_versions:
                pairs.append(((base, v), (base, v), True))
        newest = new_versions[-1]
        if newest not in old_versions:
            pairs.append(((base, old_versions[-1]), (base, newest), False))
    return pairs


def tag_of(service):
    base, version = service
    return f'{base}-v{version}' if version else base


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    old_dir, new_dir = (a.rstrip('/') for a in sys.argv[1:3])
    old_meta, old = load(old_dir)
    new_meta, new = load(new_dir)
    pairs = pick_pairs(old, new)

    rows = []
    summary = []
    for old_service, new_service, control in pairs:
        ratios = []
        for key, r_new in new[new_service].items():
            r_old = old[old_service].get(key)
            if not r_old or not r_old.get('rps') or not r_new.get('rps'):
                continue
            ratio = r_new['rps'] / r_old['rps']
            ratios.append(ratio)
            rows.append([tag_of(old_service), tag_of(new_service), 'control' if control else 'changed',
                         r_new['scenario'], report.combo_label(r_new), round(r_old['rps'], 2), round(r_new['rps'], 2),
                         round((ratio - 1) * 100, 2)])
        if ratios:
            summary.append((old_service, new_service, control, len(ratios), statistics.geometric_mean(ratios), min(ratios), max(ratios)))

    def line(s):
        old_service, new_service, control, n, mean, low, high = s
        name = report.display_name(tag_of(new_service))
        was = '' if control else f' (was {old_service[1] or "unversioned"})'
        return f'| {name}{was} | {n} | {(mean - 1) * 100:+.1f}% | {(low - 1) * 100:+.1f}% | {(high - 1) * 100:+.1f}% |'

    header = ['| Service | Tests in both runs | Requests/s, geometric mean | Smallest change | Largest change |',
              '|---------|-------------------:|--------------------------:|----------------:|---------------:|']
    controls = [s for s in summary if s[2]]
    changed = sorted((s for s in summary if not s[2]), key=lambda s: -s[4])
    out = [f"# Run {new_meta.get('stamp', os.path.basename(new_dir))} against {old_meta.get('stamp', os.path.basename(old_dir))}", '',
           'Change of requests/s per service, over the tests both runs have (same scenario and parameters).', '']
    out += ['## Controls: the same version in both runs', '',
            'These services did not change. Their difference is what the machine, PostgreSQL, the load generator and the '
            'method changed between the two runs: read every other number against it.', '']
    out += (header + [line(s) for s in controls]) if controls else ['_No service has the same version in both runs._']
    if controls:
        baseline = statistics.geometric_mean([s[4] for s in controls])
        out += ['', f'Controls together: {(baseline - 1) * 100:+.1f}%.']
    out += ['', '## Services with a new version', ''] + header + [line(s) for s in changed]
    only_new = sorted({b for b, _ in new} - {b for b, _ in old})
    only_old = sorted({b for b, _ in old} - {b for b, _ in new})
    if only_new:
        out += ['', 'New in this run: ' + ', '.join(report.display_name(b) for b in only_new) + '.']
    if only_old:
        out += ['', 'No longer in this run: ' + ', '.join(report.display_name(b) for b in only_old) + '.']

    with open(os.path.join(new_dir, 'comparison.md'), 'w') as f:
        f.write('\n'.join(out) + '\n')
    with open(os.path.join(new_dir, 'comparison.csv'), 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['oldService', 'newService', 'kind', 'scenario', 'test', 'oldRps', 'newRps', 'changePercent'])
        w.writerows(rows)
    print(f"wrote {os.path.join(new_dir, 'comparison.md')} and comparison.csv ({len(rows)} test pairs)")


if __name__ == '__main__':
    main()
