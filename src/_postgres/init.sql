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

show max_connections;
