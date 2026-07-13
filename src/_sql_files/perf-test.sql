-- Raw-query twin of public.perf_test() in _postgres/init.sql — keep both in sync.
-- Parameters are positional ($N) with @param annotations declaring the same names and
-- types as the function signature, so the executed statement stays identical to the
-- function body (no runtime casts needed for type inference).
-- HTTP GET
-- @param $1 _records int
-- @param $2 _text text
-- @param $3 _int int
-- @param $4 _bigint bigint
-- @param $5 _numeric numeric
-- @param $6 _real real
-- @param $7 _double float8
-- @param $8 _bool bool
-- @param $9 _date date
-- @param $10 _timestamp timestamp
-- @param $11 _timestamptz timestamptz
-- @param $12 _uuid uuid
-- @param $13 _json json
-- @param $14 _jsonb jsonb
-- @param $15 _int_array int[]
-- @param $16 _text_array text[]
select
    i as row_num,
    -- text types
    $2 || '_' || i::text as text_val,
    left($2 || '_' || i::text, 100)::varchar(100) as varchar_val,
    lpad(i::text, 10, '0')::char(10) as char_val,
    -- integer types
    (i % 32767)::smallint as smallint_val,
    $3 + i as int_val,
    $4 + i as bigint_val,
    -- floating point
    ($5 + i + 0.1234)::numeric(12,4) as numeric_val,
    ($6 + i * 0.1)::real as real_val,
    ($7 + i * 0.001)::double precision as double_val,
    -- boolean
    case when i % 2 = 0 then $8 else not $8 end as bool_val,
    -- date/time
    $9 + i as date_val,
    ('12:00:00'::time + (i || ' minutes')::interval)::time as time_val,
    $10 + (i || ' hours')::interval as timestamp_val,
    $11 + (i || ' hours')::interval as timestamptz_val,
    (i || ' days')::interval as interval_val,
    -- special types
    case when i = 1 then $12
         else uuid_generate_v5($12, i::text) end as uuid_val,
    ($13::jsonb || jsonb_build_object('i', i))::json as json_val,
    $14 || jsonb_build_object('row', i) as jsonb_val,
    -- arrays
    $15 || array[i] as int_array_val,
    $16 || array[$2 || i::text] as text_array_val,
    -- nullable (nulls on even rows)
    case when i % 2 = 1 then $2 || '_' || i::text else null end as nullable_text,
    case when i % 2 = 1 then i else null end as nullable_int
from
    generate_series(1, $1) as i;
