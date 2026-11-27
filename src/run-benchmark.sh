#!/bin/bash

# =============================================================================
# BENCHMARK RUNNER WITH RESOURCE MONITORING
# Runs benchmarks while collecting Docker container stats
# =============================================================================

set -e

PROFILE=${PROFILE:-"local"}
SCENARIO=${SCENARIO:-"all"}
STATS_INTERVAL=${STATS_INTERVAL:-"1"}  # Sample every 1 second

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== PostgreSQL REST API Benchmark ===${NC}"
echo "Profile: $PROFILE"
echo "Scenario: $SCENARIO"
echo ""

# Create timestamp for this run
STAMP=$(date +"%Y%m%d%H%M")
RESULTS_DIR="_k6/results/${STAMP}"
STATS_DIR="${RESULTS_DIR}/stats"

mkdir -p "$RESULTS_DIR"
mkdir -p "$STATS_DIR"
chmod -R 777 "$RESULTS_DIR"

echo "Results directory: $RESULTS_DIR"
echo ""

# Get list of service containers (exclude postgres and the k6 test container).
# Exact-match the container names: a substring filter would also drop postgrest
# ("postgres" is a prefix of "postgrest"), silently losing its resource stats.
get_service_containers() {
    docker-compose ps --format '{{.Name}}' | grep -v -E '^src-(postgres|test)-1$' | sort
}

# What the run ran on: written once, next to the raw stats, so a report can say exactly which versions and which
# machine produced the numbers. (Not in the results dir itself: run-all.sh merges and removes *.json there.)
write_environment() {
    local out="$1"
    local cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^ //')
    # (ARM Linux has no "model name" line and no sysctl key: the model stays empty, and "set -e" must not end the run)
    [ -z "$cpu_model" ] && cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
    local mem_kb=$(grep -m1 MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    {
        echo "{"
        echo "  \"stamp\": \"${STAMP}\","
        echo "  \"startedUtc\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"profile\": \"${PROFILE}\","
        echo "  \"scenario\": \"${SCENARIO}\","
        echo "  \"gitCommit\": \"$(git rev-parse HEAD 2>/dev/null)\","
        echo "  \"gitDirty\": $([ -n "$(git status --porcelain -- . ':!_k6/results' 2>/dev/null)" ] && echo true || echo false),"
        echo "  \"host\": {"
        echo "    \"kernel\": \"$(uname -srm)\","
        echo "    \"os\": \"$( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || sw_vers -productVersion 2>/dev/null)\","
        echo "    \"cpuModel\": \"${cpu_model}\","
        echo "    \"cpus\": $(nproc 2>/dev/null || sysctl -n hw.ncpu),"
        echo "    \"memoryMb\": $(( ${mem_kb:-0} / 1024 )),"
        echo "    \"docker\": \"$(docker version --format '{{.Server.Version}}' 2>/dev/null)\","
        echo "    \"compose\": \"$(docker-compose version --short 2>/dev/null)\""
        echo "  },"
        echo "  \"postgres\": \"$(docker-compose exec -T postgres psql -U testuser -d testdb -Atc 'show server_version' 2>/dev/null | tr -d '\r')\","
        echo "  \"k6\": \"$(docker-compose exec -T test k6 version 2>/dev/null | head -1 | tr -d '\r')\","
        echo "  \"containers\": ["
        local first=true
        for cid in $(docker-compose ps -q); do
            local line=$(docker inspect --format '{"service":"{{index .Config.Labels "com.docker.compose.service"}}","image":"{{.Config.Image}}","imageId":"{{.Image}}","cpuset":"{{.HostConfig.CpusetCpus}}"}' "$cid" 2>/dev/null)
            [ -z "$line" ] && continue
            if [ "$first" = true ]; then first=false; else echo ","; fi
            printf '    %s' "$line"
        done
        echo ""
        echo "  ]"
        echo "}"
    } > "$out"
}

# Start collecting stats for a specific container
start_stats_collector() {
    local container=$1
    local output_file=$2

    # Write header
    echo "timestamp,cpu_percent,mem_usage_mb,mem_limit_mb,mem_percent" > "$output_file"

    # Start background collector - use nohup to ensure it runs independently
    nohup bash -c '
        container="$1"
        output_file="$2"
        interval="$3"

        while true; do
            stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" "$container" 2>/dev/null || echo "0%,0MiB / 0MiB,0%")
            timestamp=$(date +%s)

            cpu=$(echo "$stats" | cut -d"," -f1 | tr -d "%")
            mem_raw=$(echo "$stats" | cut -d"," -f2)
            mem_pct=$(echo "$stats" | cut -d"," -f3 | tr -d "%")

            mem_usage=$(echo "$mem_raw" | cut -d"/" -f1 | tr -d " ")
            mem_limit=$(echo "$mem_raw" | cut -d"/" -f2 | tr -d " ")

            # Convert to MB
            convert_to_mb() {
                local val=$1
                if echo "$val" | grep -q "GiB"; then
                    echo "$val" | tr -d "GiB" | awk "{printf \"%.2f\", \$1 * 1024}"
                elif echo "$val" | grep -q "MiB"; then
                    echo "$val" | tr -d "MiB"
                elif echo "$val" | grep -q "KiB"; then
                    echo "$val" | tr -d "KiB" | awk "{printf \"%.2f\", \$1 / 1024}"
                else
                    echo "0"
                fi
            }

            usage_mb=$(convert_to_mb "$mem_usage")
            limit_mb=$(convert_to_mb "$mem_limit")

            echo "${timestamp},${cpu},${usage_mb},${limit_mb},${mem_pct}" >> "$output_file"
            sleep "$interval"
        done
    ' _ "$container" "$output_file" "$STATS_INTERVAL" > /dev/null 2>&1 &

    echo $!
}

# Stop stats collector
stop_stats_collector() {
    local pid=$1
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
}

# Calculate stats summary from CSV.
# When a test_log.csv exists (written by run-all.sh), avg/peak CPU and memory are
# computed ONLY over the windows when that service was actually under test —
# otherwise the averages would include days of idle time and be meaningless.
summarize_stats() {
    local stats_file=$1
    local service_name=$2

    if [ ! -f "$stats_file" ] || [ $(wc -l < "$stats_file") -lt 2 ]; then
        echo '{"peakMemMb":0,"avgMemMb":0,"avgCpu":0}'
        return
    fi

    local windows_file=""
    local test_log="${RESULTS_DIR}/test_log.csv"
    if [ -n "$service_name" ] && [ -f "$test_log" ]; then
        windows_file=$(mktemp)
        # test_log.csv: start_epoch,end_epoch,tag,script,exit_code
        awk -F',' -v tag="$service_name" '$3 == tag { print $1, $2 }' "$test_log" > "$windows_file"
    fi

    if [ -n "$windows_file" ] && [ -s "$windows_file" ]; then
        # Only samples inside this service's test windows
        awk -F'[ ,]' '
        NR == FNR { ws[++n] = $1; we[n] = $2; next }
        FNR == 1 { next }
        {
            for (i = 1; i <= n; i++) {
                if ($1 >= ws[i] && $1 <= we[i]) {
                    if ($3 > max_mem) max_mem = $3
                    sum_mem += $3; sum_cpu += $2; count++
                    break
                }
            }
        }
        END {
            if (count > 0) {
                printf "{\"peakMemMb\":%.2f,\"avgMemMb\":%.2f,\"avgCpu\":%.2f}", max_mem, sum_mem/count, sum_cpu/count
            } else {
                print "{\"peakMemMb\":0,\"avgMemMb\":0,\"avgCpu\":0}"
            }
        }' "$windows_file" "$stats_file"
        rm -f "$windows_file"
        return
    fi
    [ -n "$windows_file" ] && rm -f "$windows_file"

    # Fallback: whole-run stats (no test log available)
    tail -n +2 "$stats_file" | awk -F',' '
    BEGIN { max_mem=0; sum_mem=0; sum_cpu=0; count=0 }
    {
        if ($3 > max_mem) max_mem = $3
        sum_mem += $3
        sum_cpu += $2
        count++
    }
    END {
        if (count > 0) {
            printf "{\"peakMemMb\":%.2f,\"avgMemMb\":%.2f,\"avgCpu\":%.2f}", max_mem, sum_mem/count, sum_cpu/count
        } else {
            print "{\"peakMemMb\":0,\"avgMemMb\":0,\"avgCpu\":0}"
        }
    }'
}

mkdir -p "${STATS_DIR}"

# Image size, time to the first answer and idle memory of every service (measure-services.sh). It restarts
# each service once, so it runs before the tests; every test has its own warmup afterwards.
if [ "${MEASURE_SERVICES:-true}" = "true" ]; then
    echo -e "${YELLOW}Measuring service footprint (image size, startup, idle memory)...${NC}"
    "$(dirname "$0")/measure-services.sh" "${STATS_DIR}/services.csv" "${ONLY:-}" || echo "  footprint measurement failed (the run continues)"
    echo ""
fi

# Start stats collectors for all services
echo -e "${YELLOW}Starting resource monitors...${NC}"
declare -A STATS_PIDS

CONTAINERS=$(get_service_containers)
echo "Found containers: $(echo $CONTAINERS | wc -w)"
mkdir -p "${STATS_DIR}/infra"

# One collector for everything, reading the containers' cgroup files (see collect-stats.sh): a sample per
# second without a docker call per sample. PostgreSQL and the load generator are measured too (stats/infra/):
# they are not services under test and are kept out of the resource summary; the report uses them to say,
# per test, whether the service, the database or the load generator was the one at its limit.
COLLECT_ARGS=()
for container in $CONTAINERS; do
    # Extract service name from container name (e.g., "src-django-app-v6.1.3-1" -> "django-app-v6.1.3")
    service_name=$(echo "$container" | sed 's/^src-//' | sed 's/-[0-9]*$//')
    COLLECT_ARGS+=("${service_name}=${container}" "${STATS_DIR}/${service_name}_stats.csv")
done
COLLECT_ARGS+=("postgres=src-postgres-1" "${STATS_DIR}/infra/postgres_stats.csv")
COLLECT_ARGS+=("k6=src-test-1" "${STATS_DIR}/infra/k6_stats.csv")

nohup "$(dirname "$0")/collect-stats.sh" "$STATS_INTERVAL" "${COLLECT_ARGS[@]}" > "${STATS_DIR}/collector.log" 2>&1 &
COLLECTOR_PID=$!
sleep 2
if kill -0 "$COLLECTOR_PID" 2>/dev/null; then
    STATS_PIDS["collector"]=$COLLECTOR_PID
    echo "  Monitoring $(( ${#COLLECT_ARGS[@]} / 2 )) containers through their cgroup files (PID: $COLLECTOR_PID)"
else
    # No cgroup v2 files where docker puts them (macOS, cgroup v1 ...): the old way, one docker stats loop each.
    echo "  cgroup files not available ($(tail -1 "${STATS_DIR}/collector.log" 2>/dev/null)); using docker stats"
    for ((i = 0; i < ${#COLLECT_ARGS[@]}; i += 2)); do
        name="${COLLECT_ARGS[$i]%%=*}"
        container="${COLLECT_ARGS[$i]#*=}"
        pid=$(start_stats_collector "$container" "${COLLECT_ARGS[$((i + 1))]}")
        STATS_PIDS["$name"]=$pid
        echo "  Monitoring: $name (PID: $pid)"
    done
fi

write_environment "${STATS_DIR}/environment.json"
echo "  Environment: ${STATS_DIR}/environment.json"

echo ""
echo -e "${GREEN}Starting k6 benchmarks...${NC}"
echo ""

# Run the actual benchmarks
docker-compose exec -e PROFILE="$PROFILE" -e SCENARIO="$SCENARIO" -e STAMP="$STAMP" \
    -e SHUFFLE="${SHUFFLE:-false}" -e PAUSE_IDLE="${PAUSE_IDLE:-true}" -e TARGET_HOST="${TARGET_HOST:-}" \
    -e ONLY="${ONLY:-}" -e RERUN_LIST="${RERUN_LIST:-}" test /bin/sh -c '
    # Override STAMP from environment
    export STAMP=${STAMP}
    /scripts/run-all.sh
'

echo ""
echo -e "${YELLOW}Stopping resource monitors...${NC}"

# Stop all stats collectors
for service_name in "${!STATS_PIDS[@]}"; do
    stop_stats_collector "${STATS_PIDS[$service_name]}"
done

echo ""
echo -e "${GREEN}Generating resource usage summary...${NC}"

# Create resource summary file
RESOURCE_SUMMARY="${RESULTS_DIR}/resource_usage.md"

cat > "$RESOURCE_SUMMARY" << 'EOF'
# Resource Usage Summary

Memory and CPU usage per service, measured ONLY during that service's test windows
(idle periods are excluded via test_log.csv).

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
EOF

for stats_file in "${STATS_DIR}"/*_stats.csv; do
    [ -f "$stats_file" ] || continue

    service_name=$(basename "$stats_file" _stats.csv)
    summary=$(summarize_stats "$stats_file" "$service_name")

    peak_mem=$(echo "$summary" | grep -o '"peakMemMb":[0-9.]*' | cut -d':' -f2)
    avg_mem=$(echo "$summary" | grep -o '"avgMemMb":[0-9.]*' | cut -d':' -f2)
    avg_cpu=$(echo "$summary" | grep -o '"avgCpu":[0-9.]*' | cut -d':' -f2)

    echo "| $service_name | $peak_mem | $avg_mem | $avg_cpu |" >> "$RESOURCE_SUMMARY"
done

# Also create JSON summary for potential programmatic use
RESOURCE_JSON="${RESULTS_DIR}/resource_usage.json"
echo "{" > "$RESOURCE_JSON"
first=true
for stats_file in "${STATS_DIR}"/*_stats.csv; do
    [ -f "$stats_file" ] || continue

    service_name=$(basename "$stats_file" _stats.csv)
    summary=$(summarize_stats "$stats_file" "$service_name")

    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$RESOURCE_JSON"
    fi
    echo "  \"$service_name\": $summary" >> "$RESOURCE_JSON"
done
echo "" >> "$RESOURCE_JSON"
echo "}" >> "$RESOURCE_JSON"

# Generate the analysis report (pivot tables, scaling, cross-scenario summary)
# from the merged dataset. Re-runnable at any time:
#   python3 generate-report.py _k6/results/<stamp>
if command -v python3 > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}Generating analysis report...${NC}"
    python3 "$(dirname "$0")/generate-report.py" "$RESULTS_DIR" || echo "report generation failed (rerun manually)"
fi

echo ""
echo -e "${GREEN}=== Benchmark Complete ===${NC}"
echo "Results: $RESULTS_DIR"
echo "  - Benchmark results: ${STAMP}_all.md"
echo "  - Analysis report: report.md"
echo "  - Raw dataset: results.json / results.csv"
echo "  - Resource usage: resource_usage.md (per test: results_extended.csv)"
echo "  - Environment: stats/environment.json, service footprint: stats/services.csv"
echo "  - Complete k6 summaries: k6/*.json"
echo "  - Raw stats: stats/*.csv"
