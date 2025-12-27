use actix_web::{get, web, App, HttpServer, Result};
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
    })
    .bind("0.0.0.0:5300")?
    .run()
    .await
}
