#!/usr/bin/env bash

INTEGRATION_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATION_REPO_ROOT="$(cd "$INTEGRATION_SCRIPT_DIR/.." && pwd)"
INTEGRATION_TEST_ROOT="$INTEGRATION_REPO_ROOT/integration_test"
EXPECTED_GENERATED_INTEGRATION_PACKAGES=44
EXPECTED_INTEGRATION_TEST_PACKAGES=40

validate_integration_backend() {
  local backend="$1"
  if [ "$backend" != "dio" ] && [ "$backend" != "http" ]; then
    echo "Error: backend must be either 'dio' or 'http'." >&2
    exit 64
  fi
}

discover_integration_packages() {
  local backend="$1"

  GENERATED_INTEGRATION_PACKAGES=()
  while IFS= read -r package_dir; do
    GENERATED_INTEGRATION_PACKAGES+=("$package_dir")
  done < <(
    cd "$INTEGRATION_REPO_ROOT"
    find integration_test -mindepth 2 -maxdepth 2 \
      -type d -name '*_api' -print | sort
  )

  INTEGRATION_TEST_PACKAGES=()
  while IFS= read -r package_dir; do
    INTEGRATION_TEST_PACKAGES+=("$package_dir")
  done < <(
    cd "$INTEGRATION_REPO_ROOT"
    find integration_test -mindepth 2 -maxdepth 2 \
      -type d -name '*_test' -print | sort
  )

  echo "Package discovery: backend=$backend generated=${#GENERATED_INTEGRATION_PACKAGES[@]} tests=${#INTEGRATION_TEST_PACKAGES[@]}"
  if [ "${#GENERATED_INTEGRATION_PACKAGES[@]}" -eq 0 ] || \
    [ "${#INTEGRATION_TEST_PACKAGES[@]}" -eq 0 ]; then
    echo "Error: generated and test package selections must not be empty for $backend." >&2
    exit 1
  fi
  if [ "${#GENERATED_INTEGRATION_PACKAGES[@]}" -ne \
    "$EXPECTED_GENERATED_INTEGRATION_PACKAGES" ] || \
    [ "${#INTEGRATION_TEST_PACKAGES[@]}" -ne \
      "$EXPECTED_INTEGRATION_TEST_PACKAGES" ]; then
    echo "Error: expected $EXPECTED_GENERATED_INTEGRATION_PACKAGES generated and $EXPECTED_INTEGRATION_TEST_PACKAGES test packages for $backend." >&2
    exit 1
  fi
}
