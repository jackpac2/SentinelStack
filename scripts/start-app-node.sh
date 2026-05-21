#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/start-app-node.sh <MONITORING_HOST>"
  echo "Example: ./scripts/start-app-node.sh 10.0.3.22"
  exit 1
fi

MONITORING_HOST="$1"
export MONITORING_HOST

if ! command -v envsubst >/dev/null 2>&1; then
  echo "ERROR: envsubst is required. Install gettext-base on Ubuntu/Debian."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose is required."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_FILE="${REPO_ROOT}/infrastructure/app-node/.env"
ENV_EXAMPLE="${REPO_ROOT}/infrastructure/app-node/.env.example"

cd "${REPO_ROOT}"

if [ ! -f "${ENV_FILE}" ]; then
  echo "App env file missing. Creating it from .env.example."
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  echo "Created ${ENV_FILE}"
  echo "Review database credentials before production use."
fi

echo "Generating app config for MONITORING_HOST=${MONITORING_HOST}"
"${REPO_ROOT}/scripts/generate-app-configs.sh"

echo "Starting app node stack"
docker compose \
  --env-file infrastructure/app-node/.env \
  -f infrastructure/app-node/docker-compose.yml \
  up -d --build

echo "App node started."
echo "App: http://APP_EC2_PUBLIC_IP"
