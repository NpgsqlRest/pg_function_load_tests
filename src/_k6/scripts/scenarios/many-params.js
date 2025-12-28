import { check } from "k6";
import http from "k6/http";
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

const stamp = __ENV.STAMP.trim();
const tag = __ENV.TAG.trim();
const port = __ENV.PORT.trim();
const duration = __ENV.DURATION ? __ENV.DURATION.trim() : "60s";
const target = Number(__ENV.TARGET ? __ENV.TARGET.trim() : "50");

// Determine the path based on the service type
function getPath(tag) {
    if (tag.indexOf('postgrest') !== -1) {
        return '/rpc/perf_many_params';
    }
    return '/api/perf-many-params';
}

const path = getPath(tag);

// Build URL with 20 parameters
const params = [
    '_p1=text_value_1', '_p2=123', '_p3=true', '_p4=123.456', '_p5=text_value_5',
    '_p6=text_value_6', '_p7=456', '_p8=false', '_p9=789.012', '_p10=text_value_10',
    '_p11=text_value_11', '_p12=789', '_p13=true', '_p14=345.678', '_p15=text_value_15',
    '_p16=text_value_16', '_p17=012', '_p18=false', '_p19=901.234', '_p20=text_value_20'
];

const url = 'http://' + tag + ':' + port + path + '?' + params.join('&');

export const options = {
    thresholds: {
        http_req_failed: [{ threshold: "rate<0.01", abortOnFail: true }],
        http_req_duration: ["p(99)<500"],
    },
    scenarios: {
        many_params: {
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
        [`${tag} response has param_count`]: (r) => {
            const body = JSON.parse(r.body);
            return Array.isArray(body) && body[0] && body[0].param_count === 20;
        },
        [`${tag} response has checksum`]: (r) => {
            const body = JSON.parse(r.body);
            return body[0] && body[0].checksum && body[0].checksum.length === 32; // MD5 hash length
        }
    });
}

export function handleSummary(data) {
    const fileTag = `${tag}_manyparams_${duration}vus_${target}`;
    const reqs = data.metrics.http_reqs.values.count;
    const rps = data.metrics.http_reqs.values.rate;
    const avgDuration = data.metrics.iteration_duration.values.avg;
    const failedReqs = data.metrics.http_req_failed.values.passes;

    // JSON data for aggregation (sortable by rps)
    const jsonData = JSON.stringify({
        scenario: "params",
        tag: tag,
        vus: target,
        paramCount: 20,
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
