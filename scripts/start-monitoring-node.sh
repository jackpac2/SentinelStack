#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/start-monitoring-node.sh <APP_HOST>"
  echo "Example: ./scripts/start-monitoring-node.sh 10.0.2.45"
  exit 1
fi

APP_HOST="$1"
export APP_HOST

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_FILE="${REPO_ROOT}/infrastructure/monitoring-node/.env"
ENV_EXAMPLE="${REPO_ROOT}/infrastructure/monitoring-node/.env.example"

cd "${REPO_ROOT}"

chmod +x "${REPO_ROOT}/scripts/install-dependencies.sh" 2>/dev/null || true
"${REPO_ROOT}/scripts/install-dependencies.sh"

if [ ! -f "${ENV_FILE}" ]; then
  echo "Monitoring env file missing. Creating it from .env.example."
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  echo "Created ${ENV_FILE}"
  echo "Review Grafana credentials and Discord webhook before production use."
fi

echo "Generating monitoring config for APP_HOST=${APP_HOST}"
"${REPO_ROOT}/scripts/generate-monitoring-configs.sh"

echo "Starting monitoring node stack"
if docker ps >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker compose)
else
  echo "Current session cannot access the Docker socket without sudo; using sudo for this run."
  DOCKER_COMPOSE=(sudo docker compose)
fi

"${DOCKER_COMPOSE[@]}" \
  --env-file infrastructure/monitoring-node/.env \
  -f infrastructure/monitoring-node/docker-compose.yml \
  up -d

echo "Monitoring node started."
echo "Grafana: http://MONITORING_EC2_PUBLIC_IP:3000"
echo "Prometheus: http://MONITORING_EC2_PUBLIC_IP:9090"
echo "Alertmanager: http://MONITORING_EC2_PUBLIC_IP:9093"
