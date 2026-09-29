#!/usr/bin/env bash

#==============================================================================
# BACKSTAGE PLATFORM VALIDATION
#==============================================================================

#==============================================================================
# SHELL SAFETY
#==============================================================================

set -euo pipefail

#==============================================================================
# REQUIRED FILE VALIDATION
#==============================================================================

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
required_files=(app-config.yaml app-config.production.yaml catalog/all.yaml compose.yaml packages/backend/Dockerfile scripts/bootstrap.sh scripts/manage.sh systemd/backstage-platform-backup.service systemd/backstage-platform-backup.timer templates/all.yaml)
for required_file in "${required_files[@]}"; do
  [[ -f "$repository_root/$required_file" ]] || { printf 'Missing required file: %s\n' "$required_file" >&2; exit 1; }
done

#==============================================================================
# CONTAINER IMAGE VALIDATION
#==============================================================================

if grep -R --line-number --extended-regexp '(FROM|image:)[[:space:]]+[^[:space:]]+:latest([[:space:]]|$)' "$repository_root/packages/backend/Dockerfile" "$repository_root/compose.yaml"; then
  printf 'Container images must use pinned tags.\n' >&2
  exit 1
fi

#==============================================================================
# SECRET BUNDLE VALIDATION
#==============================================================================

sample_bundle='{"backend_secret":"01234567890123456789012345678901","github_token":"github-token-at-least-twenty","postgres_password":"postgres-password-at-least-sixteen"}'
for key in backend_secret github_token postgres_password; do
  jq -er --arg key "$key" '.[$key] | select(type == "string" and length > 0 and (contains("\n") | not))' <<< "$sample_bundle" >/dev/null
done

incomplete_bundle='{"backend_secret":"present"}'
if jq -e '
  type == "object" and
  all(
    "backend_secret",
    "github_token",
    "postgres_password";
    . as $key | $ARGS.named.bundle[$key]
  )
' --argjson bundle "$incomplete_bundle" <<< "$incomplete_bundle" >/dev/null; then
  printf 'Incomplete secret bundle was accepted.\n' >&2
  exit 1
fi

#==============================================================================
# OCI PAYLOAD VALIDATION
#==============================================================================

sample_arguments=$(jq -cn --arg bundle "$sample_bundle" '["deploy","bharathcloudops/backstage-platform","v1.0.0","https://backstage.bharathcloudops.com","10.10.10.69","",$bundle]')
argument_line=$(jq -r '[.[] | @sh] | "set -- " + join(" ")' <<< "$sample_arguments")
rendered_size=$(printf '%s\n%s' "$argument_line" "$(cat "$repository_root/scripts/bootstrap.sh")" | wc -c | tr -d ' ')
(( rendered_size <= 4096 )) || { printf 'Rendered bootstrap exceeds 4096 bytes.\n' >&2; exit 1; }

#==============================================================================
# DOCKER COMPOSE VALIDATION
#==============================================================================

if docker compose version >/dev/null 2>&1; then
  temporary_directory=$(mktemp -d)
  trap 'rm -rf "$temporary_directory"' EXIT
  mkdir "$temporary_directory/secrets"
  for secret in backend-secret github-token microsoft-client-id microsoft-client-secret microsoft-tenant-id postgres-password; do printf 'validation-only\n' > "$temporary_directory/secrets/$secret"; done
  cp "$repository_root/compose.yaml" "$temporary_directory/compose.yaml"
  BACKSTAGE_BASE_URL=https://backstage.example.invalid BACKSTAGE_BIND_ADDRESS=127.0.0.1 BACKSTAGE_VERSION=validation docker compose --project-directory "$temporary_directory" --file "$temporary_directory/compose.yaml" config --quiet
fi

if grep -Fq "\$VERSION_CODENAME" "$repository_root/scripts/install-docker.sh" || \
  ! grep -Fq "\"\$distribution_codename\"" "$repository_root/scripts/install-docker.sh" || \
  ! grep -Fq 'DPkg::Lock::Timeout=300' "$repository_root/scripts/install-docker.sh" || \
  ! grep -Fq -- '--allow-downgrades' "$repository_root/scripts/install-docker.sh" || \
  ! grep -Fq "dpkg-query --show --showformat='\${Version}' docker-ce" "$repository_root/scripts/install-docker.sh" || \
  ! grep -Fq "printf 'docker_install=unchanged" "$repository_root/scripts/install-docker.sh"; then
  printf 'Docker installation must use the validated distribution codename and allow pinned downgrades.\n' >&2
  exit 1
fi

if ! grep -Fq 'compose build --pull --progress plain' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq 'build_exit=$?' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq "tail -n 40 \"\$build_log\"" "$repository_root/scripts/manage.sh" || \
  grep -Fq "tail -n 40 \"\$build_log\" >&2" "$repository_root/scripts/manage.sh" || \
  grep -Fq 'docker builder prune --all --force' "$repository_root/scripts/bootstrap.sh" || \
  grep -Fq 'docker image prune --all --force' "$repository_root/scripts/bootstrap.sh" || \
  ! grep -Fq 'docker builder prune --force --filter until=168h' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq 'docker image prune --all --force' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq 'docker system df' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq 'prune_releases' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq 'deployment.sha256' "$repository_root/scripts/manage.sh" || \
  ! grep -Fq "printf 'backstage_deploy=unchanged" "$repository_root/scripts/manage.sh" || \
  ! grep -Fq "status) verify_stack; printf 'backstage_status=ready\\n'; compose ps --services --status running ;;" "$repository_root/scripts/manage.sh"; then
  printf 'Backstage lifecycle must bound disk usage and retain required markers within the OCI response limit.\n' >&2
  exit 1
fi

deploy_marker_line=$(grep -nF "printf 'backstage_deploy=ready\n'" "$repository_root/scripts/manage.sh" | head -n 1 | cut -d: -f1)
deploy_build_line=$(grep -nF '  compose build --pull --progress plain' "$repository_root/scripts/manage.sh" | cut -d: -f1)
if [[ -z "$deploy_marker_line" || -z "$deploy_build_line" ]] || (( deploy_marker_line >= deploy_build_line )); then
  printf 'Backstage deploy marker must precede the image build for OCI output capture.\n' >&2
  exit 1
fi

deploy_function=$(sed -n '/^deploy_stack() {$/,/^}$/p' "$repository_root/scripts/manage.sh")
if ! grep -Fq 'OnCalendar=*-*-* 03:30:00' "$repository_root/systemd/backstage-platform-backup.timer" || \
  ! grep -Fq 'Persistent=true' "$repository_root/systemd/backstage-platform-backup.timer" || \
  ! grep -Fq 'systemctl enable --now backstage-platform-backup.timer' <<< "$deploy_function" || \
  ! grep -Fq 'systemctl start backstage-platform-backup.service' <<< "$deploy_function" || \
  ! grep -Fq 'backstage_backup_last_success_timestamp_seconds' "$repository_root/scripts/manage.sh"; then
  printf 'Backstage deployment must schedule and seed monitored PostgreSQL backups.\n' >&2
  exit 1
fi

#==============================================================================
# VALIDATION RESULT
#==============================================================================

printf 'backstage_validation=ready\n'