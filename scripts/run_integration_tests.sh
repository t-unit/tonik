#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INTEGRATION_TEST_DIR="$REPO_ROOT/integration_test"
ANALYZE_JOBS="${INTEGRATION_ANALYZE_JOBS:-2}"
TEST_JOBS="${INTEGRATION_TEST_JOBS:-4}"

run_commands() {
  local max_jobs="$1"
  shift
  local command
  local failed=0
  local -a pids=()
  local -a batch_commands=()

  for command in "$@"; do
    bash -c "$command" &
    pids+=("$!")
    batch_commands+=("$command")
    if [ "${#pids[@]}" -ge "$max_jobs" ]; then
      for index in "${!pids[@]}"; do
        if ! wait "${pids[$index]}"; then
          echo "Error: command failed: ${batch_commands[$index]}" >&2
          failed=1
        fi
      done
      [ "$failed" -eq 0 ] || return 1
      pids=()
      batch_commands=()
    fi
  done

  for index in "${!pids[@]}"; do
    if ! wait "${pids[$index]}"; then
      echo "Error: command failed: ${batch_commands[$index]}" >&2
      failed=1
    fi
  done
  [ "$failed" -eq 0 ]
}

GENERATED_MANIFESTS=()
while IFS= read -r manifest; do
  GENERATED_MANIFESTS+=("$manifest")
done < <(
  find "$INTEGRATION_TEST_DIR" -mindepth 3 -maxdepth 3 \
    -type f -path '*_api/pubspec.yaml' -print | sort
)

TEST_MANIFESTS=()
while IFS= read -r manifest; do
  TEST_MANIFESTS+=("$manifest")
done < <(
  find "$INTEGRATION_TEST_DIR" -mindepth 3 -maxdepth 3 \
    -type f -path '*_test/pubspec.yaml' -print | sort
)

maintained_source_count=0
for manifest in "${TEST_MANIFESTS[@]}"; do
  package_source_count="$(
    find "${manifest%/pubspec.yaml}" -type f -name '*.dart' -print |
      wc -l |
      tr -d ' '
  )"
  maintained_source_count=$((maintained_source_count + package_source_count))
done

if [ "${#GENERATED_MANIFESTS[@]}" -ne 44 ]; then
  echo "Error: expected 44 generated API packages, found ${#GENERATED_MANIFESTS[@]}." >&2
  exit 1
fi
if [ "${#TEST_MANIFESTS[@]}" -ne 40 ]; then
  echo "Error: expected 40 test packages, found ${#TEST_MANIFESTS[@]}." >&2
  exit 1
fi
if [ "$maintained_source_count" -ne 140 ]; then
  echo "Error: expected 140 maintained Dart test sources, found $maintained_source_count." >&2
  exit 1
fi

canonical_assertion_count="$(
  find "$INTEGRATION_TEST_DIR" -type f -path '*/test/*.dart' -print0 |
    xargs -0 grep -h -F 'expect(' |
    wc -l |
    tr -d ' '
)"
canonical_test_count="$(
  find "$INTEGRATION_TEST_DIR" -type f -path '*/test/*.dart' -print0 |
    xargs -0 grep -h -E '(^|[[:space:]])test\(' |
    wc -l |
    tr -d ' '
)"
empty_groups="$(
  find "$INTEGRATION_TEST_DIR" -type f -path '*/test/*.dart' -print0 |
    xargs -0 grep -n -E 'group\(.*\(\) \{\}\);' || true
)"

if [ "$canonical_assertion_count" -lt 7700 ]; then
  echo "Error: canonical assertion coverage fell below 7700; found $canonical_assertion_count." >&2
  exit 1
fi
if [ "$canonical_test_count" -lt 4030 ]; then
  echo "Error: canonical test coverage fell below 4030; found $canonical_test_count." >&2
  exit 1
fi
if [ -n "$empty_groups" ]; then
  echo "Error: empty integration test groups are forbidden:" >&2
  echo "$empty_groups" >&2
  exit 1
fi

backend=""
for manifest in "${GENERATED_MANIFESTS[@]}"; do
  candidate=""
  if grep -q '^  dio:' "$manifest"; then
    candidate="dio"
  elif grep -q '^  http:' "$manifest"; then
    candidate="http"
  fi
  if [ -z "$candidate" ]; then
    echo "Error: generated backend dependency missing from $manifest." >&2
    exit 1
  fi
  if [ -n "$backend" ] && [ "$candidate" != "$backend" ]; then
    echo "Error: generated integration packages use mixed backends." >&2
    exit 1
  fi
  backend="$candidate"
done

echo "Integration test inventory: backend=$backend generated=44 tests=40 sources=140 cases=$canonical_test_count assertions=$canonical_assertion_count"

ANALYZE_COMMANDS=(
  "cd '$INTEGRATION_TEST_DIR/test_helpers' && dart analyze --fatal-infos --fatal-warnings"
)
for manifest in "${GENERATED_MANIFESTS[@]}"; do
  ANALYZE_COMMANDS+=(
    "cd '${manifest%/pubspec.yaml}' && dart analyze --fatal-infos --fatal-warnings"
  )
done
for manifest in "${TEST_MANIFESTS[@]}"; do
  ANALYZE_COMMANDS+=(
    "cd '${manifest%/pubspec.yaml}' && dart analyze --fatal-infos --fatal-warnings"
  )
done

echo "Analyzing helper, generated, and test packages..."
run_commands "$ANALYZE_JOBS" "${ANALYZE_COMMANDS[@]}"

TEST_COMMANDS=(
  "cd '$INTEGRATION_TEST_DIR/test_helpers' && dart test"
)
for manifest in "${TEST_MANIFESTS[@]}"; do
  TEST_COMMANDS+=("cd '${manifest%/pubspec.yaml}' && dart test")
done

echo "Running helper tests and all 40 integration test packages for $backend..."
run_commands "$TEST_JOBS" "${TEST_COMMANDS[@]}"
echo "Integration tests complete: backend=$backend helper=1 tests=40"
