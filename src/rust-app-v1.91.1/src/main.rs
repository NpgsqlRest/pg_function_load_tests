use actix_web::{get, post, web, App, HttpServer, Result};
use chrono::{DateTime, NaiveDate, NaiveDateTime, NaiveTime, Utc};
use deadpool_postgres::{Config, Pool, Runtime};
use serde::{Deserialize, Serialize};
use tokio_postgres::NoTls;
use uuid::Uuid;

#[derive(Serialize)]
struct TestResult {
    row_num: i32,
    text_val: String,
    varchar_val: String,
    char_val: String,
    smallint_val: i16,
    int_val: i32,
    bigint_val: i64,
    numeric_val: f64,
    real_val: f32,
    double_val: f64,
    bool_val: bool,
    date_val: NaiveDate,
    time_val: NaiveTime,
    timestamp_val: NaiveDateTime,
    timestamptz_val: DateTime<Utc>,
    interval_val: String,
    uuid_val: Uuid,
    json_val: serde_json::Value,
    jsonb_val: serde_json::Value,
    int_array_val: Vec<i32>,
    text_array_val: Vec<String>,
    nullable_text: Option<String>,
    nullable_int: Option<i32>,
}

#[derive(Deserialize)]
struct QueryParams {
    _records: i32,
    _text: String,
    _int: i32,
    _bigint: i64,
    _numeric: String,
    _real: String,
    _double: String,
    _bool: bool,
    _date: String,
    _timestamp: String,
    _timestamptz: String,
    _uuid: String,
    _json: String,
    _jsonb: String,
    _int_array: String,
    _text_array: String,
}

#[get("/api/perf-test")]
async fn get_test_data(
    pool: web::Data<Pool>,
    query: web::Query<QueryParams>,
) -> Result<web::Json<Vec<TestResult>>> {
    let client = pool.get().await.unwrap();

    // Build SQL with inline values for types that tokio-postgres can't handle as parameters
    // Escape single quotes in json by doubling them
    let json_escaped = query._json.replace("'", "''");
    let jsonb_escaped = query._jsonb.replace("'", "''");
    let text_escaped = query._text.replace("'", "''");

    let sql = format!(
        "SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                numeric_val::float8, real_val, double_val, bool_val, date_val, time_val,
                timestamp_val, timestamptz_val, interval_val::text, uuid_val,
                json_val::text, jsonb_val::text, int_array_val, text_array_val,
                nullable_text, nullable_int
         FROM public.perf_test({}, '{}', {}, {}, {}::numeric, {}::real, {}::double precision, {}, '{}'::date, '{}'::timestamp, '{}'::timestamptz, '{}'::uuid, '{}'::json, '{}'::jsonb, '{}'::int[], '{}'::text[])",
        query._records, text_escaped, query._int, query._bigint, query._numeric, query._real, query._double,
        query._bool, query._date, query._timestamp, query._timestamptz, query._uuid,
        json_escaped, jsonb_escaped, query._int_array, query._text_array
    );

    let rows = client
        .query(&sql, &[])
        .await
        .unwrap();

    let results: Vec<TestResult> = rows
        .iter()
        .map(|row| {
            let json_str: String = row.get(17);
            let jsonb_str: String = row.get(18);

            TestResult {
                row_num: row.get(0),
                text_val: row.get(1),
                varchar_val: row.get(2),
                char_val: row.get(3),
                smallint_val: row.get(4),
                int_val: row.get(5),
                bigint_val: row.get(6),
                numeric_val: row.get(7),
                real_val: row.get(8),
                double_val: row.get(9),
                bool_val: row.get(10),
                date_val: row.get(11),
                time_val: row.get(12),
                timestamp_val: row.get(13),
                timestamptz_val: row.get(14),
                interval_val: row.get(15),
                uuid_val: row.get(16),
                json_val: serde_json::from_str(&json_str).unwrap_or(serde_json::Value::Null),
                jsonb_val: serde_json::from_str(&jsonb_str).unwrap_or(serde_json::Value::Null),
                int_array_val: row.get(19),
                text_array_val: row.get(20),
                nullable_text: row.get(21),
                nullable_int: row.get(22),
            }
        })
        .collect();

    Ok(web::Json(results))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let mut cfg = Config::new();
    cfg.host = Some("postgres".to_string());
    cfg.port = Some(5432);
    cfg.user = Some("testuser".to_string());
    cfg.password = Some("testpass".to_string());
    cfg.dbname = Some("testdb".to_string());
    cfg.pool = Some(deadpool_postgres::PoolConfig::new(100));

    let pool = cfg.create_pool(Some(Runtime::Tokio1), NoTls).unwrap();

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .service(get_test_data)
            .service(perf_minimal)
            .service(perf_post)
            .service(perf_nested)
            .service(perf_large_payload)
            .service(perf_many_params)
    })
    .bind("0.0.0.0:5300")?
    .run()
    .await
}

// New benchmark endpoints

#[derive(Serialize)]
struct MinimalResult {
    status: String,
    ts: DateTime<Utc>,
}

#[derive(Serialize)]
struct PostResult {
    row_num: i32,
    echo: serde_json::Value,
    computed: String,
}

#[derive(Deserialize)]
struct PostBody {
    _records: Option<i32>,
    _payload: Option<serde_json::Value>,
}

#[derive(Serialize)]
struct NestedResult {
    row_num: i32,
    nested: serde_json::Value,
}

#[derive(Deserialize)]
struct NestedParams {
    _records: Option<i32>,
    _depth: Option<i32>,
}

#[derive(Serialize)]
struct LargePayloadResult {
    data: String,
}

#[derive(Deserialize)]
struct LargePayloadParams {
    _size_kb: Option<i32>,
}

#[derive(Serialize)]
struct ManyParamsResult {
    param_count: i32,
    checksum: String,
}

#[derive(Deserialize)]
struct ManyParams {
    _p1: String, _p2: i32, _p3: bool, _p4: String, _p5: String,
    _p6: String, _p7: i32, _p8: bool, _p9: String, _p10: String,
    _p11: String, _p12: i32, _p13: bool, _p14: String, _p15: String,
    _p16: String, _p17: i32, _p18: bool, _p19: String, _p20: String,
}

#[get("/api/perf-minimal")]
async fn perf_minimal(pool: web::Data<Pool>) -> Result<web::Json<Vec<MinimalResult>>> {
    let client = pool.get().await.unwrap();
    let rows = client.query("SELECT status, ts FROM public.perf_minimal()", &[]).await.unwrap();
    let results: Vec<MinimalResult> = rows.iter().map(|row| MinimalResult {
        status: row.get(0),
        ts: row.get(1),
    }).collect();
    Ok(web::Json(results))
}

#[post("/api/perf-post")]
async fn perf_post(pool: web::Data<Pool>, body: web::Json<PostBody>) -> Result<web::Json<Vec<PostResult>>> {
    let client = pool.get().await.unwrap();
    let records = body._records.unwrap_or(10);
    let payload = body._payload.as_ref().map(|p| p.to_string()).unwrap_or_else(|| "{}".to_string());

    let sql = format!(
        "SELECT row_num, echo::text, computed FROM public.perf_post({}, '{}'::jsonb)",
        records, payload.replace("'", "''")
    );
    let rows = client.query(&sql, &[]).await.unwrap();

    let results: Vec<PostResult> = rows.iter().map(|row| {
        let echo_str: String = row.get(1);
        PostResult {
            row_num: row.get(0),
            echo: serde_json::from_str(&echo_str).unwrap_or(serde_json::Value::Null),
            computed: row.get(2),
        }
    }).collect();
    Ok(web::Json(results))
}

#[get("/api/perf-nested")]
async fn perf_nested(pool: web::Data<Pool>, query: web::Query<NestedParams>) -> Result<web::Json<Vec<NestedResult>>> {
    let client = pool.get().await.unwrap();
    let records = query._records.unwrap_or(100);
    let depth = query._depth.unwrap_or(3);

    let sql = format!("SELECT row_num, nested::text FROM public.perf_nested({}, {})", records, depth);
    let rows = client.query(&sql, &[]).await.unwrap();

    let results: Vec<NestedResult> = rows.iter().map(|row| {
        let nested_str: String = row.get(1);
        NestedResult {
            row_num: row.get(0),
            nested: serde_json::from_str(&nested_str).unwrap_or(serde_json::Value::Null),
        }
    }).collect();
    Ok(web::Json(results))
}

#[get("/api/perf-large-payload")]
async fn perf_large_payload(pool: web::Data<Pool>, query: web::Query<LargePayloadParams>) -> Result<web::Json<Vec<LargePayloadResult>>> {
    let client = pool.get().await.unwrap();
    let size_kb = query._size_kb.unwrap_or(100);

    let sql = format!("SELECT data FROM public.perf_large_payload({})", size_kb);
    let rows = client.query(&sql, &[]).await.unwrap();

    let results: Vec<LargePayloadResult> = rows.iter().map(|row| LargePayloadResult {
        data: row.get(0),
    }).collect();
    Ok(web::Json(results))
}

#[get("/api/perf-many-params")]
async fn perf_many_params(pool: web::Data<Pool>, query: web::Query<ManyParams>) -> Result<web::Json<Vec<ManyParamsResult>>> {
    let client = pool.get().await.unwrap();

    let sql = format!(
        "SELECT param_count, checksum FROM public.perf_many_params('{}', {}, {}, {}::numeric, '{}', '{}', {}, {}, {}::numeric, '{}', '{}', {}, {}, {}::numeric, '{}', '{}', {}, {}, {}::numeric, '{}')",
        query._p1.replace("'", "''"), query._p2, query._p3, query._p4, query._p5.replace("'", "''"),
        query._p6.replace("'", "''"), query._p7, query._p8, query._p9, query._p10.replace("'", "''"),
        query._p11.replace("'", "''"), query._p12, query._p13, query._p14, query._p15.replace("'", "''"),
        query._p16.replace("'", "''"), query._p17, query._p18, query._p19, query._p20.replace("'", "''")
    );
    let rows = client.query(&sql, &[]).await.unwrap();

    let results: Vec<ManyParamsResult> = rows.iter().map(|row| ManyParamsResult {
        param_count: row.get(0),
        checksum: row.get(1),
    }).collect();
    Ok(web::Json(results))
}
