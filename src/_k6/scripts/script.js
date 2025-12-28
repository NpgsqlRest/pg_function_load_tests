import { check } from "k6";
import http from "k6/http";
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

const stamp = __ENV.STAMP.trim();
const tag = __ENV.TAG.trim();
const records = Number(__ENV.RECORDS.trim() || "10")
const duration = __ENV.DURATION.trim() || "60s";
const target = Number(__ENV.TARGET.trim() || "100");
const port = __ENV.PORT.trim();

// Determine the path based on the service type
function getPath(tag) {
    if (tag.indexOf('postgrest') !== -1) {
        return '/rpc/perf_test';
    }
    return '/api/perf-test';
}

// Check if this service uses repeated query params for arrays (like ?a=1&a=2&a=3)
// .NET minimal API and NpgsqlRest bind arrays this way
function usesRepeatedQueryParams(tag) {
    return tag.indexOf('npgsqlrest') !== -1 ||
           tag.indexOf('net9-minapi') !== -1 ||
           tag.indexOf('net10-minapi') !== -1;
}

const path = __ENV.REQ_PATH ? __ENV.REQ_PATH.trim() : getPath(tag);

// Base parameters (non-array)
const baseParams = {
    _records: records,
    _text: 'ABCDEFGHIJKLMNOPRSTUVWXYZ',
    _int: 1234567890,
    _bigint: '9223372036854770000',
    _numeric: '12345.6789',
    _real: '123.45',
    _double: '123456.789012',
    _bool: true,
    _date: '2024-01-15',
    _timestamp: '2024-01-15T10:30:00',
    _timestamptz: '2024-01-15T10:30:00Z',
    _uuid: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    _json: '{"key":"value"}',
    _jsonb: '{"key":"value"}'
};

// Build URL with all test parameters
// NpgsqlRest uses repeated query params for arrays: _int_array=1&_int_array=2&_int_array=3
// Other services use PostgreSQL array literal: _int_array={1,2,3}
let baseUrl = 'http://' + tag + ':' + port + path + '?' +
    Object.entries(baseParams)
    .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
    .join('&');

let url;
if (usesRepeatedQueryParams(tag)) {
    // .NET services and NpgsqlRest: use repeated query params for arrays
    url = baseUrl + '&_int_array=1&_int_array=2&_int_array=3&_text_array=a&_text_array=b&_text_array=c';
} else {
    // Other services: use PostgreSQL array literal format
    url = baseUrl + '&_int_array=' + encodeURIComponent('{1,2,3}') + '&_text_array=' + encodeURIComponent('{a,b,c}');
}

export const options = {
    thresholds: {
        http_req_failed: [{ threshold: "rate<0.01", abortOnFail: true }], // availability threshold for error rate
        http_req_duration: ["p(99)<1000"], // Latency threshold for percentile
    },
    scenarios: {
        breaking: {
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
        [`${tag} response has all data records`]: (r) => r.body && JSON.parse(r.body).length == records,
        [`${tag} response first item has expected fields`]: (r) => {
            let d = JSON.parse(r.body)[0];
            return d.row_num !== undefined &&
                   d.text_val !== undefined &&
                   d.varchar_val !== undefined &&
                   d.int_val !== undefined &&
                   d.bigint_val !== undefined &&
                   d.bool_val !== undefined &&
                   d.date_val !== undefined &&
                   d.uuid_val !== undefined;
        }
    });
}

export function handleSummary(data) {
    const fileTag = `${tag}_${records}rec_${duration}vus_${target}`;
    const reqs = data.metrics.http_reqs.values.count;
    const rps = data.metrics.http_reqs.values.rate;
    const avgDuration = data.metrics.iteration_duration.values.avg;
    const failedReqs = data.metrics.http_req_failed.values.passes;

    // JSON data for aggregation (sortable by rps)
    const jsonData = JSON.stringify({
        scenario: "perf-test",
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
