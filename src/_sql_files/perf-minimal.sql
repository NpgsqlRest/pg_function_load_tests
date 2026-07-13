-- Raw-query twin of public.perf_minimal() in _postgres/init.sql — keep both in sync.
-- HTTP GET
select 'ok'::text as status, now() as ts;
