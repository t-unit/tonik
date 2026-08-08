#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/integration_package_utils.sh"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 dio|http" >&2
  exit 64
fi

backend="$1"
validate_integration_backend "$backend"
case "$backend" in
  dio) unselected_backend=http ;;
  http) unselected_backend=dio ;;
esac
discover_integration_packages "$backend"

dependency_names() {
  local package_dir="$1"
  local package_name="${package_dir##*/}"
  (
    cd "$INTEGRATION_REPO_ROOT/$package_dir"
    if ! dart pub get 1>&2; then
      exit 1
    fi
    dart pub deps --json
  ) | jq -r --arg target "$package_name" '
    INDEX(.packages[]; .name) as $packages
    | if $packages[$target] == null then
        error("Package \($target) is missing from dart pub deps output")
      else
        {
          pending: ($packages[$target].directDependencies // []),
          seen: {}
        }
        | until(
            (.pending | length) == 0;
            .pending[0] as $dependency
            | .pending = .pending[1:]
            | if .seen[$dependency] then
                .
              else
                .seen[$dependency] = true
                | .pending += (
                    $packages[$dependency].directDependencies // []
                  )
              end
          )
        | .seen
        | keys[]
      end
  '
}

require_dependency() {
  local package_dir="$1"
  local dependency="$2"
  local names="$3"
  if ! printf '%s\n' "$names" | grep -Fxq "$dependency"; then
    echo "Error: $package_dir must resolve $dependency for backend=$backend." >&2
    exit 1
  fi
}

reject_dependency() {
  local package_dir="$1"
  local dependency="$2"
  local names="$3"
  if printf '%s\n' "$names" | grep -Fxq "$dependency"; then
    echo "Error: $package_dir unexpectedly resolves $dependency for backend=$backend." >&2
    exit 1
  fi
}

for package_dir in "${GENERATED_INTEGRATION_PACKAGES[@]}"; do
  echo "Checking generated dependencies: backend=$backend package=$package_dir"
  names="$(dependency_names "$package_dir")"
  require_dependency "$package_dir" "$backend" "$names"
  reject_dependency "$package_dir" "$unselected_backend" "$names"
  if [ "$backend" = http ]; then
    reject_dependency "$package_dir" dio_web_adapter "$names"
  fi
done

handwritten_packages=(
  packages/tonik_util
  packages/tonik_core
  packages/tonik_parse
  packages/tonik_generate
  packages/tonik
)
for package_dir in "${handwritten_packages[@]}"; do
  echo "Checking handwritten dependencies: backend=$backend package=$package_dir"
  names="$(dependency_names "$package_dir")"
  reject_dependency "$package_dir" dio "$names"
  reject_dependency "$package_dir" dio_web_adapter "$names"
  reject_dependency "$package_dir" http "$names"
done

echo "Dependency isolation passed: backend=$backend generated=${#GENERATED_INTEGRATION_PACKAGES[@]} handwritten=${#handwritten_packages[@]}"
