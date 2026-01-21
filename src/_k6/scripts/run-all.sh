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
    echo "*** Using LOCAL profile (quick validation)"
fi

# =============================================================================
# Test execution setup
# =============================================================================
STAMP=$(date +"%Y%m%d%H%M")

mkdir -p /results
mkdir -p /results/$STAMP

echo "*** Starting unified benchmark suite"
echo "*** Output will be saved in /results/$STAMP"
echo "*** Profile: $PROFILE"
echo "*** Scenario: $SCENARIO"

# Service definitions: tag port
read -r -d '' SERVICES << 'EOF'
django-app-v6.0.1 8000
fastapi-app-v0.128.0 8001
fastify-app-v5.7.1 3101
bun-app-v1.3.3 3104
go-app-v1.25 5200
java24-spring-boot-v4.0.1 5400
rust-app-v1.91.1 5300
swoole-php-app-v6.0 3103
postgrest-v14.3 3000
net9-minapi-ef-jit 5002
net10-minapi-ef-jit 5003
net10-minapi-dapper-jit 5004
npgsqlrest-aot-v3.4.7 5005
npgsqlrest-jit-v3.4.7 5006
EOF

# =============================================================================
# Helper functions
# =============================================================================

run_test() {
    local script=$1
    local tag=$2
    local port=$3
    shift 3
    echo "*** Running $script for $tag:$port"
    k6 run /scripts/${script} -e STAMP=$STAMP -e TAG=$tag -e PORT=$port "$@"
    sleep $SLEEP_BETWEEN
}

# Warmup function - sends requests to trigger JIT compilation
# Results are NOT recorded (no STAMP passed)
warmup_service() {
    local tag=$1
    local port=$2
    echo "  Warming up $tag..."
    # Quick warmup: 10 VUs for 5 seconds, minimal endpoint
    k6 run --quiet /scripts/scenarios/minimal-baseline.js \
        -e TAG=$tag -e PORT=$port -e DURATION=5s -e TARGET=10 \
        --summary-trend-stats="avg" --no-summary 2>/dev/null || true
}

run_scenario_test() {
    local script=$1
    local tag=$2
    local port=$3
    shift 3
    echo "*** Running scenarios/$script for $tag:$port"
    k6 run /scripts/scenarios/${script} -e STAMP=$STAMP -e TAG=$tag -e PORT=$port "$@"
    sleep $SLEEP_BETWEEN
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
# WARMUP PHASE
# JIT-compiled frameworks (Java, .NET) need warmup before stable benchmarks.
# This phase triggers JIT compilation so it doesn't affect actual measurements.
# =============================================================================
if [ "$PROFILE" = "server" ]; then
    echo ""
    echo "############################################################"
    echo "# WARMUP PHASE: Triggering JIT compilation for all services"
    echo "############################################################"
    echo ""

    echo "$SERVICES" | while read -r tag port; do
        [ -z "$tag" ] && continue
        warmup_service "$tag" "$port"
    done

    echo ""
    echo "*** Warmup complete. Waiting ${SLEEP_BETWEEN}s before starting benchmarks..."
    sleep $SLEEP_BETWEEN
fi

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

# Clean up JSON files
rm /results/$STAMP/*.json 2>/dev/null

echo ""
echo "=========================================="
echo "Benchmark Complete"
echo "=========================================="
echo "*** Results saved to $OUTPUT_FILE"
echo "*** Detailed summaries in /results/$STAMP/"
