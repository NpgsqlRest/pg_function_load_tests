from fastapi import FastAPI, Query
from fastapi.responses import ORJSONResponse
from contextlib import asynccontextmanager
import asyncpg
import os

pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    pool = await asyncpg.create_pool(
        host=os.getenv('DB_HOST', 'postgres'),
        port=5432,
        user=os.getenv('DB_USER', 'testuser'),
        password=os.getenv('DB_PASSWORD', 'testpass'),
        database=os.getenv('DB_NAME', 'testdb'),
        min_size=10,
        max_size=100
    )
    yield
    await pool.close()

app = FastAPI(
    lifespan=lifespan,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    default_response_class=ORJSONResponse
)

@app.get("/api/perf-test")
async def get_test_data(
    _records: int = Query(...),
    _text: str = Query(...),
    _int: int = Query(...),
    _bigint: str = Query(...),
    _numeric: str = Query(...),
    _real: str = Query(...),
    _double: str = Query(...),
    _bool: bool = Query(...),
    _date: str = Query(...),
    _timestamp: str = Query(...),
    _timestamptz: str = Query(...),
    _uuid: str = Query(...),
    _json: str = Query(...),
    _jsonb: str = Query(...),
    _int_array: str = Query(...),
    _text_array: str = Query(...)
):
    # Use raw SQL with text parameters - asyncpg/PostgreSQL will handle the casts
    async with pool.acquire() as conn:
        # Build the SQL with proper escaping using execute
        # Use direct string substitution with $n for native types
        rows = await conn.fetch(f"""
            SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                   numeric_val, real_val, double_val, bool_val, date_val, time_val,
                   timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                   int_array_val, text_array_val, nullable_text, nullable_int
            FROM public.perf_test(
                {_records}, $1, {_int}, {_bigint}::bigint, {_numeric}::numeric, {_real}::real,
                {_double}::double precision, {str(_bool).lower()}, '{_date}'::date,
                '{_timestamp}'::timestamp, '{_timestamptz}'::timestamptz, '{_uuid}'::uuid,
                $2::json, $3::jsonb, '{_int_array}'::int[], '{_text_array}'::text[])
            """,
            _text, _json, _jsonb
        )
        return [dict(row) for row in rows]


# New benchmark endpoints

@app.get("/api/perf-minimal")
async def perf_minimal():
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT status, ts FROM public.perf_minimal()")
        return [dict(row) for row in rows]


@app.post("/api/perf-post")
async def perf_post(body: dict):
    records = body.get('_records', 10)
    payload = body.get('_payload', {})
    import json
    payload_str = json.dumps(payload)

    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT row_num, echo, computed FROM public.perf_post($1, $2::jsonb)",
            records, payload_str
        )
        return [dict(row) for row in rows]


@app.get("/api/perf-nested")
async def perf_nested(
    _records: int = Query(default=100),
    _depth: int = Query(default=3)
):
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT row_num, nested FROM public.perf_nested($1, $2)",
            _records, _depth
        )
        return [dict(row) for row in rows]


@app.get("/api/perf-large-payload")
async def perf_large_payload(_size_kb: int = Query(default=100)):
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT data FROM public.perf_large_payload($1)",
            _size_kb
        )
        return [dict(row) for row in rows]


@app.get("/api/perf-many-params")
async def perf_many_params(
    _p1: str = Query(...), _p2: int = Query(...), _p3: bool = Query(...), _p4: str = Query(...), _p5: str = Query(...),
    _p6: str = Query(...), _p7: int = Query(...), _p8: bool = Query(...), _p9: str = Query(...), _p10: str = Query(...),
    _p11: str = Query(...), _p12: int = Query(...), _p13: bool = Query(...), _p14: str = Query(...), _p15: str = Query(...),
    _p16: str = Query(...), _p17: int = Query(...), _p18: bool = Query(...), _p19: str = Query(...), _p20: str = Query(...)
):
    async with pool.acquire() as conn:
        rows = await conn.fetch(f"""
            SELECT param_count, checksum FROM public.perf_many_params(
                $1, {_p2}, {str(_p3).lower()}, {_p4}::numeric, $2,
                $3, {_p7}, {str(_p8).lower()}, {_p9}::numeric, $4,
                $5, {_p12}, {str(_p13).lower()}, {_p14}::numeric, $6,
                $7, {_p17}, {str(_p18).lower()}, {_p19}::numeric, $8
            )
            """,
            _p1, _p5, _p6, _p10, _p11, _p15, _p16, _p20
        )
        return [dict(row) for row in rows]
