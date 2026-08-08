#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/integration_package_utils.sh"

discover_integration_packages current
if [ ! -d "$INTEGRATION_TEST_ROOT/test_helpers" ]; then
  echo "Error: integration test helper package is missing." >&2
  exit 1
fi

all_packages=(
  "${GENERATED_INTEGRATION_PACKAGES[@]}"
  "${INTEGRATION_TEST_PACKAGES[@]}"
  integration_test/test_helpers
)
for package_dir in "${all_packages[@]}"; do
  echo "Analyzing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart pub get
    dart analyze --fatal-infos --fatal-warnings
  )
done

for package_dir in "${INTEGRATION_TEST_PACKAGES[@]}"; do
  echo "Testing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart test
  )
done
