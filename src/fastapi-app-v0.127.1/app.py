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
