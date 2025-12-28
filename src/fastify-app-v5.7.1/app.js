import Fastify from 'fastify';
import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: 5432,
    max: 100
});

const fastify = Fastify({ logger: false });

fastify.get('/api/perf-test', async (request, reply) => {
    const records = parseInt(request.query._records);
    const text = request.query._text;
    const intVal = parseInt(request.query._int);
    const bigint = request.query._bigint;
    const numeric = request.query._numeric;
    const real = request.query._real;
    const double = request.query._double;
    const bool = request.query._bool === 'true';
    const date = request.query._date;
    const timestamp = request.query._timestamp;
    const timestamptz = request.query._timestamptz;
    const uuid = request.query._uuid;
    const json = request.query._json;
    const jsonb = request.query._jsonb;
    const intArray = request.query._int_array;
    const textArray = request.query._text_array;

    const result = await pool.query(
        `SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                numeric_val, real_val, double_val, bool_val, date_val, time_val,
                timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                int_array_val, text_array_val, nullable_text, nullable_int
         FROM public.perf_test($1, $2, $3, $4::bigint, $5::numeric, $6::real, $7::double precision, $8, $9::date, $10::timestamp, $11::timestamptz, $12::uuid, $13::json, $14::jsonb, $15::int[], $16::text[])`,
        [records, text, intVal, bigint, numeric, real, double, bool, date, timestamp, timestamptz, uuid, json, jsonb, intArray, textArray]
    );
    return result.rows;
});

// New benchmark endpoints

fastify.get('/api/perf-minimal', async (request, reply) => {
    const result = await pool.query('SELECT status, ts FROM public.perf_minimal()');
    return result.rows;
});

fastify.post('/api/perf-post', async (request, reply) => {
    const { _records = 10, _payload = {} } = request.body;
    const result = await pool.query(
        'SELECT row_num, echo, computed FROM public.perf_post($1, $2::jsonb)',
        [_records, JSON.stringify(_payload)]
    );
    return result.rows;
});

fastify.get('/api/perf-nested', async (request, reply) => {
    const records = parseInt(request.query._records || '100');
    const depth = parseInt(request.query._depth || '3');
    const result = await pool.query(
        'SELECT row_num, nested FROM public.perf_nested($1, $2)',
        [records, depth]
    );
    return result.rows;
});

fastify.get('/api/perf-large-payload', async (request, reply) => {
    const sizeKb = parseInt(request.query._size_kb || '100');
    const result = await pool.query(
        'SELECT data FROM public.perf_large_payload($1)',
        [sizeKb]
    );
    return result.rows;
});

fastify.get('/api/perf-many-params', async (request, reply) => {
    const q = request.query;
    const result = await pool.query(
        `SELECT param_count, checksum FROM public.perf_many_params(
            $1, $2::int, $3::bool, $4::numeric, $5,
            $6, $7::int, $8::bool, $9::numeric, $10,
            $11, $12::int, $13::bool, $14::numeric, $15,
            $16, $17::int, $18::bool, $19::numeric, $20
        )`,
        [
            q._p1, q._p2, q._p3 === 'true', q._p4, q._p5,
            q._p6, q._p7, q._p8 === 'true', q._p9, q._p10,
            q._p11, q._p12, q._p13 === 'true', q._p14, q._p15,
            q._p16, q._p17, q._p18 === 'true', q._p19, q._p20
        ]
    );
    return result.rows;
});

fastify.listen({ port: 3101, host: '0.0.0.0' });
