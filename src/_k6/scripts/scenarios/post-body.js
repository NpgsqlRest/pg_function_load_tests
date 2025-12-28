import { check } from "k6";
import http from "k6/http";
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

const stamp = __ENV.STAMP.trim();
const tag = __ENV.TAG.trim();
const port = __ENV.PORT.trim();
const records = Number(__ENV.RECORDS ? __ENV.RECORDS.trim() : "10");
const duration = __ENV.DURATION ? __ENV.DURATION.trim() : "60s";
const target = Number(__ENV.TARGET ? __ENV.TARGET.trim() : "50");

// Determine the path based on the service type
function getPath(tag) {
    if (tag.indexOf('postgrest') !== -1) {
        return '/rpc/perf_post';
    }
    return '/api/perf-post';
}

const path = getPath(tag);
const url = 'http://' + tag + ':' + port + path;

// JSON payload to send in POST body
const payload = JSON.stringify({
    _records: records,
    _payload: {
        key: "value",
        nested: { a: 1, b: 2 },
        array: [1, 2, 3, 4, 5]
    }
});

const params = {
    headers: {
        'Content-Type': 'application/json',
    },
};

export const options = {
    thresholds: {
        http_req_failed: [{ threshold: "rate<0.01", abortOnFail: true }],
        http_req_duration: ["p(99)<1000"],
    },
    scenarios: {
        post_body: {
            executor: "ramping-vus",
            stages: [
                { duration: duration, target: target },
            ],
        },
    },
};

export default function () {
    const res = http.post(url, payload, params);
    check(res, {
        [`${tag} status is 200`]: (r) => r.status === 200,
        [`${tag} response is JSON`]: (r) => r.headers['Content-Type'] && r.headers['Content-Type'].includes('application/json'),
        [`${tag} response has all records`]: (r) => {
            const body = JSON.parse(r.body);
            return Array.isArray(body) && body.length === records;
        },
        [`${tag} response echoes payload`]: (r) => {
            const body = JSON.parse(r.body);
            return body[0] && body[0].echo && body[0].echo.key === 'value';
        }
    });
}

export function handleSummary(data) {
    const fileTag = `${tag}_post_${records}rec_${duration}vus_${target}`;
    const reqs = data.metrics.http_reqs.values.count;
    const rps = data.metrics.http_reqs.values.rate;
    const avgDuration = data.metrics.iteration_duration.values.avg;
    const failedReqs = data.metrics.http_req_failed.values.passes;

    // JSON data for aggregation (sortable by rps)
    const jsonData = JSON.stringify({
        scenario: "post",
        tag: tag,
        vus: target,
        records: records,
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
