# Benchmark Report 202611270835

**Profile:** server · **Ramp:** 10s · **Warmup:** 10s · **Sleep between tests:** 30s · **Tests:** 193

All throughput values are requests/s. 🥇🥈🥉 mark the top three per column.

## Data Type Serialization (perf-test)

### Throughput matrix

| Framework | 100vu/1rec | 100vu/10rec | 200vu/1rec | 200vu/10rec |
|-----------|---:|---:|---:|---:|
| NpgsqlRest SQL Files JIT 4.1.0 | 🥇 27,208 | 🥇 16,948 | 🥇 28,224 | 🥈 16,385 |
| NpgsqlRest SQL Files AOT 4.1.0 | 🥈 25,913 | 15,861 | 🥈 26,931 | 🥉 16,170 |
| Gin 1.12.0 | 🥉 24,446 | 🥈 16,896 | — | 🥇 17,293 |
| .NET 10 Npgsql | 19,366 | 15,417 | 19,580 | — |
| .NET 11 Npgsql | 19,301 | 15,292 | 19,532 | 15,828 |
| NestJS 12.6.0 | 16,687 | 9,351 | 17,197 | 9,416 |
| PostGraphile 5.2.1 | 7,002 | 2,465 | 6,238 | 2,490 |
| Hasura 2.50.10 | 1,934 | 1,767 | — | — |
| Laravel Octane 13.43.0 | 1,628 | 1,527 | 1,643 | — |
| Axum 0.8.9 | — | — | 18,290 | 15,820 |
| Bun 1.4.5 | — | — | 🥉 25,327 | 15,283 |
| Deno 2.9.8 | — | — | 25,312 | 15,049 |
| Django 6.1.3 | — | — | 2,022 | 1,746 |
| Express 5.3.0 | — | — | 12,711 | 7,765 |
| FastAPI 0.165.0 | — | — | 5,930 | 2,801 |
| Fastify 5.12.8 | — | — | 20,940 | 10,981 |
| Go 1.27 | — | — | 20,220 | 13,685 |
| Spring Boot 4.2.0 | — | — | 20,223 | 13,416 |
| .NET 10 EF | — | — | 12,553 | 9,917 |
| NpgsqlRest Routine JIT 4.1.0 | — | 🥉 15,940 | — | — |
| PostgREST 16.6 | — | — | 1,637 | 1,608 |
| Actix-web 1.100.0 | — | — | 18,300 | 15,818 |
| Swoole PHP 6.2.6 | — | — | 4,816 | 4,190 |

### Scaling behavior

Scaling at 1 record(s): requests/s per VU level.

Scaling = the best level divided by the 1 VU level.

| Framework | 100 VU | 200 VU | Scaling |
|-----------|---:|---:|---:|
| NpgsqlRest SQL Files JIT 4.1.0 | 27,208 | 28,224 | **1.0x** |
| NpgsqlRest SQL Files AOT 4.1.0 | 25,913 | 26,931 | **1.0x** |
| Bun 1.4.5 | — | 25,327 | — |
| Deno 2.9.8 | — | 25,312 | — |
| Fastify 5.12.8 | — | 20,940 | — |
| Spring Boot 4.2.0 | — | 20,223 | — |
| Go 1.27 | — | 20,220 | — |
| .NET 10 Npgsql | 19,366 | 19,580 | **1.0x** |
| .NET 11 Npgsql | 19,301 | 19,532 | **1.0x** |
| Actix-web 1.100.0 | — | 18,300 | — |
| Axum 0.8.9 | — | 18,290 | — |
| NestJS 12.6.0 | 16,687 | 17,197 | **1.0x** |
| Express 5.3.0 | — | 12,711 | — |
| .NET 10 EF | — | 12,553 | — |
| PostGraphile 5.2.1 | 7,002 | 6,238 | **1.0x** |
| FastAPI 0.165.0 | — | 5,930 | — |
| Swoole PHP 6.2.6 | — | 4,816 | — |
| Django 6.1.3 | — | 2,022 | — |
| Laravel Octane 13.43.0 | 1,628 | 1,643 | **1.0x** |
| PostgREST 16.6 | — | 1,637 | — |
| Gin 1.12.0 | 24,446 | — | **1.0x** |
| Hasura 2.50.10 | 1,934 | — | **1.0x** |

### Latency under heaviest load

Latency distribution at 200vu/10rec (ms).

| Framework | avg | med | p90 | p95 | p99 | max |
|-----------|----:|----:|----:|----:|----:|----:|
| NpgsqlRest SQL Files JIT 4.1.0 | 7.4 | 5.2 | 16.4 | 21.1 | 30.4 | 108.7 |
| Bun 1.4.5 | 9.2 | 6.8 | 19.5 | 23.8 | 34.0 | 136.0 |
| Gin 1.12.0 | 8.7 | 6.8 | 18.4 | 22.4 | 29.6 | 87.5 |
| NpgsqlRest SQL Files AOT 4.1.0 | 9.5 | 7.4 | 19.9 | 23.9 | 31.4 | 106.4 |
| Deno 2.9.8 | 10.0 | 7.8 | 20.6 | 24.4 | 33.2 | 115.0 |
| .NET 11 Npgsql | 10.1 | 8.3 | 19.5 | 23.3 | 31.6 | 113.2 |
| Actix-web 1.100.0 | 10.2 | 8.6 | 19.1 | 22.8 | 31.6 | 103.7 |
| Axum 0.8.9 | 10.3 | 8.8 | 19.0 | 22.7 | 31.1 | 99.7 |
| Spring Boot 4.2.0 | 13.0 | 10.3 | 25.9 | 31.5 | 42.2 | 90.5 |
| PostGraphile 5.2.1 | 30.7 | 10.5 | 96.2 | 160.0 | 276.4 | 858.7 |
| Go 1.27 | 12.8 | 11.7 | 22.8 | 26.5 | 34.0 | 70.7 |
| Fastify 5.12.8 | 16.3 | 16.6 | 21.7 | 23.4 | 27.1 | 77.1 |
| .NET 10 EF | 18.0 | 18.5 | 24.4 | 26.5 | 31.8 | 100.0 |
| NestJS 12.6.0 | 19.2 | 19.2 | 24.9 | 26.0 | 28.2 | 67.7 |
| Express 5.3.0 | 23.4 | 23.9 | 30.9 | 34.5 | 36.0 | 135.7 |
| Swoole PHP 6.2.6 | 43.7 | 43.6 | 47.8 | 50.2 | 90.3 | 153.4 |
| FastAPI 0.165.0 | 65.5 | 67.0 | 110.8 | 129.6 | 182.1 | 1,819.3 |
| PostgREST 16.6 | 114.5 | 69.3 | 284.8 | 379.6 | 600.1 | 1,951.5 |
| Django 6.1.3 | 105.3 | 109.9 | 127.1 | 133.1 | 149.1 | 186.4 |

## Cross-Scenario Summary

| Framework | Minimal | Post | Nested | Large | Params | Table-get | Table-list | Table-insert |
|-----------|---:|---:|---:|---:|---:|---:|---:|---:|
| Gin 1.12.0 | 🥇 60,090 | 🥇 13,107 | — | — | 🥇 51,464 | 🥇 54,887 | — | — |
| NpgsqlRest Routine JIT 4.1.0 | 🥈 57,264 | — | — | — | — | — | — | — |
| NpgsqlRest SQL Files JIT 4.1.0 | 🥉 57,187 | — | — | — | 🥉 45,912 | — | — | — |
| .NET 10 Npgsql | 56,471 | 🥉 5,767 | — | — | 🥈 48,111 | 🥈 52,946 | — | — |
| NpgsqlRest Routine AOT 4.1.0 | 51,786 | — | — | — | — | — | — | — |
| NpgsqlRest SQL Files AOT 4.1.0 | 49,846 | — | — | — | — | 🥉 46,906 | — | — |
| .NET 11 Npgsql | 49,416 | 🥈 5,829 | — | — | 43,100 | 46,823 | — | — |
| NestJS 12.6.0 | 26,905 | 5,735 | — | — | 25,184 | 23,944 | — | — |
| PostGraphile 5.2.1 | 11,505 | 1,823 | — | — | 8,792 | 9,762 | — | — |
| Hasura 2.50.10 | 3,824 | — | — | — | — | 3,051 | — | — |
| Laravel Octane 13.43.0 | 1,991 | — | — | — | — | 1,904 | — | — |
| FastAPI 0.165.0 | — | — | 🥈 3,692 | 🥈 6,860 | — | — | 🥈 4,418 | — |
| Fastify 5.12.8 | — | — | 🥇 14,749 | 🥇 8,584 | 40,165 | — | 🥇 18,284 | 🥇 26,707 |
| Django 6.1.3 | — | — | — | 🥉 2,039 | — | — | 🥉 2,200 | — |
| Express 5.3.0 | — | — | — | — | 28,117 | — | — | — |
| .NET 10 Dapper | — | — | — | — | 43,027 | — | — | — |

Reference combos: Minimal = 100vu, Post = 200vu/100rec, Nested = 50vu/100rec/d1, Large = 25vu/100kb, Params = 200vu, Table-get = 200vu, Table-list = 50vu, Table-insert = 50vu.

## Minimal Baseline (minimal)

| Framework | 100vu | 200vu | 500vu |
|-----------|---:|---:|---:|
| Deno 2.9.8 | — | 🥈 58,540 | 🥇 61,197 |
| Fastify 5.12.8 | — | 43,180 | 🥈 39,824 |
| Express 5.3.0 | — | 29,808 | 🥉 28,517 |
| Swoole PHP 6.2.6 | — | 12,884 | 12,876 |
| Gin 1.12.0 | 🥇 60,090 | — | — |
| Hasura 2.50.10 | 3,824 | — | — |
| Laravel Octane 13.43.0 | 1,991 | 1,993 | — |
| NestJS 12.6.0 | 26,905 | 27,050 | — |
| .NET 10 Npgsql | 56,471 | 55,478 | — |
| .NET 11 Npgsql | 49,416 | 51,353 | — |
| NpgsqlRest SQL Files AOT 4.1.0 | 49,846 | 52,300 | — |
| NpgsqlRest SQL Files JIT 4.1.0 | 🥉 57,187 | 🥉 56,831 | — |
| NpgsqlRest Routine AOT 4.1.0 | 51,786 | — | — |
| NpgsqlRest Routine JIT 4.1.0 | 🥈 57,264 | 🥇 58,886 | — |
| PostGraphile 5.2.1 | 11,505 | 11,233 | — |

## POST Body Parsing (post)

| Framework | 50vu/100rec | 100vu/10rec | 200vu/10rec | 200vu/100rec |
|-----------|---:|---:|---:|---:|
| Gin 1.12.0 | — | 🥇 38,686 | — | 🥇 13,107 |
| .NET 11 Npgsql | — | 33,722 | 32,544 | 🥈 5,829 |
| .NET 10 Npgsql | — | 🥈 34,671 | 33,314 | 🥉 5,767 |
| NestJS 12.6.0 | — | 19,265 | 19,459 | 5,735 |
| PostGraphile 5.2.1 | — | 8,408 | 8,375 | 1,823 |
| Axum 0.8.9 | — | — | 30,495 | — |
| Bun 1.4.5 | — | — | 🥇 40,889 | — |
| Deno 2.9.8 | — | — | 🥈 40,461 | — |
| Django 6.1.3 | — | — | 2,326 | — |
| Express 5.3.0 | — | — | 21,207 | — |
| FastAPI 0.165.0 | — | — | 7,813 | — |
| Fastify 5.12.8 | 🥇 5,969 | — | 27,688 | — |
| Go 1.27 | — | — | 🥉 39,636 | — |
| Hasura 2.50.10 | — | 3,107 | — | — |
| Spring Boot 4.2.0 | — | — | 23,975 | — |
| Laravel Octane 13.43.0 | — | 1,827 | 1,843 | — |
| .NET 10 EF | — | — | 13,796 | — |
| NpgsqlRest SQL Files JIT 4.1.0 | — | 🥉 34,287 | 32,805 | — |
| PostgREST 16.6 | — | — | 4,827 | — |
| Actix-web 1.100.0 | — | — | 32,407 | — |
| Swoole PHP 6.2.6 | — | — | 10,620 | — |

## Nested JSON (nested)

| Framework | 50vu/100rec/d1 | 50vu/100rec/d2 | 50vu/100rec/d3 | 100vu/100rec/d1 | 100vu/100rec/d2 | 100vu/100rec/d3 |
|-----------|---:|---:|---:|---:|---:|---:|
| Gin 1.12.0 | — | — | — | 🥇 20,297 | 🥇 18,968 | 🥇 18,455 |
| .NET 11 Npgsql | — | — | — | 15,570 | 🥈 11,588 | 🥈 8,917 |
| NestJS 12.6.0 | — | — | — | 13,501 | 11,398 | 🥉 8,809 |
| Hasura 2.50.10 | — | — | — | 3,206 | 3,148 | 3,110 |
| PostGraphile 5.2.1 | — | — | — | 2,714 | 2,568 | 2,430 |
| Laravel Octane 13.43.0 | — | — | — | 1,720 | 1,703 | 1,702 |
| Django 6.1.3 | — | 🥉 2,270 | 🥈 2,264 | — | — | — |
| FastAPI 0.165.0 | 🥈 3,692 | 🥈 3,675 | — | — | — | — |
| Fastify 5.12.8 | 🥇 14,749 | 🥇 11,958 | 🥇 9,243 | — | — | — |
| .NET 10 Npgsql | — | — | — | 🥈 15,673 | 11,493 | — |
| NpgsqlRest SQL Files AOT 4.1.0 | — | — | — | — | 11,555 | — |
| NpgsqlRest SQL Files JIT 4.1.0 | — | — | — | 🥉 15,669 | 🥉 11,582 | — |

## Large Payload (large)

| Framework | 25vu/100kb |
|-----------|---:|
| Fastify 5.12.8 | 🥇 8,584 |
| FastAPI 0.165.0 | 🥈 6,860 |
| Django 6.1.3 | 🥉 2,039 |

## Many Parameters (params)

| Framework | 100vu | 200vu |
|-----------|---:|---:|
| Gin 1.12.0 | — | 🥇 51,464 |
| .NET 10 Npgsql | — | 🥈 48,111 |
| NpgsqlRest SQL Files JIT 4.1.0 | 🥇 46,733 | 🥉 45,912 |
| .NET 11 Npgsql | 🥈 43,314 | 43,100 |
| .NET 10 Dapper | — | 43,027 |
| Fastify 5.12.8 | — | 40,165 |
| Express 5.3.0 | — | 28,117 |
| NestJS 12.6.0 | 🥉 25,019 | 25,184 |
| PostGraphile 5.2.1 | 8,770 | 8,792 |

## Table: One Row by Primary Key (table-get)

| Framework | 200vu |
|-----------|---:|
| Gin 1.12.0 | 🥇 54,887 |
| .NET 10 Npgsql | 🥈 52,946 |
| NpgsqlRest SQL Files AOT 4.1.0 | 🥉 46,906 |
| .NET 11 Npgsql | 46,823 |
| NestJS 12.6.0 | 23,944 |
| PostGraphile 5.2.1 | 9,762 |
| Hasura 2.50.10 | 3,051 |
| Laravel Octane 13.43.0 | 1,904 |

## Table: One Page of a List (table-list)

| Framework | 50vu | 200vu |
|-----------|---:|---:|
| NpgsqlRest Routine JIT 4.1.0 | — | 🥇 37,877 |
| NpgsqlRest SQL Files JIT 4.1.0 | — | 🥈 37,792 |
| .NET 10 Npgsql | — | 🥉 37,599 |
| .NET 11 Npgsql | — | 35,014 |
| NpgsqlRest Routine AOT 4.1.0 | — | 32,363 |
| NpgsqlRest SQL Files AOT 4.1.0 | — | 31,788 |
| NestJS 12.6.0 | — | 14,959 |
| PostGraphile 5.2.1 | — | 6,570 |
| Laravel Octane 13.43.0 | — | 1,790 |
| Django 6.1.3 | 🥉 2,200 | — |
| FastAPI 0.165.0 | 🥈 4,418 | — |
| Fastify 5.12.8 | 🥇 18,284 | — |

## Table: Insert Returning the Row (table-insert)

| Framework | 50vu | 200vu |
|-----------|---:|---:|
| NpgsqlRest Routine JIT 4.1.0 | — | 🥇 46,159 |
| NpgsqlRest SQL Files JIT 4.1.0 | — | 🥈 45,434 |
| .NET 10 Npgsql | — | 🥉 38,220 |
| .NET 11 Npgsql | — | 36,384 |
| NestJS 12.6.0 | — | 20,674 |
| PostGraphile 5.2.1 | — | 7,891 |
| Hasura 2.50.10 | — | 2,343 |
| Laravel Octane 13.43.0 | — | 1,861 |
| Fastify 5.12.8 | 🥇 26,707 | — |

## Resource Usage (during test windows only)

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
| Axum 0.8.9 | 17.8 | 16.4 | 285.96 |
| Actix-web 1.100.0 | 18.3 | 16.9 | 278.55 |
| NpgsqlRest SQL Files AOT 3.21.0 | 20.6 | 20.1 | 0.00 |
| NpgsqlRest Routine AOT 3.21.0 | 20.8 | 19.9 | 0.00 |
| Swoole PHP 6.2.6 | 25.6 | 20.8 | 157.22 |
| .NET 11 Dapper | 39.8 | 39.1 | 0.00 |
| Go 1.27 | 52.3 | 48.0 | 364.67 |
| NpgsqlRest Routine JIT 3.21.0 | 53.1 | 52.5 | 0.00 |
| .NET 11 EF | 53.5 | 53.3 | 0.00 |
| NpgsqlRest SQL Files JIT 3.21.0 | 53.5 | 52.8 | 0.00 |
| Gin 1.12.0 | 55.3 | 44.0 | 313.91 |
| NpgsqlRest Routine AOT 4.1.0 | 61.7 | 53.4 | 347.22 |
| PostgREST 16.6 | 79.7 | 69.6 | 259.37 |
| NpgsqlRest SQL Files AOT 4.1.0 | 104.2 | 76.2 | 321.67 |
| .NET 10 Dapper | 111.7 | 110.3 | 372.53 |
| NpgsqlRest Routine JIT 4.1.0 | 122.8 | 104.9 | 310.74 |
| .NET 10 Npgsql | 125.4 | 102.7 | 335.93 |
| .NET 11 Npgsql | 135.0 | 113.3 | 283.31 |
| NpgsqlRest SQL Files JIT 4.1.0 | 142.6 | 123.3 | 294.24 |
| .NET 10 EF | 169.8 | 158.7 | 380.42 |
| Bun 1.4.5 | 181.1 | 155.9 | 322.84 |
| Hasura 2.50.10 | 208.4 | 193.9 | 235.42 |
| FastAPI 0.165.0 | 217.6 | 211.2 | 380.30 |
| Django 6.1.3 | 288.2 | 268.6 | 349.27 |
| Deno 2.9.8 | 395.4 | 369.6 | 352.12 |
| Express 5.3.0 | 453.6 | 417.7 | 380.92 |
| NestJS 12.6.0 | 517.4 | 480.9 | 364.92 |
| Fastify 5.12.8 | 639.3 | 440.3 | 324.68 |
| Laravel Octane 13.43.0 | 688.6 | 595.4 | 383.88 |
| PostGraphile 5.2.1 | 997.5 | 803.7 | 327.58 |
| Spring Boot 4.2.0 | 1,121.0 | 1,113.8 | 378.20 |

## What Was at Its Limit

A component is "at its limit" in a test when its average CPU over the test was at least 85% of the cores it may use. Of 193 tests with resource samples:

| At its limit | Tests | Share |
|--------------|------:|------:|
| the service under test | 97 | 50% |
| the load generator | 38 | 20% |
| nothing (latency or the concurrency level set the pace) | 31 | 16% |
| PostgreSQL | 10 | 5% |
| PostgreSQL and the load generator | 6 | 3% |
| the service under test and the load generator | 6 | 3% |
| the service under test and PostgreSQL | 5 | 3% |

| Scenario | Tests | Service | PostgreSQL | Load generator | Nothing |
|----------|------:|--------:|-----------:|---------------:|--------:|
| large | 3 | 2 | 0 | 0 | 1 |
| minimal | 27 | 16 | 0 | 0 | 11 |
| nested | 30 | 9 | 0 | 18 | 4 |
| params | 13 | 13 | 0 | 0 | 0 |
| perf-test | 58 | 27 | 21 | 16 | 6 |
| post | 33 | 20 | 0 | 13 | 3 |
| table-get | 8 | 7 | 0 | 0 | 1 |
| table-insert | 9 | 5 | 0 | 0 | 4 |
| table-list | 12 | 9 | 0 | 3 | 1 |

Read a throughput number as a statement about a service only in tests where the service was at its limit and neither PostgreSQL nor the load generator was. `results_extended.csv` has the column `atLimit` for every test.

## Time in PostgreSQL

For each scenario at its reference test: milliseconds PostgreSQL spent executing one statement of the
service (pg_stat_statements: total execution time / calls), and in brackets that time as a share of the
average request latency k6 measured. The rest of a request's time is the service, the driver, the
network between the containers and waiting for a connection. Planning time is not included.

| Framework | minimal | post | nested | large | params | table-get | table-list | table-insert | Connections |
|-----------|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| .NET 10 Dapper | — | — | — | — | 0.003 (0%) | — | — | — | 100 |
| .NET 10 Npgsql | 0.003 (0%) | 0.074 (1%) | — | — | 0.003 (0%) | 0.018 (1%) | — | — | 100 |
| .NET 11 Npgsql | 0.003 (0%) | 0.072 (1%) | — | — | 0.003 (0%) | 0.017 (0%) | — | — | 100 |
| Django 6.1.3 | — | — | — | 0.491 (5%) | — | — | 0.106 (1%) | — | 48 |
| Express 5.3.0 | — | — | — | — | 0.002 (0%) | — | — | — | 100 |
| FastAPI 0.165.0 | — | — | 0.039 (0%) | 0.193 (7%) | — | — | 0.023 (0%) | — | 47 |
| Fastify 5.12.8 | — | — | 0.215 (9%) | 0.240 (11%) | 0.002 (0%) | — | 0.059 (3%) | 0.039 (2%) | 100 |
| Gin 1.12.0 | 0.002 (0%) | 0.137 (2%) | — | — | 0.034 (1%) | 0.031 (1%) | — | — | 100 |
| Hasura 2.50.10 | 0.009 (0%) | — | — | — | — | 0.062 (0%) | — | — | 38 |
| Laravel Octane 13.43.0 | 0.006 (0%) | — | — | — | — | 0.070 (0%) | — | — | 16 |
| NestJS 12.6.0 | 0.004 (0%) | 0.300 (2%) | — | — | 0.002 (0%) | 0.038 (0%) | — | — | 100 |
| NpgsqlRest Routine AOT 4.1.0 | 0.003 (0%) | — | — | — | — | — | — | — | 99 |
| NpgsqlRest Routine JIT 4.1.0 | 0.003 (0%) | — | — | — | — | — | — | — | 100 |
| NpgsqlRest SQL Files AOT 4.1.0 | 0.002 (0%) | — | — | — | — | 0.025 (1%) | — | — | 100 |
| NpgsqlRest SQL Files JIT 4.1.0 | 0.002 (0%) | — | — | — | 0.002 (0%) | — | — | — | 100 |
| PostGraphile 5.2.1 | 0.007 (0%) | 0.143 (0%) | — | — | 0.051 (0%) | 0.057 (0%) | — | — | 100 |

Connections: the most connections the service held open at the end of any of these tests.

## Memory by Scenario

Peak memory in MB of the service container during the tests of each scenario (the highest of all its
concurrency levels and sizes), sampled once a second. Memory is what `docker stats` reports: the
container's memory without the file cache the kernel can drop. Lowest first; medals for the three lowest.

| Framework | perf-test | minimal | post | nested | large | params | table-get | table-list | table-insert | Highest |
|-----------|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Axum 0.8.9 | 🥇 18 | — | 🥇 18 | — | — | — | — | — | — | 18 |
| Actix-web 1.100.0 | 🥈 18 | — | 🥈 18 | — | — | — | — | — | — | 18 |
| Swoole PHP 6.2.6 | 🥉 23 | 🥇 26 | 🥉 21 | — | — | — | — | — | — | 26 |
| Go 1.27 | 52 | — | 47 | — | — | — | — | — | — | 52 |
| Gin 1.12.0 | 55 | 🥈 43 | 50 | 🥇 42 | — | 🥇 48 | 🥇 45 | — | — | 55 |
| NpgsqlRest Routine AOT 4.1.0 | — | 🥉 48 | — | — | — | — | — | 🥇 62 | — | 62 |
| PostgREST 16.6 | 68 | — | 80 | — | — | — | — | — | — | 80 |
| NpgsqlRest SQL Files AOT 4.1.0 | 104 | 69 | — | 🥈 56 | — | — | 🥈 70 | 🥈 63 | — | 104 |
| .NET 10 Dapper | — | — | — | — | — | 🥈 112 | — | — | — | 112 |
| NpgsqlRest Routine JIT 4.1.0 | 114 | 102 | — | — | — | — | — | 🥉 112 | 🥈 123 | 123 |
| .NET 10 Npgsql | 116 | 100 | 116 | 🥉 104 | — | 🥉 125 | 🥉 113 | 120 | 🥇 118 | 125 |
| .NET 11 Npgsql | 124 | 102 | 118 | 120 | — | 133 | 135 | 128 | 🥉 132 | 135 |
| NpgsqlRest SQL Files JIT 4.1.0 | 143 | 126 | 142 | 118 | — | 141 | — | 119 | 139 | 143 |
| .NET 10 EF | 165 | — | 170 | — | — | — | — | — | — | 170 |
| Bun 1.4.5 | 181 | — | 152 | — | — | — | — | — | — | 181 |
| Hasura 2.50.10 | 199 | 194 | 192 | 203 | — | — | 199 | — | 208 | 208 |
| FastAPI 0.165.0 | 211 | — | 213 | 212 | 🥇 218 | — | — | 214 | — | 218 |
| Django 6.1.3 | 274 | — | 277 | 260 | 🥈 288 | — | — | 279 | — | 288 |
| Deno 2.9.8 | 372 | 395 | 389 | — | — | — | — | — | — | 395 |
| Express 5.3.0 | 454 | 411 | 414 | — | — | 415 | — | — | — | 454 |
| NestJS 12.6.0 | 511 | 475 | 485 | 487 | — | 486 | 510 | 517 | 511 | 517 |
| Fastify 5.12.8 | 448 | 410 | 411 | 407 | 🥉 639 | 524 | — | 542 | 543 | 639 |
| Laravel Octane 13.43.0 | 562 | 571 | 603 | 643 | — | — | 657 | 674 | 689 | 689 |
| PostGraphile 5.2.1 | 997 | 851 | 817 | 832 | — | 786 | 788 | 892 | 827 | 997 |
| Spring Boot 4.2.0 | 1,112 | — | 1,121 | — | — | — | — | — | — | 1,121 |

## Throughput per CPU Core

perf-test at 100 VU, 1 record(s). CPU cores used = average CPU of the service during the test / 100.

| Framework | Requests/s | CPU cores used | Requests/s per core | Peak memory (MB) |
|-----------|-----------:|---------------:|--------------------:|-----------------:|
| NpgsqlRest SQL Files JIT 4.1.0 | 27,208 | 2.91 | 🥇 9,355 | 120 |
| Gin 1.12.0 | 24,446 | 2.70 | 🥈 9,063 | 47 |
| .NET 11 Npgsql | 19,301 | 2.47 | 🥉 7,799 | 101 |
| NpgsqlRest SQL Files AOT 4.1.0 | 25,913 | 3.44 | 7,530 | 85 |
| .NET 10 Npgsql | 19,366 | 3.24 | 5,970 | 100 |
| NestJS 12.6.0 | 16,687 | 3.82 | 4,373 | 466 |
| PostGraphile 5.2.1 | 7,002 | 3.84 | 1,822 | 997 |
| Hasura 2.50.10 | 1,934 | 2.42 | 798 | 190 |
| Laravel Octane 13.43.0 | 1,628 | 3.81 | 427 | 534 |

## Test Completion

1 test(s) with exit code 99: a threshold was crossed (p99 >= 1 s, or 1% failed requests).

Exit code 99 with zero failed requests means the latency objective (p99 < 1 s) was missed; the test ran to its end and its numbers are valid.

| Service | Test | Exit code | Failed requests | p99 (ms) |
|---------|------|----------:|----------------:|---------:|
| Laravel Octane 13.43.0 | 200vu minimal | 99 | 0 | 445 |

## Lines of Code

| Framework | Lines of Code |
|-----------|--------------:|
| Hasura 2.50.10 | 0 |
| PostGraphile 5.2.1 | 0 |
| PostgREST 16.6 | 12 (config only) |
| NpgsqlRest Routine AOT 4.1.0 | 21 (config only) |
| NpgsqlRest Routine JIT 4.1.0 | 21 (config only) |
| Laravel Octane 13.43.0 | 99 |
| .NET 10 EF | 116 |
| Fastify 5.12.8 | 129 |
| Express 5.3.0 | 130 |
| NestJS 12.6.0 | 135 |
| FastAPI 0.165.0 | 152 |
| .NET 10 Dapper | 155 |
| NpgsqlRest SQL Files AOT 4.1.0 | 164 (config + the SQL files) |
| NpgsqlRest SQL Files JIT 4.1.0 | 164 (config + the SQL files) |
| Bun 1.4.5 | 173 |
| Deno 2.9.8 | 176 |
| Spring Boot 4.2.0 | 189 |
| Django 6.1.3 | 252 |
| Swoole PHP 6.2.6 | 264 |
| .NET 10 Npgsql | 281 |
| .NET 11 Npgsql | 281 |
| Axum 0.8.9 | 334 |
| Actix-web 1.100.0 | 345 |
| Gin 1.12.0 | 368 |
| Go 1.27 | 408 |

## Run Environment

- Started: 2026-11-27T08:35:31Z (UTC), commit `97976a5af089`
- Host: AMD EPYC-Milan Processor, 48 CPUs, 188669 MB, Ubuntu 26.04.1 LTS, kernel Linux 7.0.0-44-generic x86_64
- Docker 29.1.3, Compose 2.40.3+ds1-0ubuntu1, PostgreSQL 19.0, k6 v2.4.0 (commit/dd9395906d, go1.27.3, linux/amd64)

| Container | Image | CPU set |
|-----------|-------|---------|
| axum-app-v0.8.9 | `src-axum-app-v0.8.9` (fda5746fd773) | 28-31 |
| bun-app-v1.4.5 | `src-bun-app-v1.4.5` (7ca5918dd5f3) | 28-31 |
| deno-app-v2.9.8 | `src-deno-app-v2.9.8` (7ab7bd9a3d2d) | 28-31 |
| django-app-v6.1.3 | `src-django-app-v6.1.3` (1cad5f5a241b) | 28-31 |
| express-app-v5.3.0 | `src-express-app-v5.3.0` (105ad7108b39) | 28-31 |
| fastapi-app-v0.165.0 | `src-fastapi-app-v0.165.0` (c687b023b5f8) | 28-31 |
| fastify-app-v5.12.8 | `src-fastify-app-v5.12.8` (2fa96bc0f044) | 28-31 |
| gin-app-v1.12.0 | `src-gin-app-v1.12.0` (a0df724503e2) | 28-31 |
| go-app-v1.27 | `src-go-app-v1.27` (30bf9576b0f1) | 28-31 |
| hasura-v2.50.10 | `hasura/graphql-engine:v2.50.10.cli-migrations-v3` (2821e7d65901) | 28-31 |
| java25-spring-boot-v4.2.0 | `src-java25-spring-boot-v4.2.0` (5f113265b028) | 28-31 |
| laravel-v13.43.0-octane-app | `src-laravel-v13.43.0-octane-app` (432f03bcb129) | 28-31 |
| nestjs-app-v12.6.0 | `src-nestjs-app-v12.6.0` (6cc9e9e10649) | 28-31 |
| net10-minapi-dapper-jit | `src-net10-minapi-dapper-jit` (bcd3b58c8f9b) | 28-31 |
| net10-minapi-ef-jit | `src-net10-minapi-ef-jit` (f53ef76a9759) | 28-31 |
| net10-minapi-npgsql-jit | `src-net10-minapi-npgsql-jit` (4b6446b938fc) | 28-31 |
| net11-minapi-dapper-jit | `src-net11-minapi-dapper-jit` (7ae0173568f7) | 28-31 |
| net11-minapi-ef-jit | `src-net11-minapi-ef-jit` (49813392deb9) | 28-31 |
| net11-minapi-npgsql-jit | `src-net11-minapi-npgsql-jit` (0293e6425ded) | 28-31 |
| npgsqlrest-file-aot-v3.21.0 | `vbilopav/npgsqlrest:v3.21.0` (f07577ba1c94) | 28-31 |
| npgsqlrest-file-aot-v4.1.0 | `vbilopav/npgsqlrest:v4.1.0` (2a76ed8a526a) | 28-31 |
| npgsqlrest-file-jit-v3.21.0 | `vbilopav/npgsqlrest:v3.21.0-jit` (eca629de3500) | 28-31 |
| npgsqlrest-file-jit-v4.1.0 | `vbilopav/npgsqlrest:v4.1.0-jit` (b22cce8310a0) | 28-31 |
| npgsqlrest-routine-aot-v3.21.0 | `vbilopav/npgsqlrest:v3.21.0` (f07577ba1c94) | 28-31 |
| npgsqlrest-routine-aot-v4.1.0 | `vbilopav/npgsqlrest:v4.1.0` (2a76ed8a526a) | 28-31 |
| npgsqlrest-routine-jit-v3.21.0 | `vbilopav/npgsqlrest:v3.21.0-jit` (eca629de3500) | 28-31 |
| npgsqlrest-routine-jit-v4.1.0 | `vbilopav/npgsqlrest:v4.1.0-jit` (b22cce8310a0) | 28-31 |
| postgraphile-v5.2.1 | `src-postgraphile-v5.2.1` (aeaf562d2440) | 28-31 |
| postgres | `postgres:19.0-alpine` (cac45fb483ca) | 0-15 |
| postgrest-v16.6 | `postgrest/postgrest:v16.6` (5ce030c15350) | 28-31 |
| rust-app-v1.100.0 | `src-rust-app-v1.100.0` (2d0f2173110e) | 28-31 |
| swoole-php-app-v6.2.6 | `src-swoole-php-app-v6.2.6` (d9ba71bd58ef) | 28-31 |
| test | `src-test` (4e1114a11620) | 16-27 |
