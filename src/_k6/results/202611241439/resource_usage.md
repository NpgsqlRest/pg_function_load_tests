# Resource Usage Summary

Memory and CPU usage per service, measured ONLY during that service's test windows
(idle periods are excluded via test_log.csv).

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
| axum-app-v0.8.9 | 133.18 | 24.47 | 249.57 |
| bun-app-v1.4.5 | 292.14 | 167.18 | 279.62 |
| deno-app-v2.9.8 | 552.88 | 354.16 | 282.60 |
| django-app-v6.1.3 | 769.33 | 383.58 | 321.81 |
| express-app-v5.3.0 | 745.59 | 483.33 | 325.95 |
| fastapi-app-v0.165.0 | 303.19 | 255.78 | 347.10 |
| fastify-app-v5.12.8 | 773.53 | 456.18 | 307.86 |
| gin-app-v1.12.0 | 98.46 | 38.51 | 281.55 |
| go-app-v1.27 | 80.01 | 36.59 | 289.45 |
| hasura-v2.50.10 | 2571.40 | 247.47 | 211.69 |
| java25-spring-boot-v4.2.0 | 1619.58 | 1227.31 | 288.84 |
| laravel-v13.43.0-octane-app | 977.46 | 688.61 | 348.66 |
| nestjs-app-v12.6.0 | 809.82 | 533.04 | 328.31 |
| net10-minapi-dapper-jit | 288.71 | 121.49 | 295.17 |
| net10-minapi-ef-jit | 311.57 | 163.17 | 325.78 |
| net10-minapi-npgsql-jit | 316.96 | 113.51 | 290.25 |
| net11-minapi-dapper-jit | 319.00 | 127.30 | 243.55 |
| net11-minapi-ef-jit | 348.40 | 158.44 | 309.88 |
| net11-minapi-npgsql-jit | 340.90 | 121.00 | 239.49 |
| npgsqlrest-file-aot-v3.21.0 | 435.64 | 108.29 | 284.96 |
| npgsqlrest-file-aot-v4.1.0 | 190.36 | 75.99 | 249.13 |
| npgsqlrest-file-jit-v3.21.0 | 541.56 | 164.16 | 300.53 |
| npgsqlrest-file-jit-v4.1.0 | 223.91 | 129.33 | 229.97 |
| npgsqlrest-routine-aot-v3.21.0 | 364.80 | 107.23 | 278.31 |
| npgsqlrest-routine-aot-v4.1.0 | 132.99 | 72.53 | 243.72 |
| npgsqlrest-routine-jit-v3.21.0 | 421.51 | 175.34 | 297.07 |
| npgsqlrest-routine-jit-v4.1.0 | 204.50 | 129.51 | 224.87 |
| postgraphile-v5.2.1 | 1309.23 | 849.60 | 270.16 |
| postgrest-v16.6 | 115.86 | 63.90 | 223.86 |
| rust-app-v1.100.0 | 137.46 | 39.32 | 240.24 |
| swoole-php-app-v6.2.6 | 41.31 | 25.95 | 144.33 |
