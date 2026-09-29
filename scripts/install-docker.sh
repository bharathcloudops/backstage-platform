#!/usr/bin/env bash

#==============================================================================
# PINNED DOCKER ENGINE INSTALLATION
#==============================================================================

#==============================================================================
# SHELL SAFETY
#==============================================================================

set -euo pipefail

#==============================================================================
# INSTALLATION INPUTS
#==============================================================================

action="${1:-validate}"
containerd_version="${CONTAINERD_VERSION:-2.3.4-2~ubuntu.24.04~noble}"
buildx_version="${DOCKER_BUILDX_VERSION:-0.37.0-1~ubuntu.24.04~noble}"
compose_version="${DOCKER_COMPOSE_VERSION:-5.5.1-1~ubuntu.24.04~noble}"
engine_version="${DOCKER_ENGINE_VERSION:-5:29.8.0-1~ubuntu.24.04~noble}"

#==============================================================================
# PLATFORM AND ACTION VALIDATION
#==============================================================================

[[ "$action" =~ ^(validate|dry-run|deploy)$ ]] || { printf 'Invalid Docker action.\n' >&2; exit 2; }
distribution_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')
distribution_codename=$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release | tr -d '"')
[[ "$distribution_id" == "ubuntu" && "$distribution_codename" == "noble" ]] || { printf 'Ubuntu 24.04 is required.\n' >&2; exit 1; }
if [[ "$action" == "validate" ]]; then printf 'docker_install_validation=ready\n'; exit 0; fi
if [[ "$action" == "dry-run" ]]; then printf 'docker_install_dry_run=ready\n'; exit 0; fi
(( EUID == 0 )) || { printf 'Root is required.\n' >&2; exit 1; }

if [[ "$(dpkg-query --show --showformat='${Version}' docker-ce 2>/dev/null || true)" == "$engine_version" &&
  "$(dpkg-query --show --showformat='${Version}' docker-ce-cli 2>/dev/null || true)" == "$engine_version" &&
  "$(dpkg-query --show --showformat='${Version}' containerd.io 2>/dev/null || true)" == "$containerd_version" &&
  "$(dpkg-query --show --showformat='${Version}' docker-buildx-plugin 2>/dev/null || true)" == "$buildx_version" &&
  "$(dpkg-query --show --showformat='${Version}' docker-compose-plugin 2>/dev/null || true)" == "$compose_version" ]] &&
  systemctl is-active --quiet docker; then
  docker version >/dev/null
  docker compose version >/dev/null
  printf 'docker_install=unchanged\n'
  printf 'docker_install=ready\n'
  exit 0
fi

#==============================================================================
# DOCKER PACKAGE REPOSITORY
#==============================================================================

install -d -m 0755 /etc/apt/keyrings
curl --fail --location --silent --show-error https://download.docker.com/linux/ubuntu/gpg --output /etc/apt/keyrings/docker.asc
chmod 0644 /etc/apt/keyrings/docker.asc
architecture=$(dpkg --print-architecture)
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' "$architecture" "$distribution_codename" > /etc/apt/sources.list.d/docker.list

#==============================================================================
# PINNED PACKAGE INSTALLATION
#==============================================================================

apt_get_options=(-o DPkg::Lock::Timeout=300)
apt-get "${apt_get_options[@]}" update >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get "${apt_get_options[@]}" install --yes --quiet --allow-downgrades \
  "docker-ce=$engine_version" "docker-ce-cli=$engine_version" \
  "containerd.io=$containerd_version" "docker-buildx-plugin=$buildx_version" \
  "docker-compose-plugin=$compose_version" >/dev/null

#==============================================================================
# SERVICE ACTIVATION AND VERIFICATION
#==============================================================================

systemctl enable --now docker
docker version >/dev/null
docker compose version >/dev/null
printf 'docker_install=ready\n'