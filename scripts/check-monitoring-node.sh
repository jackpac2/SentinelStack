#!/usr/bin/env bash
set -uo pipefail

PASSED=0
FAILED=0
WARNED=0
FATAL=0

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

fatal() {
  echo "[FATAL] $1"
  FATAL=$((FATAL + 1))
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
    return 0
  fi

  fail "${name}"
  return 1
}

check_fatal_cmd() {
  local name="$1"
  local cmd="$2"

  if eval "${cmd}" >/dev/null 2>&1; then
    pass "${name}"
    return 0
  fi

  fatal "${name}"
  return 1
}

retry_url() {
  local name="$1"
  local url="$2"
  local attempts="${3:-12}"
  local sleep_seconds="${4:-5}"
  local severity="${5:-fail}"
  local attempt

  for attempt in $(seq 1 "${attempts}"); do
    if curl -fsS --connect-timeout 3 --max-time 10 "${url}" >/dev/null 2>&1; then
      pass "${name}: ${url}"
      return 0
    fi

    info "${name} not ready yet (${attempt}/${attempts})"
    sleep "${sleep_seconds}"
  done

  if [ "${severity}" = "warn" ]; then
    warn "${name}: ${url}"
    return 0
  fi

  fail "${name}: ${url}"
  return 1
}

check_container() {
  local container="$1"
  local severity="${2:-fail}"

  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "${container}"; then
    pass "Container running: ${container}"
    return 0
  fi

  if [ "${severity}" = "warn" ]; then
    warn "Container not running yet: ${container}"
    return 0
  fi

  fail "Container running: ${container}"
  return 1
}

print_container_logs() {
  local container="$1"
  local lines="${2:-30}"

  section "Recent logs: ${container}"
  if docker logs "${container}" --tail="${lines}"; then
    pass "Logs readable: ${container}"
  else
    warn "Logs not readable: ${container}"
  fi
}

print_prometheus_targets() {
  local body
  local job

  section "Prometheus target health"
  body="$(curl -fsS --connect-timeout 3 --max-time 10 http://localhost:9090/api/v1/targets 2>/dev/null)"
  if [ -z "${body}" ]; then
    fail "Prometheus targets API reachable"
    return 1
  fi

  pass "Prometheus targets API reachable"

  if command -v jq >/dev/null 2>&1; then
    echo "${body}" | jq -r '.data.activeTargets[] | "\(.labels.job)\t\(.health)\t\(.scrapeUrl)"'
  else
    echo "${body}" | grep -o '"job":"[^"]*"\|"health":"[^"]*"\|"scrapeUrl":"[^"]*"' | sed 's/[{}"]//g'
  fi

  for job in prometheus alertmanager loki sentinelstack-backend sentinelstack-cadvisor sentinelstack-node-exporter; do
    if echo "${body}" | grep -q "\"job\":\"${job}\""; then
      pass "Prometheus target present: ${job}"
    else
      warn "Prometheus target missing or not discovered yet: ${job}"
    fi
  done
}

print_loki_labels() {
  local body
  local label

  section "Loki labels"
  body="$(curl -fsS --connect-timeout 3 --max-time 10 http://localhost:3100/loki/api/v1/labels 2>/dev/null)"
  if [ -z "${body}" ]; then
    warn "Loki labels API not ready yet"
    return 0
  fi

  pass "Loki labels API reachable"

  if command -v jq >/dev/null 2>&1; then
    echo "${body}" | jq -r '.data[]?'
    if [ "$(echo "${body}" | jq '.data | length')" -eq 0 ]; then
      warn "No Loki labels found yet. Promtail may still be starting or no app logs have been pushed."
    else
      pass "Loki labels found"
    fi
  else
    echo "${body}"
    if echo "${body}" | grep -q '"data":\[\]'; then
      warn "No Loki labels found yet. Promtail may still be starting or no app logs have been pushed."
    else
      pass "Loki labels found"
    fi
  fi

  for label in job service container host environment; do
    if echo "${body}" | grep -q "\"${label}\""; then
      pass "Loki label present: ${label}"
    else
      warn "Loki label not found yet: ${label}"
    fi
  done
}

check_loki_query() {
  local query="$1"
  local body

  section "Loki query: ${query}"
  body="$(curl -fsS --connect-timeout 3 --max-time 10 \
    -G "http://localhost:3100/loki/api/v1/query" \
    --data-urlencode "query=${query}" 2>/dev/null)"

  if [ -z "${body}" ]; then
    warn "Loki query failed or returned no response: ${query}"
    return 0
  fi

  pass "Loki query accepted: ${query}"
  if command -v jq >/dev/null 2>&1; then
    echo "${body}" | jq -r '.data.result[]?.stream // empty' | head -20
    if [ "$(echo "${body}" | jq '.data.result | length')" -eq 0 ]; then
      warn "No log streams returned yet for query: ${query}"
    else
      pass "Loki query returned log streams"
    fi
  else
    echo "${body}" | head -20
    if echo "${body}" | grep -q '"result":\[\]'; then
      warn "No log streams returned yet for query: ${query}"
    else
      pass "Loki query returned log streams"
    fi
  fi
}

section "SentinelStack monitoring node checks"

check_fatal_cmd "Docker CLI installed" "command -v docker"
check_fatal_cmd "Docker daemon reachable" "docker ps"
check_fatal_cmd "Docker Compose available" "docker compose version"

if [ "${FATAL}" -gt 0 ]; then
  echo
  echo "Summary: ${PASSED} passed, ${FAILED} failed, ${WARNED} warnings, ${FATAL} fatal"
  exit 2
fi

section "Containers"
for container in \
  sentinelstack-prometheus \
  sentinelstack-grafana \
  sentinelstack-loki \
  sentinelstack-alertmanager; do
  check_container "${container}" "fail"
done

section "Service readiness"
retry_url "Prometheus ready" "http://localhost:9090/-/ready" 12 5 "fail"
retry_url "Grafana health" "http://localhost:3000/api/health" 12 5 "fail"
retry_url "Loki ready" "http://localhost:3100/ready" 12 5 "warn"
retry_url "Alertmanager ready" "http://localhost:9093/-/ready" 12 5 "fail"
retry_url "Alertmanager status" "http://localhost:9093/api/v2/status" 6 5 "fail"

print_prometheus_targets
print_loki_labels
check_loki_query '{job="sentinelstack"}'
check_loki_query '{service="backend"}'
check_loki_query '{job="sentinelstack"} |~ "(?i)error|exception|failed|fatal"'

print_container_logs "sentinelstack-prometheus" 30
print_container_logs "sentinelstack-loki" 30
print_container_logs "sentinelstack-alertmanager" 30

echo
echo "Summary: ${PASSED} passed, ${FAILED} failed, ${WARNED} warnings, ${FATAL} fatal"

if [ "${FATAL}" -gt 0 ]; then
  exit 2
fi

if [ "${FAILED}" -gt 0 ]; then
  exit 1
fi

exit 0
