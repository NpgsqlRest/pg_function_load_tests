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
    $method = $request->server['request_method'];

    // New benchmark endpoints
    if ($path === '/api/perf-minimal' && $method === 'GET') {
        $pdo = $pool->get();
        try {
            $stmt = $pdo->query("SELECT status, ts FROM public.perf_minimal()");
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
        return;
    }

    if ($path === '/api/perf-post' && $method === 'POST') {
        $pdo = $pool->get();
        try {
            $body = json_decode($request->getContent(), true) ?? [];
            $records = (int) ($body['_records'] ?? 10);
            $payload = json_encode($body['_payload'] ?? new stdClass());

            $stmt = $pdo->prepare("SELECT row_num, echo, computed FROM public.perf_post(:records, :payload::jsonb)");
            $stmt->bindValue(':records', $records, PDO::PARAM_INT);
            $stmt->bindValue(':payload', $payload, PDO::PARAM_STR);
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
        return;
    }

    if ($path === '/api/perf-nested' && $method === 'GET') {
        $pdo = $pool->get();
        try {
            $records = (int) ($request->get['_records'] ?? 100);
            $depth = (int) ($request->get['_depth'] ?? 3);

            $stmt = $pdo->prepare("SELECT row_num, nested FROM public.perf_nested(:records, :depth)");
            $stmt->bindValue(':records', $records, PDO::PARAM_INT);
            $stmt->bindValue(':depth', $depth, PDO::PARAM_INT);
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
        return;
    }

    if ($path === '/api/perf-large-payload' && $method === 'GET') {
        $pdo = $pool->get();
        try {
            $sizeKb = (int) ($request->get['_size_kb'] ?? 100);

            $stmt = $pdo->prepare("SELECT data FROM public.perf_large_payload(:size_kb)");
            $stmt->bindValue(':size_kb', $sizeKb, PDO::PARAM_INT);
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
        return;
    }

    if ($path === '/api/perf-many-params' && $method === 'GET') {
        $pdo = $pool->get();
        try {
            $stmt = $pdo->prepare("
                SELECT param_count, checksum FROM public.perf_many_params(
                    :p1, :p2::int, :p3::bool, :p4::numeric, :p5,
                    :p6, :p7::int, :p8::bool, :p9::numeric, :p10,
                    :p11, :p12::int, :p13::bool, :p14::numeric, :p15,
                    :p16, :p17::int, :p18::bool, :p19::numeric, :p20
                )
            ");
            $stmt->bindValue(':p1', $request->get['_p1'], PDO::PARAM_STR);
            $stmt->bindValue(':p2', (int) $request->get['_p2'], PDO::PARAM_INT);
            $stmt->bindValue(':p3', $request->get['_p3'] === 'true', PDO::PARAM_BOOL);
            $stmt->bindValue(':p4', $request->get['_p4'], PDO::PARAM_STR);
            $stmt->bindValue(':p5', $request->get['_p5'], PDO::PARAM_STR);
            $stmt->bindValue(':p6', $request->get['_p6'], PDO::PARAM_STR);
            $stmt->bindValue(':p7', (int) $request->get['_p7'], PDO::PARAM_INT);
            $stmt->bindValue(':p8', $request->get['_p8'] === 'true', PDO::PARAM_BOOL);
            $stmt->bindValue(':p9', $request->get['_p9'], PDO::PARAM_STR);
            $stmt->bindValue(':p10', $request->get['_p10'], PDO::PARAM_STR);
            $stmt->bindValue(':p11', $request->get['_p11'], PDO::PARAM_STR);
            $stmt->bindValue(':p12', (int) $request->get['_p12'], PDO::PARAM_INT);
            $stmt->bindValue(':p13', $request->get['_p13'] === 'true', PDO::PARAM_BOOL);
            $stmt->bindValue(':p14', $request->get['_p14'], PDO::PARAM_STR);
            $stmt->bindValue(':p15', $request->get['_p15'], PDO::PARAM_STR);
            $stmt->bindValue(':p16', $request->get['_p16'], PDO::PARAM_STR);
            $stmt->bindValue(':p17', (int) $request->get['_p17'], PDO::PARAM_INT);
            $stmt->bindValue(':p18', $request->get['_p18'] === 'true', PDO::PARAM_BOOL);
            $stmt->bindValue(':p19', $request->get['_p19'], PDO::PARAM_STR);
            $stmt->bindValue(':p20', $request->get['_p20'], PDO::PARAM_STR);
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
        return;
    }

    if ($path !== '/api/perf-test' || $method !== 'GET') {
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
