import { check } from "k6";
import http from "k6/http";
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

const stamp = __ENV.STAMP.trim();
const tag = __ENV.TAG.trim();
const port = __ENV.PORT.trim();
const duration = __ENV.DURATION ? __ENV.DURATION.trim() : "30s";
const target = Number(__ENV.TARGET ? __ENV.TARGET.trim() : "100");

// Determine the path based on the service type
function getPath(tag) {
    if (tag.indexOf('postgrest') !== -1) {
        return '/rpc/perf_minimal';
    }
    return '/api/perf-minimal';
}

const path = getPath(tag);
const url = 'http://' + tag + ':' + port + path;

export const options = {
    thresholds: {
        http_req_failed: [{ threshold: "rate<0.01", abortOnFail: true }],
        http_req_duration: ["p(99)<100"], // Should be very fast
    },
    scenarios: {
        baseline: {
            executor: "ramping-vus",
            stages: [
                { duration: duration, target: target },
            ],
        },
    },
};

export default function () {
    const res = http.get(url);
    check(res, {
        [`${tag} status is 200`]: (r) => r.status === 200,
        [`${tag} response is JSON`]: (r) => r.headers['Content-Type'] && r.headers['Content-Type'].includes('application/json'),
        [`${tag} response has status ok`]: (r) => {
            const body = JSON.parse(r.body);
            return Array.isArray(body) && body.length > 0 && body[0].status === 'ok';
        }
    });
}

export function handleSummary(data) {
    const fileTag = `${tag}_minimal_${duration}vus_${target}`;
    const reqs = data.metrics.http_reqs.values.count;
    const rps = data.metrics.http_reqs.values.rate;
    const avgDuration = data.metrics.iteration_duration.values.avg;
    const failedReqs = data.metrics.http_req_failed.values.passes;

    // JSON data for aggregation
    const jsonData = JSON.stringify({
        scenario: "minimal",
        tag: tag,
        vus: target,
        duration: duration,
        requests: reqs,
        rps: rps,
        avgLatency: avgDuration,
        failed: failedReqs,
        summaryFile: `${fileTag}_summary.txt`
    });

    return {
        [`/results/${stamp}/${fileTag}_summary.txt`]: textSummary(data, { indent: ' ', enableColors: false }),
        [`/results/${stamp}/${fileTag}.json`]: jsonData,
    }
}
