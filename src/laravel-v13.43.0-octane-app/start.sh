#!/bin/sh
# Configuration and routes are cached at start, as in a production deployment (the environment comes from
# docker-compose, so it cannot be cached at build time).
export DB_HOST="${DB_HOST:-postgres}" DB_DATABASE="${DB_NAME:-testdb}" DB_USERNAME="${DB_USER:-testuser}" DB_PASSWORD="${DB_PASSWORD:-testpass}"
php artisan config:cache > /dev/null
php artisan route:cache > /dev/null

# An Octane worker handles one request at a time and holds one database connection, so the number of workers
# is the number of requests in flight. Four per core, as is usual for workers that wait on a database
# (WORKERS overrides it). The other services have about 100 pooled connections in total; this one has one
# per worker.
WORKERS="${WORKERS:-$(( $(nproc) * 4 ))}"
exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=3107 --workers="$WORKERS" --max-requests=0
