#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/integration_package_utils.sh"

discover_integration_packages current
analyze_integration_packages current "${INTEGRATION_ANALYSIS_JOBS-4}"

for package_dir in "${INTEGRATION_TEST_PACKAGES[@]}"; do
  echo "Testing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart test
  )
done
