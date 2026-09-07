#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/integration_setup_utils.sh"

TEST_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/tonik-setup-test.XXXXXX")"
trap 'rm -rf "$TEST_DIRECTORY"' EXIT
trap 'echo "Setup script test failed at line $LINENO" >&2' ERR
unset INTEGRATION_SETUP_JOBS TONIK_WORKERS

# Defaults share ten CPUs between four generators, with serial operation on a
# single-core runner.
(
  configure_setup_workers 10
  [ "$SETUP_JOBS" = 4 ]
  [ "$TONIK_WORKERS" = 2 ]
)
(
  configure_setup_workers 1
  [ "$SETUP_JOBS" = 1 ]
  [ "$TONIK_WORKERS" = 1 ]
)

# Explicit generator workers reduce the default number of outer jobs. Explicit
# outer jobs instead determine the default per-generator worker count.
(
  TONIK_WORKERS=3
  configure_setup_workers 10
  [ "$SETUP_JOBS" = 3 ]
  [ "$TONIK_WORKERS" = 3 ]
)
(
  INTEGRATION_SETUP_JOBS=2
  configure_setup_workers 10
  [ "$SETUP_JOBS" = 2 ]
  [ "$TONIK_WORKERS" = 5 ]
)
(
  INTEGRATION_SETUP_JOBS=6
  TONIK_WORKERS=3
  configure_setup_workers 10
  [ "$SETUP_JOBS" = 6 ]
  [ "$TONIK_WORKERS" = 3 ]
)
(
  TONIK_WORKERS=0
  configure_setup_workers 10
  [ "$SETUP_JOBS" = 1 ]
  [ "$TONIK_WORKERS" = 0 ]
)

# Reject invalid settings before compiling or deleting generated clients.
status=0
(INTEGRATION_SETUP_JOBS=0; configure_setup_workers 10) 2>"$TEST_DIRECTORY/invalid-jobs" || status=$?
[ "$status" = 64 ]
grep -q 'INTEGRATION_SETUP_JOBS must be a positive integer' "$TEST_DIRECTORY/invalid-jobs"
status=0
(TONIK_WORKERS=invalid; configure_setup_workers 10) 2>"$TEST_DIRECTORY/invalid-workers" || status=$?
[ "$status" = 64 ]
grep -q 'TONIK_WORKERS must be a non-negative integer' "$TEST_DIRECTORY/invalid-workers"

mkdir "$TEST_DIRECTORY/commands with spaces"
cd "$TEST_DIRECTORY/commands with spaces"

# With one slot, the second command must wait for the first to finish.
run_commands 1 \
  'sleep 0.1; printf "first\n" > order' \
  'test "$(cat order)" = first && printf "second\n" >> order'
[ "$(cat order)" = "$(printf 'first\nsecond')" ]

# The first command waits for the third. A fixed batch cannot satisfy this;
# the deadline keeps a broken scheduler from hanging the test run.
status=0
run_commands 2 \
  'SECONDS=0; while [ ! -f third-started ] && [ "$SECONDS" -lt 10 ]; do sleep 0.05; done; test -f third-started' \
  'touch second-finished' \
  'test -f second-finished && touch third-started' || status=$?
[ "$status" = 0 ]
[ -f third-started ]

# An exit of 255 must be reported and must not make xargs abandon later work.
status=0
run_commands 1 'exit 255' 'touch finished-after-failure' 2>failure-log || status=$?
[ "$status" -ne 0 ]
[ -f finished-after-failure ]
grep -q 'command failed (exit 255,' failure-log

# Large overrides are bounded by the actual number of commands, without integer
# overflow. NUL-delimited dispatch preserves a command containing newlines.
(
  INTEGRATION_SETUP_JOBS=999999999999999999999999
  configure_setup_workers 10
  [ "$TONIK_WORKERS" = 1 ]
  run_commands "$SETUP_JOBS" 'printf "line one\nline two\n" > "multiline output"'
)
[ "$(cat 'multiline output')" = "$(printf 'line one\nline two')" ]

status=0
run_commands 0 'touch should-not-run' 2>invalid-pool || status=$?
[ "$status" = 64 ]
[ ! -f should-not-run ]
run_commands 2

echo "Integration setup tests passed."
