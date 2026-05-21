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

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/check-app-node.sh <MONITORING_HOST>"
  echo "Example: ./scripts/check-app-node.sh 10.0.3.22"
  exit 1
fi

MONITORING_HOST="$1"

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
check_url "Loki ready from app node" "http://${MONITORING_HOST}:3100/ready"

if grep -n "loki/api/v1/push" infrastructure/app-node/configs/promtail/config.yml >/dev/null 2>&1; then
  pass "Promtail config contains Loki push URL"
  grep -n "loki/api/v1/push" infrastructure/app-node/configs/promtail/config.yml
else
  fail "Promtail config contains Loki push URL"
fi

info "Recent Promtail logs"
if docker logs sentinelstack-promtail --tail=50; then
  pass "Promtail logs readable"
else
  fail "Promtail logs readable"
fi

echo
echo "Summary: ${PASSED} passed, ${FAILED} failed"

if [ "${FAILED}" -gt 0 ]; then
  exit 1
fi
