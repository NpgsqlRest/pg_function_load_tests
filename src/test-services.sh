#!/bin/bash

# PostgreSQL Function Load Test - Service Validation Script
# This script tests all services against the npgsqlrest-jit reference implementation
#
# Usage: ./test-services.sh [HOST]
# Default HOST is localhost

HOST="${1:-localhost}"

# URL-encoded test parameters
# Note: JSON values are URL-encoded: {"key":"value"} = %7B%22key%22%3A%22value%22%7D
# Note: Array literal {1,2,3} = %7B1,2,3%7D

# Base query params for services using PostgreSQL array literals
PARAMS_PG_ARRAYS="_records=1&_text=test&_int=42&_bigint=9223372036854770000&_numeric=123.456&_real=1.23&_double=1.23456789&_bool=true&_date=2024-01-15&_timestamp=2024-01-15T10:30:00&_timestamptz=2024-01-15T10:30:00Z&_uuid=a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11&_json=%7B%22key%22%3A%22value%22%7D&_jsonb=%7B%22key%22%3A%22value%22%7D&_int_array=%7B1,2,3%7D&_text_array=%7Ba,b,c%7D"

# Base query params for services using repeated query params for arrays (NpgsqlRest, .NET)
PARAMS_REPEATED_ARRAYS="_records=1&_text=test&_int=42&_bigint=9223372036854770000&_numeric=123.456&_real=1.23&_double=1.23456789&_bool=true&_date=2024-01-15&_timestamp=2024-01-15T10:30:00&_timestamptz=2024-01-15T10:30:00Z&_uuid=a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11&_json=%7B%22key%22%3A%22value%22%7D&_jsonb=%7B%22key%22%3A%22value%22%7D&_int_array=1&_int_array=2&_int_array=3&_text_array=a&_text_array=b&_text_array=c"

echo "=============================================="
echo "PostgreSQL Function Load Test - Service Tests"
echo "Host: $HOST"
echo "=============================================="
echo ""

# Function to test a service
test_service() {
    local name="$1"
    local port="$2"
    local endpoint="$3"
    local params="$4"

    echo "Testing: $name (port $port)"
    local url="http://${HOST}:${port}${endpoint}?${params}"
    local response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null)
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        # Check if response is valid JSON array
        if echo "$body" | jq -e '.[0]' > /dev/null 2>&1; then
            echo "  Status: OK (HTTP $http_code)"
            # Show key fields for verification
            echo "  Sample: row_num=$(echo "$body" | jq -r '.[0].row_num'), bigint_val=$(echo "$body" | jq -r '.[0].bigint_val')"
        else
            echo "  Status: PARSE ERROR (HTTP $http_code)"
            echo "  Response: $body"
        fi
    else
        echo "  Status: FAILED (HTTP $http_code)"
        echo "  Response: $body"
    fi
    echo ""
}

echo "=== Reference Implementation ==="
test_service "npgsqlrest-jit-v3.2.2" "5005" "/api/perf-test" "$PARAMS_REPEATED_ARRAYS"

echo "=== NpgsqlRest Implementations ==="
test_service "npgsqlrest-aot-v2.36.2" "5006" "/api/perf-test" "$PARAMS_REPEATED_ARRAYS"

echo "=== .NET Implementations (Repeated Array Params) ==="
test_service "net9-minapi-ef-jit" "5002" "/api/perf-test" "$PARAMS_REPEATED_ARRAYS"
test_service "net10-minapi-ef-jit" "5003" "/api/perf-test" "$PARAMS_REPEATED_ARRAYS"
test_service "net10-minapi-dapper-jit" "5004" "/api/perf-test" "$PARAMS_REPEATED_ARRAYS"

echo "=== Python Implementations (PostgreSQL Array Literals) ==="
test_service "django-app-v5.1.4" "8000" "/api/perf-test" "$PARAMS_PG_ARRAYS"
test_service "fastapi-app-v0.115.6" "8001" "/api/perf-test" "$PARAMS_PG_ARRAYS"

echo "=== Node.js/Bun Implementations (PostgreSQL Array Literals) ==="
test_service "fastify-app-v5.2.1" "3101" "/api/perf-test" "$PARAMS_PG_ARRAYS"
test_service "bun-app-v1.1.42" "3104" "/api/perf-test" "$PARAMS_PG_ARRAYS"

echo "=== Other Implementations (PostgreSQL Array Literals) ==="
test_service "go-app-v1.23.4" "5200" "/api/perf-test" "$PARAMS_PG_ARRAYS"
test_service "java24-spring-boot-v3.4.1" "5400" "/api/perf-test" "$PARAMS_PG_ARRAYS"
test_service "rust-app-v1.83.0" "5300" "/api/perf-test" "$PARAMS_PG_ARRAYS"
test_service "swoole-php-app-v8.4.0" "3103" "/api/perf-test" "$PARAMS_PG_ARRAYS"

echo "=== PostgREST (PostgreSQL Array Literals, different endpoint) ==="
test_service "postgrest-v12.2.8" "3000" "/rpc/perf_test" "$PARAMS_PG_ARRAYS"

echo "=============================================="
echo "Test completed."
echo "=============================================="
