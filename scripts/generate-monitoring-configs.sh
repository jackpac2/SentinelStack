#!/usr/bin/env bash
set -euo pipefail

if ! command -v envsubst >/dev/null 2>&1; then
  echo "ERROR: envsubst is required. Install gettext-base on Ubuntu/Debian."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEMPLATE="${REPO_ROOT}/infrastructure/monitoring-node/configs/prometheus/prometheus.yml.template"
OUTPUT="${REPO_ROOT}/infrastructure/monitoring-node/configs/prometheus/prometheus.yml"

if [ -z "${APP_HOST:-}" ]; then
  echo "ERROR: APP_HOST is required."
  echo "Example: APP_HOST=10.0.2.45 ./scripts/generate-monitoring-configs.sh"
  exit 1
fi

envsubst '${APP_HOST}' < "${TEMPLATE}" > "${OUTPUT}"

echo "Generated monitoring config:"
echo "  ${OUTPUT}"
echo "Using APP_HOST=${APP_HOST}"
