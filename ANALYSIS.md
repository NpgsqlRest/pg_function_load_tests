# Next Round: Fairness, Realism and What the Results Can Tell

Written 2026-11-21 while preparing the round that follows July 2026 (`202607131327`). It has three parts: what the July data says about the method, what was changed in the tooling because of it, and what is proposed but not done.

Everything under "Done" is in the repository. Everything under "Proposed" is a decision for whoever runs the round: each one changes the numbers, so it should be chosen before the run, not after.

## 1. What the July data says about the method

The July round measured CPU and memory of every service, sampled while that service was under test. Reading those samples per test, not per service, gives this:

| Service | Tests | Median CPU during a test | Highest CPU in any test | Tests at 85% or more of its 4 cores |
|---|---:|---:|---:|---:|
| FastAPI | 38 | 1.8 cores | 3.9 cores | 9 |
| Django | 38 | 2.8 cores | 3.5 cores | 6 |
| .NET 10 EF | 38 | 1.4 cores | 3.8 cores | 3 |
| NpgsqlRest (all six) | 38 each | 1.1 to 1.2 cores | 2.4 to 3.2 cores | 0 |
| .NET 10 Dapper | 38 | 1.2 cores | 3.1 cores | 0 |
| PostgREST | 38 | 0.9 cores | 3.1 cores | 0 |
| Express, Deno, Bun, Fastify | 38 each | 0.8 to 1.1 cores | 2.2 to 2.9 cores | 0 |
| Spring Boot | 38 | 0.8 cores | 2.8 cores | 0 |
| Go | 38 | 0.9 cores | 1.9 cores | 0 |
| Swoole, Actix-web, Axum | 38 each | 0.4 to 0.6 cores | 1.3 to 1.6 cores | 0 |

**In 18 of 760 tests the service under test used most of the CPU it was given. In the other 742 something else set the pace.** The candidates are PostgreSQL (2 cores), the load generator (2 cores), or simply the concurrency level (at 1 virtual user nothing is at a limit). Neither PostgreSQL nor k6 was measured in July, so the data cannot say which.

What follows from that:

- A throughput number from those 742 tests is not a statement about how much load a framework can carry. It is a statement about how fast one request travels through that framework **and** PostgreSQL **and** k6 at that concurrency. Frameworks that spend less CPU per request (Rust, Swoole, Go) do not get credit for it in requests per second, because the requests per second were capped elsewhere.
- The ranking is still meaningful as "time per request at this concurrency". It is not meaningful as "capacity".
- Differences of a few percent between services in a test where PostgreSQL is at its limit are differences in how each driver talks to PostgreSQL (pipelining, prepared statements, binary or text results), not in the web framework.

Two smaller things in the same data:

- **Samples came every 3 seconds, not every second.** Each of the 20 collectors ran `docker stats --no-stream` in a loop, and one call takes about two seconds. A 30-second test had about ten samples.
- **The collectors were load.** Twenty of those loops ran for the whole run, on the host, on any core, including the four given to the service under test.

## 2. Done

### Measuring what was not measured

- **PostgreSQL and the load generator are measured** (`stats/infra/postgres_stats.csv`, `k6_stats.csv`), with the services.
- **One collector reads the containers' cgroup files** (`src/collect-stats.sh`): one process, one pass per second, no docker call per sample. When the files are not where docker puts them (macOS, cgroup v1) the run falls back to the old method and says so.
- **Every test's k6 parameters are in `test_log.csv`** (new `params` column), so a test in the log can be joined to its row in the results.
- **`results_extended.csv`** (written by `generate-report.py`): every row of `results.csv` plus the k6 exit code, average and peak CPU and memory of the service, average and peak CPU of PostgreSQL and of k6, requests per second per CPU core the service used (`rpsPerCore`), and `atLimit`: which of the three was at 85% or more of the cores it may use.
- **`report.md` has three new sections**: "What Was at Its Limit" (how many tests were limited by the service, by PostgreSQL, by the load generator, by nothing, in total and per scenario), "Throughput per CPU Core" and "Run Environment".
- **`stats/environment.json`**: commit, kernel, CPU model, memory, docker and compose versions, PostgreSQL and k6 versions, and for every container its image, image id and CPU set.

### What can only be captured during the run

Analysis can be written after a round, from the raw data. Data that was not captured cannot be. These were added for that reason:

- **The complete k6 summary of every test** (`k6/<test>.json`): time to first byte, connection time, checks, iterations, every percentile. The results table keeps a selection; the rest is no longer only in a text file.
- **`rpsHold`**: requests per second during the hold stage only, next to `rps`, which includes the ramp and is unchanged (so rounds stay comparable). Section 3.4 below proposed this; it is done.
- **PostgreSQL's own numbers per test** (`pg_stat_statements`, reset before each measured run and read after it): statements executed, time spent executing them, rows, and the connections the service held. From these: `pgExecMsPerCall` and `dbTimeShare`, the share of an average request's time that PostgreSQL spent executing. This is the number that separates "the database was slow" from "the service was slow", per test. Planning time is not included (tracking it has a known cost under concurrency). The cost of tracking execution is the same for every service.
- **Service footprint** (`stats/services.csv`, `src/measure-services.sh`): image size, time from a container restart to the first correct answer, and memory ten seconds after it, before any load. Measured once per service before the tests.
- **Memory by scenario** in the report, and memory counted as `docker stats` counts it (without the file cache the kernel can drop), as in July.

### Reading exit codes

In July the report's "Test Completion" table listed 103 tests with exit code 99 and no explanation. k6 returns 99 when a threshold is crossed. Here that is almost always the latency objective (p99 below one second), which does not stop a test. The table now says what the code means and shows the failed requests and the p99 of each such test, so an abort can be told from a missed objective.

### Failed tests are not results

A service that answers every request with an error does it faster than one that does the work, so it ranked with a high requests per second number. The report now shows "failed" in place of a number for any test in which more than 1% of the requests failed, and ranks it last. (Found in the local dry run: Laravel answered 400 to every k6 request and was listed with 3,900 requests per second. The cause was Symfony's rule against a Host name that ends in a number, and the docker service name ended in `.0`; the service is named `laravel-v13.43.0-octane-app` because of it.)

### Reproducibility

- **k6 is pinned** (`grafana/k6:2.4.0`). It was `latest`: two rounds could run different load generators without anyone deciding it.
- **`SHUFFLE=true`** runs the services in a new random order for every combination. Default is the fixed order. With the fixed order every service always runs after the same neighbor.
- **`src/compare-runs.py <old> <new>`** writes `comparison.md` and `comparison.csv`: the change of requests per second per service between two rounds, matched by service name and test. Services with the same version in both rounds are listed first as **controls**: they did not change, so their difference is what the machine, PostgreSQL, k6 and the method changed. This round has four real controls: the NpgsqlRest 3.21.0 services run the same published images as in July. (The script calls every service with an unchanged name a control. `axum-app-v0.8.9` and the two `net10-minapi` services kept their names but were rebuilt with a newer toolchain or libraries, so read those three as changed.)

### Smaller corrections to the report

- The scaling table says what its factor is (the best level divided by the 1 VU level). The July article described it as "1 to 200 VU", which is not what was computed.
- The lines-of-code table labels the SQL file services "config + the SQL files", not "config only".

## 3. Proposed: fairness

### 3.1 Give PostgreSQL and the load generator enough CPU that the service is the limit

This is the one that matters most, and the data to decide it does not exist yet. Proposal:

1. On the server, before the real run, do a **pilot of about two and a half hours**: `SCENARIO=minimal` and `SCENARIO=perf-test` with the server profile for four services (`ONLY=...`) (see the Hetzner guide, step 6).
2. Read "What Was at Its Limit" in the pilot's `report.md`.
3. If PostgreSQL or k6 is at its limit in most tests, change the split before the real run. Options:
   - **A 16 vCPU server (CCX43)** with `docker-compose.server-16.yml`: PostgreSQL 6 cores, k6 4 cores, service 4 cores, 2 left for the system. Keeps the service at four cores, so July's numbers stay roughly comparable.
   - **A 48 vCPU server (CCX63)** with `docker-compose.server-48.yml`: PostgreSQL 16 cores, k6 12 cores, service 4 cores. The same idea with so much room that neither can be the limit; about 70 EUR for the round.
   - **Stay on 8 vCPU and give the service fewer cores**: PostgreSQL 3, k6 2, service 3 (edit `docker-compose.server.yml`). Cheaper, but not comparable with July.
   - **Two servers**: k6 on its own machine (`TARGET_HOST`, already supported), PostgreSQL 4 cores and service 4 cores on the other. Adds a real network, which is closer to production and adds its own variance.

### 3.2 Repetition

One run per combination gives no measure of noise; July's article used "under 3% is a tie" as a rule of thumb. Proposal: run the round twice (same server, `SHUFFLE=true` on the second), and report the median and the spread. It doubles the time (about 42 hours each, with 30 services and the table scenarios). A cheaper version: repeat only the reference combinations three times.

### 3.3 The load generator's own work

Every k6 iteration parses the response body as JSON (twice in `script.js`) to check it. For 500 KB responses that is most of what k6 does, on its two cores. If the pilot shows k6 at its limit in the large-payload tests, switch those scenarios to checking status and length only (`discardResponseBodies`), and leave correctness to `test-services.sh`, which already checks every endpoint before the run.

### 3.4 Requests per second include the ramp (addressed: `rpsHold`)

`rps` is all requests divided by the whole k6 run: 10 seconds of ramp and 60 seconds of hold. The ramp has fewer virtual users, so the number is a little below the rate at the target. It is the same for every service. To report the rate during the hold only, tag the hold stage in the k6 scripts and read the tagged sub-metric.

### 3.5 A fixed arrival rate, for latency

All tests are closed-loop: a virtual user sends the next request when the last one answered. A slow service is therefore sent fewer requests, and its latency looks better than it would under the load a fast service handled. July's article names this. Proposal: one more scenario with k6's `constant-arrival-rate` executor at two or three fixed rates (for example 1,000, 3,000 and 6,000 requests per second on the minimal endpoint), reporting p50, p99 and dropped iterations. That is the table that answers "which one keeps its latency at the same load".

### 3.6 Kernel limits

At 500 virtual users with new connections per test, the defaults for `net.core.somaxconn`, the local port range and `TIME_WAIT` handling can become the limit for the fastest services. The comment in `run-all.sh` assumes `tcp_tw_reuse`; nothing sets it. Setting these once on the server (Hetzner guide, step 2) is the same for every service and removes a limit that has nothing to do with them.

## 4. Proposed: realism

The six scenarios call functions that compute in memory. That isolates the framework, which is the stated goal, and it is also why a round says little about a real API. Proposals, in the order of what they would add:

1. **A table. Done for this round** (`SCENARIO=table`, see section 7). The proposal was: one indexed lookup by primary key, one page of a list (`limit`/`offset` or keyset) and one insert that returns the new row, against a table of a few hundred thousand rows. This is what most endpoints do. PostgreSQL's share of the work becomes real, which changes the weight of everything else, and it shows connection pool behavior under contention.
2. **An authenticated endpoint.** Every real API checks a token. A scenario with a JWT in the `Authorization` header that each service must verify measures a cost that the current round leaves out for everyone.
3. **A mixed workload.** 80% reads, 15% list pages, 5% writes, from one k6 script, as one number per service. A single number per service is what readers look for; today the report has to pick a "reference" test to stand for it.
4. **What an operator cares about besides throughput**, measured once per service at start: time from container start to the first successful request, memory when idle, and image size. All three are cheap to collect automatically and belong in the resource table.
5. **HTTP as it is deployed.** Everything is HTTP/1.1 without TLS and without compression, from the same host. Compression and HTTP/2 are on in most deployments and cost different amounts in different stacks. Lower priority: it is usually a reverse proxy's job.

## 5. Proposed: turning a run into an article

What the July series needed that the tooling did not produce, from reading the published pages against `generate-report.py`:

| The article has | Today | Proposal |
|---|---|---|
| "Winners by category" and podium totals over all 38 combinations | Counted by hand from the pivot tables | A table in `report.md`: per service, gold, silver and bronze counts over all combinations |
| Tiers ("leader", "the pack, within 20%") | By hand | A tier column from a stated rule (for example: within 5%, 20%, 50% of the best) |
| p99 objective: "657 of 760 tests met it", per service "11 of 16" | By hand from exit codes | A table: per service, tests that met p99 < 1 s, out of how many (`results_extended.csv` has `exitCode` and `latencyP99` now) |
| Sibling pairs (Actix against Axum, Fastify against Express, Bun against Deno, EF against Dapper) | By hand; the percentages in the article could not all be reproduced from the tables | A "pairs" table with a fixed definition: geometric mean of the ratio over all combinations |
| NpgsqlRest against PostgREST, "best variant per scenario" | By hand; the published table does not always use the best variant | The same pairs table, with the variant named |
| January to July movements | By hand | `compare-runs.py` (done) |
| .NET 10 against .NET 11, 3.21.0 against 4.1.0 | New this round | The pairs table again: `net10-minapi-dapper-jit` against `net11-minapi-dapper-jit`, and so on |
| One page per framework | Written per framework | `generate-report.py --service <name>`: that service's rows from every table, its rank in each, its resource rows, its limit column |
| Charts | None; the series is tables only | `results_extended.csv` is flat and typed, so any charting tool reads it directly. A bar chart per scenario at the reference combination would carry most of the story |

A rule that would have prevented the inconsistencies found in the July pages: **every number in an article comes from a generated table**, and a derived number (a ratio, a percentage, a count) has its definition printed under the table that contains it. The scaling factor and the sibling-pair percentages were the two that did not follow it.

## 6. What changed in the services for this round

- **NpgsqlRest**: 3.4.7 removed; 3.21.0 kept unchanged (the controls); 4.1.0 added, routine and SQL file sources, AOT and JIT.
- **.NET**: .NET 11 services added next to the .NET 10 ones. The two Dapper services use the same libraries (Npgsql 11.0.0, Dapper 2.1.100), so they differ in the runtime only. The two EF services use the EF Core of their platform.
- **Six new services**, chosen for what readers ask about: **Gin** (the most used Go framework, next to plain `net/http`), **NestJS** (on its default Express platform, next to Express and Fastify), **Laravel Octane** on Swoole (next to plain Swoole), **.NET 11 with plain Npgsql** (no Dapper, no EF: the floor for the .NET services), and two GraphQL servers that generate their API from the database, as NpgsqlRest and PostgREST do: **PostGraphile** and **Hasura**.
- **The GraphQL two are a different protocol, and that is said where their numbers are shown.** Each request is a `POST` with a query document and variables, and the server parses and plans GraphQL before it reaches PostgreSQL. Hasura cannot expose a function that returns `TABLE(...)`, so it calls `select * from` wrapper functions in its own schema (`src/_postgres/hasura.sql`) that PostgreSQL inlines. Their rows in the POST-body scenario are not "a POST against a GET" as for the others: every one of their requests is a POST.
- **Laravel Octane has one database connection per worker**, and four workers per core (16 on the 4 cores it is given), where the other services have a pool of about 100. That is how Octane works, not a setting left low: a worker handles one request at a time. `WORKERS` overrides the count.
- **Everything else** is on its current release (see the table in `README.md`), PostgreSQL is 19.0, and two driver upgrades are major versions worth a look in the results: `postgres` (the JavaScript driver used by Bun and Deno) 3.4 to 4.1, and PostgREST 14 to 16.

## 7. The table scenarios (added for this round)

Three scenarios that read and write real tables (`src/_postgres/tables.sql`), next to the six that compute in memory. The six are unchanged, so they stay comparable with July; the three are new and have no July counterpart.

| Scenario | Function | What it does |
|---|---|---|
| `table-get` | `perf_table_get(_id)` | one row by primary key from `perf_items` (500,000 rows) |
| `table-list` | `perf_table_list(_category, _after_id, _limit)` | one page of 20 rows of a category after a given id (keyset pagination over an index) |
| `table-insert` | `perf_table_insert(_item_id, _quantity, _note)` | one insert into `perf_orders` that returns the new row |

Decisions that affect the numbers:

- **Every request asks for different data.** A virtual user draws its ids and pages from a seeded generator (`src/_k6/scripts/lib/table.js`), so the index and the table are read across their whole range, and every service gets the same sequence.
- **Still functions.** Every service calls the same function, as in the other scenarios, so the SQL that runs is the same for all. The NpgsqlRest SQL file services run the same statements from `src/_sql_files/`.
- **The insert table is emptied before every insert test** (`reset_orders` in `run-all.sh`), so the thirtieth service does not insert into a table that the first twenty-nine filled. This needs the docker socket in the k6 container, which the run already uses to pause idle services. With k6 on a second server (`TARGET_HOST`) it cannot be done and the run says so.
- **The data fits in memory** (about 60 MB with indexes), so reads are from PostgreSQL's cache, not from disk. That is what a well-sized production database does for its hot data, and it keeps the disk of the rented server out of the read results. The insert scenario does write to disk (WAL with the default `synchronous_commit`), so there the server's disk is part of the result, the same for every service.
- **Two concurrency levels** (50 and 200 virtual users), to keep the added time near six hours.
- **PostgreSQL's share of the work is larger here** than in the in-memory scenarios. Expect the services to be closer to each other, and expect "What Was at Its Limit" to name PostgreSQL more often. That is the realistic picture, not a flaw of the scenario.
