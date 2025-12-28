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

        // New benchmark endpoints
        if (pathname === '/api/perf-minimal' && request.method === 'GET') {
            const rows = await sql`SELECT status, ts FROM public.perf_minimal()`;
            return new Response(JSON.stringify(rows), {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        if (pathname === '/api/perf-post' && request.method === 'POST') {
            const body = await request.json() as { _records?: number; _payload?: object };
            const records = body._records || 10;
            const payload = JSON.stringify(body._payload || {});
            const rows = await sql`
                SELECT row_num, echo, computed
                FROM public.perf_post(${records}, ${payload}::jsonb)
            `;
            return new Response(JSON.stringify(rows), {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        if (pathname === '/api/perf-nested' && request.method === 'GET') {
            const records = parseInt(params.get('_records') || '100');
            const depth = parseInt(params.get('_depth') || '3');
            const rows = await sql`
                SELECT row_num, nested
                FROM public.perf_nested(${records}, ${depth})
            `;
            return new Response(JSON.stringify(rows), {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        if (pathname === '/api/perf-large-payload' && request.method === 'GET') {
            const sizeKb = parseInt(params.get('_size_kb') || '100');
            const rows = await sql`SELECT data FROM public.perf_large_payload(${sizeKb})`;
            return new Response(JSON.stringify(rows), {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        if (pathname === '/api/perf-many-params' && request.method === 'GET') {
            const p1 = params.get('_p1') || '';
            const p2 = parseInt(params.get('_p2') || '0');
            const p3 = params.get('_p3') === 'true';
            const p4 = params.get('_p4') || '0';
            const p5 = params.get('_p5') || '';
            const p6 = params.get('_p6') || '';
            const p7 = parseInt(params.get('_p7') || '0');
            const p8 = params.get('_p8') === 'true';
            const p9 = params.get('_p9') || '0';
            const p10 = params.get('_p10') || '';
            const p11 = params.get('_p11') || '';
            const p12 = parseInt(params.get('_p12') || '0');
            const p13 = params.get('_p13') === 'true';
            const p14 = params.get('_p14') || '0';
            const p15 = params.get('_p15') || '';
            const p16 = params.get('_p16') || '';
            const p17 = parseInt(params.get('_p17') || '0');
            const p18 = params.get('_p18') === 'true';
            const p19 = params.get('_p19') || '0';
            const p20 = params.get('_p20') || '';
            const rows = await sql`
                SELECT param_count, checksum
                FROM public.perf_many_params(
                    ${p1}, ${p2}, ${p3}, ${p4}::numeric, ${p5},
                    ${p6}, ${p7}, ${p8}, ${p9}::numeric, ${p10},
                    ${p11}, ${p12}, ${p13}, ${p14}::numeric, ${p15},
                    ${p16}, ${p17}, ${p18}, ${p19}::numeric, ${p20}
                )
            `;
            return new Response(JSON.stringify(rows), {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        return new Response('Not Found', { status: 404 });
    }
});

console.log(`Bun server running on port ${server.port}`);
