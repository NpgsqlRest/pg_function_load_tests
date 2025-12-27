<?php
use Swoole\HTTP\Server;
use Swoole\HTTP\Request;
use Swoole\HTTP\Response;

$server = new Server("0.0.0.0", 3103);

$server->set([
    'worker_num' => swoole_cpu_num() * 2,
    'max_request' => 0,
    'enable_coroutine' => true,
    'tcp_fastopen' => true,
    'open_tcp_nodelay' => true,
]);

$server->on('start', function ($server) {
    echo "Swoole HTTP server started at http://0.0.0.0:3103\n";
});

$pool = new \Swoole\Database\PDOPool(
    (new \Swoole\Database\PDOConfig())
        ->withHost(getenv('DB_HOST') ?: 'postgres')
        ->withPort(5432)
        ->withDbName(getenv('DB_NAME') ?: 'testdb')
        ->withUsername(getenv('DB_USER') ?: 'testuser')
        ->withPassword(getenv('DB_PASSWORD') ?: 'testpass')
        ->withDriver('pgsql'),
    100
);

$server->on('request', function (Request $request, Response $response) use ($pool) {
    $path = parse_url($request->server['request_uri'], PHP_URL_PATH);

    if ($path !== '/api/perf-test' || $request->server['request_method'] !== 'GET') {
        $response->status(404);
        $response->header('Content-Type', 'application/json');
        $response->end(json_encode(['error' => 'Not Found']));
        return;
    }

    $pdo = $pool->get();

    try {
        $stmt = $pdo->prepare("
            SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                   numeric_val, real_val, double_val, bool_val, date_val, time_val,
                   timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                   int_array_val, text_array_val, nullable_text, nullable_int
            FROM public.perf_test(:records, :text, :int, :bigint::bigint, :numeric::numeric, :real::real, :double::double precision, :bool, :date::date, :timestamp::timestamp, :timestamptz::timestamptz, :uuid::uuid, :json::json, :jsonb::jsonb, :int_array::int[], :text_array::text[])
        ");

        $stmt->bindValue(':records', (int) $request->get['_records'], PDO::PARAM_INT);
        $stmt->bindValue(':text', $request->get['_text'], PDO::PARAM_STR);
        $stmt->bindValue(':int', (int) $request->get['_int'], PDO::PARAM_INT);
        $stmt->bindValue(':bigint', $request->get['_bigint'], PDO::PARAM_STR);
        $stmt->bindValue(':numeric', $request->get['_numeric'], PDO::PARAM_STR);
        $stmt->bindValue(':real', $request->get['_real'], PDO::PARAM_STR);
        $stmt->bindValue(':double', $request->get['_double'], PDO::PARAM_STR);
        $stmt->bindValue(':bool', $request->get['_bool'] === 'true', PDO::PARAM_BOOL);
        $stmt->bindValue(':date', $request->get['_date'], PDO::PARAM_STR);
        $stmt->bindValue(':timestamp', $request->get['_timestamp'], PDO::PARAM_STR);
        $stmt->bindValue(':timestamptz', $request->get['_timestamptz'], PDO::PARAM_STR);
        $stmt->bindValue(':uuid', $request->get['_uuid'], PDO::PARAM_STR);
        $stmt->bindValue(':json', $request->get['_json'], PDO::PARAM_STR);
        $stmt->bindValue(':jsonb', $request->get['_jsonb'], PDO::PARAM_STR);
        $stmt->bindValue(':int_array', $request->get['_int_array'], PDO::PARAM_STR);
        $stmt->bindValue(':text_array', $request->get['_text_array'], PDO::PARAM_STR);
        $stmt->execute();
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $pool->put($pdo);

        $response->header('Content-Type', 'application/json');
        $response->end(json_encode($results));

    } catch (Throwable $e) {
        $pool->put($pdo);
        $response->status(500);
        $response->header('Content-Type', 'application/json');
        $response->end(json_encode(['error' => $e->getMessage()]));
    }
});

$server->start();
