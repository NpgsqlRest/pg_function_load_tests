#!/bin/bash

# =============================================================================
# SERVICE FOOTPRINT
# What an operator sees of a service before it serves anything: how large its
# image is, how long it takes from "start the container" to the first correct
# answer, and how much memory it holds when idle.
#
# Usage: measure-services.sh <output.csv> [ONLY regex]
#
# For each service: restart its container, poll its minimal endpoint until it
# answers 200, wait IDLE_SECONDS, read its memory. One service at a time. The
# services are restarted, so run it before the benchmark, not during it
# (run-benchmark.sh does; MEASURE_SERVICES=false skips it).
#
# Columns: service,image,imageMb,startupMs,idleMemMb
#   startupMs  from "docker restart" returning to the first HTTP 200 (polled every 20 ms);
#              empty when the service did not answer within START_TIMEOUT seconds
#   idleMemMb  as "docker stats" reports memory, IDLE_SECONDS after the first answer
# =============================================================================

OUT="$1"
ONLY="${2:-}"
IDLE_SECONDS="${IDLE_SECONDS:-10}"
START_TIMEOUT="${START_TIMEOUT:-120}"
HOST="${HOST:-localhost}"
SMOKE_DIR="$(dirname "$0")/_graphql_smoke"

if [ -z "$OUT" ]; then
    echo "usage: $0 <output.csv> [ONLY regex]" >&2
    exit 2
fi

now_ms() {
    # GNU date has nanoseconds; elsewhere (macOS) fall back to python
    local ns=$(date +%s%N 2>/dev/null)
    case "$ns" in
        *N) python3 -c 'import time; print(int(time.time() * 1000))' ;;
        *) echo $((ns / 1000000)) ;;
    esac
}

# One request to the service's minimal endpoint; prints the HTTP status.
probe() {
    local service=$1 port=$2
    case "$service" in
        postgraphile*)
            curl -s -o /dev/null -w '%{http_code}' --max-time 2 -X POST -H 'Content-Type: application/json' \
                --data-binary "@${SMOKE_DIR}/postgraphile-perf_minimal.json" "http://${HOST}:${port}/graphql" ;;
        hasura*)
            curl -s -o /dev/null -w '%{http_code}' --max-time 2 -X POST -H 'Content-Type: application/json' \
                --data-binary "@${SMOKE_DIR}/hasura-perf_minimal.json" "http://${HOST}:${port}/v1/graphql" ;;
        postgrest*)
            curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://${HOST}:${port}/rpc/perf_minimal" ;;
        *)
            curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://${HOST}:${port}/api/perf-minimal" ;;
    esac
}

echo "service,image,imageMb,startupMs,idleMemMb" > "$OUT"

for cid in $(docker-compose ps -q); do
    service=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.service"}}' "$cid")
    case "$service" in postgres|test) continue ;; esac
    if [ -n "$ONLY" ] && ! echo "$service" | grep -q -E -- "$ONLY"; then
        continue
    fi
    port=$(docker inspect --format '{{range $p, $b := .HostConfig.PortBindings}}{{(index $b 0).HostPort}} {{end}}' "$cid" | awk '{print $1}')
    image=$(docker inspect --format '{{.Config.Image}}' "$cid")
    image_mb=$(docker image inspect --format '{{.Size}}' "$(docker inspect --format '{{.Image}}' "$cid")" 2>/dev/null | awk '{printf "%.1f", $1 / 1048576}')

    docker restart -t 5 "$cid" > /dev/null 2>&1
    start=$(now_ms)
    startup=""
    while [ $(( $(now_ms) - start )) -lt $((START_TIMEOUT * 1000)) ]; do
        if [ "$(probe "$service" "$port")" = "200" ]; then
            startup=$(( $(now_ms) - start ))
            break
        fi
        sleep 0.02
    done

    idle=""
    if [ -n "$startup" ]; then
        sleep "$IDLE_SECONDS"
        # "12.3MiB / 31.3GiB" -> MB
        idle=$(docker stats --no-stream --format '{{.MemUsage}}' "$cid" 2>/dev/null | awk '{
            v = $1; n = v + 0;
            if (v ~ /GiB/) n *= 1024; else if (v ~ /KiB/) n /= 1024; else if (v ~ /^[0-9.]+B/) n /= 1048576;
            printf "%.1f", n }')
    fi
    echo "${service},${image},${image_mb},${startup},${idle}" >> "$OUT"
    echo "  ${service}: image ${image_mb} MB, first answer after ${startup:-?} ms, idle ${idle:-?} MB"
done
