#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: ./examples/run.sh EXAMPLE [--backend both|dio|http] [--update-spec]
                                [--timeout SECONDS]

Examples: python_fastapi, typescript_nestjs, javascript_fastify,
          java_spring_boot, ruby_rails, all

Build a local server, fetch its OpenAPI, generate Dart clients, and run the demos
and live tests. Both backends run by default. Requires Docker Compose, curl, and
Dart. Set TONIK_DART to choose a Dart SDK executable. These tests refuse CI.
HELP
}

fail() { echo "$*" >&2; exit 1; }

if [[ $# -eq 0 ]]; then usage; exit 1; fi
case "$1" in
  -h|--help) usage; exit 0 ;;
  all) examples=(python_fastapi typescript_nestjs javascript_fastify java_spring_boot ruby_rails) ;;
  python_fastapi|typescript_nestjs|javascript_fastify|java_spring_boot|ruby_rails) examples=("$1") ;;
  *) fail "Unknown example: $1. Use --help for available examples." ;;
esac
shift
backend=both
update_spec=false
timeout=180
while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) [[ $# -ge 2 ]] || fail '--backend needs a value'; backend=$2; shift 2 ;;
    --timeout) [[ $# -ge 2 ]] || fail '--timeout needs a value'; timeout=$2; shift 2 ;;
    --update-spec) update_spec=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
done
case "$backend" in
  both) backends=(dio http) ;;
  dio|http) backends=("$backend") ;;
  *) fail '--backend must be both, dio, or http' ;;
esac
[[ "$timeout" =~ ^[1-9][0-9]*$ ]] || fail '--timeout must be a positive integer'
case "${CI:-}" in [Tt][Rr][Uu][Ee]|1) fail 'Live examples are on-demand only; CI is refused.' ;; esac

# Resolve paths once so this script works from any working directory.
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
dart=${TONIK_DART:-dart}
if [[ -z "${TONIK_DART:-}" && -x .fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart ]]; then
  dart="$root/.fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart"
fi
if [[ "$dart" == */* && "$dart" != /* ]]; then
  dart="$root/$dart"
fi
command -v "$dart" >/dev/null || fail 'Dart is required; set TONIK_DART to its SDK executable.'
command -v docker >/dev/null || fail 'Docker Compose is required.'
command -v curl >/dev/null || fail 'curl is required.'
docker compose version >/dev/null
docker info >/dev/null

# Waiting on a child lets Bash handle interrupts immediately, including during a
# build or test. Stop that command before removing this run's containers.
child_pid=
active_example=
run_in() {
  local directory=$1
  shift
  (cd "$directory" && exec "$@") &
  child_pid=$!
  local result=0
  wait "$child_pid" || result=$?
  child_pid=
  return "$result"
}
interrupt() {
  if [[ -n "$child_pid" ]]; then
    kill "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  exit "$1"
}
cleanup() {
  [[ -n "$active_example" ]] || return 0
  local result=0
  "${compose[@]}" logs --no-color > "$artifact/server.log" 2>&1 || true
  "${compose[@]}" down --volumes --remove-orphans || result=1
  rmdir "$lock" || result=1
  active_example=
  return "$result"
}
trap 'exit_status=$?; cleanup || exit_status=1; exit "$exit_status"' EXIT
trap 'interrupt 130' INT
trap 'interrupt 143' TERM

run_in "$root" "$dart" pub get
mkdir -p examples/.artifacts examples/.locks
for example in "${examples[@]}"; do
  artifact="$root/examples/.artifacts/$example"
  lock="$root/examples/.locks/$example"
  project="tonik-example-${example//_/-}-$$"
  compose=(docker compose -f "$root/examples/compose.yaml" -p "$project" --profile "$example")
  mkdir "$lock" 2>/dev/null || fail "Cannot lock $example. Another run may be active; remove $lock only if it is stale."
  active_example=$example
  mkdir -p "$artifact"

  run_in "$root" "${compose[@]}" up --build --detach "$example"
  address=$("${compose[@]}" port "$example" 8000)
  base_url="http://$address"
  deadline=$((SECONDS + timeout))
  until curl --fail --silent --max-time 2 "$base_url/health" >/dev/null; do
    (( SECONDS < deadline )) || fail "$example did not become ready within ${timeout}s. See $artifact/server.log after cleanup."
    sleep 1
  done
  spec="$artifact/openapi.json"
  run_in "$root" curl --fail --silent --show-error --max-time 30 "$base_url/openapi.json" -o "$spec"

  client="$root/examples/$example/client"
  generated="$root/examples/$example/generated/${example}_api"
  for backend in "${backends[@]}"; do
    echo "Running $example with $backend"
    rm -rf "$generated"
    run_in "$root" "$dart" run packages/tonik/bin/tonik.dart \
      --config "examples/$example/tonik.yaml" --spec "$spec" \
      --output-dir "examples/$example/generated" --backend "$backend"
    cat > "$generated/pubspec_overrides.yaml" <<'OVERRIDES'
dependency_overrides:
  tonik_util:
    path: ../../../../packages/tonik_util
OVERRIDES
    run_in "$generated" "$dart" pub get
    run_in "$generated" "$dart" analyze --fatal-infos
    run_in "$client" "$dart" pub get
    run_in "$client" "$dart" analyze --fatal-infos
    run_in "$client" env TONIK_EXAMPLE_BASE_URL="$base_url" "$dart" run bin/example.dart
    run_in "$client" env TONIK_EXAMPLE_BASE_URL="$base_url" "$dart" test --reporter expanded
    echo "PASS $example / $backend"
  done
  if [[ "$update_spec" == true ]]; then
    cp "$spec" "examples/$example/openapi.json"
  fi
  cleanup
done
