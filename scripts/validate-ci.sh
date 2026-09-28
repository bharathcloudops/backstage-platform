#!/usr/bin/env bash

#==============================================================================
# BACKSTAGE CONTINUOUS INTEGRATION VALIDATION
#==============================================================================

#==============================================================================
# SHELL SAFETY
#==============================================================================

set -euo pipefail

#==============================================================================
# REPOSITORY VALIDATION
#==============================================================================

bash scripts/validate.sh

#==============================================================================
# NODE BUILD VALIDATION
#==============================================================================

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
docker_arguments=(--rm)

if [[ -n "${JENKINS_CONTAINER_ID:-}" ]]; then
  docker_arguments+=(--volumes-from "$JENKINS_CONTAINER_ID" --workdir "$repository_root")
else
  docker_arguments+=(--volume "$repository_root:/workspace" --workdir /workspace)
fi

docker run "${docker_arguments[@]}" node:24-trixie \
  sh -c 'node .yarn/releases/yarn-4.13.0.cjs install --immutable && node .yarn/releases/yarn-4.13.0.cjs tsc && node .yarn/releases/yarn-4.13.0.cjs workspace app test --watch=false && node .yarn/releases/yarn-4.13.0.cjs workspace backend build'