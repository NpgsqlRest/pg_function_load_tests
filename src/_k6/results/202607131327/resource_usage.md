# Resource Usage Summary

Memory and CPU usage per service, measured ONLY during that service's test windows
(idle periods are excluded via test_log.csv).

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
| axum-app-v0.8.9 | 144.70 | 24.86 | 48.84 |
| bun-app-v1.3.14 | 340.00 | 228.57 | 109.63 |
| deno-app-v2.9.2 | 740.10 | 500.48 | 104.84 |
| django-app-v6.0.7 | 671.20 | 281.04 | 229.61 |
| express-app-v5.2.1 | 1093.63 | 576.69 | 108.88 |
| fastapi-app-v0.139.0 | 282.40 | 236.85 | 200.43 |
| fastify-app-v5.10.0 | 1176.58 | 600.06 | 91.68 |
| go-app-v1.26 | 58.84 | 25.14 | 90.16 |
| java25-spring-boot-v4.1.0 | 756.10 | 404.43 | 97.57 |
| net10-minapi-dapper-jit | 243.50 | 102.17 | 127.99 |
| net10-minapi-ef-jit | 214.10 | 123.70 | 150.25 |
| npgsqlrest-file-aot-v3.21.0 | 154.80 | 62.39 | 113.54 |
| npgsqlrest-file-jit-v3.21.0 | 225.00 | 124.88 | 133.58 |
| npgsqlrest-routine-aot-v3.21.0 | 168.10 | 65.16 | 110.39 |
| npgsqlrest-routine-aot-v3.4.7 | 155.60 | 61.76 | 106.88 |
| npgsqlrest-routine-jit-v3.21.0 | 280.50 | 128.65 | 128.98 |
| npgsqlrest-routine-jit-v3.4.7 | 230.20 | 124.25 | 125.93 |
| postgrest-v14.14 | 112.00 | 56.61 | 102.98 |
| rust-app-v1.97.0 | 167.40 | 58.85 | 57.85 |
| swoole-php-app-v6.2.1 | 44.30 | 23.56 | 65.59 |
