package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.sql.Array;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@SpringBootApplication
@RestController
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/api/perf-test")
    public ResponseEntity<?> getTestData(
            @RequestParam("_records") Integer numRecords,
            @RequestParam("_text") String text,
            @RequestParam("_int") Integer intVal,
            @RequestParam("_bigint") String bigint,
            @RequestParam("_numeric") String numeric,
            @RequestParam("_real") String real,
            @RequestParam("_double") String doubleVal,
            @RequestParam("_bool") Boolean boolVal,
            @RequestParam("_date") String date,
            @RequestParam("_timestamp") String timestamp,
            @RequestParam("_timestamptz") String timestamptz,
            @RequestParam("_uuid") String uuid,
            @RequestParam("_json") String json,
            @RequestParam("_jsonb") String jsonb,
            @RequestParam("_int_array") String intArray,
            @RequestParam("_text_array") String textArray) {
        String sql = """
            SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
                   numeric_val, real_val, double_val, bool_val, date_val, time_val,
                   timestamp_val, timestamptz_val, interval_val, uuid_val, json_val, jsonb_val,
                   int_array_val, text_array_val, nullable_text, nullable_int
            FROM public.perf_test(?, ?, ?, ?::bigint, ?::numeric, ?::real, ?::double precision, ?, ?::date, ?::timestamp, ?::timestamptz, ?::uuid, ?::json, ?::jsonb, ?::int[], ?::text[])
            """;

        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql, numRecords, text, intVal, bigint, numeric, real, doubleVal, boolVal, date, timestamp, timestamptz, uuid, json, jsonb, intArray, textArray);

        // Convert PgArray to native Java arrays
        for (Map<String, Object> row : result) {
            convertArrayFields(row, "int_array_val");
            convertArrayFields(row, "text_array_val");
        }

        return ResponseEntity.ok(result);
    }

    private void convertArrayFields(Map<String, Object> row, String fieldName) {
        Object value = row.get(fieldName);
        if (value instanceof Array) {
            try {
                row.put(fieldName, ((Array) value).getArray());
            } catch (SQLException e) {
                row.put(fieldName, null);
            }
        }
    }

    // New benchmark endpoints

    @GetMapping("/api/perf-minimal")
    public ResponseEntity<?> perfMinimal() {
        String sql = "SELECT status, ts FROM public.perf_minimal()";
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/api/perf-post")
    public ResponseEntity<?> perfPost(@RequestBody Map<String, Object> body) {
        Integer records = body.get("_records") != null ? ((Number) body.get("_records")).intValue() : 10;
        String payload = "{}";
        if (body.get("_payload") != null) {
            try {
                payload = new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(body.get("_payload"));
            } catch (Exception e) {
                payload = "{}";
            }
        }
        String sql = "SELECT row_num, echo, computed FROM public.perf_post(?, ?::jsonb)";
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql, records, payload);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/api/perf-nested")
    public ResponseEntity<?> perfNested(
            @RequestParam(value = "_records", defaultValue = "100") Integer records,
            @RequestParam(value = "_depth", defaultValue = "3") Integer depth) {
        String sql = "SELECT row_num, nested FROM public.perf_nested(?, ?)";
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql, records, depth);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/api/perf-large-payload")
    public ResponseEntity<?> perfLargePayload(
            @RequestParam(value = "_size_kb", defaultValue = "100") Integer sizeKb) {
        String sql = "SELECT data FROM public.perf_large_payload(?)";
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql, sizeKb);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/api/perf-many-params")
    public ResponseEntity<?> perfManyParams(
            @RequestParam("_p1") String p1, @RequestParam("_p2") Integer p2, @RequestParam("_p3") Boolean p3, @RequestParam("_p4") String p4, @RequestParam("_p5") String p5,
            @RequestParam("_p6") String p6, @RequestParam("_p7") Integer p7, @RequestParam("_p8") Boolean p8, @RequestParam("_p9") String p9, @RequestParam("_p10") String p10,
            @RequestParam("_p11") String p11, @RequestParam("_p12") Integer p12, @RequestParam("_p13") Boolean p13, @RequestParam("_p14") String p14, @RequestParam("_p15") String p15,
            @RequestParam("_p16") String p16, @RequestParam("_p17") Integer p17, @RequestParam("_p18") Boolean p18, @RequestParam("_p19") String p19, @RequestParam("_p20") String p20) {
        String sql = """
            SELECT param_count, checksum FROM public.perf_many_params(
                ?, ?, ?, ?::numeric, ?,
                ?, ?, ?, ?::numeric, ?,
                ?, ?, ?, ?::numeric, ?,
                ?, ?, ?, ?::numeric, ?
            )
            """;
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql,
            p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20);
        return ResponseEntity.ok(result);
    }

}
