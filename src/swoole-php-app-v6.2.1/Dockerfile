FROM phpswoole/swoole:6.2.1-php8.5-alpine

RUN apk add --no-cache postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql

WORKDIR /app
COPY . .

CMD ["php", "server.php"]
