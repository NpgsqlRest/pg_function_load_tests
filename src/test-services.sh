#!/bin/bash

# PostgreSQL Function Load Test - Service Validation Script
# This script tests all services against all benchmark endpoints
#
# Usage: ./test-services.sh [HOST]
# Default HOST is localhost

HOST="${1:-localhost}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# URL-encoded test parameters
# Note: JSON values are URL-encoded: {"key":"value"} = %7B%22key%22%3A%22value%22%7D
# Note: Array literal {1,2,3} = %7B1,2,3%7D

# Base query params for services using PostgreSQL array literals
PARAMS_PG_ARRAYS="_records=1&_text=test&_int=42&_bigint=9223372036854770000&_numeric=123.456&_real=1.23&_double=1.23456789&_bool=true&_date=2024-01-15&_timestamp=2024-01-15T10:30:00&_timestamptz=2024-01-15T10:30:00Z&_uuid=a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11&_json=%7B%22key%22%3A%22value%22%7D&_jsonb=%7B%22key%22%3A%22value%22%7D&_int_array=%7B1,2,3%7D&_text_array=%7Ba,b,c%7D"

# Base query params for services using repeated query params for arrays (NpgsqlRest, .NET)
PARAMS_REPEATED_ARRAYS="_records=1&_text=test&_int=42&_bigint=9223372036854770000&_numeric=123.456&_real=1.23&_double=1.23456789&_bool=true&_date=2024-01-15&_timestamp=2024-01-15T10:30:00&_timestamptz=2024-01-15T10:30:00Z&_uuid=a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11&_json=%7B%22key%22%3A%22value%22%7D&_jsonb=%7B%22key%22%3A%22value%22%7D&_int_array=1&_int_array=2&_int_array=3&_text_array=a&_text_array=b&_text_array=c"

# Additional endpoint params
PARAMS_NESTED="_records=3&_depth=3"
PARAMS_LARGE_PAYLOAD="_size_kb=10"
PARAMS_MANY_PARAMS="_p1=a&_p2=1&_p3=true&_p4=1.1&_p5=e&_p6=f&_p7=2&_p8=false&_p9=2.2&_p10=j&_p11=k&_p12=3&_p13=true&_p14=3.3&_p15=o&_p16=p&_p17=4&_p18=false&_p19=4.4&_p20=t"
POST_BODY='{"_records":3,"_payload":{"test":"value"}}'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo "=============================================="
echo "PostgreSQL Function Load Test - Service Tests"
echo "Host: $HOST"
echo "=============================================="
echo ""

# Function to test a GET endpoint
test_get() {
    local name="$1"
    local port="$2"
    local endpoint="$3"
    local params="$4"
    local expect_array="${5:-true}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local url="http://${HOST}:${port}${endpoint}?${params}"
    local response=$(curl -s -w "\n%{http_code}" --max-time 10 "$url" 2>/dev/null)
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        if [ "$expect_array" = "true" ]; then
            if echo "$body" | jq -e '.[0]' > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $endpoint"
                PASSED_TESTS=$((PASSED_TESTS + 1))
                return 0
            fi
        else
            if echo "$body" | jq -e '.' > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $endpoint"
                PASSED_TESTS=$((PASSED_TESTS + 1))
                return 0
            fi
        fi
        echo -e "  ${RED}✗${NC} $endpoint - Parse error"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    else
        echo -e "  ${RED}✗${NC} $endpoint - HTTP $http_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to test a POST endpoint
test_post() {
    local name="$1"
    local port="$2"
    local endpoint="$3"
    local body_data="$4"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local url="http://${HOST}:${port}${endpoint}"
    local response=$(curl -s -w "\n%{http_code}" --max-time 10 -X POST -H "Content-Type: application/json" -d "$body_data" "$url" 2>/dev/null)
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        if echo "$body" | jq -e '.[0]' > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $endpoint (POST)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        fi
        echo -e "  ${RED}✗${NC} $endpoint (POST) - Parse error"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    else
        echo -e "  ${RED}✗${NC} $endpoint (POST) - HTTP $http_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to test all endpoints for a service
test_service_all_endpoints() {
    local name="$1"
    local port="$2"
    local array_style="$3"  # "pg" or "repeated"
    local endpoint_prefix="$4"  # "/api" or "/rpc" for PostgREST
    local use_underscore="$5"  # "true" for PostgREST (perf_test vs perf-test)

    echo "Testing: $name (port $port)"

    # Select params based on array style
    local perf_test_params
    if [ "$array_style" = "repeated" ]; then
        perf_test_params="$PARAMS_REPEATED_ARRAYS"
    else
        perf_test_params="$PARAMS_PG_ARRAYS"
    fi

    # Determine endpoint names (kebab-case vs underscore)
    local ep_perf_test ep_minimal ep_nested ep_large ep_many ep_post
    if [ "$use_underscore" = "true" ]; then
        ep_perf_test="${endpoint_prefix}/perf_test"
        ep_minimal="${endpoint_prefix}/perf_minimal"
        ep_nested="${endpoint_prefix}/perf_nested"
        ep_large="${endpoint_prefix}/perf_large_payload"
        ep_many="${endpoint_prefix}/perf_many_params"
        ep_post="${endpoint_prefix}/perf_post"
    else
        ep_perf_test="${endpoint_prefix}/perf-test"
        ep_minimal="${endpoint_prefix}/perf-minimal"
        ep_nested="${endpoint_prefix}/perf-nested"
        ep_large="${endpoint_prefix}/perf-large-payload"
        ep_many="${endpoint_prefix}/perf-many-params"
        ep_post="${endpoint_prefix}/perf-post"
    fi

    # Test all endpoints
    test_get "$name" "$port" "$ep_perf_test" "$perf_test_params" "true"
    test_get "$name" "$port" "$ep_minimal" "" "true"
    test_get "$name" "$port" "$ep_nested" "$PARAMS_NESTED" "true"
    test_get "$name" "$port" "$ep_large" "$PARAMS_LARGE_PAYLOAD" "true"
    test_get "$name" "$port" "$ep_many" "$PARAMS_MANY_PARAMS" "true"
    test_post "$name" "$port" "$ep_post" "$POST_BODY"

    echo ""
}

echo "=== NpgsqlRest Implementations ==="
test_service_all_endpoints "npgsqlrest-aot-v3.4.6" "5005" "repeated" "/api" "false"
test_service_all_endpoints "npgsqlrest-jit-v3.4.6" "5006" "repeated" "/api" "false"

echo "=== PostgREST ==="
test_service_all_endpoints "postgrest-v14.3" "3000" "pg" "/rpc" "true"

echo "=== .NET Implementations ==="
test_service_all_endpoints "net9-minapi-ef-jit" "5002" "repeated" "/api" "false"
test_service_all_endpoints "net10-minapi-ef-jit" "5003" "repeated" "/api" "false"
test_service_all_endpoints "net10-minapi-dapper-jit" "5004" "repeated" "/api" "false"

echo "=== Python Implementations ==="
test_service_all_endpoints "django-app-v6.0.1" "8000" "pg" "/api" "false"
test_service_all_endpoints "fastapi-app-v0.128.0" "8001" "pg" "/api" "false"

echo "=== Node.js/Bun Implementations ==="
test_service_all_endpoints "fastify-app-v5.7.1" "3101" "pg" "/api" "false"
test_service_all_endpoints "bun-app-v1.3.3" "3104" "pg" "/api" "false"

echo "=== Other Implementations ==="
test_service_all_endpoints "go-app-v1.25" "5200" "pg" "/api" "false"
test_service_all_endpoints "java24-spring-boot-v4.0.1" "5400" "pg" "/api" "false"
test_service_all_endpoints "rust-app-v1.91.1" "5300" "pg" "/api" "false"
test_service_all_endpoints "swoole-php-app-v6.0" "3103" "pg" "/api" "false"

echo "=============================================="
echo "Test Summary"
echo "=============================================="
echo -e "Total:  $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo "=============================================="

if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
fi
