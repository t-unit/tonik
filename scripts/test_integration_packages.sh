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

echo "Tests: backend=$backend packages=${#INTEGRATION_TEST_PACKAGES[@]}"
for package_dir in "${INTEGRATION_TEST_PACKAGES[@]}"; do
  echo "Testing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart pub get
    dart test --concurrency=2
  )
done
