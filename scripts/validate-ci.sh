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
docker run --rm --volume "$repository_root:/workspace" --workdir /workspace node:24-trixie \
  sh -c 'node .yarn/releases/yarn-4.13.0.cjs install --immutable && node .yarn/releases/yarn-4.13.0.cjs tsc && node .yarn/releases/yarn-4.13.0.cjs workspace app test --watch=false && node .yarn/releases/yarn-4.13.0.cjs workspace backend build'