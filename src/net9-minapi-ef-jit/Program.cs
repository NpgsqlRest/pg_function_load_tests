using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateSlimBuilder(args);
builder.WebHost.UseUrls("http://0.0.0.0:5002");
builder.Services.AddDbContext<DbContext>(options => options.UseNpgsql("Host=postgres;Port=5432;Username=testuser;Password=testpass;Database=testdb"));
builder.Logging.SetMinimumLevel(LogLevel.Warning);
var app = builder.Build();

app.MapGet("/api/perf-test", (DbContext dbContext,
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
    return dbContext.Database.SqlQuery<Result>($"""
        SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
               numeric_val, real_val, double_val, bool_val, date_val, time_val,
               timestamp_val, timestamptz_val, interval_val, uuid_val, json_val::text as json_val, jsonb_val::text as jsonb_val,
               int_array_val, text_array_val, nullable_text, nullable_int
        FROM public.perf_test({_records}, {_text}, {_int}, {_bigint}::bigint, {_numeric}::numeric, {_real}::real, {_double}::double precision, {_bool}, {_date}::date, {_timestamp}::timestamp, {_timestamptz}::timestamptz, {_uuid}::uuid, {_json}::json, {_jsonb}::jsonb, {_int_array}, {_text_array})
        """);
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
