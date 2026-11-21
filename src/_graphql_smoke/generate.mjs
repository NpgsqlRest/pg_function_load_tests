// Writes the request bodies the smoke test (test-services.sh) posts to the GraphQL services, from the same
// builder the k6 scripts use. Usage: node gqlgen.mjs <path to lib/graphql.js> <output directory>
import { mkdirSync, writeFileSync } from 'node:fs';
const lib = await import(process.argv[2]);
const out = process.argv[3];
mkdirSync(out, { recursive: true });
const cases = {
    perf_test: {
        _records: 1, _text: 'test', _int: 42, _bigint: '9223372036854770000', _numeric: '123.456',
        _real: 1.23, _double: 1.23456789, _bool: true, _date: '2024-01-15', _timestamp: '2024-01-15T10:30:00',
        _timestamptz: '2024-01-15T10:30:00Z', _uuid: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        _json: { key: 'value' }, _jsonb: { key: 'value' }, _int_array: [1, 2, 3], _text_array: ['a', 'b', 'c'],
    },
    perf_minimal: {},
    perf_post: { _records: 3, _payload: { test: 'value' } },
    perf_nested: { _records: 3, _depth: 3 },
    perf_large_payload: { _size_kb: 10 },
    perf_many_params: {
        _p1: 'a', _p2: 1, _p3: true, _p4: '1.1', _p5: 'e', _p6: 'f', _p7: 2, _p8: false, _p9: '2.2', _p10: 'j',
        _p11: 'k', _p12: 3, _p13: true, _p14: '3.3', _p15: 'o', _p16: 'p', _p17: 4, _p18: false, _p19: '4.4', _p20: 't',
    },
    perf_table_get: { _id: 123456 },
    perf_table_list: { _category: 7, _after_id: 250000, _limit: 20 },
    perf_table_insert: { _item_id: 5, _quantity: 2, _note: 'smoke test' },
};
for (const kind of ['postgraphile', 'hasura']) {
    for (const [op, values] of Object.entries(cases)) {
        const r = lib.graphqlRequest(kind, '', op, values);
        writeFileSync(`${out}/${kind}-${op}.json`, r.body + '\n');
    }
}
console.log('written to', out);
