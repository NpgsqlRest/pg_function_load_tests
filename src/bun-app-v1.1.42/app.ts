import postgres from 'postgres';

const sql = postgres({
    host: process.env.DB_HOST || 'postgres',
    port: 5432,
    database: process.env.DB_NAME || 'testdb',
    username: process.env.DB_USER || 'testuser',
    password: process.env.DB_PASSWORD || 'testpass',
    max: 100
});

const server = Bun.serve({
    port: 3104,
    async fetch(request) {
        // Extract path and query from request.url manually to avoid URL parsing issues with Docker hostnames
        const rawUrl = request.url;
        const pathStart = rawUrl.indexOf('/', rawUrl.indexOf('://') + 3);
        const pathAndQuery = pathStart >= 0 ? rawUrl.substring(pathStart) : '/';
        const [pathname, queryString] = pathAndQuery.split('?');
        const params = new URLSearchParams(queryString || '');

        if (pathname === '/api/perf-test' && request.method === 'GET') {
            const records = parseInt(params.get('_records') || '0');
            const text = params.get('_text') || '';
            const intVal = parseInt(params.get('_int') || '0');
            const bigint = params.get('_bigint') || '0';
            const numeric = params.get('_numeric') || '0';
            const real = params.get('_real') || '0';
            const double = params.get('_double') || '0';
            const bool = params.get('_bool') === 'true';
            const date = params.get('_date') || '';
            const timestamp = params.get('_timestamp') || '';
            const timestamptz = params.get('_timestamptz') || '';
            const uuid = params.get('_uuid') || '';
            const json = params.get('_json') || '{}';
            const jsonb = params.get('_jsonb') || '{}';
            const intArray = params.get('_int_array') || '{}';
            const textArray = params.get('_text_array') || '{}';

            const rows = await sql`
                SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                       numeric_val, real_val, double_val, bool_val, date_val, time_val,
                       timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                       int_array_val, text_array_val, nullable_text, nullable_int
                FROM public.perf_test(${records}, ${text}, ${intVal}, ${bigint}::bigint, ${numeric}::numeric, ${real}::real, ${double}::double precision, ${bool}, ${date}::date, ${timestamp}::timestamp, ${timestamptz}::timestamptz, ${uuid}::uuid, ${json}::json, ${jsonb}::jsonb, ${intArray}::int[], ${textArray}::text[])
            `;

            return new Response(JSON.stringify(rows), {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        return new Response('Not Found', { status: 404 });
    }
});

console.log(`Bun server running on port ${server.port}`);
