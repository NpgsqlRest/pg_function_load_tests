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

# Get list of service containers (exclude postgres and test)
get_service_containers() {
    docker-compose ps --format '{{.Name}}' | grep -v -E '(postgres|test)' | sort
}

# Start collecting stats for a specific container
start_stats_collector() {
    local container=$1
    local output_file=$2

    # Collect stats in background, output CSV format
    (
        echo "timestamp,cpu_percent,mem_usage_mb,mem_limit_mb,mem_percent" > "$output_file"
        while true; do
            stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" "$container" 2>/dev/null || echo "0%,0MiB / 0MiB,0%")
            timestamp=$(date +%s)

            # Parse memory (e.g., "123.4MiB / 1GiB" -> "123.4,1024")
            cpu=$(echo "$stats" | cut -d',' -f1 | tr -d '%')
            mem_raw=$(echo "$stats" | cut -d',' -f2)
            mem_pct=$(echo "$stats" | cut -d',' -f3 | tr -d '%')

            # Extract usage and limit
            mem_usage=$(echo "$mem_raw" | cut -d'/' -f1 | tr -d ' ')
            mem_limit=$(echo "$mem_raw" | cut -d'/' -f2 | tr -d ' ')

            # Convert to MB
            convert_to_mb() {
                local val=$1
                if echo "$val" | grep -q "GiB"; then
                    echo "$val" | tr -d 'GiB' | awk '{printf "%.2f", $1 * 1024}'
                elif echo "$val" | grep -q "MiB"; then
                    echo "$val" | tr -d 'MiB'
                elif echo "$val" | grep -q "KiB"; then
                    echo "$val" | tr -d 'KiB' | awk '{printf "%.2f", $1 / 1024}'
                else
                    echo "0"
                fi
            }

            usage_mb=$(convert_to_mb "$mem_usage")
            limit_mb=$(convert_to_mb "$mem_limit")

            echo "${timestamp},${cpu},${usage_mb},${limit_mb},${mem_pct}" >> "$output_file"
            sleep "$STATS_INTERVAL"
        done
    ) &
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

# Calculate stats summary from CSV
summarize_stats() {
    local stats_file=$1

    if [ ! -f "$stats_file" ] || [ $(wc -l < "$stats_file") -lt 2 ]; then
        echo '{"peakMemMb":0,"avgMemMb":0,"avgCpu":0}'
        return
    fi

    # Skip header, calculate peak/avg memory and avg CPU
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

# Start stats collectors for all services
echo -e "${YELLOW}Starting resource monitors...${NC}"
declare -A STATS_PIDS

CONTAINERS=$(get_service_containers)
echo "Found containers: $(echo $CONTAINERS | wc -w)"

for container in $CONTAINERS; do
    # Extract service name from container name (e.g., "src-django-app-v6.0.1-1" -> "django-app-v6.0.1")
    service_name=$(echo "$container" | sed 's/^src-//' | sed 's/-[0-9]*$//')
    stats_file="${STATS_DIR}/${service_name}_stats.csv"

    echo "  Starting monitor for: $service_name..."
    pid=$(start_stats_collector "$container" "$stats_file")
    STATS_PIDS["$service_name"]=$pid
    echo "  Monitoring: $service_name (PID: $pid)"
done

echo ""
echo -e "${GREEN}Starting k6 benchmarks...${NC}"
echo ""

# Run the actual benchmarks
docker-compose exec -e PROFILE="$PROFILE" -e SCENARIO="$SCENARIO" -e STAMP="$STAMP" test /bin/sh -c '
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

Memory and CPU usage captured during benchmark execution.

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
EOF

for stats_file in "${STATS_DIR}"/*_stats.csv; do
    [ -f "$stats_file" ] || continue

    service_name=$(basename "$stats_file" _stats.csv)
    summary=$(summarize_stats "$stats_file")

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
    summary=$(summarize_stats "$stats_file")

    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$RESOURCE_JSON"
    fi
    echo "  \"$service_name\": $summary" >> "$RESOURCE_JSON"
done
echo "" >> "$RESOURCE_JSON"
echo "}" >> "$RESOURCE_JSON"

echo ""
echo -e "${GREEN}=== Benchmark Complete ===${NC}"
echo "Results: $RESULTS_DIR"
echo "  - Benchmark results: ${STAMP}_all.md"
echo "  - Resource usage: resource_usage.md"
echo "  - Raw stats: stats/*.csv"
