#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "[INFO] Re-running as root with sudo."
  exec sudo -E bash "$0" "$@"
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: ./scripts/start-app-node.sh <MONITORING_HOST>"
  echo "Example: ./scripts/start-app-node.sh 10.0.3.22"
  exit 1
fi

MONITORING_HOST="$1"
export MONITORING_HOST

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
if docker ps >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker compose)
else
  info "Current session cannot access the Docker socket without sudo; using sudo for this run."
  DOCKER_COMPOSE=(sudo docker compose)
fi

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
