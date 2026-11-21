#!/bin/bash
# =============================================================================
# One resource collector for every container of the benchmark.
#
# Reads each container's cgroup (v2) files directly: cpu.stat (usage_usec) and
# memory.current. One process, one pass per interval, no docker CLI calls while
# sampling. The previous collector ran `docker stats --no-stream` in a loop per
# container: with 26 containers that is 26 loops of a command that takes about
# two seconds each, so samples came every 3 seconds, not every second, and the
# collectors themselves put load on the machine that is being measured.
#
# Usage:  collect-stats.sh <interval-seconds> <name>=<container> <file> [<name>=<container> <file> ...]
#   Writes, per container, the same CSV as before:
#     timestamp,cpu_percent,mem_usage_mb,mem_limit_mb,mem_percent
#   cpu_percent is 100 per fully used core (400 = four cores), as docker stats reports it.
#
# Exit code 3 when the cgroup files cannot be found (not Linux, cgroup v1, or a
# docker setup with another layout): the caller then falls back to docker stats.
# =============================================================================
interval=${1:-1}
shift

# where a container's cgroup is: systemd driver, then cgroupfs driver
cgroup_dir() {
    local id=$1
    for dir in "/sys/fs/cgroup/system.slice/docker-${id}.scope" "/sys/fs/cgroup/docker/${id}"; do
        if [ -r "${dir}/cpu.stat" ]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

names=()
dirs=()
files=()
while [ $# -ge 2 ]; do
    name="${1%%=*}"
    container="${1#*=}"
    file="$2"
    shift 2
    id=$(docker inspect --format '{{.Id}}' "$container" 2>/dev/null)
    dir=$(cgroup_dir "$id") || { echo "collect-stats: no cgroup v2 files for $container" >&2; exit 3; }
    names+=("$name"); dirs+=("$dir"); files+=("$file")
    echo "timestamp,cpu_percent,mem_usage_mb,mem_limit_mb,mem_percent" > "$file"
done
[ ${#names[@]} -gt 0 ] || { echo "collect-stats: nothing to collect" >&2; exit 2; }

host_mem=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo)
declare -a last_usage
last_ns=0

while true; do
    now_ns=$(date +%s%N)
    now=$((now_ns / 1000000000))
    for i in "${!names[@]}"; do
        dir="${dirs[$i]}"
        # the container is gone or paused state changed the path: skip the sample
        [ -r "${dir}/cpu.stat" ] || continue
        usage=$(awk '$1 == "usage_usec" {print $2}' "${dir}/cpu.stat")
        # Memory as "docker stats" reports it (and as July's numbers were taken): what the container uses
        # without the file cache the kernel can drop (memory.current - inactive_file). Without this, a
        # service is charged for files it only read once at start (assemblies, node_modules, a JAR).
        mem=$(cat "${dir}/memory.current" 2>/dev/null || echo 0)
        cache=$(awk '$1 == "inactive_file" {print $2}' "${dir}/memory.stat" 2>/dev/null)
        mem=$(( mem - ${cache:-0} ))
        [ "$mem" -lt 0 ] && mem=0
        limit=$(cat "${dir}/memory.max" 2>/dev/null || echo max)
        [ "$limit" = "max" ] && limit=$host_mem
        if [ "$last_ns" -gt 0 ] && [ -n "${last_usage[$i]}" ]; then
            awk -v t="$now" -v u="$usage" -v lu="${last_usage[$i]}" -v ns="$((now_ns - last_ns))" -v m="$mem" -v l="$limit" 'BEGIN {
                cpu = (ns > 0) ? (u - lu) * 1000 / ns * 100 : 0;      # usec used / usec elapsed * 100
                printf "%d,%.2f,%.2f,%.2f,%.2f\n", t, cpu, m / 1048576, l / 1048576, (l > 0) ? m * 100 / l : 0
            }' >> "${files[$i]}"
        fi
        last_usage[$i]=$usage
    done
    last_ns=$now_ns
    sleep "$interval"
done
