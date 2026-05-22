#!/usr/bin/env bash
set -euo pipefail

DURATION_SECONDS="${1:-180}"
WORKERS="${2:-2}"
CONTAINER="sentinelstack-cpu-spike"

echo "[INFO] Starting bounded CPU spike in a disposable Docker container"
echo "[INFO] Duration: ${DURATION_SECONDS}s"
echo "[INFO] Workers: ${WORKERS}"
echo "[INFO] This should help trigger HighCPUUsage on small EC2 instances."

if ! command -v docker >/dev/null 2>&1; then
  echo "[FAIL] docker is not installed or not in PATH"
  exit 1
fi

cleanup() {
  docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true

docker run --rm --name "${CONTAINER}" alpine:3.20 sh -c "
  i=1
  while [ \"\$i\" -le \"${WORKERS}\" ]; do
    yes > /dev/null &
    i=\$((i + 1))
  done
  sleep \"${DURATION_SECONDS}\"
"

echo "[INFO] CPU spike finished. Check Prometheus Alerts, Alertmanager, Discord, and the App Node Metrics dashboard."
