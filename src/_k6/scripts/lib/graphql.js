// GraphQL services (PostGraphile, Hasura): the same six operations as the REST services, asked for the way
// a GraphQL client asks: one POST to the GraphQL endpoint with a query document and its variables.
//
// Every scenario script uses three things from here:
//   graphqlKind(tag)                                 'postgraphile', 'hasura' or null (a REST service)
//   graphqlRequest(kind, base, operation, values)    { url, body, params } for http.post
//   graphqlRows(kind, operation, response)           the rows of the response, under the column names of
//                                                    the PostgreSQL function, so that the same checks apply

const PERF_TEST_COLUMNS = [
    'row_num', 'text_val', 'varchar_val', 'char_val', 'smallint_val', 'int_val', 'bigint_val',
    'numeric_val', 'real_val', 'double_val', 'bool_val', 'date_val', 'time_val',
    'timestamp_val', 'timestamptz_val', 'interval_val', 'uuid_val', 'json_val', 'jsonb_val',
    'int_array_val', 'text_array_val', 'nullable_text', 'nullable_int',
];

const COLUMNS = {
    perf_test: PERF_TEST_COLUMNS,
    perf_minimal: ['status', 'ts'],
    perf_post: ['row_num', 'echo', 'computed'],
    perf_nested: ['row_num', 'nested'],
    perf_large_payload: ['data'],
    perf_many_params: ['param_count', 'checksum'],
    perf_table_get: ['id', 'name', 'category', 'price', 'active', 'created_at'],
    perf_table_list: ['id', 'name', 'category', 'price', 'active', 'created_at'],
    perf_table_insert: ['id', 'item_id', 'quantity', 'note', 'created_at'],
};

// Functions that write are mutations in both servers.
const MUTATIONS = { perf_table_insert: true };

function camel(name) {
    return name.replace(/_([a-z0-9])/g, function (match, c) { return c.toUpperCase(); });
}

// PostGraphile: camelCase fields, arguments that keep their leading underscore (_records, _intArray),
// a connection with nodes, and an interval that is an object.
const POSTGRAPHILE_TYPES = {
    _records: 'Int', _text: 'String', _int: 'Int', _bigint: 'BigInt', _numeric: 'BigFloat', _real: 'Float',
    _double: 'Float', _bool: 'Boolean', _date: 'Date', _timestamp: 'Datetime', _timestamptz: 'Datetime',
    _uuid: 'UUID', _json: 'JSON', _jsonb: 'JSON', _int_array: '[Int]', _text_array: '[String]',
    _payload: 'JSON', _depth: 'Int', _size_kb: 'Int',
    _id: 'Int', _category: 'Int', _after_id: 'Int', _limit: 'Int', _item_id: 'Int', _quantity: 'Int', _note: 'String',
};

function postgraphileType(name) {
    if (POSTGRAPHILE_TYPES[name]) {
        return POSTGRAPHILE_TYPES[name];
    }
    // perf_many_params: _p1 text, _p2 int, _p3 bool, _p4 numeric, _p5 text, then the same five again
    const n = (parseInt(name.slice(2)) - 1) % 5;
    return ['String', 'Int', 'Boolean', 'BigFloat', 'String'][n];
}

function postgraphileQuery(operation, names) {
    const fields = COLUMNS[operation].map(function (c) {
        return c === 'interval_val' ? 'intervalVal { years months days hours minutes seconds }' : camel(c);
    }).join(' ');
    const declared = names.map(function (n) { return '$' + n.slice(1) + ': ' + postgraphileType(n); }).join(', ');
    const passed = names.map(function (n) { return '_' + camel(n.slice(1)) + ': $' + n.slice(1); }).join(', ');
    if (MUTATIONS[operation]) {
        // a mutation takes its arguments in one input object and returns the rows under "result"
        return 'mutation(' + declared + ') { ' + camel(operation) + '(input: { ' + passed + ' }) { result { ' + fields + ' } } }';
    }
    // a function with one result column is a connection of scalars: its nodes have no fields to select
    const nodes = COLUMNS[operation].length === 1 ? 'nodes' : 'nodes { ' + fields + ' }';
    return 'query' + (declared ? '(' + declared + ')' : '') + ' { ' + camel(operation) + (passed ? '(' + passed + ')' : '') +
        ' { ' + nodes + ' } }';
}

// Hasura: the function's own names, and one variable that holds all the arguments.
function hasuraQuery(operation, names) {
    const fields = COLUMNS[operation].join(' ');
    if (MUTATIONS[operation]) {
        return 'mutation($args: hasura_' + operation + '_args!) { hasura_' + operation + '(args: $args) { ' + fields + ' } }';
    }
    return names.length
        ? 'query($args: hasura_' + operation + '_args!) { hasura_' + operation + '(args: $args) { ' + fields + ' } }'
        : 'query { hasura_' + operation + ' { ' + fields + ' } }';
}

export function graphqlKind(tag) {
    if (tag.indexOf('postgraphile') !== -1) {
        return 'postgraphile';
    }
    if (tag.indexOf('hasura') !== -1) {
        return 'hasura';
    }
    return null;
}

// values: an object keyed by the function's parameter names ({ _records: 10, _text: '...' }).
// Arrays are JavaScript arrays; json values are objects.
export function graphqlRequest(kind, base, operation, values) {
    const names = Object.keys(values || {});
    let query;
    let variables = {};
    if (kind === 'postgraphile') {
        query = postgraphileQuery(operation, names);
        names.forEach(function (n) { variables[n.slice(1)] = values[n]; });
    } else {
        query = hasuraQuery(operation, names);
        if (names.length) {
            const args = {};
            // Hasura takes a PostgreSQL array as its literal: {1,2,3}
            names.forEach(function (n) {
                args[n] = Array.isArray(values[n]) ? '{' + values[n].join(',') + '}' : values[n];
            });
            variables = { args: args };
        }
    }
    return {
        url: base + (kind === 'postgraphile' ? '/graphql' : '/v1/graphql'),
        body: JSON.stringify({ query: query, variables: variables }),
        params: { headers: { 'Content-Type': 'application/json', Accept: 'application/json' } },
    };
}

// The rows, under the function's column names. PostGraphile's camelCase is mapped back.
export function graphqlRows(kind, operation, response) {
    const body = JSON.parse(response.body);
    if (!body.data) {
        return [];
    }
    if (kind === 'hasura') {
        return body.data['hasura_' + operation] || [];
    }
    const field = body.data[camel(operation)] || {};
    const nodes = (MUTATIONS[operation] ? field.result : field.nodes) || [];
    const columns = COLUMNS[operation];
    return nodes.map(function (node) {
        const row = {};
        if (columns.length === 1) {
            row[columns[0]] = node;
        } else {
            columns.forEach(function (c) { row[c] = node[camel(c)]; });
        }
        return row;
    });
}
