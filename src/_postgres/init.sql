create extension if not exists "uuid-ossp";

-- Main performance test function with all parameter types
create function public.perf_test(
    _records int,
    _text text,
    _int int,
    _bigint bigint,
    _numeric numeric,
    _real real,
    _double double precision,
    _bool bool,
    _date date,
    _timestamp timestamp,
    _timestamptz timestamptz,
    _uuid uuid,
    _json json,
    _jsonb jsonb,
    _int_array int[],
    _text_array text[]
)
returns table(
    row_num int,
    -- text types
    text_val text,
    varchar_val varchar(100),
    char_val char(10),
    -- integer types
    smallint_val smallint,
    int_val int,
    bigint_val bigint,
    -- floating point
    numeric_val numeric(12,4),
    real_val real,
    double_val double precision,
    -- boolean
    bool_val bool,
    -- date/time
    date_val date,
    time_val time,
    timestamp_val timestamp,
    timestamptz_val timestamptz,
    interval_val interval,
    -- special types
    uuid_val uuid,
    json_val json,
    jsonb_val jsonb,
    -- arrays
    int_array_val int[],
    text_array_val text[],
    -- nullable
    nullable_text text,
    nullable_int int
)
stable
language sql
as
$$
select
    i as row_num,
    -- text types
    _text || '_' || i::text as text_val,
    left(_text || '_' || i::text, 100)::varchar(100) as varchar_val,
    lpad(i::text, 10, '0')::char(10) as char_val,
    -- integer types
    (i % 32767)::smallint as smallint_val,
    _int + i as int_val,
    _bigint + i as bigint_val,
    -- floating point
    (_numeric + i + 0.1234)::numeric(12,4) as numeric_val,
    (_real + i * 0.1)::real as real_val,
    (_double + i * 0.001)::double precision as double_val,
    -- boolean
    case when i % 2 = 0 then _bool else not _bool end as bool_val,
    -- date/time
    _date + i as date_val,
    ('12:00:00'::time + (i || ' minutes')::interval)::time as time_val,
    _timestamp + (i || ' hours')::interval as timestamp_val,
    _timestamptz + (i || ' hours')::interval as timestamptz_val,
    (i || ' days')::interval as interval_val,
    -- special types
    case when i = 1 then _uuid
         else uuid_generate_v5(_uuid, i::text) end as uuid_val,
    (_json::jsonb || jsonb_build_object('i', i))::json as json_val,
    _jsonb || jsonb_build_object('row', i) as jsonb_val,
    -- arrays
    _int_array || array[i] as int_array_val,
    _text_array || array[_text || i::text] as text_array_val,
    -- nullable (nulls on even rows)
    case when i % 2 = 1 then _text || '_' || i::text else null end as nullable_text,
    case when i % 2 = 1 then i else null end as nullable_int
from
    generate_series(1, _records) as i
$$;

comment on function public.perf_test(int,text,int,bigint,numeric,real,double precision,bool,date,timestamp,timestamptz,uuid,json,jsonb,int[],text[]) is 'HTTP GET /api/perf-test';

-- ============================================
-- ADDITIONAL BENCHMARK FUNCTIONS
-- All use generate_series() or in-memory computation only
-- No table reads/writes to ensure constant DB response time
-- ============================================

-- SCENARIO 1: POST with JSON body (tests request body parsing)
create function public.perf_post(_records int, _payload jsonb)
returns table(row_num int, echo jsonb, computed text)
stable
language sql
as
$$
select
    i as row_num,
    _payload as echo,
    'row_' || i::text as computed
from generate_series(1, _records) as i
$$;

comment on function public.perf_post(int, jsonb) is 'HTTP POST /api/perf-post';

-- SCENARIO 2: Nested JSON (tests nested object serialization)
create function public.perf_nested(_records int, _depth int)
returns table(row_num int, nested jsonb)
stable
language sql
as
$$
select
    i as row_num,
    case _depth
        when 1 then jsonb_build_object('a', i)
        when 2 then jsonb_build_object('a', jsonb_build_object('b', i))
        when 3 then jsonb_build_object('a', jsonb_build_object('b', jsonb_build_object('c', i)))
        else jsonb_build_object('a', i)
    end as nested
from generate_series(1, _records) as i
$$;

comment on function public.perf_nested(int, int) is 'HTTP GET /api/perf-nested';

-- SCENARIO 3: Minimal overhead baseline
create function public.perf_minimal()
returns table(status text, ts timestamptz)
stable
language sql
as
$$
select 'ok'::text as status, now() as ts
$$;

comment on function public.perf_minimal() is 'HTTP GET /api/perf-minimal';

-- SCENARIO 4: Large payload (tests chunked transfer, buffer handling)
create function public.perf_large_payload(_size_kb int)
returns table(data text)
stable
language sql
as
$$
select repeat('x', _size_kb * 1024) as data
$$;

comment on function public.perf_large_payload(int) is 'HTTP GET /api/perf-large-payload';

-- SCENARIO 5: Many parameters (tests query string parsing)
create function public.perf_many_params(
    _p1 text, _p2 int, _p3 bool, _p4 numeric, _p5 text,
    _p6 text, _p7 int, _p8 bool, _p9 numeric, _p10 text,
    _p11 text, _p12 int, _p13 bool, _p14 numeric, _p15 text,
    _p16 text, _p17 int, _p18 bool, _p19 numeric, _p20 text
)
returns table(param_count int, checksum text)
stable
language sql
as
$$
select 20 as param_count, md5(_p1 || coalesce(_p10, '') || coalesce(_p20, '')) as checksum
$$;

comment on function public.perf_many_params(text,int,bool,numeric,text,text,int,bool,numeric,text,text,int,bool,numeric,text,text,int,bool,numeric,text) is 'HTTP GET /api/perf-many-params';

show max_connections;
