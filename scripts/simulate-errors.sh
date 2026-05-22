#!/usr/bin/env bash
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: ./scripts/simulate-errors.sh <APP_HOST> [COUNT]"
  echo "Example: ./scripts/simulate-errors.sh 10.0.2.45 40"
  exit 1
fi

APP_HOST="$1"
COUNT="${2:-40}"
URL="http://${APP_HOST}/api/error"

echo "[INFO] Triggering backend 5xx responses"
echo "[INFO] Target: ${URL}"
echo "[INFO] Requests: ${COUNT}"
echo "[INFO] This should help trigger High5xxRate after the alert 'for' duration."

for i in $(seq 1 "${COUNT}"); do
  status="$(curl -sS -o /dev/null -w '%{http_code}' "${URL}" || true)"
  echo "[INFO] ${i}/${COUNT} status=${status}"
  sleep 1
done

echo "[INFO] Done. Check Prometheus Alerts, Alertmanager, Discord, and Grafana logs."
