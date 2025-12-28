import { check } from "k6";
import http from "k6/http";
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

const stamp = __ENV.STAMP.trim();
const tag = __ENV.TAG.trim();
const port = __ENV.PORT.trim();
const sizeKb = Number(__ENV.SIZE_KB ? __ENV.SIZE_KB.trim() : "100");
const duration = __ENV.DURATION ? __ENV.DURATION.trim() : "60s";
const target = Number(__ENV.TARGET ? __ENV.TARGET.trim() : "50");

// Determine the path based on the service type
function getPath(tag) {
    if (tag.indexOf('postgrest') !== -1) {
        return '/rpc/perf_large_payload';
    }
    return '/api/perf-large-payload';
}

const path = getPath(tag);
const url = 'http://' + tag + ':' + port + path + '?_size_kb=' + sizeKb;

export const options = {
    thresholds: {
        http_req_failed: [{ threshold: "rate<0.01", abortOnFail: true }],
        http_req_duration: ["p(99)<5000"], // Large payloads take longer
    },
    scenarios: {
        large_payload: {
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
        [`${tag} response has expected size`]: (r) => {
            const body = JSON.parse(r.body);
            // Allow some variance for JSON overhead
            return Array.isArray(body) && body[0] && body[0].data && body[0].data.length >= (sizeKb * 1024 * 0.9);
        }
    });
}

export function handleSummary(data) {
    const fileTag = `${tag}_large_${sizeKb}kb_${duration}vus_${target}`;
    const reqs = data.metrics.http_reqs.values.count;
    const rps = data.metrics.http_reqs.values.rate;
    const avgDuration = data.metrics.iteration_duration.values.avg;
    const failedReqs = data.metrics.http_req_failed.values.passes;
    const dataReceivedBytes = data.metrics.data_received.values.count;

    // JSON data for aggregation (sortable by rps)
    const jsonData = JSON.stringify({
        scenario: "large",
        tag: tag,
        vus: target,
        sizeKb: sizeKb,
        duration: duration,
        requests: reqs,
        rps: rps,
        avgLatency: avgDuration,
        dataReceived: dataReceivedBytes,
        failed: failedReqs,
        summaryFile: `${fileTag}_summary.txt`
    });

    return {
        [`/results/${stamp}/${fileTag}_summary.txt`]: textSummary(data, { indent: ' ', enableColors: false }),
        [`/results/${stamp}/${fileTag}.json`]: jsonData,
    }
}
