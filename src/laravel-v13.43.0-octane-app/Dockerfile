FROM phpswoole/swoole:6.2.6-php8.5-alpine

RUN apk add --no-cache postgresql-dev git unzip \
    && docker-php-ext-install pdo pdo_pgsql pcntl

WORKDIR /var/www
# The application is the one "composer create-project laravel/laravel" creates, with Octane installed the
# documented way. Only the routes and the routing bootstrap of this service replace the skeleton's.
RUN composer create-project --no-interaction --prefer-dist laravel/laravel:^13.0 app \
    && cd app \
    && composer require --no-interaction laravel/framework:13.43.0 laravel/octane:^2.25 \
    && php artisan octane:install --server=swoole --no-interaction

WORKDIR /var/www/app
COPY routes/api.php routes/api.php
COPY bootstrap/app.php bootstrap/app.php
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=null \
    DB_CONNECTION=pgsql \
    DB_PORT=5432 \
    CACHE_STORE=array \
    SESSION_DRIVER=array \
    QUEUE_CONNECTION=sync

EXPOSE 3107
CMD ["/start.sh"]
