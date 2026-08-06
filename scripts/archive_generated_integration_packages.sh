#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/integration_package_utils.sh"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 dio|http" >&2
  exit 64
fi

backend="$1"
validate_integration_backend "$backend"
discover_integration_packages "$backend"

cd "$INTEGRATION_REPO_ROOT"
tar -czf generated-integration-code.tar.gz \
  "${GENERATED_INTEGRATION_PACKAGES[@]}"
echo "Archived ${#GENERATED_INTEGRATION_PACKAGES[@]} generated packages for $backend."
