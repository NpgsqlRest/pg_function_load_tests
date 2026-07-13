import express from 'express';
import pg from 'pg';
import cluster from 'node:cluster';
import os from 'node:os';

// Workers = CPU cores so the single-threaded event loop can use the whole machine,
// matching natively multi-threaded runtimes (Go, Rust, .NET, JVM).
const WORKERS = parseInt(process.env.WORKERS || '') || os.availableParallelism();

if (cluster.isPrimary) {
    for (let i = 0; i < WORKERS; i++) {
        cluster.fork();
    }
    cluster.on('exit', () => cluster.fork());
} else {

const { Pool } = pg;

// Pool is per cluster worker; workers x max ~= 100 aggregate
// to match the single-pool services.
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: 5432,
    max: Math.max(2, Math.floor(100 / WORKERS))
});

const app = express();
app.use(express.json());

app.get('/api/perf-test', async (req, res) => {
    const records = parseInt(req.query._records);
    const text = req.query._text;
    const intVal = parseInt(req.query._int);
    const bigint = req.query._bigint;
    const numeric = req.query._numeric;
    const real = req.query._real;
    const double = req.query._double;
    const bool = req.query._bool === 'true';
    const date = req.query._date;
    const timestamp = req.query._timestamp;
    const timestamptz = req.query._timestamptz;
    const uuid = req.query._uuid;
    const json = req.query._json;
    const jsonb = req.query._jsonb;
    const intArray = req.query._int_array;
    const textArray = req.query._text_array;

    const result = await pool.query(
        `SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                numeric_val, real_val, double_val, bool_val, date_val, time_val,
                timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                int_array_val, text_array_val, nullable_text, nullable_int
         FROM public.perf_test($1, $2, $3, $4::bigint, $5::numeric, $6::real, $7::double precision, $8, $9::date, $10::timestamp, $11::timestamptz, $12::uuid, $13::json, $14::jsonb, $15::int[], $16::text[])`,
        [records, text, intVal, bigint, numeric, real, double, bool, date, timestamp, timestamptz, uuid, json, jsonb, intArray, textArray]
    );
    res.json(result.rows);
});

// New benchmark endpoints

app.get('/api/perf-minimal', async (req, res) => {
    const result = await pool.query('SELECT status, ts FROM public.perf_minimal()');
    res.json(result.rows);
});

app.post('/api/perf-post', async (req, res) => {
    const { _records = 10, _payload = {} } = req.body;
    const result = await pool.query(
        'SELECT row_num, echo, computed FROM public.perf_post($1, $2::jsonb)',
        [_records, JSON.stringify(_payload)]
    );
    res.json(result.rows);
});

app.get('/api/perf-nested', async (req, res) => {
    const records = parseInt(req.query._records || '100');
    const depth = parseInt(req.query._depth || '3');
    const result = await pool.query(
        'SELECT row_num, nested FROM public.perf_nested($1, $2)',
        [records, depth]
    );
    res.json(result.rows);
});

app.get('/api/perf-large-payload', async (req, res) => {
    const sizeKb = parseInt(req.query._size_kb || '100');
    const result = await pool.query(
        'SELECT data FROM public.perf_large_payload($1)',
        [sizeKb]
    );
    res.json(result.rows);
});

app.get('/api/perf-many-params', async (req, res) => {
    const q = req.query;
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
    res.json(result.rows);
});

app.listen(3102, '0.0.0.0');

}
