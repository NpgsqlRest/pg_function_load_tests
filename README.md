# Load Performance Testing for Web APIs Returning PostgreSQL Functions

This project performs load performance testing for Web APIs on different tech stacks that execute PostgreSQL functions and return the results. The goal is to **measure framework overhead**, not database performance - all test functions use `generate_series()` for constant, predictable database response times.

## Frameworks Tested

| Framework | Version | Port | Language |
|-----------|---------|------|----------|
| Django | 6.1.3 | 8000 | Python 3.15 |
| FastAPI | 0.165.0 | 8001 | Python 3.15 |
| Fastify | 5.12.8 | 3101 | Node.js 26 |
| Express | 5.3.0 | 3102 | Node.js 26 |
| NestJS | 12.6.0 (Express platform) | 3106 | Node.js 26 |
| Bun | 1.4.5 | 3104 | Bun/TypeScript |
| Deno | 2.9.8 | 3105 | Deno/TypeScript |
| Go (net/http) | 1.27 | 5200 | Go |
| Gin | 1.12.0 | 5201 | Go 1.27 |
| Spring Boot | 4.2.0 | 5400 | Java 25 |
| Actix-web | 4.20 | 5300 | Rust 1.100 |
| Axum | 0.8.9 | 5301 | Rust 1.100 |
| Swoole | 6.2.6 | 3103 | PHP 8.5 |
| Laravel Octane | 13.43.0, Octane 2.25 on Swoole | 3107 | PHP 8.5 |
| PostgREST | 16.6 | 3000 | Haskell |
| PostGraphile | 5.2.1 (GraphQL) | 3108 | Node.js 26 |
| Hasura | 2.50.10 (GraphQL) | 3109 | Haskell |
| .NET 10 Minimal API (EF) | 10.0, EF Core 10 | 5003 | C# |
| .NET 10 Minimal API (Dapper) | 10.0, Npgsql 11 | 5004 | C# |
| .NET 11 Minimal API (EF) | 11.0, EF Core 11 | 5013 | C# |
| .NET 11 Minimal API (Dapper) | 11.0, Npgsql 11 | 5014 | C# |
| .NET 10 Minimal API (plain Npgsql) | 10.0, Npgsql 11 | 5016 | C# |
| .NET 11 Minimal API (plain Npgsql) | 11.0, Npgsql 11 | 5015 | C# |
| NpgsqlRest Routine (AOT) | 3.21.0 (.NET 10) | 5007 | C# |
| NpgsqlRest Routine (JIT) | 3.21.0 (.NET 10) | 5008 | C# |
| NpgsqlRest SQL Files (AOT) | 3.21.0 (.NET 10) | 5009 | C# |
| NpgsqlRest SQL Files (JIT) | 3.21.0 (.NET 10) | 5010 | C# |
| NpgsqlRest Routine (AOT) | 4.1.0 (.NET 11) | 5005 | C# |
| NpgsqlRest Routine (JIT) | 4.1.0 (.NET 11) | 5006 | C# |
| NpgsqlRest SQL Files (AOT) | 4.1.0 (.NET 11) | 5011 | C# |
| NpgsqlRest SQL Files (JIT) | 4.1.0 (.NET 11) | 5012 | C# |

PostgreSQL is 19.0; the load generator is k6 2.4.0 (pinned).

**.NET 10 against .NET 11.** The two Dapper services are the same code with the same libraries (Npgsql 11.0.0, Dapper 2.1.100) on the two runtimes, so their difference is the runtime. The two EF services each use the EF Core of their platform (EF Core 10 with Npgsql 10 on .NET 10, EF Core 11 with Npgsql 11 on .NET 11), so their difference is the platform as a user gets it. NpgsqlRest 3.21.0 runs on .NET 10 and 4.1.0 on .NET 11 (with Npgsql 11); that comparison is the release as shipped.

NpgsqlRest is tested with two endpoint sources: **Routine** services expose the PostgreSQL functions from `src/_postgres/init.sql`; **SQL Files** services (3.21.0+) expose raw-query `.sql` file endpoints from `src/_sql_files/` (the query bodies are twins of the functions, executed directly without a function call).

### GraphQL services

PostGraphile and Hasura answer the same six operations over GraphQL: one `POST` with a query document and its variables per operation (the k6 scripts build it in `src/_k6/scripts/lib/graphql.js`). It is the same data from the same functions, asked for in the way each product is used, so the comparison is "this data over HTTP", with a different protocol on the way.

- **PostGraphile** exposes the functions in `public` as they are (`perfTest(_records: ...) { nodes { rowNum ... } }`).
- **Hasura** exposes a function only when it returns `SETOF` a table it tracks, and the benchmark functions return `TABLE(...)`. For Hasura alone, `src/_postgres/hasura.sql` adds a schema with one empty table per result shape and one `select * from` SQL function per benchmark function. PostgreSQL inlines such functions, so the work is the same.

### API Differences

Frameworks have different URL patterns and data serialization behaviors. See [SERVICES.MD](src/SERVICES.MD) for details on:
- URL patterns (PostgREST uses `/rpc/perf_*`, others use `/api/perf-*`)
- Array parameter syntax differences
- JSON/timestamp/interval serialization variations

## Benchmark Scenarios

The first six scenarios use memory-only PostgreSQL functions (no table I/O) to isolate framework overhead. The three table scenarios (added 2026-11) read and write real tables, as the endpoints of a real API do:

| Scenario | Endpoint | Tests |
|----------|----------|-------|
| **perf_test** | `GET /api/perf-test` | Comprehensive data type serialization (23 types) |
| **perf_minimal** | `GET /api/perf-minimal` | Pure routing overhead baseline |
| **perf_post** | `POST /api/perf-post` | JSON request body parsing |
| **perf_nested** | `GET /api/perf-nested` | Nested JSON object serialization |
| **perf_large_payload** | `GET /api/perf-large-payload` | Large response streaming/buffering |
| **perf_many_params** | `GET /api/perf-many-params` | Query string parsing (20 parameters) |
| **perf_table_get** | `GET /api/perf-table-get` | One row by primary key from a 500,000 row table |
| **perf_table_list** | `GET /api/perf-table-list` | One page (20 rows) of a list, keyset pagination over an index |
| **perf_table_insert** | `POST /api/perf-table-insert` | An insert that returns the new row |

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- `jq` (for running `test-services.sh` validation script)

### Clone and Build

```bash
git clone https://github.com/vb-consulting/pg_function_load_tests.git
cd pg_function_load_tests/src
docker-compose down && docker-compose up --build --detach
```

Wait for health checks to pass (all services depend on PostgreSQL being ready).

### Verify Services

Test all 31 services and 279 endpoints:

```bash
./test-services.sh
```

Or test against a remote server:

```bash
./test-services.sh your-server-ip
```

## Running Benchmarks

### Test Profiles

The benchmark runner supports three profiles:

| Profile | Purpose | Duration | Use Case |
|---------|---------|----------|----------|
| **minimal** | Markdown validation | ~2 min | Test output format before deploying |
| **local** | Development testing | ~30 min | Validate changes locally |
| **server** | Production benchmarks | ~4 hours | Full benchmark on dedicated server |

### Local Testing

**Quick markdown validation** (minimal profile):
```bash
docker-compose exec test /bin/sh -c "PROFILE=minimal /scripts/run-all.sh"
```

**Development testing** (local profile - default):
```bash
docker-compose exec test /bin/sh /scripts/run-all.sh
```

**Run specific scenario only**:
```bash
docker-compose exec test /bin/sh -c "SCENARIO=minimal /scripts/run-all.sh"
```

Available scenarios: `all`, `perf-test`, `minimal`, `post`, `nested`, `large`, `params`, `table`

### Server Testing

For production benchmarks on a dedicated server, follow **[HETZNER-GUIDE.md](HETZNER-GUIDE.md)**: the whole procedure step by step, from creating the server to deleting it, including the dry run and the pilot that decide the server size. [ANALYSIS.md](ANALYSIS.md) explains what the method can and cannot say, and what is proposed for future rounds.

In short:

```bash
# Set permissions so the k6 container can write results
chmod -R 777 src/_k6/results

# Start a tmux session (survives SSH disconnection)
tmux

# Start the stack with CPU partitioning (recommended on the server)
docker-compose -f docker-compose.yml -f docker-compose.server.yml up --build --detach

# Run full benchmark suite with resource monitoring
PROFILE=server ./run-benchmark.sh

# Or without resource monitoring (original method)
docker-compose exec test /bin/sh -c "PROFILE=server /scripts/run-all.sh"

# Detach: Press Ctrl+B, then D
# Reattach later: tmux attach
```

**Server profile settings:**
- 10s ramp-up + 60s measured hold per combination (30s hold for minimal baseline)
- VUs: 1, 50, 100, 200 (up to 500 for minimal baseline)
- 30s sleep between tests (TCP TIME_WAIT clearance)
- 10s untimed warmup run before every measured test (same script and parameters)
- Idle services are paused (`docker pause`) while another service is under test

**Options** (environment variables in front of `./run-benchmark.sh`):

| Variable | Meaning |
|---|---|
| `PROFILE` | `server`, `local` (default) or `minimal` (three seconds per test: a dry run of the whole chain) |
| `SCENARIO` | `all` (default), `perf-test`, `minimal`, `post`, `nested`, `large`, `params`, `table` |
| `ONLY` | A regular expression: only the services whose name matches are tested (`ONLY='^go-app\|^rust-app'`; without `^`, `go-app` also matches `django-app`) |
| `SHUFFLE` | `true`: a new random order of the services for every combination. Default: the fixed order |
| `PAUSE_IDLE` | `false`: do not pause the idle services |
| `TARGET_HOST` | The address of the services when k6 runs on another machine |
| `MEASURE_SERVICES` | `false`: skip the footprint measurement before the tests (image size, startup time, idle memory; it restarts every service once) |

### Results

Results are saved to `src/_k6/results/<timestamp>/`:
- `results.json` / `results.csv` - **The raw dataset**: one record per test with throughput,
  latency percentiles (avg/med/p90/p95/p99/max), bytes transferred, and failure counts,
  plus run metadata (profile, ramp, warmup). Every analysis view is derived from this.
- `report.md` - Generated analysis: per-scenario pivot matrices (framework × combo, medals
  for top 3), scaling-behavior table, latency distribution, cross-scenario summary,
  resource usage, what was at its limit in each test, service footprint, time in PostgreSQL,
  memory by scenario, throughput per CPU core, test completion
  (what each non-zero exit code means), lines-of-code comparison and the run environment
- `<timestamp>_all.md` - Detailed per-combination tables (one table per scenario/VU/records)
- `resource_usage.md` - Memory and CPU per service, measured only during its test windows
- `results_extended.csv` - `results.csv` plus, per test: the k6 exit code, CPU and memory of the
  service, CPU of PostgreSQL and of the load generator, requests per second per CPU core used, and
  `atLimit`: which of the three was out of CPU; `rpsHold` (requests per second after the ramp);
  time to first byte and the share of passed checks from k6; and PostgreSQL's own numbers for the
  test (`pgCalls`, `pgExecMs`, `pgExecMsPerCall`, `pgConnections`, and `dbTimeShare`: the share of
  an average request's time that PostgreSQL spent executing). **Start here for any analysis.**
- `k6/<test>.json` - The complete k6 summary of every test: every metric k6 has, not only the
  ones the tables use
- `test_log.csv` - Start/end time, k6 exit code and k6 parameters of every test, and what
  `pg_stat_statements` counted during it (statements, execution time, rows, open connections)
- `stats/` - Raw resource samples, one per second and container (`stats/infra/` for PostgreSQL and
  k6), `stats/environment.json`: commit, machine, versions, images and CPU sets of the run, and
  `stats/services.csv`: image size, time to the first answer and idle memory of every service
- `comparison.md` / `comparison.csv` - Written by `python3 compare-runs.py <old run> <new run>`: the
  change per service against an earlier round, with the unchanged services as controls
- Individual test summaries for each service/scenario combination

Regenerate the analysis views at any time (e.g. after tweaking `generate-report.py`)
without re-running the benchmark:

```bash
python3 generate-report.py _k6/results/<timestamp>
```

## Architecture

### PostgreSQL Configuration

```yaml
postgres:
  image: postgres:18.4-alpine
  command: postgres -c 'max_connections=2000'
```

**Connection calculation:**
- Tests are serialized (one service at a time)
- Active service: 100 connections (pool max)
- 30 idle services: ~310 connections
- Total during test: ~300 connections
- Setting 2000 provides 6x headroom

### Test Isolation

Tests are **serialized** - only one service is tested at a time. This ensures:
- No resource contention between services
- Clean baseline for each test
- Accurate framework overhead measurement

The 30s sleep between tests (server profile) allows:
- TCP TIME_WAIT connections to clear
- Connection pools to stabilize
- CPU/memory to return to baseline
- JIT-compiled code to cool down

## Fairness & Methodology

Changes made in the 2026-07 round to keep the comparison fair, balanced, and realistic
(these intentionally break comparability with earlier rounds):

**Equal core budget for every framework.** Single-threaded event-loop frameworks now run
one worker per CPU core (uvicorn `--workers`, gunicorn `-w`, Node.js `cluster`,
Bun `SO_REUSEPORT` workers), matching natively multi-threaded runtimes (Go, Rust, .NET,
JVM). Swoole was reduced from `cpu*2` to `cpu` workers. Worker counts follow `nproc`,
which respects cpuset limits.

**Equal database connection budget.** Every service gets an aggregate pool of ~100
connections. Multi-worker services split it evenly (workers x per-worker pool ~= 100).
Fixed: Django previously ran with psycopg_pool defaults (4 per worker), PostgREST with
its default `db-pool` of 10.

**Real, per-test warmup.** Every measured test is preceded by an untimed run of the same
script and parameters, so JIT compilation (JVM/.NET), connection pools, and PostgreSQL
plan caches are warm for the exact code path being measured. (The previous global warmup
phase silently crashed on a missing env var and only targeted one endpoint.)

**Ramp + hold load shape.** Tests now ramp to the target VUs (10s on server profile) and
hold there for the full measured duration. Previously the ramp spanned the whole test, so
a "200 VU" test averaged ~100 VUs and never sustained its labeled concurrency.

**CPU partitioning** (`docker-compose.server.yml`). PostgreSQL (cores 0-1) and the k6
load generator (cores 2-3) are pinned away from the service under test (cores 4-7), so
the measured service never competes with the database or the load generator for CPU.

**Idle services are paused.** During each test, all other services are frozen with
`docker pause` (cgroup freezer) - removing idle JVM/CLR GC ticks, pool keepalives, and
scheduler noise while preserving their JIT-warmed state. Controlled by `PAUSE_IDLE`
(default `true`; requires the docker socket mounted into the test container).

**Serialization parity.** Spring Boot now serializes PostgreSQL `json`/`jsonb` values as
raw JSON like every other framework (previously Jackson wrapped them in a
`{"null":...,"type":...,"value":...}` object, inflating its payloads).

**Honest bookkeeping.** Each test's start/end time and k6 exit code are recorded in
`test_log.csv` (threshold aborts are visible instead of silently missing), and
`resource_usage.md` averages CPU/memory only over each service's active test windows
instead of the whole multi-day run.

**Two-server topology (optional).** All k6 scripts accept `TARGET_HOST` to point at a
remote application server, so the load generator can run on a separate instance over a
private network. `./test-services.sh <host>` validates a remote stack the same way.

## Manual Testing

Use `test.http` with VS Code REST Client or similar tools to manually test individual endpoints.

Example:
```http
### Django - perf_test
GET http://localhost:8000/api/perf-test?_records=1&_text=test&...

### PostgREST - perf_minimal
GET http://localhost:3000/rpc/perf_minimal
```

## Latest Results

**July 2026 round** — 20 services, 760 tests, full fairness overhaul:

- 📊 **[Full analysis series](https://npgsqlrest.github.io/blog/benchmarks-2026-07/)** — methodology, per-framework deep dives, overall analysis, raw result tables
- [Results branch (202607131327)](https://github.com/NpgsqlRest/pg_function_load_tests/tree/202607131327) — the exact code that ran
- [Raw dataset & report](https://github.com/NpgsqlRest/pg_function_load_tests/tree/202607131327/src/_k6/results/202607131327) — `results.csv`, `report.md`, 760 k6 summaries, resource stats

**Previous rounds:**

- [January 2026](https://npgsqlrest.github.io/blog/postgresql-rest-api-benchmark-2026.html) ([branch 202601211416](https://github.com/NpgsqlRest/pg_function_load_tests/tree/202601211416)) — not comparable to July 2026 (methodology changed)
- [2025](https://npgsqlrest.github.io/blog/postgresql-rest-api-benchmark-2025.html) ([branch 202412302119](https://github.com/NpgsqlRest/pg_function_load_tests/tree/202412302119))

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
