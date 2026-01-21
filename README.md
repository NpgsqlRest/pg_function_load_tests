# Load Performance Testing for Web APIs Returning PostgreSQL Functions

This project performs load performance testing for Web APIs on different tech stacks that execute PostgreSQL functions and return the results. The goal is to **measure framework overhead**, not database performance - all test functions use `generate_series()` for constant, predictable database response times.

## Frameworks Tested

| Framework | Version | Port | Language |
|-----------|---------|------|----------|
| Django | 6.0.1 | 8000 | Python |
| FastAPI | 0.128.0 | 8001 | Python |
| Fastify | 5.7.1 | 3101 | Node.js |
| Bun | 1.3.3 | 3104 | Bun/TypeScript |
| Go (net/http) | 1.25 | 5200 | Go |
| Spring Boot | 4.0.1 | 5400 | Java 24 |
| Actix-web | 1.91.1 | 5300 | Rust |
| Swoole | 6.0 | 3103 | PHP |
| PostgREST | 14.3 | 3000 | Haskell |
| .NET 9 Minimal API (EF) | 9.0 | 5002 | C# |
| .NET 10 Minimal API (EF) | 10.0 | 5003 | C# |
| .NET 10 Minimal API (Dapper) | 10.0 | 5004 | C# |
| NpgsqlRest (AOT) | 3.4.7 | 5005 | C# |
| NpgsqlRest (JIT) | 3.4.7 | 5006 | C# |

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

Test all 14 services and 84 endpoints:

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

# Run full benchmark suite with resource monitoring
PROFILE=server ./run-benchmark.sh

# Or without resource monitoring (original method)
docker-compose exec test /bin/sh -c "PROFILE=server /scripts/run-all.sh"

# Detach: Press Ctrl+B, then D
# Reattach later: tmux attach
```

**Server profile settings:**
- 60s test duration per combination
- VUs: 1, 50, 100, 200 (up to 500 for minimal baseline)
- 30s sleep between tests (TCP TIME_WAIT clearance)
- JIT warmup phase before benchmarks

### Results

Results are saved to `src/_k6/results/<timestamp>/`:
- `<timestamp>_all.md` - Unified summary with all results
- `resource_usage.md` - Memory and CPU usage per service (when using run-benchmark.sh)
- `stats/` - Raw resource monitoring data
- Individual test summaries for each service/scenario combination

## Architecture

### PostgreSQL Configuration

```yaml
postgres:
  image: postgres:17.2-alpine
  command: postgres -c 'max_connections=2000'
```

**Connection calculation:**
- Tests are serialized (one service at a time)
- Active service: 100 connections (pool max)
- 13 idle services: ~200 connections
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
