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

# Keep dependency resolution and analysis ordered within each package, while
# allowing independent packages to use the available analysis workers.
analyze_integration_packages() (
  local backend="$1"
  local analysis_jobs="$2"
  local analysis_logs
  local package_dir
  local package_index=0
  local failed=0
  local runner_failed=0
  local -a all_packages=(
    "${GENERATED_INTEGRATION_PACKAGES[@]}"
    "${INTEGRATION_TEST_PACKAGES[@]}"
    integration_test/test_helpers
  )
  local package_count="${#all_packages[@]}"

  if [[ ! "$analysis_jobs" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: INTEGRATION_ANALYSIS_JOBS must be a positive integer." >&2
    exit 64
  fi
  if [ ! -d "$INTEGRATION_TEST_ROOT/test_helpers" ]; then
    echo "Error: integration test helper package is missing." >&2
    exit 1
  fi

  # Compare lengths first so even very large valid overrides cannot overflow
  # shell arithmetic or xargs' worker-count argument.
  if [ "${#analysis_jobs}" -gt "${#package_count}" ] || \
    [ "$analysis_jobs" -gt "$package_count" ]; then
    analysis_jobs="$package_count"
  fi

  analysis_logs="$(mktemp -d "${TMPDIR:-/tmp}/tonik-analysis.XXXXXX")" || exit 1
  trap 'rm -rf "$analysis_logs"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  echo "Analysis: backend=$backend packages=$package_count workers=$analysis_jobs"

  # xargs -P maintains a rolling pool on both macOS' Bash 3.2 and Linux.
  # NUL-delimited arguments preserve paths containing spaces. Map every package
  # failure to exit 1: xargs stops dispatching early if a worker exits with 255.
  if for package_dir in "${all_packages[@]}"; do
    printf '%s\0' "$INTEGRATION_REPO_ROOT/$package_dir" \
      "$package_dir" "$analysis_logs/$package_index"
    package_index=$((package_index + 1))
  done | xargs -0 -n 3 -P "$analysis_jobs" bash -c '
    echo "Analyzing $2"
    if (
      cd "$1" &&
      dart pub get &&
      dart analyze --fatal-infos --fatal-warnings
    ) >"$3.log" 2>&1; then
      : >"$3.ok" || exit 1
      echo "Analysis passed: $2"
    else
      echo "Analysis failed: $2" >&2
      exit 1
    fi
  ' integration-analysis; then
    :
  else
    runner_failed=1
  fi

  # Print failures together, after every worker has finished, so diagnostics
  # remain readable and no package failure can be hidden by a later success.
  package_index=0
  for package_dir in "${all_packages[@]}"; do
    if [ ! -f "$analysis_logs/$package_index.ok" ]; then
      failed=$((failed + 1))
      echo "--- Analysis failed: $package_dir ---" >&2
      if [ -f "$analysis_logs/$package_index.log" ]; then
        cat "$analysis_logs/$package_index.log" >&2
      else
        echo "Error: analysis worker did not produce a log." >&2
      fi
    fi
    package_index=$((package_index + 1))
  done

  if [ "$runner_failed" -ne 0 ] || [ "$failed" -ne 0 ]; then
    echo "Error: integration analysis failed ($failed/$package_count packages)." >&2
    exit 1
  fi
  echo "Analysis complete: $package_count/$package_count packages passed."
)
