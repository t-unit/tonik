#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/integration_package_utils.sh"

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 dio|http shard" >&2
  exit 64
fi

backend="$1"
shard="$2"
validate_integration_backend "$backend"
validate_integration_shard "$shard"
discover_integration_packages "$backend"

shard_packages=()
for index in "${!INTEGRATION_TEST_PACKAGES[@]}"; do
  if [ $((index % 3)) -eq "$shard" ]; then
    shard_packages+=("${INTEGRATION_TEST_PACKAGES[$index]}")
  fi
done
if [ "${#shard_packages[@]}" -eq 0 ]; then
  echo "Error: test shard $shard is empty for $backend." >&2
  exit 1
fi

echo "Test shard: backend=$backend shard=$shard packages=${#shard_packages[@]}"
for package_dir in "${shard_packages[@]}"; do
  echo "Testing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart pub get
    dart test --concurrency=2
  )
done
