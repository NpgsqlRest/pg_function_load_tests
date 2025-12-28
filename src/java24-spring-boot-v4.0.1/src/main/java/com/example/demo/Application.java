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

}
