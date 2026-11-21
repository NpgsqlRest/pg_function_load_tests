// Two things every scenario script records besides its own summary:
//
// 1. Requests during the hold stage only. "rps" in the results is all requests divided by the whole run,
//    ramp included; the ramp has fewer virtual users, so that number is a little below the rate at the
//    target. "rpsHold" is the rate after the ramp. "rps" is kept as it was, so rounds stay comparable.
// 2. The complete k6 summary of the test as JSON (results/<stamp>/k6/<test>.json): every metric k6 has,
//    not only the ones the results table uses (time to first byte, connection time, checks, iterations).
import exec from 'k6/execution';
import { Counter } from 'k6/metrics';

const holdRequests = new Counter('hold_reqs');

// '10s', '500ms', '2m' -> seconds
export function seconds(text) {
    const m = /^([0-9.]+)(ms|s|m)$/.exec(String(text).trim());
    if (!m) {
        return 0;
    }
    return Number(m[1]) * { ms: 0.001, s: 1, m: 60 }[m[2]];
}

// Call once per request, after it: counts it when the ramp is over.
export function countHold(rampSeconds) {
    if (exec.instance.currentTestRunDuration >= rampSeconds * 1000) {
        holdRequests.add(1);
    }
}

export function holdRps(data, holdSeconds) {
    const metric = data.metrics.hold_reqs;
    return metric && holdSeconds > 0 ? metric.values.count / holdSeconds : null;
}

// An entry for handleSummary's result: the whole summary, as k6 gives it.
export function rawSummary(stamp, fileTag, data) {
    const out = {};
    out['/results/' + stamp + '/k6/' + fileTag + '.json'] = JSON.stringify(data);
    return out;
}
