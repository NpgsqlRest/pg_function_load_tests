-- pg_stat_statements: the benchmark runner resets it before every measured test and reads it after
-- (run-all.sh), so that each test has PostgreSQL's own count of statements and the time it spent executing
-- them. That is the part of a request's time that no framework can change. The library is preloaded by the
-- postgres command in docker-compose.yml; the cost of tracking is the same for every service.
create extension if not exists pg_stat_statements;
