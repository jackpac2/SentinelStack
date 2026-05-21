#!/usr/bin/env bash

PASSED=0
FAILED=0

pass() {
  echo "[PASS] $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "[FAIL] $1"
  FAILED=$((FAILED + 1))
}

info() {
  echo "[INFO] $1"
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

  if curl -fsS "${url}" >/dev/null 2>&1; then
    pass "${name}: ${url}"
  else
    fail "${name}: ${url}"
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

print_prometheus_targets() {
  local body

  info "Prometheus target health"
  body="$(curl -fsS http://localhost:9090/api/v1/targets 2>/dev/null)"
  if [ -z "${body}" ]; then
    fail "Prometheus targets API reachable"
    return
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
      fail "Prometheus target present: ${job}"
    fi
  done
}

print_loki_labels() {
  local body

  info "Loki labels"
  body="$(curl -fsS http://localhost:3100/loki/api/v1/labels 2>/dev/null)"
  if [ -z "${body}" ]; then
    fail "Loki labels API reachable"
    return
  fi

  pass "Loki labels API reachable"

  if command -v jq >/dev/null 2>&1; then
    echo "${body}" | jq -r '.data[]?'
    if [ "$(echo "${body}" | jq '.data | length')" -eq 0 ]; then
      fail "Loki labels found"
      echo "[INFO] No labels found. Promtail may not be pushing logs yet."
    else
      pass "Loki labels found"
    fi
  else
    echo "${body}"
    if echo "${body}" | grep -q '"data":\[\]'; then
      fail "Loki labels found"
      echo "[INFO] No labels found. Promtail may not be pushing logs yet."
    else
      pass "Loki labels found"
    fi
  fi
}

info "Checking SentinelStack monitoring node"

check_cmd "Docker CLI installed" "command -v docker"
check_cmd "Docker daemon reachable" "docker ps"
check_cmd "Docker Compose available" "docker compose version"

for container in \
  sentinelstack-prometheus \
  sentinelstack-grafana \
  sentinelstack-loki \
  sentinelstack-alertmanager; do
  check_container "${container}"
done

check_url "Prometheus ready" "http://localhost:9090/-/ready"
check_url "Grafana health" "http://localhost:3000/api/health"
check_url "Loki ready" "http://localhost:3100/ready"
check_url "Alertmanager ready" "http://localhost:9093/-/ready"
check_url "Alertmanager status" "http://localhost:9093/api/v2/status"

print_prometheus_targets
print_loki_labels

info "Recent Prometheus logs"
if docker logs sentinelstack-prometheus --tail=30; then
  pass "Prometheus logs readable"
else
  fail "Prometheus logs readable"
fi

info "Recent Loki logs"
if docker logs sentinelstack-loki --tail=30; then
  pass "Loki logs readable"
else
  fail "Loki logs readable"
fi

info "Recent Alertmanager logs"
if docker logs sentinelstack-alertmanager --tail=30; then
  pass "Alertmanager logs readable"
else
  fail "Alertmanager logs readable"
fi

echo
echo "Summary: ${PASSED} passed, ${FAILED} failed"

if [ "${FAILED}" -gt 0 ]; then
  exit 1
fi
