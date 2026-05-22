#!/usr/bin/env bash
set -uo pipefail

APP_HOST="${1:-localhost}"
COUNT="${2:-50}"
BASE_URL="http://${APP_HOST}"

echo "[INFO] Generating normal SentinelStack traffic"
echo "[INFO] Target: ${BASE_URL}"
echo "[INFO] Requests per endpoint: ${COUNT}"

for i in $(seq 1 "${COUNT}"); do
  curl -fsS "${BASE_URL}/api/health" >/dev/null 2>&1 || echo "[WARN] health request failed on iteration ${i}"
  curl -fsS "${BASE_URL}/api/products" >/dev/null 2>&1 || echo "[WARN] products request failed on iteration ${i}"
  curl -fsS "${BASE_URL}/api/orders" >/dev/null 2>&1 || echo "[WARN] orders request failed on iteration ${i}"
done

echo "[INFO] Done. Check Prometheus/Grafana request-rate panels."
