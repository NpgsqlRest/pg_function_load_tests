<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

// The six benchmark endpoints, as route closures over the query builder's raw select: the shortest way a
// Laravel application calls a PostgreSQL function. Values come back as PDO returns them (json and arrays as
// text), the same as in the Swoole service.

Route::get('/perf-test', function (Request $request) {
    return response()->json(DB::select(
        'SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                numeric_val, real_val, double_val, bool_val, date_val, time_val,
                timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                int_array_val, text_array_val, nullable_text, nullable_int
         FROM public.perf_test(?::int, ?, ?::int, ?::bigint, ?::numeric, ?::real, ?::double precision, ?::bool, ?::date, ?::timestamp, ?::timestamptz, ?::uuid, ?::json, ?::jsonb, ?::int[], ?::text[])',
        [
            (int) $request->query('_records'), $request->query('_text'), (int) $request->query('_int'),
            $request->query('_bigint'), $request->query('_numeric'), $request->query('_real'), $request->query('_double'),
            $request->query('_bool') === 'true' ? 'true' : 'false', $request->query('_date'), $request->query('_timestamp'),
            $request->query('_timestamptz'), $request->query('_uuid'), $request->query('_json'), $request->query('_jsonb'),
            $request->query('_int_array'), $request->query('_text_array'),
        ]
    ));
});

Route::get('/perf-minimal', function () {
    return response()->json(DB::select('SELECT status, ts FROM public.perf_minimal()'));
});

Route::post('/perf-post', function (Request $request) {
    return response()->json(DB::select(
        'SELECT row_num, echo, computed FROM public.perf_post(?::int, ?::jsonb)',
        [(int) $request->input('_records', 10), json_encode($request->input('_payload', new stdClass()))]
    ));
});

Route::get('/perf-nested', function (Request $request) {
    return response()->json(DB::select(
        'SELECT row_num, nested FROM public.perf_nested(?::int, ?::int)',
        [(int) $request->query('_records', 100), (int) $request->query('_depth', 3)]
    ));
});

Route::get('/perf-large-payload', function (Request $request) {
    return response()->json(DB::select(
        'SELECT data FROM public.perf_large_payload(?::int)',
        [(int) $request->query('_size_kb', 100)]
    ));
});

Route::get('/perf-many-params', function (Request $request) {
    $q = $request->query();
    $bool = fn (string $key) => ($q[$key] ?? '') === 'true' ? 'true' : 'false';
    return response()->json(DB::select(
        'SELECT param_count, checksum FROM public.perf_many_params(
            ?, ?::int, ?::bool, ?::numeric, ?,
            ?, ?::int, ?::bool, ?::numeric, ?,
            ?, ?::int, ?::bool, ?::numeric, ?,
            ?, ?::int, ?::bool, ?::numeric, ?
        )',
        [
            $q['_p1'], (int) $q['_p2'], $bool('_p3'), $q['_p4'], $q['_p5'],
            $q['_p6'], (int) $q['_p7'], $bool('_p8'), $q['_p9'], $q['_p10'],
            $q['_p11'], (int) $q['_p12'], $bool('_p13'), $q['_p14'], $q['_p15'],
            $q['_p16'], (int) $q['_p17'], $bool('_p18'), $q['_p19'], $q['_p20'],
        ]
    ));
});

Route::get('/perf-table-get', function (Request $request) {
    return response()->json(DB::select(
        'SELECT id, name, category, price, active, created_at FROM public.perf_table_get(?::int)',
        [(int) $request->query('_id')]
    ));
});

Route::get('/perf-table-list', function (Request $request) {
    return response()->json(DB::select(
        'SELECT id, name, category, price, active, created_at FROM public.perf_table_list(?::int, ?::int, ?::int)',
        [(int) $request->query('_category'), (int) $request->query('_after_id'), (int) $request->query('_limit')]
    ));
});

Route::post('/perf-table-insert', function (Request $request) {
    return response()->json(DB::select(
        'SELECT id, item_id, quantity, note, created_at FROM public.perf_table_insert(?::int, ?::int, ?)',
        [(int) $request->input('_item_id'), (int) $request->input('_quantity'), $request->input('_note')]
    ));
});
