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

all_packages=(
  "${GENERATED_INTEGRATION_PACKAGES[@]}"
  "${INTEGRATION_TEST_PACKAGES[@]}"
)
shard_packages=()
for index in "${!all_packages[@]}"; do
  if [ $((index % 3)) -eq "$shard" ]; then
    shard_packages+=("${all_packages[$index]}")
  fi
done

if [ "$shard" -eq 0 ]; then
  if [ ! -d "$INTEGRATION_TEST_ROOT/test_helpers" ]; then
    echo "Error: integration test helper package is missing." >&2
    exit 1
  fi
  shard_packages+=(integration_test/test_helpers)
fi
if [ "${#shard_packages[@]}" -eq 0 ]; then
  echo "Error: analysis shard $shard is empty for $backend." >&2
  exit 1
fi

echo "Analysis shard: backend=$backend shard=$shard packages=${#shard_packages[@]}"
for package_dir in "${shard_packages[@]}"; do
  echo "Analyzing $package_dir"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    dart pub get
    dart analyze --fatal-infos --fatal-warnings
  )
done
