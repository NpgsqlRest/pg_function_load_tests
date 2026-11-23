using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

// The control for the two libraries: the same endpoints and the same result types as the Dapper and EF
// services, with nothing between the handler and Npgsql. A command with positional parameters, a reader,
// and the columns read by position into the result objects.
var builder = WebApplication.CreateSlimBuilder(args);
builder.WebHost.UseUrls("http://0.0.0.0:5016");
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
    await using var command = dataSource.CreateCommand(
        """
        SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
               numeric_val, real_val, double_val, bool_val, date_val, time_val,
               timestamp_val, timestamptz_val, interval_val, uuid_val, json_val::text as json_val, jsonb_val::text as jsonb_val,
               int_array_val, text_array_val, nullable_text, nullable_int
        FROM public.perf_test($1, $2, $3, $4::bigint, $5::numeric, $6::real, $7::double precision, $8, $9::date, $10::timestamp, $11::timestamptz, $12::uuid, $13::json, $14::jsonb, $15, $16)
        """);
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _records });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _text });
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _int });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _bigint });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _numeric });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _real });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _double });
    command.Parameters.Add(new NpgsqlParameter<bool> { TypedValue = _bool });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _date });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _timestamp });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _timestamptz });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _uuid });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _json });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = _jsonb });
    command.Parameters.Add(new NpgsqlParameter<int[]> { TypedValue = _int_array });
    command.Parameters.Add(new NpgsqlParameter<string[]> { TypedValue = _text_array });

    var results = new List<Result>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new Result
        {
            row_num = reader.GetInt32(0),
            text_val = reader.GetString(1),
            varchar_val = reader.GetString(2),
            char_val = reader.GetString(3),
            smallint_val = reader.GetInt16(4),
            int_val = reader.GetInt32(5),
            bigint_val = reader.GetInt64(6),
            numeric_val = reader.GetDecimal(7),
            real_val = reader.GetFloat(8),
            double_val = reader.GetDouble(9),
            bool_val = reader.GetBoolean(10),
            date_val = reader.GetFieldValue<DateOnly>(11),
            time_val = reader.GetFieldValue<TimeOnly>(12),
            timestamp_val = reader.GetDateTime(13),
            timestamptz_val = reader.GetFieldValue<DateTimeOffset>(14),
            interval_val = reader.GetTimeSpan(15),
            uuid_val = reader.GetGuid(16),
            json_val = reader.GetString(17),
            jsonb_val = reader.GetString(18),
            int_array_val = reader.GetFieldValue<int[]>(19),
            text_array_val = reader.GetFieldValue<string[]>(20),
            nullable_text = reader.IsDBNull(21) ? null : reader.GetString(21),
            nullable_int = reader.IsDBNull(22) ? null : reader.GetInt32(22),
        });
    }
    return results;
});

app.MapGet("/api/perf-minimal", async (NpgsqlDataSource dataSource) =>
{
    await using var command = dataSource.CreateCommand("SELECT status, ts FROM public.perf_minimal()");
    var results = new List<MinimalResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new MinimalResult { status = reader.GetString(0), ts = reader.GetFieldValue<DateTimeOffset>(1) });
    }
    return results;
});

app.MapPost("/api/perf-post", async (NpgsqlDataSource dataSource, PostBody body) =>
{
    await using var command = dataSource.CreateCommand("SELECT row_num, echo::text as echo, computed FROM public.perf_post($1, $2::jsonb)");
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = body._records ?? 10 });
    command.Parameters.Add(new NpgsqlParameter<string> { TypedValue = body._payload != null ? JsonSerializer.Serialize(body._payload) : "{}" });
    var results = new List<PostResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new PostResult { row_num = reader.GetInt32(0), echo = reader.GetString(1), computed = reader.GetString(2) });
    }
    return results;
});

app.MapGet("/api/perf-nested", async (NpgsqlDataSource dataSource, [FromQuery] int _records = 100, [FromQuery] int _depth = 3) =>
{
    await using var command = dataSource.CreateCommand("SELECT row_num, nested::text as nested FROM public.perf_nested($1, $2)");
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _records });
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _depth });
    var results = new List<NestedResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new NestedResult { row_num = reader.GetInt32(0), nested = reader.GetString(1) });
    }
    return results;
});

app.MapGet("/api/perf-large-payload", async (NpgsqlDataSource dataSource, [FromQuery] int _size_kb = 100) =>
{
    await using var command = dataSource.CreateCommand("SELECT data FROM public.perf_large_payload($1)");
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _size_kb });
    var results = new List<LargePayloadResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new LargePayloadResult { data = reader.GetString(0) });
    }
    return results;
});

app.MapGet("/api/perf-many-params", async (NpgsqlDataSource dataSource,
    [FromQuery] string _p1, [FromQuery] int _p2, [FromQuery] bool _p3, [FromQuery] string _p4, [FromQuery] string _p5,
    [FromQuery] string _p6, [FromQuery] int _p7, [FromQuery] bool _p8, [FromQuery] string _p9, [FromQuery] string _p10,
    [FromQuery] string _p11, [FromQuery] int _p12, [FromQuery] bool _p13, [FromQuery] string _p14, [FromQuery] string _p15,
    [FromQuery] string _p16, [FromQuery] int _p17, [FromQuery] bool _p18, [FromQuery] string _p19, [FromQuery] string _p20) =>
{
    await using var command = dataSource.CreateCommand(
        """
        SELECT param_count, checksum FROM public.perf_many_params(
            $1, $2, $3, $4::numeric, $5,
            $6, $7, $8, $9::numeric, $10,
            $11, $12, $13, $14::numeric, $15,
            $16, $17, $18, $19::numeric, $20
        )
        """);
    object[] values = [_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12, _p13, _p14, _p15, _p16, _p17, _p18, _p19, _p20];
    foreach (var value in values)
    {
        command.Parameters.Add(value switch
        {
            int i => new NpgsqlParameter<int> { TypedValue = i },
            bool b => new NpgsqlParameter<bool> { TypedValue = b },
            _ => new NpgsqlParameter<string> { TypedValue = (string)value }
        });
    }
    var results = new List<ManyParamsResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new ManyParamsResult { param_count = reader.GetInt32(0), checksum = reader.GetString(1) });
    }
    return results;
});

// Table scenarios
app.MapGet("/api/perf-table-get", async (NpgsqlDataSource dataSource, [FromQuery] int _id) =>
{
    await using var command = dataSource.CreateCommand("SELECT id, name, category, price, active, created_at FROM public.perf_table_get($1)");
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _id });
    var results = new List<TableItemResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new TableItemResult
        {
            id = reader.GetInt32(0),
            name = reader.GetString(1),
            category = reader.GetInt32(2),
            price = reader.GetDecimal(3),
            active = reader.GetBoolean(4),
            created_at = reader.GetFieldValue<DateTimeOffset>(5),
        });
    }
    return results;
});

app.MapGet("/api/perf-table-list", async (NpgsqlDataSource dataSource, [FromQuery] int _category, [FromQuery] int _after_id, [FromQuery] int _limit) =>
{
    await using var command = dataSource.CreateCommand("SELECT id, name, category, price, active, created_at FROM public.perf_table_list($1, $2, $3)");
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _category });
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _after_id });
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = _limit });
    var results = new List<TableItemResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new TableItemResult
        {
            id = reader.GetInt32(0),
            name = reader.GetString(1),
            category = reader.GetInt32(2),
            price = reader.GetDecimal(3),
            active = reader.GetBoolean(4),
            created_at = reader.GetFieldValue<DateTimeOffset>(5),
        });
    }
    return results;
});

app.MapPost("/api/perf-table-insert", async (NpgsqlDataSource dataSource, TableInsertBody body) =>
{
    await using var command = dataSource.CreateCommand("SELECT id, item_id, quantity, note, created_at FROM public.perf_table_insert($1, $2, $3)");
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = body._item_id });
    command.Parameters.Add(new NpgsqlParameter<int> { TypedValue = body._quantity });
    command.Parameters.Add(new NpgsqlParameter<string?> { TypedValue = body._note });
    var results = new List<TableInsertResult>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new TableInsertResult
        {
            id = reader.GetInt64(0),
            item_id = reader.GetInt32(1),
            quantity = reader.GetInt32(2),
            note = reader.IsDBNull(3) ? null : reader.GetString(3),
            created_at = reader.GetFieldValue<DateTimeOffset>(4),
        });
    }
    return results;
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

// Table scenario types
public class TableItemResult { public int id { get; set; } public string? name { get; set; } public int category { get; set; } public decimal price { get; set; } public bool active { get; set; } public DateTimeOffset created_at { get; set; } }
public class TableInsertBody { public int _item_id { get; set; } public int _quantity { get; set; } public string? _note { get; set; } }
public class TableInsertResult { public long id { get; set; } public int item_id { get; set; } public int quantity { get; set; } public string? note { get; set; } public DateTimeOffset created_at { get; set; } }
