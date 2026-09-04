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

if [ ! -d "$INTEGRATION_TEST_ROOT/test_helpers" ]; then
  echo "Error: integration test helper package is missing." >&2
  exit 1
fi

all_packages=(
  "${GENERATED_INTEGRATION_PACKAGES[@]}"
  "${INTEGRATION_TEST_PACKAGES[@]}"
  integration_test/test_helpers
)

echo "Analysis: backend=$backend packages=${#all_packages[@]}"
for package_dir in "${all_packages[@]}"; do
  echo "Analyzing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart pub get
    dart analyze --fatal-infos --fatal-warnings
  )
done
