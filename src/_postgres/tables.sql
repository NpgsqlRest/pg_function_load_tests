-- ============================================
-- TABLE SCENARIOS (added 2026-11)
-- The six scenarios in init.sql compute in memory. These three read and write real tables, which is what
-- most endpoints of a real API do: one row by primary key, one page of a list, one insert that returns the
-- new row. Every service calls the same three functions.
-- ============================================

create table public.perf_items (
    id int primary key,
    name text not null,
    category int not null,
    price numeric(10,2) not null,
    active bool not null,
    created_at timestamptz not null
);

-- 500,000 rows in 1,000 categories of 500 rows each. Deterministic: every run has the same data.
insert into public.perf_items (id, name, category, price, active, created_at)
select
    i,
    'Item ' || i,
    i % 1000,
    round(1 + (i % 10000) / 100.0, 2),
    i % 7 <> 0,
    timestamptz '2026-01-01 00:00:00+00' + i * interval '1 minute'
from generate_series(1, 500000) as i;

create index perf_items_category_id_idx on public.perf_items (category, id);
analyze public.perf_items;

-- The table the insert scenario writes to. The benchmark runner empties it before every insert test
-- (run-all.sh), so that every service writes into a table of the same size.
create table public.perf_orders (
    id bigint generated always as identity primary key,
    item_id int not null,
    quantity int not null,
    note text,
    created_at timestamptz not null default now()
);

-- SCENARIO 6: one row by primary key
create function public.perf_table_get(_id int)
returns table(id int, name text, category int, price numeric, active bool, created_at timestamptz)
stable
language sql
as
$$
select i.id, i.name, i.category, i.price, i.active, i.created_at
from public.perf_items i
where i.id = _id;
$$;
comment on function public.perf_table_get(int) is 'HTTP GET /api/perf-table-get';

-- SCENARIO 7: one page of a list (keyset pagination: the rows of a category after a given id)
create function public.perf_table_list(_category int, _after_id int, _limit int)
returns table(id int, name text, category int, price numeric, active bool, created_at timestamptz)
stable
language sql
as
$$
select i.id, i.name, i.category, i.price, i.active, i.created_at
from public.perf_items i
where i.category = _category and i.id > _after_id
order by i.id
limit _limit;
$$;
comment on function public.perf_table_list(int, int, int) is 'HTTP GET /api/perf-table-list';

-- SCENARIO 8: an insert that returns the new row
create function public.perf_table_insert(_item_id int, _quantity int, _note text)
returns table(id bigint, item_id int, quantity int, note text, created_at timestamptz)
volatile
language sql
as
$$
insert into public.perf_orders (item_id, quantity, note)
values (_item_id, _quantity, _note)
returning id, item_id, quantity, note, created_at;
$$;
comment on function public.perf_table_insert(int, int, text) is 'HTTP POST /api/perf-table-insert';
