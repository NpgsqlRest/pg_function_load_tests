from django.http import JsonResponse
from django.db import connection

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
