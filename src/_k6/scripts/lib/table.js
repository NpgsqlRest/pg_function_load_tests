// The three table scenarios (table-get, table-list, table-insert) are one script with three entry files
// (scenarios/table-get.js ...): what differs is the request and its check.
//
// Unlike the other scenarios, every iteration asks for different data (a random row, a random page), so
// that the table and its indexes are read as an API reads them, not one cached row again and again.
// The random sequence differs per virtual user and is the same for every service.
import { check } from 'k6';
import http from 'k6/http';
import exec from 'k6/execution';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';
import { graphqlKind, graphqlRequest, graphqlRows } from './graphql.js';
import { seconds, countHold, holdRps, rawSummary } from './measure.js';

const ITEMS = 500000;       // rows in public.perf_items (tables.sql)
const CATEGORIES = 1000;    // 500 rows each

const OPERATIONS = {
    get: { fn: 'perf_table_get', path: 'perf-table-get', scenario: 'table-get' },
    list: { fn: 'perf_table_list', path: 'perf-table-list', scenario: 'table-list' },
    insert: { fn: 'perf_table_insert', path: 'perf-table-insert', scenario: 'table-insert' },
};

// A small deterministic generator (mulberry32), seeded per virtual user: every service gets the same
// sequence of rows and pages, so no service is luckier with the cache than another.
function generator(seed) {
    let a = seed >>> 0;
    return function () {
        a = (a + 0x6D2B79F5) >>> 0;
        let t = a;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

export function tableScenario(operationName) {
    const op = OPERATIONS[operationName];
    const stamp = (__ENV.STAMP || '').trim();
    const tag = __ENV.TAG.trim();
    const port = __ENV.PORT.trim();
    const targetHost = (__ENV.TARGET_HOST || '').trim() || tag;
    const duration = __ENV.DURATION ? __ENV.DURATION.trim() : '60s';
    const ramp = (__ENV.RAMP || '10s').trim();
    const target = Number(__ENV.TARGET ? __ENV.TARGET.trim() : '50');
    const rampSeconds = seconds(ramp);
    const limit = Number(__ENV.LIMIT ? __ENV.LIMIT.trim() : '20');

    const base = 'http://' + targetHost + ':' + port;
    const url = base + (tag.indexOf('postgrest') !== -1 ? '/rpc/' + op.fn : '/api/' + op.path);
    const gql = graphqlKind(tag);
    const jsonHeaders = { headers: { 'Content-Type': 'application/json' }, tags: { name: op.scenario } };
    const getParams = { tags: { name: op.scenario } };   // one metric name for all the different URLs

    let random = null;

    function values() {
        if (random === null) {
            random = generator(exec.vu.idInTest * 7919 + 17);
        }
        if (operationName === 'get') {
            return { _id: 1 + Math.floor(random() * ITEMS) };
        }
        if (operationName === 'list') {
            // a page from the first half of a category: there are always "limit" rows after it
            return { _category: Math.floor(random() * CATEGORIES), _after_id: Math.floor(random() * (ITEMS / 2)), _limit: limit };
        }
        return { _item_id: 1 + Math.floor(random() * ITEMS), _quantity: 1 + Math.floor(random() * 10), _note: 'order from the benchmark' };
    }

    function request(v) {
        if (gql) {
            const r = graphqlRequest(gql, base, op.fn, v);
            return http.post(r.url, r.body, { headers: r.params.headers, tags: { name: op.scenario } });
        }
        if (operationName === 'insert') {
            return http.post(url, JSON.stringify(v), jsonHeaders);
        }
        const query = Object.keys(v).map(function (k) { return k + '=' + v[k]; }).join('&');
        return http.get(url + '?' + query, getParams);
    }

    function rows(r) {
        return gql ? graphqlRows(gql, op.fn, r) : JSON.parse(r.body);
    }

    function run() {
        const v = values();
        const res = request(v);
        countHold(rampSeconds);
        const checks = {};
        checks[tag + ' status is 200'] = function (r) { return r.status === 200; };
        checks[tag + ' response is JSON'] = function (r) {
            return r.headers['Content-Type'] && r.headers['Content-Type'].includes('application/json');
        };
        if (operationName === 'get') {
            checks[tag + ' response is the row asked for'] = function (r) {
                const body = rows(r);
                return Array.isArray(body) && body.length === 1 && Number(body[0].id) === v._id && body[0].name === 'Item ' + v._id;
            };
        } else if (operationName === 'list') {
            checks[tag + ' response is a full page of the category'] = function (r) {
                const body = rows(r);
                return Array.isArray(body) && body.length === limit && Number(body[0].category) === v._category &&
                    Number(body[0].id) > v._after_id;
            };
        } else {
            checks[tag + ' response is the new row'] = function (r) {
                const body = rows(r);
                return Array.isArray(body) && body.length === 1 && Number(body[0].id) > 0 && Number(body[0].item_id) === v._item_id;
            };
        }
        check(res, checks);
    }

    const options = {
        summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
        thresholds: {
            http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: true }],
            http_req_duration: ['p(99)<1000'],
        },
        scenarios: {
            table: {
                executor: 'ramping-vus',
                stages: [
                    { duration: ramp, target: target },      // ramp up
                    { duration: duration, target: target },  // hold at target
                ],
            },
        },
    };

    function handleSummary(data) {
        if (!stamp) { return {}; }  // warmup mode: no output files
        const fileTag = tag + '_' + op.scenario + '_' + duration + 'vus_' + target;
        const dur = data.metrics.http_req_duration ? data.metrics.http_req_duration.values : {};
        const jsonData = JSON.stringify({
            scenario: op.scenario,
            tag: tag,
            vus: target,
            duration: duration,
            requests: data.metrics.http_reqs.values.count,
            rps: data.metrics.http_reqs.values.rate,
            rpsHold: holdRps(data, seconds(duration)),
            avgLatency: data.metrics.iteration_duration.values.avg,
            failed: data.metrics.http_req_failed.values.passes,
            latency: { avg: dur.avg, med: dur.med, p90: dur['p(90)'], p95: dur['p(95)'], p99: dur['p(99)'], max: dur.max },
            dataReceivedBytes: data.metrics.data_received ? data.metrics.data_received.values.count : 0,
            dataSentBytes: data.metrics.data_sent ? data.metrics.data_sent.values.count : 0,
            summaryFile: fileTag + '_summary.txt',
        });
        const out = {};
        out['/results/' + stamp + '/' + fileTag + '_summary.txt'] = textSummary(data, { indent: ' ', enableColors: false });
        out['/results/' + stamp + '/' + fileTag + '.json'] = jsonData;
        return Object.assign(out, rawSummary(stamp, fileTag, data));
    }

    return { options: options, run: run, handleSummary: handleSummary };
}
