-- Raw-query twin of public.perf_large_payload() in _postgres/init.sql — keep both in sync.
-- Requires UnnamedSingleColumnSet: false so the single column returns [{"data": "..."}] like the function endpoint.
-- HTTP GET
-- @param $1 _size_kb int
select repeat('x', $1 * 1024) as data;
