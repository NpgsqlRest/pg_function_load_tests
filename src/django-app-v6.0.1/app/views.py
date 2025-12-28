import json
from django.http import JsonResponse
from django.db import connection
from django.views.decorators.csrf import csrf_exempt

def get_test_data(request):
    records = int(request.GET.get('_records'))
    text_val = request.GET.get('_text')
    int_val = int(request.GET.get('_int'))
    bigint_val = int(request.GET.get('_bigint'))
    numeric_val = request.GET.get('_numeric')
    real_val = request.GET.get('_real')
    double_val = request.GET.get('_double')
    bool_val = request.GET.get('_bool', '').lower() == 'true'
    date_val = request.GET.get('_date')
    timestamp_val = request.GET.get('_timestamp')
    timestamptz_val = request.GET.get('_timestamptz')
    uuid_val = request.GET.get('_uuid')
    json_val = request.GET.get('_json')
    jsonb_val = request.GET.get('_jsonb')
    int_array_val = request.GET.get('_int_array')
    text_array_val = request.GET.get('_text_array')

    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                   numeric_val, real_val, double_val, bool_val, date_val, time_val,
                   timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                   int_array_val, text_array_val, nullable_text, nullable_int
            FROM public.perf_test(%s, %s, %s, %s, %s, %s, %s, %s, %s::date, %s::timestamp, %s::timestamptz, %s::uuid, %s::json, %s::jsonb, %s::int[], %s::text[])
            """,
            [records, text_val, int_val, bigint_val, numeric_val, real_val, double_val, bool_val, date_val, timestamp_val, timestamptz_val, uuid_val, json_val, jsonb_val, int_array_val, text_array_val]
        )
        columns = [col[0] for col in cursor.description]
        results = []
        for row in cursor.fetchall():
            row_dict = {}
            for col, val in zip(columns, row):
                if hasattr(val, 'isoformat'):
                    row_dict[col] = val.isoformat()
                elif hasattr(val, 'total_seconds'):
                    row_dict[col] = str(val)
                else:
                    row_dict[col] = val
            results.append(row_dict)

    return JsonResponse(results, safe=False)


# New benchmark endpoints

def perf_minimal(request):
    with connection.cursor() as cursor:
        cursor.execute("SELECT status, ts FROM public.perf_minimal()")
        columns = [col[0] for col in cursor.description]
        results = []
        for row in cursor.fetchall():
            row_dict = {}
            for col, val in zip(columns, row):
                if hasattr(val, 'isoformat'):
                    row_dict[col] = val.isoformat()
                else:
                    row_dict[col] = val
            results.append(row_dict)
    return JsonResponse(results, safe=False)


@csrf_exempt
def perf_post(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    body = json.loads(request.body)
    records = int(body.get('_records', 10))
    payload = json.dumps(body.get('_payload', {}))

    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT row_num, echo, computed FROM public.perf_post(%s, %s::jsonb)",
            [records, payload]
        )
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

    return JsonResponse(results, safe=False)


def perf_nested(request):
    records = int(request.GET.get('_records', 100))
    depth = int(request.GET.get('_depth', 3))

    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT row_num, nested FROM public.perf_nested(%s, %s)",
            [records, depth]
        )
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

    return JsonResponse(results, safe=False)


def perf_large_payload(request):
    size_kb = int(request.GET.get('_size_kb', 100))

    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT data FROM public.perf_large_payload(%s)",
            [size_kb]
        )
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

    return JsonResponse(results, safe=False)


def perf_many_params(request):
    params = [
        request.GET.get('_p1'), int(request.GET.get('_p2', 0)), request.GET.get('_p3', 'true').lower() == 'true',
        request.GET.get('_p4'), request.GET.get('_p5'),
        request.GET.get('_p6'), int(request.GET.get('_p7', 0)), request.GET.get('_p8', 'true').lower() == 'true',
        request.GET.get('_p9'), request.GET.get('_p10'),
        request.GET.get('_p11'), int(request.GET.get('_p12', 0)), request.GET.get('_p13', 'true').lower() == 'true',
        request.GET.get('_p14'), request.GET.get('_p15'),
        request.GET.get('_p16'), int(request.GET.get('_p17', 0)), request.GET.get('_p18', 'true').lower() == 'true',
        request.GET.get('_p19'), request.GET.get('_p20'),
    ]

    with connection.cursor() as cursor:
        cursor.execute(
            """SELECT param_count, checksum FROM public.perf_many_params(
                %s, %s, %s, %s::numeric, %s,
                %s, %s, %s, %s::numeric, %s,
                %s, %s, %s, %s::numeric, %s,
                %s, %s, %s, %s::numeric, %s
            )""",
            params
        )
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

    return JsonResponse(results, safe=False)
