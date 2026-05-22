#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${1:-sentinelstack-backend}"

echo "[INFO] Simulating a safe container restart"
echo "[INFO] Container: ${CONTAINER}"
echo "[INFO] This should help trigger ContainerRestart from cAdvisor metrics."

if ! command -v docker >/dev/null 2>&1; then
  echo "[FAIL] docker is not installed or not in PATH"
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER}"; then
  echo "[FAIL] Container is not running: ${CONTAINER}"
  exit 1
fi

docker restart "${CONTAINER}"

echo "[INFO] Restart issued. Cleanup is automatic because this only restarts an existing container."
echo "[INFO] Check Prometheus Alerts, Alertmanager, Discord, and the Docker Container Metrics dashboard."
