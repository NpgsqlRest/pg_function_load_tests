# Benchmark Report 202607131327

**Profile:** server · **Ramp:** 10s · **Warmup:** 10s · **Sleep between tests:** 30s · **Tests:** 760

All throughput values are requests/s. 🥇🥈🥉 mark the top three per column.

## Data Type Serialization (perf-test)

### Throughput matrix

| Framework | 1vu/1rec | 1vu/10rec | 1vu/100rec | 1vu/500rec | 50vu/1rec | 50vu/10rec | 50vu/100rec | 50vu/500rec | 100vu/1rec | 100vu/10rec | 100vu/100rec | 100vu/500rec | 200vu/1rec | 200vu/10rec | 200vu/100rec | 200vu/500rec |
|-----------|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| FastAPI 0.139.0 | 🥈 854 | 270 | 63.87 | 12.16 | 🥇 5,048 | 🥉 1,576 | 🥉 182 | 🥉 38.62 | 🥇 5,109 | 🥉 1,535 | 🥉 181 | 🥉 38.32 | 🥇 5,053 | 🥉 1,533 | 🥉 182 | 🥉 37.96 |
| NpgsqlRest SQL Files AOT 3.21.0 | 658 | 411 | 93.82 | 🥈 21.71 | 🥉 3,568 | 1,474 | 168 | 34.96 | 🥈 3,524 | 1,457 | 167 | 35.00 | 🥈 3,481 | 1,429 | 165 | 34.79 |
| NpgsqlRest SQL Files JIT 3.21.0 | 753 | 🥉 425 | 🥈 107 | 🥉 21.69 | 🥈 3,621 | 1,466 | 169 | 35.00 | 🥉 3,467 | 1,457 | 166 | 34.92 | 🥉 3,453 | 1,408 | 167 | 34.72 |
| Deno 2.9.2 | 676 | 376 | 88.03 | 19.12 | 3,065 | 1,464 | 164 | 34.09 | 3,047 | 1,420 | 165 | 34.33 | 3,120 | 1,391 | 164 | 34.20 |
| Bun 1.3.14 | 738 | 372 | 88.29 | 19.64 | 3,068 | 1,450 | 164 | 34.48 | 3,016 | 1,429 | 163 | 34.32 | 3,140 | 1,378 | 164 | 34.12 |
| Go 1.26 | 🥇 927 | 🥇 458 | 🥉 98.80 | 21.56 | 3,049 | 🥈 1,621 | 🥈 187 | 🥈 39.20 | 2,948 | 🥈 1,583 | 🥈 184 | 🥈 38.87 | 2,943 | 🥈 1,549 | 🥈 184 | 🥈 38.66 |
| Spring Boot 4.1.0 | 🥉 773 | 409 | 85.59 | 18.31 | 2,772 | 1,489 | 168 | 35.03 | 2,710 | 1,446 | 167 | 34.93 | 2,704 | 1,416 | 166 | 34.52 |
| NpgsqlRest Routine JIT 3.4.7 | 626 | 389 | 98.08 | 21.67 | 2,704 | 1,478 | 169 | 35.34 | 2,620 | 1,456 | 167 | 34.00 | 2,604 | 1,417 | 167 | 34.47 |
| NpgsqlRest Routine AOT 3.4.7 | 595 | 314 | 90.92 | 21.63 | 2,682 | 1,481 | 168 | 35.12 | 2,618 | 1,439 | 167 | 33.37 | 2,620 | 1,422 | 167 | 34.76 |
| NpgsqlRest Routine JIT 3.21.0 | 670 | 340 | 98.08 | 21.55 | 2,701 | 1,462 | 167 | 34.87 | 2,617 | 1,438 | 166 | 34.75 | 2,593 | 1,414 | 166 | 34.72 |
| NpgsqlRest Routine AOT 3.21.0 | 608 | 332 | 92.40 | 21.61 | 2,700 | 1,473 | 169 | 35.19 | 2,615 | 1,434 | 166 | 34.99 | 2,623 | 1,411 | 167 | 34.40 |
| Fastify 5.10.0 | 752 | 331 | 82.46 | 18.76 | 2,644 | 1,446 | 165 | 34.57 | 2,583 | 1,419 | 163 | 34.19 | 2,582 | 1,384 | 163 | 34.01 |
| Express 5.2.1 | 611 | 344 | 83.14 | 18.40 | 2,642 | 1,440 | 165 | 34.48 | 2,578 | 1,419 | 162 | 34.05 | 2,552 | 1,385 | 161 | 33.84 |
| Swoole PHP 6.2.1 | 765 | 🥈 433 | 🥇 111 | 🥇 24.40 | 2,432 | 🥇 1,834 | 🥇 215 | 🥇 45.45 | 2,431 | 🥇 1,801 | 🥇 212 | 🥇 44.99 | 2,436 | 🥇 1,764 | 🥇 212 | 🥇 44.89 |
| Axum 0.8.9 | 718 | 367 | 95.82 | 20.50 | 2,364 | 1,493 | 169 | 35.40 | 2,263 | 1,454 | 169 | 35.32 | 2,221 | 1,430 | 167 | 34.94 |
| .NET 10 Dapper | 582 | 298 | 89.35 | 20.28 | 2,283 | 1,464 | 169 | 35.13 | 2,255 | 1,422 | 164 | 34.17 | 2,237 | 1,415 | 166 | 34.39 |
| Actix-web 1.97.0 | 720 | 348 | 91.86 | 20.40 | 2,352 | 1,481 | 170 | 35.46 | 2,246 | 1,451 | 168 | 35.08 | 2,241 | 1,431 | 168 | 34.87 |
| .NET 10 EF | 620 | 323 | 91.06 | 21.09 | 2,296 | 1,468 | 169 | 35.03 | 2,230 | 1,431 | 167 | 34.96 | 2,217 | 1,406 | 166 | 34.74 |
| Django 6.0.7 | 358 | 225 | 62.96 | 14.45 | 2,005 | 1,437 | 174 | 36.63 | 1,911 | 1,414 | 173 | 36.03 | 1,887 | 1,406 | 171 | 35.95 |
| PostgREST 14.14 | 427 | 232 | 74.48 | 17.30 | 1,363 | 1,109 | 169 | 35.20 | 1,322 | 1,077 | 168 | 35.31 | 1,237 | 1,053 | 168 | 35.05 |

### Scaling behavior

Scaling at 1 record(s): requests/s per VU level.

| Framework | 1 VU | 50 VU | 100 VU | 200 VU | Scaling |
|-----------|---:|---:|---:|---:|---:|
| FastAPI 0.139.0 | 854 | 5,048 | 5,109 | 5,053 | **6.0x** |
| NpgsqlRest SQL Files AOT 3.21.0 | 658 | 3,568 | 3,524 | 3,481 | **5.4x** |
| NpgsqlRest SQL Files JIT 3.21.0 | 753 | 3,621 | 3,467 | 3,453 | **4.8x** |
| Bun 1.3.14 | 738 | 3,068 | 3,016 | 3,140 | **4.3x** |
| Deno 2.9.2 | 676 | 3,065 | 3,047 | 3,120 | **4.6x** |
| Go 1.26 | 927 | 3,049 | 2,948 | 2,943 | **3.3x** |
| Spring Boot 4.1.0 | 773 | 2,772 | 2,710 | 2,704 | **3.6x** |
| NpgsqlRest Routine AOT 3.21.0 | 608 | 2,700 | 2,615 | 2,623 | **4.4x** |
| NpgsqlRest Routine AOT 3.4.7 | 595 | 2,682 | 2,618 | 2,620 | **4.5x** |
| NpgsqlRest Routine JIT 3.4.7 | 626 | 2,704 | 2,620 | 2,604 | **4.3x** |
| NpgsqlRest Routine JIT 3.21.0 | 670 | 2,701 | 2,617 | 2,593 | **4.0x** |
| Fastify 5.10.0 | 752 | 2,644 | 2,583 | 2,582 | **3.5x** |
| Express 5.2.1 | 611 | 2,642 | 2,578 | 2,552 | **4.3x** |
| Swoole PHP 6.2.1 | 765 | 2,432 | 2,431 | 2,436 | **3.2x** |
| Actix-web 1.97.0 | 720 | 2,352 | 2,246 | 2,241 | **3.3x** |
| .NET 10 Dapper | 582 | 2,283 | 2,255 | 2,237 | **3.9x** |
| Axum 0.8.9 | 718 | 2,364 | 2,263 | 2,221 | **3.3x** |
| .NET 10 EF | 620 | 2,296 | 2,230 | 2,217 | **3.7x** |
| Django 6.0.7 | 358 | 2,005 | 1,911 | 1,887 | **5.6x** |
| PostgREST 14.14 | 427 | 1,363 | 1,322 | 1,237 | **3.2x** |

### Latency under heaviest load

Latency distribution at 200vu/500rec (ms).

| Framework | avg | med | p90 | p95 | p99 | max |
|-----------|----:|----:|----:|----:|----:|----:|
| Swoole PHP 6.2.1 | 1,578.4 | 1,453.9 | 2,752.2 | 3,078.8 | 3,704.8 | 5,223.5 |
| FastAPI 0.139.0 | 2,058.1 | 1,490.1 | 4,720.7 | 5,440.8 | 6,528.4 | 8,992.7 |
| Express 5.2.1 | 2,054.9 | 1,495.2 | 4,614.3 | 5,508.8 | 6,944.2 | 9,811.8 |
| PostgREST 14.14 | 1,693.3 | 1,512.1 | 3,150.8 | 3,562.1 | 4,595.6 | 7,356.9 |
| Go 1.26 | 1,664.7 | 1,518.6 | 2,929.4 | 3,279.3 | 3,931.0 | 8,316.9 |
| NpgsqlRest SQL Files JIT 3.21.0 | 1,725.8 | 1,569.0 | 3,059.2 | 3,415.1 | 4,448.7 | 6,555.3 |
| NpgsqlRest Routine AOT 3.21.0 | 1,767.2 | 1,580.0 | 3,220.7 | 3,564.0 | 4,650.3 | 7,351.0 |
| NpgsqlRest Routine JIT 3.21.0 | 1,748.6 | 1,585.0 | 3,031.4 | 3,413.1 | 4,238.1 | 5,849.9 |
| Actix-web 1.97.0 | 2,163.4 | 1,591.9 | 4,566.0 | 5,214.5 | 6,383.1 | 8,304.7 |
| .NET 10 Dapper | 1,761.4 | 1,596.3 | 3,147.1 | 3,550.4 | 4,390.2 | 6,879.8 |
| NpgsqlRest Routine AOT 3.4.7 | 1,758.5 | 1,606.9 | 3,088.0 | 3,432.1 | 4,265.8 | 7,646.2 |
| NpgsqlRest SQL Files AOT 3.21.0 | 1,724.9 | 1,608.5 | 3,003.2 | 3,344.0 | 4,246.6 | 5,922.0 |
| Axum 0.8.9 | 1,757.1 | 1,610.8 | 3,059.7 | 3,481.3 | 4,383.5 | 5,555.5 |
| Spring Boot 4.1.0 | 1,750.1 | 1,610.9 | 2,959.7 | 3,409.2 | 4,215.5 | 5,960.8 |
| .NET 10 EF | 1,749.6 | 1,619.9 | 3,039.0 | 3,466.4 | 4,313.6 | 6,088.2 |
| NpgsqlRest Routine JIT 3.4.7 | 1,753.6 | 1,620.5 | 3,063.9 | 3,405.5 | 3,989.6 | 6,747.2 |
| Deno 2.9.2 | 1,779.9 | 1,628.3 | 3,069.0 | 3,508.6 | 4,219.7 | 5,677.2 |
| Bun 1.3.14 | 1,822.0 | 1,634.6 | 3,180.6 | 3,556.7 | 5,184.5 | 9,820.9 |
| Fastify 5.10.0 | 1,781.7 | 1,637.2 | 3,144.6 | 3,420.0 | 4,156.1 | 5,753.0 |
| Django 6.0.7 | 2,057.7 | 1,767.6 | 3,702.4 | 4,173.9 | 5,167.1 | 6,223.4 |

## Cross-Scenario Summary

| Framework | Minimal | Post | Nested | Large | Params |
|-----------|---:|---:|---:|---:|---:|
| Go 1.26 | 🥇 16,882 | 🥇 7,598 | 🥇 2,106 | 🥇 1,427 | 🥇 15,449 |
| Deno 2.9.2 | 🥈 16,436 | 🥉 7,238 | 1,655 | 🥈 1,418 | 🥉 14,797 |
| Fastify 5.10.0 | 🥉 16,243 | 4,111 | 1,676 | 1,389 | 12,494 |
| Express 5.2.1 | 16,140 | 4,097 | 1,649 | 1,390 | 12,418 |
| Bun 1.3.14 | 16,106 | 🥈 7,461 | 1,657 | 1,408 | 🥈 15,156 |
| NpgsqlRest SQL Files AOT 3.21.0 | 15,776 | 4,058 | 1,640 | 1,365 | 14,437 |
| NpgsqlRest SQL Files JIT 3.21.0 | 15,556 | 4,050 | 1,636 | 1,368 | 14,169 |
| NpgsqlRest Routine AOT 3.21.0 | 15,549 | 4,041 | 1,640 | 1,359 | 11,435 |
| .NET 10 Dapper | 15,378 | 4,018 | 1,649 | 1,363 | 12,161 |
| NpgsqlRest Routine JIT 3.4.7 | 15,374 | 4,042 | 1,646 | 1,360 | 11,497 |
| NpgsqlRest Routine AOT 3.4.7 | 15,327 | 4,077 | 1,646 | 1,359 | 11,389 |
| NpgsqlRest Routine JIT 3.21.0 | 15,280 | 4,066 | 1,637 | 1,364 | 11,563 |
| Spring Boot 4.1.0 | 14,803 | 4,015 | 1,661 | 1,362 | 13,802 |
| .NET 10 EF | 13,203 | 3,938 | 1,642 | 1,358 | 11,210 |
| Actix-web 1.97.0 | 12,669 | 4,099 | 1,666 | 1,289 | 9,591 |
| Axum 0.8.9 | 12,644 | 4,079 | 1,663 | 1,289 | 9,768 |
| FastAPI 0.139.0 | 11,610 | 6,713 | 🥉 2,030 | 🥉 1,416 | 5,996 |
| Swoole PHP 6.2.1 | 10,794 | 7,200 | 🥈 2,092 | 1,287 | 8,447 |
| PostgREST 14.14 | 6,986 | 3,867 | 1,633 | 729 | 3,726 |
| Django 6.0.7 | 2,601 | 2,492 | 1,963 | 1,338 | 2,411 |

Reference combos: Minimal = 100vu, Post = 50vu/10rec, Nested = 50vu/100rec/d1, Large = 25vu/100kb, Params = 50vu.

## Minimal Baseline (minimal)

| Framework | 100vu | 200vu | 500vu |
|-----------|---:|---:|---:|
| Go 1.26 | 🥇 16,882 | 🥇 15,736 | 🥇 13,613 |
| Deno 2.9.2 | 🥈 16,436 | 🥉 15,140 | 🥈 13,487 |
| Bun 1.3.14 | 16,106 | 14,777 | 🥉 13,483 |
| Express 5.2.1 | 16,140 | 15,001 | 13,235 |
| Fastify 5.10.0 | 🥉 16,243 | 🥈 15,214 | 13,180 |
| NpgsqlRest SQL Files AOT 3.21.0 | 15,776 | 14,339 | 13,032 |
| NpgsqlRest Routine JIT 3.21.0 | 15,280 | 13,965 | 12,856 |
| Spring Boot 4.1.0 | 14,803 | 13,952 | 12,853 |
| NpgsqlRest SQL Files JIT 3.21.0 | 15,556 | 14,170 | 12,787 |
| NpgsqlRest Routine AOT 3.21.0 | 15,549 | 14,080 | 12,783 |
| .NET 10 Dapper | 15,378 | 14,043 | 12,695 |
| NpgsqlRest Routine AOT 3.4.7 | 15,327 | 14,045 | 12,692 |
| NpgsqlRest Routine JIT 3.4.7 | 15,374 | 14,020 | 12,683 |
| Actix-web 1.97.0 | 12,669 | 12,666 | 12,607 |
| Axum 0.8.9 | 12,644 | 12,749 | 12,574 |
| .NET 10 EF | 13,203 | 12,747 | 12,187 |
| FastAPI 0.139.0 | 11,610 | 11,534 | 10,941 |
| Swoole PHP 6.2.1 | 10,794 | 10,778 | 10,706 |
| PostgREST 14.14 | 6,986 | 6,811 | 6,450 |
| Django 6.0.7 | 2,601 | 2,481 | 2,331 |

## POST Body Parsing (post)

| Framework | 50vu/10rec | 50vu/100rec | 100vu/10rec | 100vu/100rec | 200vu/10rec | 200vu/100rec |
|-----------|---:|---:|---:|---:|---:|---:|
| Bun 1.3.14 | 🥈 7,461 | 🥉 1,342 | 🥉 6,897 | 🥈 1,308 | 6,469 | 🥇 1,286 |
| Swoole PHP 6.2.1 | 7,200 | 🥈 1,343 | 🥈 6,992 | 1,290 | 🥈 6,533 | 🥈 1,273 |
| Go 1.26 | 🥇 7,598 | 1,338 | 🥇 7,198 | 🥉 1,301 | 🥇 6,595 | 🥉 1,270 |
| Deno 2.9.2 | 🥉 7,238 | 🥇 1,347 | 6,890 | 🥇 1,315 | 🥉 6,512 | 1,252 |
| FastAPI 0.139.0 | 6,713 | 1,302 | 6,071 | 1,279 | 6,225 | 1,244 |
| Django 6.0.7 | 2,492 | 1,284 | 2,298 | 1,268 | 2,250 | 1,223 |
| Actix-web 1.97.0 | 4,099 | 548 | 3,836 | 535 | 3,661 | 527 |
| NpgsqlRest Routine JIT 3.21.0 | 4,066 | 544 | 3,827 | 532 | 3,638 | 526 |
| Fastify 5.10.0 | 4,111 | 543 | 3,839 | 534 | 3,664 | 525 |
| NpgsqlRest SQL Files AOT 3.21.0 | 4,058 | 547 | 3,793 | 534 | 3,669 | 523 |
| Spring Boot 4.1.0 | 4,015 | 546 | 3,788 | 533 | 3,640 | 523 |
| NpgsqlRest SQL Files JIT 3.21.0 | 4,050 | 542 | 3,797 | 535 | 3,650 | 522 |
| Express 5.2.1 | 4,097 | 546 | 3,852 | 533 | 3,632 | 522 |
| NpgsqlRest Routine AOT 3.21.0 | 4,041 | 544 | 3,831 | 525 | 3,612 | 522 |
| Axum 0.8.9 | 4,079 | 548 | 3,842 | 537 | 3,678 | 521 |
| PostgREST 14.14 | 3,867 | 545 | 3,654 | 532 | 3,469 | 520 |
| .NET 10 Dapper | 4,018 | 545 | 3,810 | 533 | 3,660 | 517 |
| .NET 10 EF | 3,938 | 542 | 3,760 | 535 | 3,614 | 517 |
| NpgsqlRest Routine JIT 3.4.7 | 4,042 | 545 | 3,822 | 533 | 3,652 | 515 |
| NpgsqlRest Routine AOT 3.4.7 | 4,077 | 546 | 3,827 | 533 | 3,655 | 514 |

## Nested JSON (nested)

| Framework | 50vu/100rec/d1 | 50vu/100rec/d2 | 50vu/100rec/d3 | 100vu/100rec/d1 | 100vu/100rec/d2 | 100vu/100rec/d3 |
|-----------|---:|---:|---:|---:|---:|---:|
| Swoole PHP 6.2.1 | 🥈 2,092 | 🥇 1,997 | 🥈 1,960 | 🥈 1,992 | 🥇 1,949 | 🥇 1,894 |
| Go 1.26 | 🥇 2,106 | 🥈 1,991 | 🥇 1,971 | 🥇 2,005 | 🥈 1,930 | 🥈 1,884 |
| FastAPI 0.139.0 | 🥉 2,030 | 🥉 1,945 | 🥉 1,904 | 🥉 1,950 | 🥉 1,884 | 🥉 1,847 |
| Django 6.0.7 | 1,963 | 1,900 | 1,869 | 1,879 | 1,848 | 1,800 |
| Axum 0.8.9 | 1,663 | 1,344 | 1,140 | 1,606 | 1,317 | 1,096 |
| NpgsqlRest Routine AOT 3.4.7 | 1,646 | 1,339 | 1,133 | 1,590 | 1,302 | 1,096 |
| NpgsqlRest SQL Files AOT 3.21.0 | 1,640 | 1,337 | 1,139 | 1,581 | 1,299 | 1,095 |
| NpgsqlRest Routine JIT 3.21.0 | 1,637 | 1,334 | 1,138 | 1,579 | 1,298 | 1,092 |
| Fastify 5.10.0 | 1,676 | 1,334 | 1,142 | 1,600 | 1,300 | 1,092 |
| NpgsqlRest Routine AOT 3.21.0 | 1,640 | 1,333 | 1,132 | 1,584 | 1,296 | 1,092 |
| NpgsqlRest SQL Files JIT 3.21.0 | 1,636 | 1,332 | 1,135 | 1,575 | 1,300 | 1,091 |
| NpgsqlRest Routine JIT 3.4.7 | 1,646 | 1,335 | 1,132 | 1,587 | 1,299 | 1,091 |
| .NET 10 EF | 1,642 | 1,333 | 1,127 | 1,568 | 1,287 | 1,091 |
| Actix-web 1.97.0 | 1,666 | 1,345 | 1,136 | 1,600 | 1,305 | 1,090 |
| .NET 10 Dapper | 1,649 | 1,337 | 1,138 | 1,601 | 1,306 | 1,089 |
| Express 5.2.1 | 1,649 | 1,335 | 1,126 | 1,594 | 1,299 | 1,087 |
| Spring Boot 4.1.0 | 1,661 | 1,331 | 1,131 | 1,584 | 1,301 | 1,087 |
| PostgREST 14.14 | 1,633 | 1,310 | 1,125 | 1,567 | 1,287 | 1,085 |
| Deno 2.9.2 | 1,655 | 1,327 | 1,125 | 1,589 | 1,300 | 1,084 |
| Bun 1.3.14 | 1,657 | 1,327 | 1,127 | 1,578 | 1,289 | 1,081 |

## Large Payload (large)

| Framework | 25vu/100kb | 25vu/500kb | 50vu/100kb | 50vu/500kb |
|-----------|---:|---:|---:|---:|
| FastAPI 0.139.0 | 🥉 1,416 | 🥈 334 | 🥈 1,402 | 🥇 342 |
| Go 1.26 | 🥇 1,427 | 🥇 335 | 🥇 1,415 | 🥈 341 |
| Bun 1.3.14 | 1,408 | 🥉 334 | 🥉 1,399 | 🥉 340 |
| Deno 2.9.2 | 🥈 1,418 | 331 | 1,389 | 338 |
| Django 6.0.7 | 1,338 | 322 | 1,329 | 327 |
| NpgsqlRest SQL Files JIT 3.21.0 | 1,368 | 317 | 1,368 | 323 |
| Spring Boot 4.1.0 | 1,362 | 317 | 1,354 | 322 |
| .NET 10 Dapper | 1,363 | 317 | 1,367 | 321 |
| Actix-web 1.97.0 | 1,289 | 316 | 1,300 | 321 |
| .NET 10 EF | 1,358 | 304 | 1,358 | 321 |
| NpgsqlRest SQL Files AOT 3.21.0 | 1,365 | 316 | 1,362 | 321 |
| Axum 0.8.9 | 1,289 | 315 | 1,303 | 320 |
| Express 5.2.1 | 1,390 | 316 | 1,380 | 319 |
| Swoole PHP 6.2.1 | 1,287 | 316 | 1,298 | 318 |
| Fastify 5.10.0 | 1,389 | 315 | 1,382 | 317 |
| NpgsqlRest Routine AOT 3.21.0 | 1,359 | 310 | 1,358 | 316 |
| NpgsqlRest Routine JIT 3.21.0 | 1,364 | 312 | 1,365 | 316 |
| NpgsqlRest Routine JIT 3.4.7 | 1,360 | 313 | 1,361 | 316 |
| NpgsqlRest Routine AOT 3.4.7 | 1,359 | 310 | 1,364 | 315 |
| PostgREST 14.14 | 729 | 164 | 727 | 170 |

## Many Parameters (params)

| Framework | 50vu | 100vu | 200vu |
|-----------|---:|---:|---:|
| Go 1.26 | 🥇 15,449 | 🥇 14,975 | 🥇 13,866 |
| Bun 1.3.14 | 🥈 15,156 | 🥈 14,453 | 🥈 13,118 |
| Deno 2.9.2 | 🥉 14,797 | 🥉 14,010 | 🥉 13,086 |
| NpgsqlRest SQL Files AOT 3.21.0 | 14,437 | 13,574 | 12,692 |
| NpgsqlRest SQL Files JIT 3.21.0 | 14,169 | 13,686 | 12,603 |
| NpgsqlRest Routine JIT 3.21.0 | 11,563 | 13,133 | 12,456 |
| NpgsqlRest Routine AOT 3.4.7 | 11,389 | 13,051 | 12,445 |
| NpgsqlRest Routine JIT 3.4.7 | 11,497 | 13,067 | 12,374 |
| Spring Boot 4.1.0 | 13,802 | 13,374 | 12,357 |
| NpgsqlRest Routine AOT 3.21.0 | 11,435 | 13,008 | 12,254 |
| Fastify 5.10.0 | 12,494 | 11,753 | 11,773 |
| Express 5.2.1 | 12,418 | 11,581 | 11,656 |
| .NET 10 Dapper | 12,161 | 11,118 | 11,067 |
| .NET 10 EF | 11,210 | 10,403 | 10,471 |
| Axum 0.8.9 | 9,768 | 9,731 | 9,783 |
| Actix-web 1.97.0 | 9,591 | 9,462 | 9,735 |
| Swoole PHP 6.2.1 | 8,447 | 8,501 | 8,565 |
| FastAPI 0.139.0 | 5,996 | 6,157 | 6,119 |
| PostgREST 14.14 | 3,726 | 3,675 | 3,649 |
| Django 6.0.7 | 2,411 | 2,296 | 2,188 |

## Resource Usage (during test windows only)

| Service | Peak Memory (MB) | Avg Memory (MB) | Avg CPU (%) |
|---------|----------------:|----------------:|------------:|
| Swoole PHP 6.2.1 | 44.3 | 23.6 | 65.59 |
| Go 1.26 | 58.8 | 25.1 | 90.16 |
| PostgREST 14.14 | 112.0 | 56.6 | 102.98 |
| Axum 0.8.9 | 144.7 | 24.9 | 48.84 |
| NpgsqlRest SQL Files AOT 3.21.0 | 154.8 | 62.4 | 113.54 |
| NpgsqlRest Routine AOT 3.4.7 | 155.6 | 61.8 | 106.88 |
| Actix-web 1.97.0 | 167.4 | 58.9 | 57.85 |
| NpgsqlRest Routine AOT 3.21.0 | 168.1 | 65.2 | 110.39 |
| .NET 10 EF | 214.1 | 123.7 | 150.25 |
| NpgsqlRest SQL Files JIT 3.21.0 | 225.0 | 124.9 | 133.58 |
| NpgsqlRest Routine JIT 3.4.7 | 230.2 | 124.2 | 125.93 |
| .NET 10 Dapper | 243.5 | 102.2 | 127.99 |
| NpgsqlRest Routine JIT 3.21.0 | 280.5 | 128.7 | 128.98 |
| FastAPI 0.139.0 | 282.4 | 236.8 | 200.43 |
| Bun 1.3.14 | 340.0 | 228.6 | 109.63 |
| Django 6.0.7 | 671.2 | 281.0 | 229.61 |
| Deno 2.9.2 | 740.1 | 500.5 | 104.84 |
| Spring Boot 4.1.0 | 756.1 | 404.4 | 97.57 |
| Express 5.2.1 | 1,093.6 | 576.7 | 108.88 |
| Fastify 5.10.0 | 1,176.6 | 600.1 | 91.68 |

## Test Completion

| Service | Script | Exit code |
|---------|--------|----------:|
| Django 6.0.7 | script.js | 99 |
| FastAPI 0.139.0 | script.js | 99 |
| Fastify 5.10.0 | script.js | 99 |
| Bun 1.3.14 | script.js | 99 |
| Go 1.26 | script.js | 99 |
| Spring Boot 4.1.0 | script.js | 99 |
| Actix-web 1.97.0 | script.js | 99 |
| Swoole PHP 6.2.1 | script.js | 99 |
| Express 5.2.1 | script.js | 99 |
| Deno 2.9.2 | script.js | 99 |
| Axum 0.8.9 | script.js | 99 |
| PostgREST 14.14 | script.js | 99 |
| .NET 10 EF | script.js | 99 |
| .NET 10 Dapper | script.js | 99 |
| NpgsqlRest Routine AOT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine JIT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine AOT 3.21.0 | script.js | 99 |
| NpgsqlRest Routine JIT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files AOT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files JIT 3.21.0 | script.js | 99 |
| Django 6.0.7 | script.js | 99 |
| FastAPI 0.139.0 | script.js | 99 |
| Fastify 5.10.0 | script.js | 99 |
| Bun 1.3.14 | script.js | 99 |
| Go 1.26 | script.js | 99 |
| Spring Boot 4.1.0 | script.js | 99 |
| Actix-web 1.97.0 | script.js | 99 |
| Swoole PHP 6.2.1 | script.js | 99 |
| Express 5.2.1 | script.js | 99 |
| Deno 2.9.2 | script.js | 99 |
| Axum 0.8.9 | script.js | 99 |
| PostgREST 14.14 | script.js | 99 |
| .NET 10 EF | script.js | 99 |
| .NET 10 Dapper | script.js | 99 |
| NpgsqlRest Routine AOT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine JIT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine AOT 3.21.0 | script.js | 99 |
| NpgsqlRest Routine JIT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files AOT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files JIT 3.21.0 | script.js | 99 |
| Django 6.0.7 | script.js | 99 |
| FastAPI 0.139.0 | script.js | 99 |
| Fastify 5.10.0 | script.js | 99 |
| Go 1.26 | script.js | 99 |
| Spring Boot 4.1.0 | script.js | 99 |
| Actix-web 1.97.0 | script.js | 99 |
| Express 5.2.1 | script.js | 99 |
| Deno 2.9.2 | script.js | 99 |
| Axum 0.8.9 | script.js | 99 |
| PostgREST 14.14 | script.js | 99 |
| .NET 10 EF | script.js | 99 |
| .NET 10 Dapper | script.js | 99 |
| NpgsqlRest Routine AOT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine JIT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine AOT 3.21.0 | script.js | 99 |
| NpgsqlRest Routine JIT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files AOT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files JIT 3.21.0 | script.js | 99 |
| Django 6.0.7 | script.js | 99 |
| FastAPI 0.139.0 | script.js | 99 |
| Fastify 5.10.0 | script.js | 99 |
| Bun 1.3.14 | script.js | 99 |
| Go 1.26 | script.js | 99 |
| Spring Boot 4.1.0 | script.js | 99 |
| Actix-web 1.97.0 | script.js | 99 |
| Swoole PHP 6.2.1 | script.js | 99 |
| Express 5.2.1 | script.js | 99 |
| Deno 2.9.2 | script.js | 99 |
| Axum 0.8.9 | script.js | 99 |
| PostgREST 14.14 | script.js | 99 |
| .NET 10 EF | script.js | 99 |
| .NET 10 Dapper | script.js | 99 |
| NpgsqlRest Routine AOT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine JIT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine AOT 3.21.0 | script.js | 99 |
| NpgsqlRest Routine JIT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files AOT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files JIT 3.21.0 | script.js | 99 |
| Django 6.0.7 | script.js | 99 |
| FastAPI 0.139.0 | script.js | 99 |
| Fastify 5.10.0 | script.js | 99 |
| Bun 1.3.14 | script.js | 99 |
| Go 1.26 | script.js | 99 |
| Spring Boot 4.1.0 | script.js | 99 |
| Actix-web 1.97.0 | script.js | 99 |
| Swoole PHP 6.2.1 | script.js | 99 |
| Express 5.2.1 | script.js | 99 |
| Deno 2.9.2 | script.js | 99 |
| Axum 0.8.9 | script.js | 99 |
| PostgREST 14.14 | script.js | 99 |
| .NET 10 EF | script.js | 99 |
| .NET 10 Dapper | script.js | 99 |
| NpgsqlRest Routine AOT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine JIT 3.4.7 | script.js | 99 |
| NpgsqlRest Routine AOT 3.21.0 | script.js | 99 |
| NpgsqlRest Routine JIT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files AOT 3.21.0 | script.js | 99 |
| NpgsqlRest SQL Files JIT 3.21.0 | script.js | 99 |
| Django 6.0.7 | scenarios/minimal-baseline.js | 99 |
| Django 6.0.7 | scenarios/minimal-baseline.js | 99 |
| FastAPI 0.139.0 | scenarios/minimal-baseline.js | 99 |
| Swoole PHP 6.2.1 | scenarios/minimal-baseline.js | 99 |
| PostgREST 14.14 | scenarios/minimal-baseline.js | 99 |

## Lines of Code

| Framework | Lines of Code |
|-----------|--------------:|
| PostgREST 14.14 | 12 (config only) |
| NpgsqlRest Routine AOT 3.21.0 | 21 (config only) |
| NpgsqlRest Routine AOT 3.4.7 | 21 (config only) |
| NpgsqlRest Routine JIT 3.21.0 | 21 (config only) |
| NpgsqlRest Routine JIT 3.4.7 | 21 (config only) |
| Fastify 5.10.0 | 102 |
| Express 5.2.1 | 103 |
| .NET 10 EF | 105 |
| FastAPI 0.139.0 | 123 |
| .NET 10 Dapper | 129 |
| Bun 1.3.14 | 140 |
| NpgsqlRest SQL Files AOT 3.21.0 | 140 (config only) |
| NpgsqlRest SQL Files JIT 3.21.0 | 140 (config only) |
| Deno 2.9.2 | 143 |
| Spring Boot 4.1.0 | 165 |
| Django 6.0.7 | 183 |
| Swoole PHP 6.2.1 | 198 |
| Axum 0.8.9 | 248 |
| Actix-web 1.97.0 | 256 |
| Go 1.26 | 303 |
