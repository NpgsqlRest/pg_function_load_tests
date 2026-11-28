# Resource Usage Summary

Memory and CPU usage per service, measured ONLY during that service's test windows
(idle periods are excluded via test_log.csv).

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
| axum-app-v0.8.9 | 17.75 | 16.43 | 285.96 |
| bun-app-v1.4.5 | 181.12 | 155.91 | 322.84 |
| deno-app-v2.9.8 | 395.44 | 369.61 | 352.12 |
| django-app-v6.1.3 | 288.16 | 268.61 | 349.27 |
| express-app-v5.3.0 | 453.57 | 417.74 | 380.92 |
| fastapi-app-v0.165.0 | 217.61 | 211.20 | 380.30 |
| fastify-app-v5.12.8 | 639.27 | 440.26 | 324.68 |
| gin-app-v1.12.0 | 55.29 | 44.01 | 313.91 |
| go-app-v1.27 | 52.26 | 47.97 | 364.67 |
| hasura-v2.50.10 | 208.38 | 193.91 | 235.42 |
| java25-spring-boot-v4.2.0 | 1121.05 | 1113.78 | 378.20 |
| laravel-v13.43.0-octane-app | 688.58 | 595.41 | 383.88 |
| nestjs-app-v12.6.0 | 517.44 | 480.90 | 364.92 |
| net10-minapi-dapper-jit | 111.68 | 110.27 | 372.53 |
| net10-minapi-ef-jit | 169.85 | 158.70 | 380.42 |
| net10-minapi-npgsql-jit | 125.37 | 102.68 | 335.93 |
| net11-minapi-dapper-jit | 39.81 | 39.11 | 0.00 |
| net11-minapi-ef-jit | 53.50 | 53.27 | 0.00 |
| net11-minapi-npgsql-jit | 135.00 | 113.31 | 283.31 |
| npgsqlrest-file-aot-v3.21.0 | 20.65 | 20.15 | 0.00 |
| npgsqlrest-file-aot-v4.1.0 | 104.21 | 76.15 | 321.67 |
| npgsqlrest-file-jit-v3.21.0 | 53.50 | 52.79 | 0.00 |
| npgsqlrest-file-jit-v4.1.0 | 142.62 | 123.33 | 294.24 |
| npgsqlrest-routine-aot-v3.21.0 | 20.84 | 19.85 | 0.00 |
| npgsqlrest-routine-aot-v4.1.0 | 61.71 | 53.36 | 347.22 |
| npgsqlrest-routine-jit-v3.21.0 | 53.10 | 52.50 | 0.00 |
| npgsqlrest-routine-jit-v4.1.0 | 122.81 | 104.93 | 310.74 |
| postgraphile-v5.2.1 | 997.45 | 803.70 | 327.58 |
| postgrest-v16.6 | 79.74 | 69.58 | 259.37 |
| rust-app-v1.100.0 | 18.26 | 16.94 | 278.55 |
| swoole-php-app-v6.2.6 | 25.55 | 20.84 | 157.22 |
