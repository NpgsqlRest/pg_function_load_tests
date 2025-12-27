FROM phpswoole/swoole:6.0-php8.4-alpine

RUN apk add --no-cache postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql

WORKDIR /app
COPY . .

CMD ["php", "server.php"]
