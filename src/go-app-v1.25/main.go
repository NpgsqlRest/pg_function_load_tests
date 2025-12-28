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

// Result types for new benchmark endpoints
type MinimalResult struct {
	Status string    `json:"status"`
	Ts     time.Time `json:"ts"`
}

type PostResult struct {
	RowNum   int    `json:"row_num"`
	Echo     string `json:"echo"`
	Computed string `json:"computed"`
}

type NestedResult struct {
	RowNum int    `json:"row_num"`
	Nested string `json:"nested"`
}

type LargePayloadResult struct {
	Data string `json:"data"`
}

type ManyParamsResult struct {
	ParamCount int    `json:"param_count"`
	Checksum   string `json:"checksum"`
}

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
	http.HandleFunc("/api/perf-minimal", handleMinimal)
	http.HandleFunc("/api/perf-post", handlePost)
	http.HandleFunc("/api/perf-nested", handleNested)
	http.HandleFunc("/api/perf-large-payload", handleLargePayload)
	http.HandleFunc("/api/perf-many-params", handleManyParams)

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

// New benchmark endpoints

func handleMinimal(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := context.Background()
	rows, err := pool.Query(ctx, "SELECT status, ts FROM public.perf_minimal()")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []MinimalResult
	for rows.Next() {
		var res MinimalResult
		if err := rows.Scan(&res.Status, &res.Ts); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, res)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func handlePost(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body struct {
		Records int            `json:"_records"`
		Payload map[string]any `json:"_payload"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if body.Records == 0 {
		body.Records = 10
	}
	payloadBytes, _ := json.Marshal(body.Payload)

	ctx := context.Background()
	rows, err := pool.Query(ctx, "SELECT row_num, echo::text, computed FROM public.perf_post($1, $2::jsonb)",
		body.Records, string(payloadBytes))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []PostResult
	for rows.Next() {
		var res PostResult
		if err := rows.Scan(&res.RowNum, &res.Echo, &res.Computed); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, res)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func handleNested(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	records := r.URL.Query().Get("_records")
	if records == "" {
		records = "100"
	}
	depth := r.URL.Query().Get("_depth")
	if depth == "" {
		depth = "3"
	}

	ctx := context.Background()
	rows, err := pool.Query(ctx, "SELECT row_num, nested::text FROM public.perf_nested($1::int, $2::int)",
		records, depth)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []NestedResult
	for rows.Next() {
		var res NestedResult
		if err := rows.Scan(&res.RowNum, &res.Nested); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, res)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func handleLargePayload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sizeKb := r.URL.Query().Get("_size_kb")
	if sizeKb == "" {
		sizeKb = "100"
	}

	ctx := context.Background()
	rows, err := pool.Query(ctx, "SELECT data FROM public.perf_large_payload($1::int)", sizeKb)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []LargePayloadResult
	for rows.Next() {
		var res LargePayloadResult
		if err := rows.Scan(&res.Data); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, res)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func handleManyParams(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	q := r.URL.Query()
	p3 := q.Get("_p3") == "true"
	p8 := q.Get("_p8") == "true"
	p13 := q.Get("_p13") == "true"
	p18 := q.Get("_p18") == "true"

	ctx := context.Background()
	rows, err := pool.Query(ctx, `
		SELECT param_count, checksum FROM public.perf_many_params(
			$1, $2::int, $3, $4::numeric, $5,
			$6, $7::int, $8, $9::numeric, $10,
			$11, $12::int, $13, $14::numeric, $15,
			$16, $17::int, $18, $19::numeric, $20
		)`,
		q.Get("_p1"), q.Get("_p2"), p3, q.Get("_p4"), q.Get("_p5"),
		q.Get("_p6"), q.Get("_p7"), p8, q.Get("_p9"), q.Get("_p10"),
		q.Get("_p11"), q.Get("_p12"), p13, q.Get("_p14"), q.Get("_p15"),
		q.Get("_p16"), q.Get("_p17"), p18, q.Get("_p19"), q.Get("_p20"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []ManyParamsResult
	for rows.Next() {
		var res ManyParamsResult
		if err := rows.Scan(&res.ParamCount, &res.Checksum); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		results = append(results, res)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}
