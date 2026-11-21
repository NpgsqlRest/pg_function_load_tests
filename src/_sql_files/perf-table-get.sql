-- Raw-query twin of public.perf_table_get() in _postgres/tables.sql — keep both in sync.
-- HTTP GET
-- @param $1 _id int
select id, name, category, price, active, created_at
from public.perf_items
where id = $1;
