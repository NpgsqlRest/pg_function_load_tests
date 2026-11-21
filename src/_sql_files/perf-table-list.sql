-- Raw-query twin of public.perf_table_list() in _postgres/tables.sql — keep both in sync.
-- HTTP GET
-- @param $1 _category int
-- @param $2 _after_id int
-- @param $3 _limit int
select id, name, category, price, active, created_at
from public.perf_items
where category = $1 and id > $2
order by id
limit $3;
