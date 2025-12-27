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

fastify.listen({ port: 3101, host: '0.0.0.0' });
