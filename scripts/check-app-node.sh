#!/usr/bin/env bash
set -uo pipefail

PASSED=0
FAILED=0
WARNED=0

pass() {
  echo "[PASS] $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "[FAIL] $1"
  FAILED=$((FAILED + 1))
}

warn() {
  echo "[WARN] $1"
  WARNED=$((WARNED + 1))
}

info() {
  echo "[INFO] $1"
}

section() {
  echo
  echo "========== $1 =========="
}

check_cmd() {
  local name="$1"
  local cmd="$2"

  if eval "${cmd}" >/dev/null 2>&1; then
    pass "${name}"
  else
    fail "${name}"
  fi
}

check_url() {
  local name="$1"
  local url="$2"
  local severity="${3:-fail}"

  if curl -fsS --connect-timeout 3 --max-time 10 "${url}" >/dev/null 2>&1; then
    pass "${name}: ${url}"
  else
    if [ "${severity}" = "warn" ]; then
      warn "${name}: ${url}"
    else
      fail "${name}: ${url}"
    fi
  fi
}

check_container() {
  local container="$1"

  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "${container}"; then
    pass "Container running: ${container}"
  else
    fail "Container running: ${container}"
  fi
}

check_file_contains() {
  local name="$1"
  local file="$2"
  local pattern="$3"
  local severity="${4:-fail}"

  if grep -n "${pattern}" "${file}" >/dev/null 2>&1; then
    pass "${name}"
    grep -n "${pattern}" "${file}"
    return 0
  fi

  if [ "${severity}" = "warn" ]; then
    warn "${name}"
    return 0
  fi

  fail "${name}"
  return 1
}

print_loki_labels() {
  local body

  section "Loki labels from monitoring node"
  body="$(curl -fsS --connect-timeout 3 --max-time 10 "http://${MONITORING_HOST}:3100/loki/api/v1/labels" 2>/dev/null)"
  if [ -z "${body}" ]; then
    warn "Loki labels API not reachable from app node"
    return 0
  fi

  pass "Loki labels API reachable from app node"
  echo "${body}"

  if echo "${body}" | grep -q '"data":\[\]'; then
    warn "Loki has no labels yet. Promtail may be starting, blocked by security groups, or no logs have been pushed."
  else
    pass "Loki labels returned data"
  fi
}

check_loki_query() {
  local query="$1"

  section "Loki query check"
  if curl -fsS --connect-timeout 3 --max-time 10 \
    -G "http://${MONITORING_HOST}:3100/loki/api/v1/query" \
    --data-urlencode "query=${query}" >/dev/null 2>&1; then
    pass "Loki query accepted: ${query}"
  else
    warn "Loki query failed or returned an API error: ${query}"
  fi
}

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/check-app-node.sh <MONITORING_HOST>"
  echo "Example: ./scripts/check-app-node.sh 10.0.3.22"
  exit 1
fi

MONITORING_HOST="$1"

section "SentinelStack app node checks"
info "Checking SentinelStack app node"
info "Monitoring host: ${MONITORING_HOST}"

check_cmd "Docker CLI installed" "command -v docker"
check_cmd "Docker daemon reachable" "docker ps"
check_cmd "Docker Compose available" "docker compose version"

for container in \
  sentinelstack-nginx \
  sentinelstack-frontend \
  sentinelstack-backend \
  sentinelstack-postgres \
  sentinelstack-node-exporter \
  sentinelstack-cadvisor \
  sentinelstack-promtail; do
  check_container "${container}"
done

check_url "App health endpoint" "http://localhost/api/health"
check_url "Products endpoint" "http://localhost/api/products"
check_url "Backend metrics through nginx" "http://localhost/api/metrics"

check_url "node-exporter metrics" "http://localhost:9100/metrics"
check_url "cAdvisor metrics" "http://localhost:8080/metrics"
check_url "Loki ready from app node" "http://${MONITORING_HOST}:3100/ready" "warn"

section "Promtail generated config"
check_file_contains "Promtail config contains Loki push URL" "infrastructure/app-node/configs/promtail/config.yml" "loki/api/v1/push"
check_file_contains "Promtail config sets job label" "infrastructure/app-node/configs/promtail/config.yml" "target_label: job"
check_file_contains "Promtail config sets service label" "infrastructure/app-node/configs/promtail/config.yml" "target_label: service"
check_file_contains "Promtail config sets container label" "infrastructure/app-node/configs/promtail/config.yml" "target_label: container"
check_file_contains "Promtail config sets environment label" "infrastructure/app-node/configs/promtail/config.yml" "target_label: environment" "warn"
check_file_contains "Promtail config sets Docker log path" "infrastructure/app-node/configs/promtail/config.yml" "target_label: __path__"

print_loki_labels
check_loki_query '{job="sentinelstack"}'

section "Promtail logs"
info "Recent Promtail logs"
if docker logs sentinelstack-promtail --tail=50; then
  pass "Promtail logs readable"
else
  fail "Promtail logs readable"
fi

echo
echo "Summary: ${PASSED} passed, ${FAILED} failed, ${WARNED} warnings"

if [ "${FAILED}" -gt 0 ]; then
  exit 1
fi
