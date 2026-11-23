# Running a Benchmark Round on Hetzner, Step by Step

For the round after July 2026: 31 services, 44 combinations each (38 as in July and 6 for the new table scenarios), **1,364 tests, about 43 to 45 hours** unattended.
Each test is a 10 s warm-up, a 10 s ramp, a 60 s hold (30 s for the minimal scenario) and a 30 s pause.

Tick the boxes as you go. Problems go into **Issues** at the bottom, for the next round.

Read [ANALYSIS.md](ANALYSIS.md) first if you have not: step 6 (the pilot) decides whether the real run uses this server or a larger one.

---

## 0. Create the server (5 minutes, in the browser)

- [ ] Log in at <https://console.hetzner.cloud>, open your project (or create one).
- [ ] **Security → SSH keys → Add SSH key**: paste your public key (`cat ~/.ssh/id_ed25519.pub`) if it is not there yet.
- [ ] **Firewalls → Create firewall**, name `ssh-only`: one inbound rule, **TCP port 22** from any IPv4 and IPv6; no other inbound rule. Outbound: leave everything allowed.
      Do not skip this. The stack publishes PostgreSQL (5432, with a test password) and 24 HTTP ports on all interfaces.
- [ ] **Servers → Add server**:
  - Location: any (Falkenstein, Nuremberg or Helsinki); the same one as last time keeps the hardware the same.
  - Image: **Ubuntu 26.04**.
  - Type: **Dedicated vCPU → CCX33** (8 vCPU, 32 GB). Dedicated, not shared: shared vCPUs make the numbers worthless.
    (If the pilot in step 6 says so, you will come back and create a **CCX43**, 16 vCPU, instead.)
    **Or start on a CCX63** (48 vCPU, 192 GB, about 1.45 EUR per hour) with `docker-compose.server-48.yml`: PostgreSQL 16 cores, k6 12 cores, the service 4 cores as in July. It removes the question the pilot answers, for about 70 EUR for the whole round. With it, use `docker-compose.server-48.yml` wherever this guide says `docker-compose.server.yml`; the pilot becomes a check, not a decision.
  - Networking: public IPv4 on.
  - SSH keys: yours. Firewalls: `ssh-only`.
  - Name: `bench`.
- [ ] Create. Copy the IPv4 address. Below it is `<SERVER_IP>`.

The server is billed by the hour until you **delete** it (step 11). Powering it off does not stop the billing.

## 1. Log in and install (3 minutes)

- [ ] ```bash
      ssh root@<SERVER_IP>
      ```
- [ ] ```bash
      apt update && apt -y upgrade
      apt install -y docker.io docker-compose-v2 git tmux jq python3
      systemctl enable --now docker
      ```
- [ ] Ubuntu 26.04 has compose only as the `docker compose` plugin; the scripts call `docker-compose`:
      ```bash
      printf '#!/bin/sh\nexec docker compose "$@"\n' > /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
      ```
- [ ] If `apt upgrade` installed a new kernel: `reboot`, wait a minute, log in again.
- [ ] Check:
      ```bash
      docker --version && docker-compose version && python3 --version && nproc && free -g | head -2
      ```
      Expect 8 processors and about 31 GB.

## 2. Kernel limits (1 minute)

The same for every service; they remove limits that have nothing to do with the services (ANALYSIS.md, 3.6).

- [ ] ```bash
      cat > /etc/sysctl.d/99-benchmark.conf <<'SYSCTL'
      net.core.somaxconn = 65535
      net.ipv4.tcp_max_syn_backlog = 65535
      net.ipv4.ip_local_port_range = 1024 65535
      net.ipv4.tcp_tw_reuse = 1
      SYSCTL
      sysctl --system | grep -E 'somaxconn|port_range|tw_reuse'
      ```

If you want this round to be comparable with July to the last percent, skip this step (July did not have it) and note that in the article.

## 3. Clone (1 minute)

- [ ] ```bash
      cd /root
      git clone https://github.com/NpgsqlRest/pg_function_load_tests.git
      cd pg_function_load_tests
      git log --oneline -1
      chmod -R 777 src/_k6/results
      ```
      The commit shown is the code that will run. It must be the one you prepared.

## 4. Build and start (20 to 30 minutes the first time)

- [ ] ```bash
      cd /root/pg_function_load_tests/src
      docker-compose -f docker-compose.yml -f docker-compose.server.yml up --build --detach
      ```
      If a pull fails with `429 Too Many Requests`: Docker Hub allows 100 anonymous pulls per hour per address. Run `docker login` with a Docker Hub account (free) and repeat the command; it continues where it stopped.
- [ ] All 33 containers are up (31 services, postgres, test):
      ```bash
      docker-compose ps --format '{{.Name}} {{.State}}' | sort
      docker-compose ps --format '{{.State}}' | sort | uniq -c      # expect: 26 running
      ```
- [ ] The CPU sets are in place (postgres `0,1`, test `2,3`, every service `4-7`):
      ```bash
      for c in $(docker-compose ps -q); do docker inspect --format '{{.HostConfig.CpusetCpus}} {{.Name}}' $c; done | sort
      ```

## 5. Smoke test: do not skip (2 minutes)

- [ ] ```bash
      ./test-services.sh
      ```
      Must end with **Total: 279, Passed: 279, Failed: 0**.
      If anything fails: stop and fix it. Everything after this runs unattended.

## 6. Dry run and pilot (about two and a half hours, and it decides the server size)

**Dry run** (5 minutes): every script against every service for three seconds. It proves that the whole chain works on this machine: the collector, the test log, the report.

- [ ] ```bash
      PROFILE=minimal ./run-benchmark.sh
      ```
- [ ] The line `Monitoring 33 containers through their cgroup files` appeared near the start.
      If it says `using docker stats` instead, the cgroup files were not found: the run still works, with the old, coarser collector. Log it under Issues with the output of `cat _k6/results/*/stats/collector.log`.
- [ ] ```bash
      D=$(ls -d _k6/results/2*/ | tail -1); ls $D
      head -3 $D/results_extended.csv
      grep -c . $D/test_log.csv                          # 280: a header and 279 tests
      awk -F',' 'NR>1 && $5!=0' $D/test_log.csv          # prints nothing
      ```
      `results_extended.csv` must have numbers in the columns `svcCpuAvg`, `pgCpuAvg` and `k6CpuAvg`.
- [ ] Delete the dry run: `rm -rf $D ${D%/}_all.md`

**Pilot** (about 2 hours 20 minutes): real durations, four services that stand for the range (a compiled one that needs little CPU, NpgsqlRest, Go, and one that needs a lot of CPU), two scenarios. It answers the question the July data could not: in how many tests is the service the part that runs out of CPU?

- [ ] ```bash
      tmux new -s pilot
      export ONLY='^rust-app|^go-app|^npgsqlrest-routine-aot-v4|^fastapi-app'   # ^ matters: plain go-app also matches django-app
      PROFILE=server SCENARIO=minimal ./run-benchmark.sh      # 12 tests, about 16 minutes
      PROFILE=server SCENARIO=perf-test ./run-benchmark.sh    # 64 tests, about 2 hours
      unset ONLY
      ```
      `Ctrl+B`, then `D` to detach; `tmux attach -t pilot` to come back.
- [ ] Read the section **What Was at Its Limit** in the `report.md` of both pilot runs:
      ```bash
      for D in $(ls -d _k6/results/2*/ | tail -2); do sed -n '/## What Was at Its Limit/,/## Throughput per CPU Core/p' $D/report.md; done
      ```
- [ ] Decide:
  - **The service is at its limit in most tests** (or nothing is): stay on this server, go to step 7.
  - **PostgreSQL or the load generator is at its limit in most tests**: the round would measure them, not the services. Delete this server (step 11), create a **CCX43** (16 vCPU) in step 0, repeat steps 1 to 5 with `docker-compose.server-16.yml` in place of `docker-compose.server.yml` (step 4 then shows `0-5`, `6-9` and `10-13`), and run the pilot again there.
- [ ] Keep the pilot's two directories (they go into the results branch as evidence for the decision), or delete them as in the dry run. Write the decision under Issues.

## 7. Start the round (2 minutes, then about 43 to 45 hours)

- [ ] Restart the stack, so that every service starts the round from the same state:
      ```bash
      cd /root/pg_function_load_tests/src
      docker-compose -f docker-compose.yml -f docker-compose.server.yml restart
      sleep 60 && ./test-services.sh | tail -3
      ```
      (Use `docker-compose.server-16.yml` here and everywhere below if that is what step 6 decided.)
- [ ] ```bash
      tmux new -s bench
      PROFILE=server ./run-benchmark.sh
      ```
      Add `SHUFFLE=true` in front to run the services in a random order per combination (ANALYSIS.md, section 2).
- [ ] The first lines show: the results directory (its name is the `<STAMP>`), then `Measuring service footprint` with one line per service (about ten minutes: each service is restarted once and timed), `Monitoring 33 containers through their cgroup files`, `PAUSE_IDLE enabled`, then per test `warmup (10s)...`. A line starting with `!!! no docker access to postgres` must NOT appear: without it there are no PostgreSQL statistics per test and the insert table is not emptied.
- [ ] Detach: `Ctrl+B`, then `D`. You can log out and switch your computer off.

## 8. Looking in (any time)

```bash
ssh root@<SERVER_IP>
tmux attach -t bench                 # watch; Ctrl+B, D to leave it running

cd /root/pg_function_load_tests/src
wc -l _k6/results/*/test_log.csv                        # progress: 913 lines when done
awk -F',' 'NR>1 && $5!=0 && $5!=99' _k6/results/*/test_log.csv   # real failures: should print nothing
tail -2 _k6/results/*/stats/infra/postgres_stats.csv    # the collector is alive: the timestamps move
```

Exit code 99 in the log is not a failure: k6 returns it when the latency objective (p99 below 1 s) was missed. Any other non-zero code is one.

## 9. When it has finished

- [ ] The last lines in tmux say `=== Benchmark Complete ===` and name the results directory.
- [ ] ```bash
      cd /root/pg_function_load_tests/src
      D=_k6/results/<STAMP>
      ls $D | grep -v _summary.txt
      # expect: report.md  resource_usage.json  resource_usage.md  results.csv  results.json
      #         results_extended.csv  stats  test_log.csv
      ls $D/*_summary.txt | wc -l                       # 1364
      less $D/report.md
      ```
- [ ] If `report.md` or `results_extended.csv` is missing: `python3 generate-report.py $D`
- [ ] Compare with July (the July results are on their own branch):
      ```bash
      git fetch origin 202607131327
      mkdir -p /tmp/july && git archive origin/202607131327 src/_k6/results/202607131327 | tar -x -C /tmp/july
      python3 compare-runs.py /tmp/july/src/_k6/results/202607131327 $D
      less $D/comparison.md
      ```
      The NpgsqlRest 3.21.0 services are the controls: they are the same images as in July.

## 10. Commit the results to a branch named after the stamp

The generated links in the report point at a branch with that name, so it has to exist.

- [ ] ```bash
      cd /root/pg_function_load_tests
      git config user.name "YOUR_NAME"
      git config user.email "YOUR_EMAIL"
      git checkout -b <STAMP>
      git add -A
      git commit -m "Benchmark results <STAMP>"
      git push origin <STAMP>
      ```
      Authentication: a GitHub personal access token as the password when asked (HTTPS), or switch to SSH with a key that may push: `git remote set-url origin git@github.com:NpgsqlRest/pg_function_load_tests.git`.
- [ ] On your own computer: `git fetch && git checkout <STAMP>` and check that `src/_k6/results/<STAMP>/report.md` is there.

## 11. Delete the server

- [ ] Only after step 10 is verified from your own computer. In the console: the server → **Delete**. Then delete the `ssh-only` firewall if you do not keep it for next time.

---

## If something goes wrong during the run

| What you see | What to do |
|---|---|
| The run stopped, or the SSH session died | It runs in tmux: `tmux attach -t bench`. If tmux is gone the server was rebooted: start again from step 7; delete the partial results directory first. |
| A service fails every test (exit code other than 0 or 99) | Let the run go on; the other services are unaffected. Afterwards: `docker-compose logs --tail 50 <service>`, and log it under Issues. |
| Containers stay paused after you stopped the run with Ctrl+C | `docker ps -q --filter status=paused \| xargs -r docker unpause` |
| You stopped the run and want to start over | `pkill -f collect-stats.sh; pkill -f 'docker stats'`, unpause as above, delete the partial results directory, step 7. |
| Disk full | `docker system df`, `docker builder prune -af` (the build cache is the large part). |
| You want one scenario only | `PROFILE=server SCENARIO=perf-test ./run-benchmark.sh` (also `minimal`, `post`, `nested`, `large`, `params`, `table`). |
| You want some services only | `ONLY='^go-app\|^rust-app' PROFILE=server ./run-benchmark.sh` (a regular expression over the service names; without `^`, `go-app` also matches `django-app`). |

## Issues

<!-- log problems here as they come up -->

- **[resolved, July 2026]** Ubuntu 26.04: `docker-compose` command not found. Compose v2 is plugin-only (`docker compose`). Fixed with the shim in step 1.
- **[resolved, July 2026]** `run-benchmark.sh` started monitors for only 19 of 20 services: the `grep -v '(postgres|test)'` filter also matched **postgrest**. The January 2026 article's resource table is missing PostgREST for that reason. Fixed in `7f7b22a`.
- **[November 2026]** The July round did not measure PostgreSQL or the load generator, and its service samples came every 3 seconds. Both changed for this round (see ANALYSIS.md); step 6 is new because of it.
