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
ALERTMANAGER_TEMPLATE="${REPO_ROOT}/infrastructure/monitoring-node/configs/alertmanager/alertmanager.yml.template"
ALERTMANAGER_OUTPUT="${REPO_ROOT}/infrastructure/monitoring-node/configs/alertmanager/alertmanager.yml"
MONITORING_ENV="${REPO_ROOT}/infrastructure/monitoring-node/.env"

read_env_value() {
  local key="$1"
  local file="$2"

  if [ ! -f "${file}" ]; then
    return 0
  fi

  grep -E "^${key}=" "${file}" | tail -n 1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
}

if [ -z "${APP_HOST:-}" ]; then
  echo "ERROR: APP_HOST is required."
  echo "Example: APP_HOST=10.0.2.45 ./scripts/generate-monitoring-configs.sh"
  exit 1
fi

envsubst '${APP_HOST}' < "${TEMPLATE}" > "${OUTPUT}"

echo "Generated monitoring config:"
echo "  ${OUTPUT}"
echo "Using APP_HOST=${APP_HOST}"

DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-$(read_env_value DISCORD_WEBHOOK_URL "${MONITORING_ENV}")}"

if [ -n "${DISCORD_WEBHOOK_URL}" ]; then
  ALERTMANAGER_RECEIVER_NAME="discord"
  ALERTMANAGER_RECEIVER_CONFIG="$(cat <<EOF
    discord_configs:
      - webhook_url: "${DISCORD_WEBHOOK_URL}"
        send_resolved: true
        title: '[{{ .Status }}] SentinelStack: {{ .CommonLabels.alertname }}'
        message: |-
          {{ if eq .Status "firing" }}FIRING alerts{{ else }}RESOLVED alerts{{ end }}: {{ len .Alerts }}

          {{ range .Alerts }}
          Alert: {{ .Labels.alertname }}
          Severity: {{ .Labels.severity }}
          Status: {{ .Status }}
          Service: {{ .Labels.service }}
          Category: {{ .Labels.category }}
          Job: {{ .Labels.job }}
          Instance: {{ .Labels.instance }}
          Summary: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Started: {{ .StartsAt }}
          Dashboard: {{ .Annotations.dashboard }}
          Runbook: {{ .Annotations.runbook }}
          {{ end }}
EOF
)"
  echo "Generating Alertmanager config with Discord receiver enabled."
else
  ALERTMANAGER_RECEIVER_NAME="default-receiver"
  ALERTMANAGER_RECEIVER_CONFIG=""
  echo "Generating Alertmanager config with safe no-op receiver. Set DISCORD_WEBHOOK_URL in infrastructure/monitoring-node/.env to enable Discord."
fi

export ALERTMANAGER_RECEIVER_NAME
export ALERTMANAGER_RECEIVER_CONFIG

envsubst '${ALERTMANAGER_RECEIVER_NAME} ${ALERTMANAGER_RECEIVER_CONFIG}' < "${ALERTMANAGER_TEMPLATE}" > "${ALERTMANAGER_OUTPUT}"

echo "Generated Alertmanager config:"
echo "  ${ALERTMANAGER_OUTPUT}"
