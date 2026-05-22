#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/start-monitoring-node.sh <APP_HOST>"
  echo "Example: ./scripts/start-monitoring-node.sh 10.0.2.45"
  exit 1
fi

APP_HOST="$1"
export APP_HOST

info() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1"
}

fatal() {
  echo "[FATAL] $1"
  exit 1
}

sync_repo_if_available() {
  local repo_root="$1"
  local before_sha
  local after_sha

  if ! command -v git >/dev/null 2>&1; then
    warn "git is not installed; repo sync skipped."
    return 0
  fi

  if [ ! -d "${repo_root}" ]; then
    warn "Repo directory does not exist; repo sync skipped: ${repo_root}"
    return 0
  fi

  if ! git -C "${repo_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    info "Not inside a git repo; repo sync skipped."
    return 0
  fi

  if [ ! -d "${repo_root}/.git" ]; then
    fatal "Refusing to sync because .git was not found at ${repo_root}/.git"
  fi

  before_sha="$(git -C "${repo_root}" rev-parse HEAD)"
  info "Syncing repo with origin/main from ${repo_root}"

  git -C "${repo_root}" fetch origin main

  # EC2 nodes are deployment targets. Reset/clean makes manual runs deterministic
  # and prevents local server edits from blocking startup.
  git -C "${repo_root}" reset --hard origin/main
  git -C "${repo_root}" clean -fd

  after_sha="$(git -C "${repo_root}" rev-parse HEAD)"
  if [ "${before_sha}" = "${after_sha}" ]; then
    info "Repo already up to date at ${after_sha}"
  else
    info "Repo updated from ${before_sha} to ${after_sha}"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

sync_repo_if_available "${REPO_ROOT}"

# Recompute paths after sync so the rest of the script uses the current checkout.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_FILE="${REPO_ROOT}/infrastructure/monitoring-node/.env"
ENV_EXAMPLE="${REPO_ROOT}/infrastructure/monitoring-node/.env.example"

cd "${REPO_ROOT}"

chmod +x "${REPO_ROOT}"/scripts/*.sh 2>/dev/null || true
"${REPO_ROOT}/scripts/install-dependencies.sh"

if [ ! -f "${ENV_FILE}" ]; then
  info "Monitoring env file missing. Creating it from .env.example."
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  info "Created ${ENV_FILE}"
  info "Review Grafana credentials and Discord webhook before production use."
fi

info "Generating monitoring config for APP_HOST=${APP_HOST}"
"${REPO_ROOT}/scripts/generate-monitoring-configs.sh"

info "Starting monitoring node stack"
if docker ps >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker compose)
else
  if getent group docker | awk -F: '{print $4}' | tr ',' '\n' | grep -qx "$(id -un)"; then
    fatal "User $(id -un) is in the docker group, but this SSH session has not picked it up yet. Reconnect SSH and run again."
  fi

  fatal "Docker is not reachable for user $(id -un). Add the user to the docker group, reconnect SSH, and run again."
fi

"${DOCKER_COMPOSE[@]}" \
  --env-file infrastructure/monitoring-node/.env \
  -f infrastructure/monitoring-node/docker-compose.yml \
  up -d

info "Monitoring node started."
info "Grafana: http://MONITORING_EC2_PUBLIC_IP:3000"
info "Prometheus: http://MONITORING_EC2_PUBLIC_IP:9090"
info "Alertmanager: http://MONITORING_EC2_PUBLIC_IP:9093"
