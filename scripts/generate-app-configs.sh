#!/usr/bin/env bash
set -euo pipefail

if ! command -v envsubst >/dev/null 2>&1; then
  echo "ERROR: envsubst is required. Install gettext-base on Ubuntu/Debian."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEMPLATE="${REPO_ROOT}/infrastructure/app-node/configs/promtail/config.yml.template"
OUTPUT="${REPO_ROOT}/infrastructure/app-node/configs/promtail/config.yml"

if [ -z "${MONITORING_HOST:-}" ]; then
  echo "ERROR: MONITORING_HOST is required."
  echo "Example: MONITORING_HOST=10.0.3.22 ./scripts/generate-app-configs.sh"
  exit 1
fi

envsubst '${MONITORING_HOST}' < "${TEMPLATE}" > "${OUTPUT}"

echo "Generated app config:"
echo "  ${OUTPUT}"
echo "Using MONITORING_HOST=${MONITORING_HOST}"
