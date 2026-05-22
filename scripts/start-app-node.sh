#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/start-app-node.sh <MONITORING_HOST>"
  echo "Example: ./scripts/start-app-node.sh 10.0.3.22"
  exit 1
fi

MONITORING_HOST="$1"
export MONITORING_HOST

COLOR_INFO="\033[0;36m"
COLOR_WARN="\033[0;33m"
COLOR_FATAL="\033[0;31m"
COLOR_RESET="\033[0m"

log_info() {
  printf "%b[INFO]%b %s\n" "${COLOR_INFO}" "${COLOR_RESET}" "$1"
}

log_warn() {
  printf "%b[WARN]%b %s\n" "${COLOR_WARN}" "${COLOR_RESET}" "$1"
}

log_fatal() {
  printf "%b[FATAL]%b %s\n" "${COLOR_FATAL}" "${COLOR_RESET}" "$1" >&2
  exit 1
}

info() { log_info "$1"; }
warn() { log_warn "$1"; }
fatal() { log_fatal "$1"; }

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

  if { [ ! -w "${repo_root}/.git" ]; } || { [ -e "${repo_root}/.git/FETCH_HEAD" ] && [ ! -w "${repo_root}/.git/FETCH_HEAD" ]; }; then
    warn "Git metadata is not writable by $(id -un); fixing repo ownership once."
    sudo chown -R "$(id -u):$(id -g)" "${repo_root}"
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

user_is_listed_in_docker_group() {
  getent group docker 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n' | grep -qx "$(id -un)"
}

ensure_docker_access() {
  # Linux calculates supplementary groups when the user logs in. If this script
  # just added ubuntu to the docker group, the current SSH session may still not
  # have the docker group until the user reconnects or starts a new group shell.
  if docker ps >/dev/null 2>&1; then
    DOCKER_COMPOSE=(docker compose)
    log_info "Docker access validated for user $(id -un)."
    return 0
  fi

  if user_is_listed_in_docker_group; then
    log_warn "User $(id -un) is listed in the docker group, but this SSH session has not picked up that group yet."

    if [ "${SENTINELSTACK_NEWGRP_ATTEMPTED:-0}" != "1" ] && command -v newgrp >/dev/null 2>&1; then
      log_warn "Attempting to refresh group membership with: newgrp docker"
      SENTINELSTACK_NEWGRP_ATTEMPTED=1 newgrp docker <<EOF
cd "${REPO_ROOT}"
export SENTINELSTACK_NEWGRP_ATTEMPTED=1
export MONITORING_HOST="${MONITORING_HOST}"
export GHCR_OWNER="${GHCR_OWNER:-}"
export IMAGE_TAG="${IMAGE_TAG:-}"
bash "${SCRIPT_DIR}/start-app-node.sh" "${MONITORING_HOST}"
EOF
      exit $?
    fi

    log_fatal "Docker is still not reachable after attempting group refresh. Reconnect SSH so Linux reloads docker group membership, then rerun ./scripts/start-app-node.sh ${MONITORING_HOST}."
  fi

  log_fatal "Docker is not reachable for user $(id -un). Add the user to the docker group, reconnect SSH, and rerun the script."
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

sync_repo_if_available "${REPO_ROOT}"

# Recompute paths after sync so the rest of the script uses the current checkout.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV_FILE="${REPO_ROOT}/infrastructure/app-node/.env"
ENV_EXAMPLE="${REPO_ROOT}/infrastructure/app-node/.env.example"

cd "${REPO_ROOT}"

chmod +x "${REPO_ROOT}"/scripts/*.sh 2>/dev/null || true
"${REPO_ROOT}/scripts/install-dependencies.sh"

if [ ! -f "${ENV_FILE}" ]; then
  info "App env file missing. Creating it from .env.example."
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  info "Created ${ENV_FILE}"
  info "Review database credentials before production use."
fi

set_env_value() {
  local key="$1"
  local value="$2"
  local file="$3"

  if [ -z "${value}" ]; then
    return
  fi

  if grep -q "^${key}=" "${file}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${file}"
  else
    printf '\n%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

ensure_env_value() {
  local key="$1"
  local value="$2"
  local file="$3"

  if ! grep -q "^${key}=" "${file}"; then
    printf '\n%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

set_env_value "GHCR_OWNER" "${GHCR_OWNER:-}" "${ENV_FILE}"
set_env_value "IMAGE_TAG" "${IMAGE_TAG:-}" "${ENV_FILE}"
ensure_env_value "GHCR_OWNER" "your-github-username" "${ENV_FILE}"
ensure_env_value "IMAGE_TAG" "latest" "${ENV_FILE}"

info "Generating app config for MONITORING_HOST=${MONITORING_HOST}"
"${REPO_ROOT}/scripts/generate-app-configs.sh"

info "Starting app node stack"
ensure_docker_access

"${DOCKER_COMPOSE[@]}" \
  --env-file infrastructure/app-node/.env \
  -f infrastructure/app-node/docker-compose.yml \
  pull || true

"${DOCKER_COMPOSE[@]}" \
  --env-file infrastructure/app-node/.env \
  -f infrastructure/app-node/docker-compose.yml \
  up -d

info "App node started."
info "App: http://APP_EC2_PUBLIC_IP"
