#!/usr/bin/env bash
set -euo pipefail

require_ubuntu() {
  if [ ! -f /etc/os-release ]; then
    echo "ERROR: /etc/os-release not found. This installer targets Ubuntu EC2 instances."
    exit 1
  fi

  local os_id
  os_id="$(awk -F= '$1=="ID"{gsub(/"/, "", $2); print $2}' /etc/os-release)"

  if [ "${os_id}" != "ubuntu" ]; then
    echo "ERROR: This installer targets Ubuntu 22.04+ and 24.04+."
    echo "Detected OS ID: ${os_id:-unknown}"
    exit 1
  fi
}

ubuntu_codename() {
  local codename
  codename="$(awk -F= '$1=="UBUNTU_CODENAME"{gsub(/"/, "", $2); print $2}' /etc/os-release)"

  if [ -z "${codename}" ]; then
    codename="$(awk -F= '$1=="VERSION_CODENAME"{gsub(/"/, "", $2); print $2}' /etc/os-release)"
  fi

  if [ -z "${codename}" ]; then
    echo "ERROR: Could not determine Ubuntu codename from /etc/os-release."
    exit 1
  fi

  echo "${codename}"
}

install_envsubst() {
  if command -v envsubst >/dev/null 2>&1; then
    echo "envsubst already installed: $(envsubst --version | head -n 1)"
    return
  fi

  echo "Installing envsubst via gettext-base..."
  sudo apt-get update
  sudo apt-get install -y gettext-base
  echo "Installed envsubst: $(envsubst --version | head -n 1)"
}

configure_docker_apt_repository() {
  local codename
  codename="$(ubuntu_codename)"

  echo "Configuring Docker official apt repository for Ubuntu ${codename}..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings

  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  else
    echo "Docker GPG key already exists."
  fi

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  else
    echo "Docker apt repository already configured."
  fi

  sudo apt-get update
}

install_docker_engine() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "Docker already installed: $(docker --version)"
    echo "Docker Compose plugin already installed: $(docker compose version)"
    return
  fi

  configure_docker_apt_repository

  if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker Engine from Docker's official Ubuntu repository..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  elif ! docker compose version >/dev/null 2>&1; then
    echo "Docker exists, but Docker Compose plugin is missing. Installing Compose plugin..."
    sudo apt-get install -y docker-buildx-plugin docker-compose-plugin
  fi

  sudo systemctl enable docker
  sudo systemctl start docker

  echo "Docker installed: $(docker --version)"
  echo "Docker Compose plugin installed: $(docker compose version)"
}

configure_docker_group() {
  local target_user
  target_user="${SUDO_USER:-${USER:-$(id -un)}}"

  if [ -z "${target_user}" ] || [ "${target_user}" = "root" ]; then
    echo "No non-root deployment user detected for docker group setup."
    return
  fi

  if ! getent group docker >/dev/null 2>&1; then
    echo "Docker group not found; skipping non-sudo Docker access setup."
    return
  fi

  if id -nG "${target_user}" | tr ' ' '\n' | grep -qx docker; then
    echo "User ${target_user} already belongs to the docker group."
    return
  fi

  echo "Adding ${target_user} to docker group for future non-sudo Docker access..."
  sudo usermod -aG docker "${target_user}"
  echo "Log out and back in (or reconnect SSH) for non-sudo Docker access."
}

require_ubuntu
install_envsubst
install_docker_engine
configure_docker_group

echo "Dependency check complete."
