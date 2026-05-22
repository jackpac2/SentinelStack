#!/usr/bin/env bash
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: ./scripts/simulate-latency.sh <APP_HOST> [COUNT]"
  echo "Example: ./scripts/simulate-latency.sh 10.0.2.45 30"
  exit 1
fi

APP_HOST="$1"
COUNT="${2:-30}"
URL="http://${APP_HOST}/api/slow"

echo "[INFO] Triggering slow backend requests"
echo "[INFO] Target: ${URL}"
echo "[INFO] Requests: ${COUNT}"
echo "[INFO] This should help trigger HighLatency after the alert 'for' duration."

for i in $(seq 1 "${COUNT}"); do
  status="$(curl -sS -o /dev/null -w '%{http_code}' "${URL}" || true)"
  echo "[INFO] ${i}/${COUNT} status=${status}"
done

echo "[INFO] Done. Check Prometheus Alerts, Alertmanager, Discord, and Grafana latency panels."
