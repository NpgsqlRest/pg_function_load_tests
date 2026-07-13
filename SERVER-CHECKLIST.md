# Hetzner Server Checklist — 2026-07 Benchmark Round

Server: Hetzner CCX33 (8 dedicated vCPU / 32 GB RAM), Ubuntu 26.04 — `ssh root@<SERVER_IP>`
Repo state: master @ `88646e8`
Expected duration: **~20–24 hours** (760 tests: 38 combinations × 20 services; warmup 10s + ramp 10s + hold 60s + sleep 30s each)

> Working checklist for running a benchmark round on the server. Log problems in **Issues** at the bottom for the next round.

---

## 1. Install prerequisites (~2 min)

- [ ] ```bash
      apt update
      apt install -y docker.io docker-compose-v2 git tmux jq
      systemctl enable --now docker
      ```
- [ ] Ubuntu 26.04 ships compose only as the `docker compose` plugin; the repo
      scripts call the hyphenated `docker-compose`, so add a shim:
      ```bash
      printf '#!/bin/sh\nexec docker compose "$@"\n' > /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
      ```
- [ ] Verify:
      ```bash
      docker --version && docker compose version && docker-compose version && python3 --version
      ```

## 2. Clone and prepare (~1 min)

- [ ] ```bash
      cd /root
      git clone https://github.com/NpgsqlRest/pg_function_load_tests.git
      cd pg_function_load_tests
      chmod -R 777 src/_k6/results
      ```

## 3. Build and start the stack with CPU partitioning (~15–25 min first time)

- [ ] ```bash
      cd /root/pg_function_load_tests/src
      docker-compose -f docker-compose.yml -f docker-compose.server.yml up --build --detach
      ```
- [ ] All 22 containers up (20 services + postgres + test):
      ```bash
      docker-compose ps --format '{{.Name}} {{.State}}' | sort
      ```

## 4. Smoke test — DO NOT SKIP (~2 min)

- [ ] ```bash
      ./test-services.sh
      ```
      Must print **Total: 120, Passed: 120, Failed: 0**.
      If anything fails: stop, fix, re-test — everything after this is unattended.

## 5. Launch the benchmark inside tmux

- [ ] ```bash
      tmux new -s bench
      cd /root/pg_function_load_tests/src
      PROFILE=server ./run-benchmark.sh
      ```
- [ ] Confirm the startup lines: `PAUSE_IDLE enabled`, resource monitors starting,
      then per-test `warmup (10s)...` lines.
- [ ] Detach: `Ctrl+B`, then `D` → safe to log off and shut the computer down.

## 6. Checking in (optional, anytime)

```bash
ssh root@<SERVER_IP>
tmux attach -t bench                # watch live; Ctrl+B, D to detach again

# without attaching — progress (of 760 tests) and aborts (should print nothing):
wc -l /root/pg_function_load_tests/src/_k6/results/*/test_log.csv
awk -F',' 'NR>1 && $5!=0' /root/pg_function_load_tests/src/_k6/results/*/test_log.csv
```

## 7. When it finishes

- [ ] Verify artifacts (the run prints the results dir at the end; `<STAMP>` = dir name):
      ```bash
      cd /root/pg_function_load_tests/src
      ls _k6/results/<STAMP>/
      # expect: results.json, results.csv, report.md, resource_usage.md,
      #         test_log.csv, stats/, 760 *_summary.txt files
      less _k6/results/<STAMP>/report.md
      ```
- [ ] If `report.md` is missing:
      ```bash
      python3 generate-report.py _k6/results/<STAMP>
      ```

## 8. Commit results to the timestamp branch (critical — generated GitHub links point at it)

- [ ] ```bash
      cd /root/pg_function_load_tests
      git config user.name "YOUR_NAME"
      git config user.email "YOUR_EMAIL"
      git checkout -b <STAMP>
      git add -A
      git commit -m "Benchmark results <STAMP>"
      git push origin <STAMP>
      ```
      Auth: HTTPS + PAT when prompted, or switch to SSH:
      `git remote set-url origin git@github.com:NpgsqlRest/pg_function_load_tests.git`

## 9. Afterwards

- [ ] Locally: `git fetch && git checkout <STAMP>` → blog series from `results.csv` + `report.md`
- [ ] **Deprovision the server** (CCX33 = €173/mo)

---

## Issues

<!-- log problems here as they come up -->

- **[resolved]** Ubuntu 26.04: `docker-compose` command not found — compose v2 is
  plugin-only (`docker compose`). Fixed with a `/usr/local/bin/docker-compose` shim
  (see step 1).
- **[resolved]** run-benchmark.sh started monitors for only 19 of 20 services —
  the `grep -v '(postgres|test)'` filter also matched **postgrest** (substring).
  Pre-existing bug: the January 2026 blog's resource table is missing PostgREST.
  Fixed in `7f7b22a` (exact-match filter); required Ctrl+C + cleanup + restart of
  the run (~10 min lost).
