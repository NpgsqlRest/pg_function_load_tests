#!/bin/sh

# =============================================================================
# UNIFIED BENCHMARK RUNNER
# Runs all benchmark scenarios: perf_test + new scenarios
# =============================================================================

# PROFILE: Choose "server", "local", or "minimal"
# - server: Realistic tests for Hetzner CCX33 (8 vCPU, 32GB RAM)
# - local: Quick tests for local development/validation
# - minimal: Ultra-fast tests for markdown generation validation only
PROFILE=${PROFILE:-"local"}

# SCENARIO: Choose which scenarios to run
# - all: Run everything (default)
# - perf-test: Original comprehensive data type serialization test
# - minimal: Minimal baseline (pure routing overhead)
# - post: POST body parsing test
# - nested: Nested JSON serialization test
# - large: Large payload streaming test
# - params: Many query parameters test
SCENARIO=${SCENARIO:-"all"}

# =============================================================================
# SERVER PROFILE (Hetzner CCX33: 8 dedicated vCPUs, 32 GB RAM, 240 GB SSD)
# Designed for comprehensive benchmarking with realistic load
#
# IMPORTANT: Tests are serialized - only ONE test runs at a time.
# Sleep between tests allows:
#   - TCP connections to fully close (TIME_WAIT ~30s with tcp_tw_reuse)
#   - Connection pools to stabilize
#   - CPU/memory to return to baseline
#   - JIT frameworks to cool down between tests
# =============================================================================

# perf_test scenario (original) - comprehensive data type serialization
SERVER_PERFTEST_RECORDS="1 10 100 500"
SERVER_PERFTEST_VUS="1 50 100 200"        # Added 200 VUs for stress testing
SERVER_PERFTEST_DURATION="60s"

# minimal baseline scenario - measures pure routing overhead
SERVER_MINIMAL_VUS="100 200 500"          # Higher VUs since minimal work per request
SERVER_MINIMAL_DURATION="30s"

# POST body scenario - tests JSON request parsing
SERVER_POST_RECORDS="10 100"
SERVER_POST_VUS="50 100 200"
SERVER_POST_DURATION="60s"

# nested JSON scenario - tests serialization of complex objects
SERVER_NESTED_RECORDS="100"
SERVER_NESTED_DEPTHS="1 2 3"
SERVER_NESTED_VUS="50 100"
SERVER_NESTED_DURATION="60s"

# large payload scenario - tests response streaming/buffering
# Lower VUs since each response is large (100KB-500KB)
SERVER_LARGE_SIZES="100 500"
SERVER_LARGE_VUS="25 50"
SERVER_LARGE_DURATION="60s"

# many params scenario - tests query string parsing overhead
SERVER_PARAMS_VUS="50 100 200"
SERVER_PARAMS_DURATION="60s"

# Sleep between tests (in seconds)
# 30s allows TCP TIME_WAIT to clear and services to stabilize
# This ensures each test starts from a clean baseline state
SERVER_SLEEP="30"

# Ramp-up stage before the measured hold (k6 stages: ramp to target, then hold)
SERVER_RAMP="10s"
# Untimed warmup run before every measured test (JIT compilation, connection pools,
# PG plan cache for the exact endpoint under test). 0 = skip.
SERVER_WARMUP="10s"

# =============================================================================
# LOCAL PROFILE (for quick validation and development)
# Designed to complete quickly while still testing basic functionality
# =============================================================================

# perf_test scenario (original)
LOCAL_PERFTEST_RECORDS="10 100"
LOCAL_PERFTEST_VUS="10 50"
LOCAL_PERFTEST_DURATION="15s"

# minimal baseline scenario
LOCAL_MINIMAL_VUS="50 100"
LOCAL_MINIMAL_DURATION="10s"

# POST body scenario
LOCAL_POST_RECORDS="10"
LOCAL_POST_VUS="25 50"
LOCAL_POST_DURATION="15s"

# nested JSON scenario
LOCAL_NESTED_RECORDS="50"
LOCAL_NESTED_DEPTHS="1 3"
LOCAL_NESTED_VUS="25 50"
LOCAL_NESTED_DURATION="15s"

# large payload scenario
LOCAL_LARGE_SIZES="100"
LOCAL_LARGE_VUS="25"
LOCAL_LARGE_DURATION="15s"

# many params scenario
LOCAL_PARAMS_VUS="25 50"
LOCAL_PARAMS_DURATION="15s"

# common settings
LOCAL_SLEEP="2"
LOCAL_RAMP="3s"
LOCAL_WARMUP="2s"

# =============================================================================
# MINIMAL PROFILE (for markdown generation testing only)
# Ultra-fast: just enough to generate valid output files
# Use this to verify markdown formatting before deploying to server
# =============================================================================

# perf_test scenario - single quick test
MINIMAL_PERFTEST_RECORDS="10"
MINIMAL_PERFTEST_VUS="5"
MINIMAL_PERFTEST_DURATION="3s"

# minimal baseline scenario
MINIMAL_MINIMAL_VUS="5"
MINIMAL_MINIMAL_DURATION="3s"

# POST body scenario
MINIMAL_POST_RECORDS="10"
MINIMAL_POST_VUS="5"
MINIMAL_POST_DURATION="3s"

# nested JSON scenario
MINIMAL_NESTED_RECORDS="10"
MINIMAL_NESTED_DEPTHS="2"
MINIMAL_NESTED_VUS="5"
MINIMAL_NESTED_DURATION="3s"

# large payload scenario
MINIMAL_LARGE_SIZES="100"
MINIMAL_LARGE_VUS="5"
MINIMAL_LARGE_DURATION="3s"

# many params scenario
MINIMAL_PARAMS_VUS="5"
MINIMAL_PARAMS_DURATION="3s"

# common settings - no sleep needed for minimal
MINIMAL_SLEEP="1"
MINIMAL_RAMP="1s"
MINIMAL_WARMUP="0"

# =============================================================================
# Apply profile settings
# =============================================================================
if [ "$PROFILE" = "server" ]; then
    PERFTEST_RECORDS="$SERVER_PERFTEST_RECORDS"
    PERFTEST_VUS="$SERVER_PERFTEST_VUS"
    PERFTEST_DURATION="$SERVER_PERFTEST_DURATION"
    MINIMAL_VUS="$SERVER_MINIMAL_VUS"
    MINIMAL_DURATION="$SERVER_MINIMAL_DURATION"
    POST_RECORDS="$SERVER_POST_RECORDS"
    POST_VUS="$SERVER_POST_VUS"
    POST_DURATION="$SERVER_POST_DURATION"
    NESTED_RECORDS="$SERVER_NESTED_RECORDS"
    NESTED_DEPTHS="$SERVER_NESTED_DEPTHS"
    NESTED_VUS="$SERVER_NESTED_VUS"
    NESTED_DURATION="$SERVER_NESTED_DURATION"
    LARGE_SIZES="$SERVER_LARGE_SIZES"
    LARGE_VUS="$SERVER_LARGE_VUS"
    LARGE_DURATION="$SERVER_LARGE_DURATION"
    PARAMS_VUS="$SERVER_PARAMS_VUS"
    PARAMS_DURATION="$SERVER_PARAMS_DURATION"
    SLEEP_BETWEEN="$SERVER_SLEEP"
    RAMP="$SERVER_RAMP"
    WARMUP="$SERVER_WARMUP"
    echo "*** Using SERVER profile (Hetzner CCX33)"
elif [ "$PROFILE" = "minimal" ]; then
    PERFTEST_RECORDS="$MINIMAL_PERFTEST_RECORDS"
    PERFTEST_VUS="$MINIMAL_PERFTEST_VUS"
    PERFTEST_DURATION="$MINIMAL_PERFTEST_DURATION"
    MINIMAL_VUS="$MINIMAL_MINIMAL_VUS"
    MINIMAL_DURATION="$MINIMAL_MINIMAL_DURATION"
    POST_RECORDS="$MINIMAL_POST_RECORDS"
    POST_VUS="$MINIMAL_POST_VUS"
    POST_DURATION="$MINIMAL_POST_DURATION"
    NESTED_RECORDS="$MINIMAL_NESTED_RECORDS"
    NESTED_DEPTHS="$MINIMAL_NESTED_DEPTHS"
    NESTED_VUS="$MINIMAL_NESTED_VUS"
    NESTED_DURATION="$MINIMAL_NESTED_DURATION"
    LARGE_SIZES="$MINIMAL_LARGE_SIZES"
    LARGE_VUS="$MINIMAL_LARGE_VUS"
    LARGE_DURATION="$MINIMAL_LARGE_DURATION"
    PARAMS_VUS="$MINIMAL_PARAMS_VUS"
    PARAMS_DURATION="$MINIMAL_PARAMS_DURATION"
    SLEEP_BETWEEN="$MINIMAL_SLEEP"
    RAMP="$MINIMAL_RAMP"
    WARMUP="$MINIMAL_WARMUP"
    echo "*** Using MINIMAL profile (markdown validation only)"
else
    PERFTEST_RECORDS="$LOCAL_PERFTEST_RECORDS"
    PERFTEST_VUS="$LOCAL_PERFTEST_VUS"
    PERFTEST_DURATION="$LOCAL_PERFTEST_DURATION"
    MINIMAL_VUS="$LOCAL_MINIMAL_VUS"
    MINIMAL_DURATION="$LOCAL_MINIMAL_DURATION"
    POST_RECORDS="$LOCAL_POST_RECORDS"
    POST_VUS="$LOCAL_POST_VUS"
    POST_DURATION="$LOCAL_POST_DURATION"
    NESTED_RECORDS="$LOCAL_NESTED_RECORDS"
    NESTED_DEPTHS="$LOCAL_NESTED_DEPTHS"
    NESTED_VUS="$LOCAL_NESTED_VUS"
    NESTED_DURATION="$LOCAL_NESTED_DURATION"
    LARGE_SIZES="$LOCAL_LARGE_SIZES"
    LARGE_VUS="$LOCAL_LARGE_VUS"
    LARGE_DURATION="$LOCAL_LARGE_DURATION"
    PARAMS_VUS="$LOCAL_PARAMS_VUS"
    PARAMS_DURATION="$LOCAL_PARAMS_DURATION"
    SLEEP_BETWEEN="$LOCAL_SLEEP"
    RAMP="$LOCAL_RAMP"
    WARMUP="$LOCAL_WARMUP"
    echo "*** Using LOCAL profile (quick validation)"
fi

# =============================================================================
# Test execution setup
# =============================================================================
# Respect a STAMP passed from the host (run-benchmark.sh) so the host results
# dir and the container results dir are guaranteed to match; generate otherwise.
STAMP=${STAMP:-$(date +"%Y%m%d%H%M")}

mkdir -p /results
mkdir -p /results/$STAMP
echo "start_epoch,end_epoch,tag,script,exit_code" > /results/$STAMP/test_log.csv

echo "*** Starting unified benchmark suite"
echo "*** Output will be saved in /results/$STAMP"
echo "*** Profile: $PROFILE"
echo "*** Scenario: $SCENARIO"

# Service definitions: tag port
read -r -d '' SERVICES << 'EOF'
django-app-v6.0.7 8000
fastapi-app-v0.139.0 8001
fastify-app-v5.10.0 3101
bun-app-v1.3.14 3104
go-app-v1.26 5200
java25-spring-boot-v4.1.0 5400
rust-app-v1.97.0 5300
swoole-php-app-v6.2.1 3103
express-app-v5.2.1 3102
deno-app-v2.9.2 3105
axum-app-v0.8.9 5301
postgrest-v14.14 3000
net10-minapi-ef-jit 5003
net10-minapi-dapper-jit 5004
npgsqlrest-routine-aot-v3.4.7 5005
npgsqlrest-routine-jit-v3.4.7 5006
npgsqlrest-routine-aot-v3.21.0 5007
npgsqlrest-routine-jit-v3.21.0 5008
npgsqlrest-file-aot-v3.21.0 5009
npgsqlrest-file-jit-v3.21.0 5010
EOF

# =============================================================================
# Helper functions
# =============================================================================

# Optional remote target host (two-server topology): when TARGET_HOST is set,
# k6 connects to TARGET_HOST:port instead of the docker service name.
TARGET_HOST=${TARGET_HOST:-""}

# Pause idle services during each test (removes idle JVM/CLR/pool background noise
# while preserving JIT-warmed state). Requires the docker CLI and the docker socket
# mounted into this container; silently disabled otherwise.
PAUSE_IDLE=${PAUSE_IDLE:-"true"}
DOCKER_OK="false"
if [ "$PAUSE_IDLE" = "true" ] && command -v docker > /dev/null 2>&1 && docker ps > /dev/null 2>&1; then
    DOCKER_OK="true"
    echo "*** PAUSE_IDLE enabled: idle services will be paused during tests"
else
    echo "*** PAUSE_IDLE disabled (no docker CLI/socket or PAUSE_IDLE=false)"
fi

service_container() {
    docker ps -aq --filter "label=com.docker.compose.service=$1" | head -n 1
}

# Pause every service except the active one; unpause the active one.
# postgres and the test container are never touched (not in SERVICES).
ensure_only_active() {
    [ "$DOCKER_OK" = "true" ] || return 0
    local active=$1
    echo "$SERVICES" | while read -r tag port; do
        [ -z "$tag" ] && continue
        local cid=$(service_container "$tag")
        [ -z "$cid" ] && continue
        if [ "$tag" = "$active" ]; then
            docker unpause "$cid" > /dev/null 2>&1 || true
        else
            docker pause "$cid" > /dev/null 2>&1 || true
        fi
    done
}

unpause_all() {
    [ "$DOCKER_OK" = "true" ] || return 0
    echo "$SERVICES" | while read -r tag port; do
        [ -z "$tag" ] && continue
        local cid=$(service_container "$tag")
        [ -z "$cid" ] && continue
        docker unpause "$cid" > /dev/null 2>&1 || true
    done
}
trap unpause_all EXIT

# Per-test test log: start/end epochs let resource stats be windowed to the
# exact period each service was under load; exit code records threshold aborts.
TEST_LOG="/results/$STAMP/test_log.csv"

# Warmup + measured run. The warmup run uses the SAME script and parameters
# (so JIT compiles the exact code path and PG caches the exact plan) but no
# STAMP -> the script writes no output files.
run_k6() {
    local script_path=$1
    local script_name=$2
    local tag=$3
    local port=$4
    shift 4

    ensure_only_active "$tag"

    local host_args=""
    [ -n "$TARGET_HOST" ] && host_args="-e TARGET_HOST=$TARGET_HOST"

    if [ "$WARMUP" != "0" ]; then
        echo "  warmup ($WARMUP)..."
        k6 run "$script_path" -e TAG=$tag -e PORT=$port $host_args \
            -e DURATION=$WARMUP -e RAMP=2s "$@" > /dev/null 2>&1 || true
        sleep 2
    fi

    echo "*** Running $script_name for $tag:$port"
    local start=$(date +%s)
    k6 run "$script_path" -e STAMP=$STAMP -e TAG=$tag -e PORT=$port $host_args \
        -e RAMP=$RAMP "$@"
    local code=$?
    local end=$(date +%s)
    echo "$start,$end,$tag,$script_name,$code" >> "$TEST_LOG"
    if [ $code -ne 0 ]; then
        echo "!!! $tag $script_name exited with code $code (threshold abort or error)"
    fi
    sleep $SLEEP_BETWEEN
}

run_test() {
    local script=$1
    local tag=$2
    local port=$3
    shift 3
    run_k6 "/scripts/${script}" "$script" "$tag" "$port" "$@"
}

run_scenario_test() {
    local script=$1
    local tag=$2
    local port=$3
    shift 3
    run_k6 "/scripts/scenarios/${script}" "scenarios/$script" "$tag" "$port" "$@"
}

run_for_all_services() {
    local script_type=$1  # "main" or "scenario"
    local script=$2
    shift 2
    echo ""
    echo "=========================================="
    echo "Running: $script"
    echo "=========================================="

    echo "$SERVICES" | while read -r tag port; do
        [ -z "$tag" ] && continue
        if [ "$script_type" = "main" ]; then
            run_test "$script" "$tag" "$port" "$@"
        else
            run_scenario_test "$script" "$tag" "$port" "$@"
        fi
    done
}

# =============================================================================
# WARMUP
# Warmup now happens per test inside run_k6(): each measured run is preceded by
# an untimed run of the SAME script and parameters, so JIT compilation, connection
# pools, and PostgreSQL plan caches are warm for the exact code path being measured.
# (The old global warmup phase only exercised perf-minimal and silently crashed on
# a missing STAMP env - it never actually warmed anything.)
# =============================================================================

# =============================================================================
# SCENARIO 1: perf_test (Original comprehensive data type serialization)
# =============================================================================
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "perf-test" ]; then
    echo ""
    echo "############################################################"
    echo "# PERF_TEST: Comprehensive data type serialization"
    echo "############################################################"

    for records in $PERFTEST_RECORDS; do
        for target in $PERFTEST_VUS; do
            run_for_all_services "main" "script.js" \
                -e RECORDS=$records \
                -e DURATION=$PERFTEST_DURATION \
                -e TARGET=$target
        done
    done
fi

# =============================================================================
# SCENARIO 2: Minimal Baseline (pure routing overhead)
# =============================================================================
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "minimal" ]; then
    echo ""
    echo "############################################################"
    echo "# MINIMAL: Pure routing overhead baseline"
    echo "############################################################"

    for target in $MINIMAL_VUS; do
        run_for_all_services "scenario" "minimal-baseline.js" \
            -e DURATION=$MINIMAL_DURATION \
            -e TARGET=$target
    done
fi

# =============================================================================
# SCENARIO 3: POST Body (request body parsing)
# =============================================================================
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "post" ]; then
    echo ""
    echo "############################################################"
    echo "# POST: Request body parsing test"
    echo "############################################################"

    for records in $POST_RECORDS; do
        for target in $POST_VUS; do
            run_for_all_services "scenario" "post-body.js" \
                -e DURATION=$POST_DURATION \
                -e RECORDS=$records \
                -e TARGET=$target
        done
    done
fi

# =============================================================================
# SCENARIO 4: Nested JSON (complex serialization)
# =============================================================================
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "nested" ]; then
    echo ""
    echo "############################################################"
    echo "# NESTED: Complex JSON serialization test"
    echo "############################################################"

    for depth in $NESTED_DEPTHS; do
        for target in $NESTED_VUS; do
            run_for_all_services "scenario" "nested-json.js" \
                -e DURATION=$NESTED_DURATION \
                -e RECORDS=$NESTED_RECORDS \
                -e DEPTH=$depth \
                -e TARGET=$target
        done
    done
fi

# =============================================================================
# SCENARIO 5: Large Payload (streaming/buffering)
# =============================================================================
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "large" ]; then
    echo ""
    echo "############################################################"
    echo "# LARGE: Large payload streaming test"
    echo "############################################################"

    for size in $LARGE_SIZES; do
        for target in $LARGE_VUS; do
            run_for_all_services "scenario" "large-payload.js" \
                -e DURATION=$LARGE_DURATION \
                -e SIZE_KB=$size \
                -e TARGET=$target
        done
    done
fi

# =============================================================================
# SCENARIO 6: Many Parameters (query string parsing)
# =============================================================================
if [ "$SCENARIO" = "all" ] || [ "$SCENARIO" = "params" ]; then
    echo ""
    echo "############################################################"
    echo "# PARAMS: Query string parsing test"
    echo "############################################################"

    for target in $PARAMS_VUS; do
        run_for_all_services "scenario" "many-params.js" \
            -e DURATION=$PARAMS_DURATION \
            -e TARGET=$target
    done
fi

# =============================================================================
# Generate unified summary report
# =============================================================================
echo ""
echo "=========================================="
echo "Generating Unified Summary Report"
echo "=========================================="

OUTPUT_FILE="/results/${STAMP}_all.md"

# GitHub base URLs for links
GITHUB_BASE="https://github.com/NpgsqlRest/pg_function_load_tests"
GITHUB_BLOB="${GITHUB_BASE}/blob/${STAMP}"
GITHUB_TREE="${GITHUB_BASE}/tree/${STAMP}"

cat > "$OUTPUT_FILE" << 'HEADER'
# Benchmark Results

Results are grouped by concurrency level and payload size, sorted by requests per second (highest first).

HEADER

echo "**Profile:** $PROFILE" >> "$OUTPUT_FILE"
echo "**Timestamp:** $STAMP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# Helper function to process JSON files and generate markdown tables
# =============================================================================
generate_table() {
    local scenario=$1
    local group_by=$2  # e.g., "vus_records", "vus", "vus_sizeKb", etc.
    local title=$3

    echo "" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "## $title" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Find all JSON files for this scenario
    local json_files=$(find /results/$STAMP -name "*.json" -exec grep -l "\"scenario\":\"$scenario\"" {} \; 2>/dev/null)

    if [ -z "$json_files" ]; then
        echo "_No results for this scenario_" >> "$OUTPUT_FILE"
        return
    fi

    # Get unique groupings (e.g., vus+records combinations)
    case "$group_by" in
        "vus_records")
            # Group by VUs and Records for perf-test and post scenarios
            local groups=$(echo "$json_files" | xargs -I {} cat {} | jq -r '[.vus, .records] | @csv' | sort -t',' -k1,1n -k2,2n | uniq)
            for group in $groups; do
                local vus=$(echo "$group" | cut -d',' -f1)
                local records=$(echo "$group" | cut -d',' -f2)
                echo "" >> "$OUTPUT_FILE"
                echo "### ${vus} Virtual Users, ${records} Records" >> "$OUTPUT_FILE"
                echo "| Framework | Requests/s | Avg Latency | Total Requests | Summary | Source |" >> "$OUTPUT_FILE"
                echo "|-----------|----------:|------------:|---------------:|---------|--------|" >> "$OUTPUT_FILE"

                # Get results for this group, sorted by RPS descending
                echo "$json_files" | xargs -I {} cat {} | \
                    jq -r --argjson vus "$vus" --argjson records "$records" \
                    'select(.vus == $vus and .records == $records) | [.tag, .rps, .avgLatency, .requests, .summaryFile] | @tsv' | \
                    sort -t$'\t' -k2 -rn | \
                    while IFS=$'\t' read -r tag rps latency requests summaryFile; do
                        local rps_fmt=$(printf "%.2f" "$rps")
                        local latency_fmt=$(printf "%.2f" "$latency")
                        local requests_fmt=$(printf "%d" "$requests")
                        local summary_url="${GITHUB_BLOB}/src/_k6/results/${STAMP}/${summaryFile}"
                        local source_url="${GITHUB_TREE}/src/${tag}"
                        echo "| ${tag} | ${rps_fmt}/s | ${latency_fmt}ms | ${requests_fmt} | [summary](${summary_url}) | [source](${source_url}) |" >> "$OUTPUT_FILE"
                    done
            done
            ;;
        "vus")
            # Group by VUs only for minimal and params scenarios
            local groups=$(echo "$json_files" | xargs -I {} cat {} | jq -r '.vus' | sort -n | uniq)
            for vus in $groups; do
                echo "" >> "$OUTPUT_FILE"
                echo "### ${vus} Virtual Users" >> "$OUTPUT_FILE"
                echo "| Framework | Requests/s | Avg Latency | Total Requests | Summary | Source |" >> "$OUTPUT_FILE"
                echo "|-----------|----------:|------------:|---------------:|---------|--------|" >> "$OUTPUT_FILE"

                echo "$json_files" | xargs -I {} cat {} | \
                    jq -r --argjson vus "$vus" \
                    'select(.vus == $vus) | [.tag, .rps, .avgLatency, .requests, .summaryFile] | @tsv' | \
                    sort -t$'\t' -k2 -rn | \
                    while IFS=$'\t' read -r tag rps latency requests summaryFile; do
                        local rps_fmt=$(printf "%.2f" "$rps")
                        local latency_fmt=$(printf "%.2f" "$latency")
                        local requests_fmt=$(printf "%d" "$requests")
                        local summary_url="${GITHUB_BLOB}/src/_k6/results/${STAMP}/${summaryFile}"
                        local source_url="${GITHUB_TREE}/src/${tag}"
                        echo "| ${tag} | ${rps_fmt}/s | ${latency_fmt}ms | ${requests_fmt} | [summary](${summary_url}) | [source](${source_url}) |" >> "$OUTPUT_FILE"
                    done
            done
            ;;
        "vus_depth")
            # Group by VUs and Depth for nested JSON scenario
            local groups=$(echo "$json_files" | xargs -I {} cat {} | jq -r '[.vus, .depth] | @csv' | sort -t',' -k1,1n -k2,2n | uniq)
            for group in $groups; do
                local vus=$(echo "$group" | cut -d',' -f1)
                local depth=$(echo "$group" | cut -d',' -f2)
                echo "" >> "$OUTPUT_FILE"
                echo "### ${vus} Virtual Users, Depth ${depth}" >> "$OUTPUT_FILE"
                echo "| Framework | Requests/s | Avg Latency | Total Requests | Summary | Source |" >> "$OUTPUT_FILE"
                echo "|-----------|----------:|------------:|---------------:|---------|--------|" >> "$OUTPUT_FILE"

                echo "$json_files" | xargs -I {} cat {} | \
                    jq -r --argjson vus "$vus" --argjson depth "$depth" \
                    'select(.vus == $vus and .depth == $depth) | [.tag, .rps, .avgLatency, .requests, .summaryFile] | @tsv' | \
                    sort -t$'\t' -k2 -rn | \
                    while IFS=$'\t' read -r tag rps latency requests summaryFile; do
                        local rps_fmt=$(printf "%.2f" "$rps")
                        local latency_fmt=$(printf "%.2f" "$latency")
                        local requests_fmt=$(printf "%d" "$requests")
                        local summary_url="${GITHUB_BLOB}/src/_k6/results/${STAMP}/${summaryFile}"
                        local source_url="${GITHUB_TREE}/src/${tag}"
                        echo "| ${tag} | ${rps_fmt}/s | ${latency_fmt}ms | ${requests_fmt} | [summary](${summary_url}) | [source](${source_url}) |" >> "$OUTPUT_FILE"
                    done
            done
            ;;
        "vus_size")
            # Group by VUs and Size for large payload scenario
            local groups=$(echo "$json_files" | xargs -I {} cat {} | jq -r '[.vus, .sizeKb] | @csv' | sort -t',' -k1,1n -k2,2n | uniq)
            for group in $groups; do
                local vus=$(echo "$group" | cut -d',' -f1)
                local size=$(echo "$group" | cut -d',' -f2)
                echo "" >> "$OUTPUT_FILE"
                echo "### ${vus} Virtual Users, ${size}KB Payload" >> "$OUTPUT_FILE"
                echo "| Framework | Requests/s | Avg Latency | Total Requests | Data Received | Summary | Source |" >> "$OUTPUT_FILE"
                echo "|-----------|----------:|------------:|---------------:|--------------:|---------|--------|" >> "$OUTPUT_FILE"

                echo "$json_files" | xargs -I {} cat {} | \
                    jq -r --argjson vus "$vus" --argjson size "$size" \
                    'select(.vus == $vus and .sizeKb == $size) | [.tag, .rps, .avgLatency, .requests, .dataReceived, .summaryFile] | @tsv' | \
                    sort -t$'\t' -k2 -rn | \
                    while IFS=$'\t' read -r tag rps latency requests dataReceived summaryFile; do
                        local rps_fmt=$(printf "%.2f" "$rps")
                        local latency_fmt=$(printf "%.2f" "$latency")
                        local requests_fmt=$(printf "%d" "$requests")
                        local data_mb=$(echo "scale=2; $dataReceived / 1024 / 1024" | bc)
                        local summary_url="${GITHUB_BLOB}/src/_k6/results/${STAMP}/${summaryFile}"
                        local source_url="${GITHUB_TREE}/src/${tag}"
                        echo "| ${tag} | ${rps_fmt}/s | ${latency_fmt}ms | ${requests_fmt} | ${data_mb}MB | [summary](${summary_url}) | [source](${source_url}) |" >> "$OUTPUT_FILE"
                    done
            done
            ;;
    esac
}

# Generate tables for each scenario
generate_table "perf-test" "vus_records" "Data Type Serialization (perf_test)"
generate_table "minimal" "vus" "Minimal Baseline"
generate_table "post" "vus_records" "POST Body Parsing"
generate_table "nested" "vus_depth" "Nested JSON Serialization"
generate_table "large" "vus_size" "Large Payload"
generate_table "params" "vus" "Many Parameters (20 params)"

# =============================================================================
# Merge per-test JSON results into one machine-readable dataset.
# results.json + results.csv are the raw data every report view (and the blog
# analysis) is generated from - regenerate views any time without re-running.
# =============================================================================
jq -s "{
    meta: {
        stamp: \"$STAMP\",
        profile: \"$PROFILE\",
        scenario: \"$SCENARIO\",
        ramp: \"$RAMP\",
        warmup: \"$WARMUP\",
        sleepBetween: \"$SLEEP_BETWEEN\"
    },
    results: .
}" /results/$STAMP/*.json > /tmp/results.json 2>/dev/null

jq -rs '
    ["scenario","tag","vus","records","depth","sizeKb","duration","requests","rps",
     "latencyAvg","latencyMed","latencyP90","latencyP95","latencyP99","latencyMax",
     "dataReceivedBytes","dataSentBytes","failed"],
    (.[] | [.scenario, .tag, .vus, (.records // ""), (.depth // ""), (.sizeKb // ""),
            .duration, .requests, .rps,
            (.latency.avg // .avgLatency // ""), (.latency.med // ""), (.latency.p90 // ""),
            (.latency.p95 // ""), (.latency.p99 // ""), (.latency.max // ""),
            (.dataReceivedBytes // ""), (.dataSentBytes // ""), .failed])
    | @csv' /results/$STAMP/*.json > /tmp/results.csv 2>/dev/null

# Replace per-test JSON files with the merged dataset
rm /results/$STAMP/*.json 2>/dev/null
mv /tmp/results.json /results/$STAMP/results.json
mv /tmp/results.csv /results/$STAMP/results.csv

echo ""
echo "=========================================="
echo "Benchmark Complete"
echo "=========================================="
echo "*** Results saved to $OUTPUT_FILE"
echo "*** Detailed summaries in /results/$STAMP/"
