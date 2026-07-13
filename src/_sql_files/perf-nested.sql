-- Raw-query twin of public.perf_nested() in _postgres/init.sql — keep both in sync.
-- HTTP GET
-- @param $1 _records int
-- @param $2 _depth int
select
    i as row_num,
    case $2
        when 1 then jsonb_build_object('a', i)
        when 2 then jsonb_build_object('a', jsonb_build_object('b', i))
        when 3 then jsonb_build_object('a', jsonb_build_object('b', jsonb_build_object('c', i)))
        else jsonb_build_object('a', i)
    end as nested
from generate_series(1, $1) as i;
