#!/usr/bin/env bash

#==============================================================================
# VERSIONED BACKSTAGE BOOTSTRAP
#==============================================================================

#==============================================================================
# SHELL SAFETY
#==============================================================================

set -euo pipefail

#==============================================================================
# BOOTSTRAP INPUTS
#==============================================================================

action="${1:-validate}"
repository="${2:-}"
release="${3:-}"
base_url="${4:-http://localhost:7007}"
bind_address="${5:-127.0.0.1}"
restore_archive="${6:-}"
secret_bundle="${7:-}"

#==============================================================================
# INPUT VALIDATION
#==============================================================================

case "$action" in
  validate|dry-run|deploy|verify|status|backup|restore|rollback) ;;
  *) printf 'Invalid Backstage action.\n' >&2; exit 2 ;;
esac
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { printf 'Invalid repository.\n' >&2; exit 1; }
[[ "$release" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf 'Invalid release.\n' >&2; exit 1; }
if [[ "$action" =~ ^(deploy|verify|status|backup|restore|rollback)$ ]]; then
  if ! command -v sudo >/dev/null || ! sudo -n true; then
    printf 'Non-interactive sudo is required.\n' >&2
    exit 1
  fi
fi

#==============================================================================
# RELEASE ACQUISITION
#==============================================================================

temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT
curl --fail --location --silent --show-error "https://github.com/$repository/archive/refs/tags/$release.tar.gz" --output "$temporary_root/source.tar.gz"
mkdir "$temporary_root/source"
tar --extract --gzip --file "$temporary_root/source.tar.gz" --directory "$temporary_root/source" --strip-components=1

#==============================================================================
# LIFECYCLE ENVIRONMENT
#==============================================================================

run_environment=(
  "AUTOMATION_REF=$release"
  "BACKSTAGE_BASE_URL=$base_url"
  "BACKSTAGE_BIND_ADDRESS=$bind_address"
  "BACKSTAGE_RESTORE_ARCHIVE=$restore_archive"
)

#==============================================================================
# ACTION DISPATCH
#==============================================================================

if [[ "$action" == "deploy" ]]; then
  sudo -n bash "$temporary_root/source/scripts/install-docker.sh" deploy
  sudo -n env "${run_environment[@]}" bash "$temporary_root/source/scripts/manage.sh" "$action" "$secret_bundle"
elif [[ "$action" =~ ^(verify|status|backup|restore|rollback)$ ]]; then
  sudo -n env "${run_environment[@]}" bash "$temporary_root/source/scripts/manage.sh" "$action"
else
  bash "$temporary_root/source/scripts/install-docker.sh" "$action"
  env "${run_environment[@]}" bash "$temporary_root/source/scripts/manage.sh" "$action"
fi