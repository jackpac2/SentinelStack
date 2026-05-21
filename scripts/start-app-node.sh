#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/start-app-node.sh <MONITORING_HOST>"
  echo "Example: ./scripts/start-app-node.sh 10.0.3.22"
  exit 1
fi

MONITORING_HOST="$1"
export MONITORING_HOST

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_FILE="${REPO_ROOT}/infrastructure/app-node/.env"
ENV_EXAMPLE="${REPO_ROOT}/infrastructure/app-node/.env.example"

cd "${REPO_ROOT}"

chmod +x "${REPO_ROOT}/scripts/install-dependencies.sh" 2>/dev/null || true
"${REPO_ROOT}/scripts/install-dependencies.sh"

if [ ! -f "${ENV_FILE}" ]; then
  echo "App env file missing. Creating it from .env.example."
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  echo "Created ${ENV_FILE}"
  echo "Review database credentials before production use."
fi

echo "Generating app config for MONITORING_HOST=${MONITORING_HOST}"
"${REPO_ROOT}/scripts/generate-app-configs.sh"

echo "Starting app node stack"
if docker ps >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker compose)
else
  echo "Current session cannot access the Docker socket without sudo; using sudo for this run."
  DOCKER_COMPOSE=(sudo docker compose)
fi

"${DOCKER_COMPOSE[@]}" \
  --env-file infrastructure/app-node/.env \
  -f infrastructure/app-node/docker-compose.yml \
  up -d --build

echo "App node started."
echo "App: http://APP_EC2_PUBLIC_IP"
