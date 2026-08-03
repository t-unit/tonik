#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tonik-integration-state.XXXXXX")"
STATE_ARCHIVE="$STATE_DIR/tracked-state.tar"

cd "$REPO_ROOT"

STATE_FILES=(
  integration_test/test_helpers/pubspec.yaml
  integration_test/test_helpers/pubspec.lock
)
while IFS= read -r file; do
  STATE_FILES+=("$file")
done < <(
  find integration_test -mindepth 3 -maxdepth 3 -type f \
    \( -path '*_test/pubspec.yaml' -o -path '*_test/pubspec.lock' \) -print |
    sort
)

tar -cf "$STATE_ARCHIVE" "${STATE_FILES[@]}"

restore_state() {
  tar -xf "$STATE_ARCHIVE" -C "$REPO_ROOT"
  rm -rf "$STATE_DIR"
}
trap restore_state EXIT

./scripts/setup_integration_tests.sh --backend dio
melos run test-integration-current
./scripts/setup_integration_tests.sh --backend http
melos run test-integration-current
