-- Raw-query twin of public.perf_post() in _postgres/init.sql — keep both in sync.
-- HTTP POST
-- @param $1 _records int
-- @param $2 _payload jsonb
select
    i as row_num,
    $2 as echo,
    'row_' || i::text as computed
from generate_series(1, $1) as i;
