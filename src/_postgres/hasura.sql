-- Hasura exposes a function only when it returns SETOF a table it tracks; it cannot expose the benchmark
-- functions, which return TABLE(...). So for Hasura alone there is a schema with one empty table per result
-- shape (used as a type only) and one SQL function per benchmark function that selects from it. The wrappers
-- are plain "select * from" functions, which PostgreSQL inlines: the work done is the work of the function in
-- the public schema that every other service calls.
create schema hasura;

create table hasura.perf_test_row (
    row_num int primary key, text_val text, varchar_val varchar(100), char_val char(10),
    smallint_val smallint, int_val int, bigint_val bigint,
    numeric_val numeric(12,4), real_val real, double_val double precision,
    bool_val bool, date_val date, time_val time, timestamp_val timestamp, timestamptz_val timestamptz,
    interval_val interval, uuid_val uuid, json_val json, jsonb_val jsonb,
    int_array_val int[], text_array_val text[], nullable_text text, nullable_int int
);
create table hasura.perf_post_row (row_num int primary key, echo jsonb, computed text);
create table hasura.perf_nested_row (row_num int primary key, nested jsonb);
create table hasura.perf_minimal_row (status text primary key, ts timestamptz);
create table hasura.perf_large_payload_row (data text);
create table hasura.perf_many_params_row (param_count int primary key, checksum text);

create function hasura.perf_test(
    _records int, _text text, _int int, _bigint bigint, _numeric numeric, _real real, _double double precision,
    _bool bool, _date date, _timestamp timestamp, _timestamptz timestamptz, _uuid uuid, _json json, _jsonb jsonb,
    _int_array int[], _text_array text[]
) returns setof hasura.perf_test_row stable language sql as $$
select * from public.perf_test(_records, _text, _int, _bigint, _numeric, _real, _double, _bool, _date,
    _timestamp, _timestamptz, _uuid, _json, _jsonb, _int_array, _text_array)
$$;

create function hasura.perf_post(_records int, _payload jsonb)
returns setof hasura.perf_post_row stable language sql as $$
select * from public.perf_post(_records, _payload)
$$;

create function hasura.perf_nested(_records int, _depth int)
returns setof hasura.perf_nested_row stable language sql as $$
select * from public.perf_nested(_records, _depth)
$$;

create function hasura.perf_minimal()
returns setof hasura.perf_minimal_row stable language sql as $$
select * from public.perf_minimal()
$$;

create function hasura.perf_large_payload(_size_kb int)
returns setof hasura.perf_large_payload_row stable language sql as $$
select * from public.perf_large_payload(_size_kb)
$$;

create function hasura.perf_many_params(
    _p1 text, _p2 int, _p3 bool, _p4 numeric, _p5 text,
    _p6 text, _p7 int, _p8 bool, _p9 numeric, _p10 text,
    _p11 text, _p12 int, _p13 bool, _p14 numeric, _p15 text,
    _p16 text, _p17 int, _p18 bool, _p19 numeric, _p20 text
) returns setof hasura.perf_many_params_row stable language sql as $$
select * from public.perf_many_params(_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10,
    _p11, _p12, _p13, _p14, _p15, _p16, _p17, _p18, _p19, _p20)
$$;

-- The table scenarios (tables.sql). The same rule: a row-shape table and a "select * from" wrapper each.
-- The insert wrapper is volatile, which Hasura exposes as a mutation.
create table hasura.perf_table_row (
    id int primary key, name text, category int, price numeric, active bool, created_at timestamptz
);
create table hasura.perf_table_insert_row (
    id bigint primary key, item_id int, quantity int, note text, created_at timestamptz
);

create function hasura.perf_table_get(_id int)
returns setof hasura.perf_table_row stable language sql as $$
select * from public.perf_table_get(_id)
$$;

create function hasura.perf_table_list(_category int, _after_id int, _limit int)
returns setof hasura.perf_table_row stable language sql as $$
select * from public.perf_table_list(_category, _after_id, _limit)
$$;

create function hasura.perf_table_insert(_item_id int, _quantity int, _note text)
returns setof hasura.perf_table_insert_row volatile language sql as $$
select * from public.perf_table_insert(_item_id, _quantity, _note)
$$;
