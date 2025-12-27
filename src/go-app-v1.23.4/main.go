package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Result struct {
	RowNum         int       `json:"row_num"`
	TextVal        string    `json:"text_val"`
	VarcharVal     string    `json:"varchar_val"`
	CharVal        string    `json:"char_val"`
	SmallintVal    int16     `json:"smallint_val"`
	IntVal         int32     `json:"int_val"`
	BigintVal      int64     `json:"bigint_val"`
	NumericVal     float64   `json:"numeric_val"`
	RealVal        float32   `json:"real_val"`
	DoubleVal      float64   `json:"double_val"`
	BoolVal        bool      `json:"bool_val"`
	DateVal        time.Time `json:"date_val"`
	TimeVal        string    `json:"time_val"`
	TimestampVal   time.Time `json:"timestamp_val"`
	TimestamptzVal time.Time `json:"timestamptz_val"`
	IntervalVal    string    `json:"interval_val"`
	UuidVal        string    `json:"uuid_val"`
	JsonVal        string    `json:"json_val"`
	JsonbVal       string    `json:"jsonb_val"`
	IntArrayVal    []int32   `json:"int_array_val"`
	TextArrayVal   []string  `json:"text_array_val"`
	NullableText   *string   `json:"nullable_text"`
	NullableInt    *int32    `json:"nullable_int"`
}

var pool *pgxpool.Pool

func main() {
	ctx := context.Background()

	connString := "host=postgres port=5432 user=testuser password=testpass dbname=testdb pool_max_conns=100"
	var err error
	pool, err = pgxpool.New(ctx, connString)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	http.HandleFunc("/api/perf-test", handleTestData)

	port := os.Getenv("PORT")
	if port == "" {
		port = "5200"
	}

	fmt.Printf("Go server starting on port %s...\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handleTestData(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	records := r.URL.Query().Get("_records")
	if records == "" {
		http.Error(w, "Missing _records parameter", http.StatusBadRequest)
		return
	}
	text := r.URL.Query().Get("_text")
	intVal := r.URL.Query().Get("_int")
	bigint := r.URL.Query().Get("_bigint")
	numeric := r.URL.Query().Get("_numeric")
	real := r.URL.Query().Get("_real")
	double := r.URL.Query().Get("_double")
	boolVal := r.URL.Query().Get("_bool") == "true"
	date := r.URL.Query().Get("_date")
	timestamp := r.URL.Query().Get("_timestamp")
	timestamptz := r.URL.Query().Get("_timestamptz")
	uuid := r.URL.Query().Get("_uuid")
	jsonVal := r.URL.Query().Get("_json")
	jsonb := r.URL.Query().Get("_jsonb")
	intArray := r.URL.Query().Get("_int_array")
	textArray := r.URL.Query().Get("_text_array")

	ctx := context.Background()
	rows, err := pool.Query(ctx, `
		SELECT row_num, text_val, varchar_val, char_val, smallint_val, int_val, bigint_val,
		       numeric_val, real_val, double_val, bool_val, date_val, time_val::text,
		       timestamp_val, timestamptz_val, interval_val::text, uuid_val::text,
		       json_val::text, jsonb_val::text, int_array_val, text_array_val,
		       nullable_text, nullable_int
		FROM public.perf_test($1::int, $2, $3::int, $4::bigint, $5::numeric, $6::real, $7::double precision, $8, $9::date, $10::timestamp, $11::timestamptz, $12::uuid, $13::json, $14::jsonb, $15::int[], $16::text[])
	`, records, text, intVal, bigint, numeric, real, double, boolVal, date, timestamp, timestamptz, uuid, jsonVal, jsonb, intArray, textArray)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []Result
	for rows.Next() {
		var res Result
		err := rows.Scan(
			&res.RowNum, &res.TextVal, &res.VarcharVal, &res.CharVal,
			&res.SmallintVal, &res.IntVal, &res.BigintVal,
			&res.NumericVal, &res.RealVal, &res.DoubleVal, &res.BoolVal,
			&res.DateVal, &res.TimeVal, &res.TimestampVal, &res.TimestamptzVal,
			&res.IntervalVal, &res.UuidVal, &res.JsonVal, &res.JsonbVal,
			&res.IntArrayVal, &res.TextArrayVal, &res.NullableText, &res.NullableInt,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, res)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}
