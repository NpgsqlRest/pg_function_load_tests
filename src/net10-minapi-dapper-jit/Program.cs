using System.Text.Json;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

var builder = WebApplication.CreateSlimBuilder(args);
builder.WebHost.UseUrls("http://0.0.0.0:5004");
builder.Logging.SetMinimumLevel(LogLevel.None);
builder.Services.AddSingleton(new NpgsqlDataSourceBuilder("Host=postgres;Port=5432;Username=testuser;Password=testpass;Database=testdb").Build());
var app = builder.Build();

app.MapGet("/api/perf-test", async (NpgsqlDataSource dataSource,
    [FromQuery] int _records,
    [FromQuery] string _text,
    [FromQuery] int _int,
    [FromQuery] string _bigint,
    [FromQuery] string _numeric,
    [FromQuery] string _real,
    [FromQuery] string _double,
    [FromQuery] bool _bool,
    [FromQuery] string _date,
    [FromQuery] string _timestamp,
    [FromQuery] string _timestamptz,
    [FromQuery] string _uuid,
    [FromQuery] string _json,
    [FromQuery] string _jsonb,
    [FromQuery] int[] _int_array,
    [FromQuery] string[] _text_array) =>
{
    await using var connection = await dataSource.OpenConnectionAsync();
    return await connection.QueryAsync<Result>(
        """
        SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
               numeric_val, real_val, double_val, bool_val, date_val, time_val,
               timestamp_val, timestamptz_val, interval_val, uuid_val, json_val::text as json_val, jsonb_val::text as jsonb_val,
               int_array_val, text_array_val, nullable_text, nullable_int
        FROM public.perf_test(@_records, @_text, @_int, @_bigint::bigint, @_numeric::numeric, @_real::real, @_double::double precision, @_bool, @_date::date, @_timestamp::timestamp, @_timestamptz::timestamptz, @_uuid::uuid, @_json::json, @_jsonb::jsonb, @_int_array, @_text_array)
        """, new { _records, _text, _int, _bigint, _numeric, _real, _double, _bool, _date, _timestamp, _timestamptz, _uuid, _json, _jsonb, _int_array, _text_array });
});

// New benchmark endpoints
app.MapGet("/api/perf-minimal", async (NpgsqlDataSource dataSource) =>
{
    await using var connection = await dataSource.OpenConnectionAsync();
    return await connection.QueryAsync<MinimalResult>("SELECT status, ts FROM public.perf_minimal()");
});

app.MapPost("/api/perf-post", async (NpgsqlDataSource dataSource, PostBody body) =>
{
    await using var connection = await dataSource.OpenConnectionAsync();
    var records = body._records ?? 10;
    var payload = body._payload != null ? System.Text.Json.JsonSerializer.Serialize(body._payload) : "{}";
    return await connection.QueryAsync<PostResult>(
        "SELECT row_num, echo::text as echo, computed FROM public.perf_post(@records, @payload::jsonb)",
        new { records, payload });
});

app.MapGet("/api/perf-nested", async (NpgsqlDataSource dataSource, [FromQuery] int _records = 100, [FromQuery] int _depth = 3) =>
{
    await using var connection = await dataSource.OpenConnectionAsync();
    return await connection.QueryAsync<NestedResult>(
        "SELECT row_num, nested::text as nested FROM public.perf_nested(@_records, @_depth)",
        new { _records, _depth });
});

app.MapGet("/api/perf-large-payload", async (NpgsqlDataSource dataSource, [FromQuery] int _size_kb = 100) =>
{
    await using var connection = await dataSource.OpenConnectionAsync();
    return await connection.QueryAsync<LargePayloadResult>(
        "SELECT data FROM public.perf_large_payload(@_size_kb)",
        new { _size_kb });
});

app.MapGet("/api/perf-many-params", async (NpgsqlDataSource dataSource,
    [FromQuery] string _p1, [FromQuery] int _p2, [FromQuery] bool _p3, [FromQuery] string _p4, [FromQuery] string _p5,
    [FromQuery] string _p6, [FromQuery] int _p7, [FromQuery] bool _p8, [FromQuery] string _p9, [FromQuery] string _p10,
    [FromQuery] string _p11, [FromQuery] int _p12, [FromQuery] bool _p13, [FromQuery] string _p14, [FromQuery] string _p15,
    [FromQuery] string _p16, [FromQuery] int _p17, [FromQuery] bool _p18, [FromQuery] string _p19, [FromQuery] string _p20) =>
{
    await using var connection = await dataSource.OpenConnectionAsync();
    return await connection.QueryAsync<ManyParamsResult>(
        """
        SELECT param_count, checksum FROM public.perf_many_params(
            @_p1, @_p2, @_p3, @_p4::numeric, @_p5,
            @_p6, @_p7, @_p8, @_p9::numeric, @_p10,
            @_p11, @_p12, @_p13, @_p14::numeric, @_p15,
            @_p16, @_p17, @_p18, @_p19::numeric, @_p20
        )
        """,
        new { _p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12, _p13, _p14, _p15, _p16, _p17, _p18, _p19, _p20 });
});

app.Run();

public class Result
{
    public int row_num { get; set; }
    public string? text_val { get; set; }
    public string? varchar_val { get; set; }
    public string? char_val { get; set; }
    public short smallint_val { get; set; }
    public int int_val { get; set; }
    public long bigint_val { get; set; }
    public decimal numeric_val { get; set; }
    public float real_val { get; set; }
    public double double_val { get; set; }
    public bool bool_val { get; set; }
    public DateOnly date_val { get; set; }
    public TimeOnly time_val { get; set; }
    public DateTime timestamp_val { get; set; }
    public DateTimeOffset timestamptz_val { get; set; }
    public TimeSpan interval_val { get; set; }
    public Guid uuid_val { get; set; }
    [System.Text.Json.Serialization.JsonConverter(typeof(RawJsonConverter))]
    public string? json_val { get; set; }
    [System.Text.Json.Serialization.JsonConverter(typeof(RawJsonConverter))]
    public string? jsonb_val { get; set; }
    public int[]? int_array_val { get; set; }
    public string[]? text_array_val { get; set; }
    public string? nullable_text { get; set; }
    public int? nullable_int { get; set; }
}

public class RawJsonConverter : System.Text.Json.Serialization.JsonConverter<string?>
{
    public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) => reader.GetString();
    public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options)
    {
        if (value is null) writer.WriteNullValue();
        else writer.WriteRawValue(value);
    }
}

// New benchmark result types
public class MinimalResult { public string? status { get; set; } public DateTimeOffset ts { get; set; } }
public class PostBody { public int? _records { get; set; } public object? _payload { get; set; } }
public class PostResult { public int row_num { get; set; } [System.Text.Json.Serialization.JsonConverter(typeof(RawJsonConverter))] public string? echo { get; set; } public string? computed { get; set; } }
public class NestedResult { public int row_num { get; set; } [System.Text.Json.Serialization.JsonConverter(typeof(RawJsonConverter))] public string? nested { get; set; } }
public class LargePayloadResult { public string? data { get; set; } }
public class ManyParamsResult { public int param_count { get; set; } public string? checksum { get; set; } }
