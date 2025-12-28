# Service Endpoint Documentation

This document details the differences between services when calling the same PostgreSQL functions.

## Services Overview

| Service | Port | URL Pattern | Language |
|---------|------|-------------|----------|
| Django | 8000 | `/api/perf-*` | Python |
| FastAPI | 8001 | `/api/perf-*` | Python |
| Fastify | 3101 | `/api/perf-*` | Node.js |
| Bun | 3104 | `/api/perf-*` | TypeScript |
| Go | 5200 | `/api/perf-*` | Go |
| Spring Boot | 5400 | `/api/perf-*` | Java |
| Rust (Actix) | 5300 | `/api/perf-*` | Rust |
| Swoole | 3103 | `/api/perf-*` | PHP |
| PostgREST | 3000 | `/rpc/perf_*` | Haskell |
| .NET 9 (EF) | 5002 | `/api/perf-*` | C# |
| .NET 10 (EF) | 5003 | `/api/perf-*` | C# |
| .NET 10 (Dapper) | 5004 | `/api/perf-*` | C# |
| NpgsqlRest (AOT) | 5005 | `/api/perf-*` | C# |
| NpgsqlRest (JIT) | 5006 | `/api/perf-*` | C# |

## URL Pattern Differences

| Framework | Route Style | Example |
|-----------|-------------|---------|
| **PostgREST** | `/rpc/function_name` (underscores) | `/rpc/perf_minimal` |
| **All others** | `/api/endpoint-name` (dashes) | `/api/perf-minimal` |

## Array Parameter Syntax

| Framework | Array Syntax | Example |
|-----------|--------------|---------|
| PostgREST, Django, FastAPI, Fastify, Bun, Go, Spring Boot, Rust, Swoole | PostgreSQL literal | `_int_array={1,2,3}` |
| .NET (all), NpgsqlRest | Repeated keys | `_int_array=1&_int_array=2&_int_array=3` |

---

## Response Format Differences

### Content-Type Header

| Framework | Content-Type |
|-----------|--------------|
| Django | `application/json` |
| FastAPI | `application/json` |
| Fastify | `application/json; charset=utf-8` |
| Bun | `application/json` |
| Go | `application/json` |
| Spring Boot | `application/json` |
| Rust | `application/json` |
| Swoole | `application/json` |
| PostgREST | `application/json; charset=utf-8` |
| .NET 9/10 (EF/Dapper) | `application/json; charset=utf-8` |
| NpgsqlRest (AOT/JIT) | `application/json` |

### Transfer-Encoding

| Framework | Uses Chunked Transfer |
|-----------|----------------------|
| Django | Yes |
| Spring Boot | Yes |
| .NET (all) | Yes |
| NpgsqlRest (AOT/JIT) | Yes |
| Others | No (Content-Length) |

---

## Data Type Serialization Differences

### Timestamp Format

| Framework | timestamp | timestamptz |
|-----------|-----------|-------------|
| Django | `2024-01-15T11:30:00` | `2024-01-15T11:30:00+00:00` |
| FastAPI | `2024-01-15T11:30:00` | `2024-01-15T11:30:00+00:00` |
| Fastify | `2024-01-15T11:30:00.000Z` | `2024-01-15T11:30:00.000Z` |
| Bun | `2024-01-15T11:30:00.000Z` | `2024-01-15T11:30:00.000Z` |
| Go | `2024-01-15T11:30:00Z` | `2024-01-15T11:30:00Z` |
| Spring Boot | `2024-01-15T11:30:00.000Z` | `2024-01-15T11:30:00.000Z` |
| Rust | `2024-01-15T11:30:00` | `2024-01-15T11:30:00Z` |
| Swoole | `2024-01-15 11:30:00` | `2024-01-15 11:30:00+00` |
| PostgREST | `2024-01-15T11:30:00` | `2024-01-15T11:30:00+00:00` |
| .NET (all) | `2024-01-15T11:30:00` | `2024-01-15T11:30:00+00:00` |
| NpgsqlRest | `2024-01-15T11:30:00` | `2024-01-15T11:30:00+00` |

### Interval Format

| Framework | Format | Example |
|-----------|--------|---------|
| Django | Python timedelta string | `1 day, 0:00:00` |
| FastAPI | Seconds (float) | `86400.0` |
| Fastify | Object | `{"days":1}` |
| Bun | PostgreSQL string | `1 day` |
| Go | PostgreSQL string | `1 day` |
| Spring Boot | Complex object | `{"days":1,"hours":0,...,"value":"0 years 0 mons 1 days..."}` |
| Rust | PostgreSQL string | `1 day` |
| Swoole | PostgreSQL string | `1 day` |
| PostgREST | PostgreSQL string | `1 day` |
| .NET (all) | TimeSpan format | `1.00:00:00` |
| NpgsqlRest | PostgreSQL string | `1 day` |

### Numeric/Decimal Precision

| Framework | numeric type | real type |
|-----------|--------------|-----------|
| Django | String `"12346.8023"` | Float `123.549995` |
| FastAPI | Float `12346.8023` | Float `123.54999542236328` |
| Fastify | String `"12346.8023"` | Float `123.549995` |
| Bun | String `"12346.8023"` | Float `123.549995` |
| Go | Float `12346.8023` | Float `123.549995` |
| Spring Boot | Float `12346.8023` | Float `123.549995` |
| Rust | Float `12346.8023` | Float `123.549995` |
| Swoole | String `"12346.8023"` | Float `123.549995` |
| PostgREST | Float `12346.8023` | Float `123.549995` |
| .NET (all) | Float `12346.8023` | Float `123.549995` |
| NpgsqlRest | Float `12346.8023` | Float `123.549995` |

### BigInt Handling

| Framework | bigint type |
|-----------|-------------|
| Django | Number `9223372036854770001` |
| FastAPI | Number `9223372036854770001` |
| Fastify | String `"9223372036854770001"` |
| Bun | String `"9223372036854770001"` |
| Go | Number `9223372036854770001` |
| Spring Boot | Number `9223372036854770001` |
| Rust | Number `9223372036854770001` |
| Swoole | Number `9223372036854770001` |
| PostgREST | Number `9223372036854770001` |
| .NET (all) | Number `9223372036854770001` |
| NpgsqlRest | Number `9223372036854770001` |

**Note**: Fastify and Bun serialize bigint as strings to avoid JavaScript number precision loss.

### JSON/JSONB Serialization

| Framework | JSON field | JSONB field |
|-----------|------------|-------------|
| Django | Native object | String `"{\"key\": \"value\"}"` |
| FastAPI | String `"{...}"` | String `"{...}"` |
| Fastify | Native object | Native object |
| Bun | Merged array | Merged array |
| Go | String `"{...}"` | String `"{...}"` |
| Spring Boot | Wrapped object | Wrapped object |
| Rust | Native object | Native object |
| Swoole | String `"{...}"` | String `"{...}"` |
| PostgREST | Native object | Native object |
| .NET (all) | Native object | Native object |
| NpgsqlRest | Native object | Native object |

**Spring Boot Special Case**: Wraps JSON types in metadata object:
```json
{"null":false,"type":"jsonb","value":"{\"key\": \"value\"}"}
```

**Bun Special Case**: Returns JSON as array of original + computed:
```json
["{\"key\":\"value\"}",{"i":1}]
```

### Array Serialization

| Framework | int[] | text[] |
|-----------|-------|--------|
| Most frameworks | `[1,2,3,1]` | `["a","b","c","test1"]` |
| Swoole | `"{1,2,3,1}"` | `"{a,b,c,test1}"` |

**Swoole**: Returns PostgreSQL array literal strings instead of JSON arrays.

---

## perf-minimal Response

All services return the same structure, but with different timestamp formats:

```json
[{"status":"ok","ts":"<timestamp>"}]
```

| Framework | Timestamp Format |
|-----------|------------------|
| Django | `2026-01-20T09:11:38.212987+00:00` |
| FastAPI | `2026-01-20T09:11:38.249020+00:00` |
| Fastify | `2026-01-20T09:11:38.287Z` |
| Bun | `2026-01-20T09:11:38.322Z` |
| Go | `2026-01-20T09:11:38.357768Z` |
| Spring Boot | `2026-01-20T09:11:38.394Z` |
| Rust | `2026-01-20T09:11:38.432517Z` |
| Swoole | `2026-01-20 09:11:38.469801+00` |
| PostgREST | `2026-01-20T09:11:38.515701+00:00` |
| .NET (all) | `2026-01-20T09:11:38.559424+00:00` |
| NpgsqlRest | `2026-01-20T09:11:38.677201+00` |

---

## perf-nested Response

Tests nested JSONB serialization with `_records=2&_depth=2`:

| Framework | nested field type |
|-----------|-------------------|
| Django | String `"{\"a\": {\"b\": 1}}"` |
| FastAPI | String `"{\"a\": {\"b\": 1}}"` |
| Fastify | Native object `{"a":{"b":1}}` |
| Bun | Native object `{"a":{"b":1}}` |
| Go | String `"{\"a\": {\"b\": 1}}"` |
| Spring Boot | Wrapped object `{"null":false,"type":"jsonb","value":"..."}` |
| Rust | Native object `{"a":{"b":1}}` |
| Swoole | String `"{\"a\": {\"b\": 1}}"` |
| PostgREST | Native object (with spaces) `{"a": {"b": 1}}` |
| .NET (all) | Native object (with spaces) `{"a": {"b": 1}}` |
| NpgsqlRest | Native object (with spaces) `{"a": {"b": 1}}` |

---

## perf-post Response

Tests POST body parsing with JSON payload `{"_records": 2, "_payload": {"test": "value"}}`:

| Framework | echo field |
|-----------|------------|
| Django | String `"{\"test\": \"value\"}"` |
| FastAPI | String `"{\"test\": \"value\"}"` |
| Fastify | Native object `{"test":"value"}` |
| Bun | String `"{\"test\":\"value\"}"` (no spaces) |
| Go | String `"{\"test\": \"value\"}"` |
| Spring Boot | Wrapped object |
| Rust | Native object `{"test":"value"}` |
| Swoole | String `"{\"test\": \"value\"}"` |
| PostgREST | Native object (with spaces) `{"test": "value"}` |
| .NET (all) | Native object (with spaces) `{"test": "value"}` |
| NpgsqlRest | Native object (with spaces) `{"test": "value"}` |

---

## Formatting Differences Summary

### JSON Output Formatting

| Framework | Spaces after colons | Newlines in output |
|-----------|--------------------|--------------------|
| Django | Yes (in strings) | No |
| FastAPI | No | No |
| Fastify | No | No |
| Bun | No | No |
| Go | No | No |
| Spring Boot | No | No |
| Rust | No | No |
| Swoole | No | No |
| PostgREST | Yes | Yes (some endpoints) |
| .NET (all) | No | No |
| NpgsqlRest | No | No |

**PostgREST** occasionally includes newlines between array elements.

---

## Benchmark Implications

These differences generally don't affect benchmark validity because:

1. **Data size** is comparable across frameworks
2. **Parsing correctness** - all return valid JSON
3. **Same PostgreSQL functions** - database work is identical

However, note:
- **Spring Boot's wrapped JSON types** add overhead to response size
- **Swoole's string arrays** may be smaller than JSON arrays
- **String vs native JSON** affects client-side parsing but not server overhead
