# Load Performance Testing for Web APIs Returning PostgreSQL Functions

This project performs load performance testing for Web APIs on different tech stacks that execute PostgreSQL functions and return the results. The goal is to **measure framework overhead**, not database performance - all test functions use `generate_series()` for constant, predictable database response times.

## Frameworks Tested

| Framework | Version | Port | Language |
|-----------|---------|------|----------|
| Django | 6.0.7 | 8000 | Python |
| FastAPI | 0.139.0 | 8001 | Python |
| Fastify | 5.10.0 | 3101 | Node.js |
| Express | 5.2.1 | 3102 | Node.js |
| Bun | 1.3.14 | 3104 | Bun/TypeScript |
| Deno | 2.9.2 | 3105 | Deno/TypeScript |
| Go (net/http) | 1.26 | 5200 | Go |
| Spring Boot | 4.1.0 | 5400 | Java 25 |
| Actix-web | 1.97.0 | 5300 | Rust |
| Axum | 0.8.9 | 5301 | Rust |
| Swoole | 6.2.1 | 3103 | PHP |
| PostgREST | 14.14 | 3000 | Haskell |
| .NET 10 Minimal API (EF) | 10.0 | 5003 | C# |
| .NET 10 Minimal API (Dapper) | 10.0 | 5004 | C# |
| NpgsqlRest Routine (AOT) | 3.4.7 | 5005 | C# |
| NpgsqlRest Routine (JIT) | 3.4.7 | 5006 | C# |
| NpgsqlRest Routine (AOT) | 3.21.0 | 5007 | C# |
| NpgsqlRest Routine (JIT) | 3.21.0 | 5008 | C# |
| NpgsqlRest SQL Files (AOT) | 3.21.0 | 5009 | C# |
| NpgsqlRest SQL Files (JIT) | 3.21.0 | 5010 | C# |

NpgsqlRest is tested with two endpoint sources: **Routine** services expose the PostgreSQL functions from `src/_postgres/init.sql`; **SQL Files** services (3.21.0+) expose raw-query `.sql` file endpoints from `src/_sql_files/` (the query bodies are twins of the functions, executed directly without a function call).

### API Differences

Frameworks have different URL patterns and data serialization behaviors. See [SERVICES.MD](src/SERVICES.MD) for details on:
- URL patterns (PostgREST uses `/rpc/perf_*`, others use `/api/perf-*`)
- Array parameter syntax differences
- JSON/timestamp/interval serialization variations

## Benchmark Scenarios

All scenarios use memory-only PostgreSQL functions (no table I/O) to isolate framework overhead:

| Scenario | Endpoint | Tests |
|----------|----------|-------|
| **perf_test** | `GET /api/perf-test` | Comprehensive data type serialization (23 types) |
| **perf_minimal** | `GET /api/perf-minimal` | Pure routing overhead baseline |
| **perf_post** | `POST /api/perf-post` | JSON request body parsing |
| **perf_nested** | `GET /api/perf-nested` | Nested JSON object serialization |
| **perf_large_payload** | `GET /api/perf-large-payload` | Large response streaming/buffering |
| **perf_many_params** | `GET /api/perf-many-params` | Query string parsing (20 parameters) |

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

Test all 20 services and 120 endpoints:

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

Available scenarios: `all`, `perf-test`, `minimal`, `post`, `nested`, `large`, `params`

### Server Testing

For production benchmarks on a dedicated server:

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

### Results

Results are saved to `src/_k6/results/<timestamp>/`:
- `results.json` / `results.csv` - **The raw dataset**: one record per test with throughput,
  latency percentiles (avg/med/p90/p95/p99/max), bytes transferred, and failure counts,
  plus run metadata (profile, ramp, warmup). Every analysis view is derived from this.
- `report.md` - Generated analysis: per-scenario pivot matrices (framework × combo, medals
  for top 3), scaling-behavior table, latency distribution, cross-scenario summary,
  resource usage, test completion (aborts), and lines-of-code comparison
- `<timestamp>_all.md` - Detailed per-combination tables (one table per scenario/VU/records)
- `resource_usage.md` - Memory and CPU per service, measured only during its test windows
- `test_log.csv` - Start/end time and k6 exit code for every test
- `stats/` - Raw resource monitoring data
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
- 19 idle services: ~200 connections
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

- [PostgreSQL REST API Benchmark 2025](https://npgsqlrest.github.io/blog/postgresql-rest-api-benchmark-2025.html)
- [Test Branch](https://github.com/vb-consulting/pg_function_load_tests/tree/202412302119)
- [Test Results Raw Output](https://github.com/vb-consulting/pg_function_load_tests/blob/202412302119/src/_k6/results/202412302119.md)
- [Parsed Tests Results Discussion Thread](https://github.com/vb-consulting/pg_function_load_tests/discussions/8)
- [Interactive Chart](https://vb-consulting.github.io/blog/npgsqlrest/load-test/)

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
