#!/usr/bin/env sh

#==============================================================================
# BACKSTAGE SECRET FILE ENTRYPOINT
#==============================================================================

#==============================================================================
# SHELL SAFETY
#==============================================================================

set -eu

#==============================================================================
# SECRET LOADER
#==============================================================================

load_secret() {
  variable_name="$1"
  file_variable_name="${variable_name}_FILE"
  eval "file_name=\${$file_variable_name:-}"
  if [ -n "$file_name" ]; then
    if [ ! -r "$file_name" ]; then
      printf 'Secret file is not readable for %s.\n' "$variable_name" >&2
      exit 1
    fi
    value=$(cat "$file_name")
    export "$variable_name=$value"
    unset "$file_variable_name"
  fi
}

#==============================================================================
# RUNTIME SECRET IMPORT
#==============================================================================

for variable_name in \
  BACKSTAGE_BACKEND_SECRET \
  GITHUB_TOKEN \
  POSTGRES_PASSWORD; do
  load_secret "$variable_name"
done

#==============================================================================
# APPLICATION EXECUTION
#==============================================================================

exec "$@"