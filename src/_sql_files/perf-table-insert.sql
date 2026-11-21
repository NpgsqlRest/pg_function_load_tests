-- Raw-query twin of public.perf_table_insert() in _postgres/tables.sql — keep both in sync.
-- HTTP POST
-- @param $1 _item_id int
-- @param $2 _quantity int
-- @param $3 _note text
insert into public.perf_orders (item_id, quantity, note)
values ($1, $2, $3)
returning id, item_id, quantity, note, created_at;
