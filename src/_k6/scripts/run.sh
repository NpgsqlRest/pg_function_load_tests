#!/bin/sh

STAMP=$(date +"%Y%m%d%H%M")

mkdir -p /results
mkdir -p /results/$STAMP

echo "*** Starting k6 tests, output will be saved in /results/$STAMP"

for records in 1 10 100 500; do # records retrieved
for target in 1 50 100; do # target number of virtual users VUs
for duration in 60s; do # duration of the test
while read -r tag port; do
    echo "*** Running $tag:$port with $records records, $target VUs, and $duration duration"
    k6 run /scripts/script.js -e STAMP=$STAMP -e TAG=$tag -e PORT=$port -e RECORDS=$records -e DURATION=$duration -e TARGET=$target
    sleep 10 # sleep for 10 seconds between tests
done << EOF
django-app-v5.1.4 8000
fastapi-app-v0.115.6 8001
fastify-app-v5.2.1 3101
bun-app-v1.1.42 3104
go-app-v1.23.4 5200
java24-spring-boot-v3.4.1 5400
rust-app-v1.83.0 5300
swoole-php-app-v8.4.0 3103
postgrest-v12.2.8 3000
net9-minapi-ef-jit 5002
net10-minapi-ef-jit 5003
net10-minapi-dapper-jit 5004
npgsqlrest-aot-v2.36.2 5006
npgsqlrest-aot-v3.2.2 5001
npgsqlrest-jit-v3.2.2 5005
EOF
done # duration of the test
done # target number of virtual users VUs
done # records retrieved

OUTPUT_FILE="/results/$STAMP.md"
> "$OUTPUT_FILE"
echo "*** processing results... Saving to $OUTPUT_FILE"

# `|${tag}|${target}|${duration}|${records}|${reqs}|${reqsPerSec}|${reqsDuration}|${failedReqs}|[summary](/${stamp}/${fileTag}_summary.txt)|`
echo "| Service | Virtual Users | Duration | Records | Total Requests | Requests Per Second | Average Duration | Failed Requests | Summary Link |" >> "$OUTPUT_FILE"
echo "|---------|--------------:|---------:|-----------------:|---------------:|--------------------:|-----------------:|----------------:|--------------|" >> "$OUTPUT_FILE"

if ls /results/$STAMP/*.md 1> /dev/null 2>&1; then
    for file in /results/$STAMP/*.md; do
        echo "Processing file: $file"
        filename=$(basename "$file" .md)
        content=$(cat "$file")
        echo "Content read: $content"
        if [ ! -z "$content" ]; then
            echo $content >> "$OUTPUT_FILE"
        else
            echo "Warning: $file is empty"
        fi
    done

    rm /results/$STAMP/*.md
else
    echo "No MD files found in /results/$STAMP/"
fi

echo "*** Results processed and saved to $OUTPUT_FILE"
