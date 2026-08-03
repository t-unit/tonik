#!/usr/bin/env bash
set -euo pipefail

BACKEND="dio"
if [ "$#" -gt 0 ]; then
  if [ "$#" -ne 2 ] || [ "$1" != "--backend" ]; then
    echo "Usage: $0 [--backend dio|http]" >&2
    exit 64
  fi
  BACKEND="$2"
fi

if [ "$BACKEND" != "dio" ] && [ "$BACKEND" != "http" ]; then
  echo "Error: backend must be either 'dio' or 'http'." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INTEGRATION_TEST_DIR="$REPO_ROOT/integration_test"
TONIK_BINARY="$REPO_ROOT/.dart_tool/tonik_compiled"

if ! command -v java >/dev/null 2>&1; then
  echo "Error: Java is not installed. Please install Java to run the tests." >&2
  exit 1
fi

JAVA_VERSION="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
JAVA_MAJOR="$(printf '%s' "$JAVA_VERSION" | cut -d. -f1)"
if [ "$JAVA_MAJOR" -lt 11 ]; then
  echo "Error: Java 11 or higher is required. Found version $JAVA_VERSION" >&2
  exit 1
fi

if command -v nproc >/dev/null 2>&1; then
  SETUP_JOBS="$(nproc)"
elif command -v sysctl >/dev/null 2>&1; then
  SETUP_JOBS="$(sysctl -n hw.ncpu)"
else
  SETUP_JOBS=4
fi
SETUP_JOBS="${INTEGRATION_SETUP_JOBS:-$SETUP_JOBS}"

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

add_tonik_util_override() {
  local manifest="$1"
  local relative_path="$2"

  if [ ! -f "$manifest" ]; then
    echo "Error: package manifest not found: $manifest" >&2
    return 1
  fi
  if ! grep -q '^dependency_overrides:' "$manifest"; then
    printf '\ndependency_overrides:\n  tonik_util:\n    path: %s\n' \
      "$relative_path" >>"$manifest"
  fi
}

GENERATED_DIRS=(
  additional_properties/additional_properties_api
  defaulted/defaulted_api
  petstore/petstore_api
  petstore_config/petstore_api
  petstore_config/petstore_filtering_api
  petstore_config/petstore_overrides_api
  petstore_config/petstore_deprecation_api
  music_streaming/music_streaming_api
  gov/gov_api
  simple_encoding/simple_encoding_api
  fastify_type_provider_zod/fastify_type_provider_zod_api
  composition/composition_api
  query_parameters/query_parameters_api
  allow_reserved/allow_reserved_api
  path_encoding/path_encoding_api
  binary_models/binary_models_api
  structured_syntax_suffix/structured_syntax_suffix_api
  form_urlencoded/form_urlencoded_api
  boolean_schemas/boolean_schemas_api
  type_arrays/type_arrays_api
  medama/medama_api
  inference/inference_api
  ref_siblings/ref_siblings_api
  defs/defs_api
  server_variables/server_variables_api
  cookies/cookies_api
  read_write_only/read_write_only_api
  nullable_bodies/nullable_bodies_api
  multipart/multipart_api
  multipart/multipart_3_1_api
  adversarial_strings/adversarial_strings_api
  figma/figma_api
  stripe/stripe_api
  github/github_api
  openai/openai_full_api
  asana/asana_api
  twilio/twilio_api
  shopify/shopify_api
  kubernetes/kubernetes_api
  cloudflare/cloudflare_api
  totem/totem_api
  immutable_collections/immutable_collections_api
  naming/naming_api
  recursive_map/recursive_map_api
)

GENERATION_COMMANDS=(
  "$TONIK_BINARY --config cloudflare/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config github/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config stripe/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config shopify/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config asana/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config kubernetes/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config twilio/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config openai/tonik_full.yaml --backend $BACKEND"
  "$TONIK_BINARY -p additional_properties_api -s additional_properties/openapi.yaml -o additional_properties --backend $BACKEND"
  "$TONIK_BINARY -p defaulted_api -s defaulted/openapi.yaml -o defaulted --backend $BACKEND"
  "$TONIK_BINARY --config petstore/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY -p petstore_api -s petstore_config/openapi.yaml -o petstore_config --backend $BACKEND"
  "$TONIK_BINARY --config petstore_config/tonik_filtering.yaml --backend $BACKEND"
  "$TONIK_BINARY --config petstore_config/tonik_overrides.yaml --backend $BACKEND"
  "$TONIK_BINARY --config petstore_config/tonik_deprecation.yaml --backend $BACKEND"
  "$TONIK_BINARY -p music_streaming_api -s music_streaming/openapi.yaml -o music_streaming --backend $BACKEND"
  "$TONIK_BINARY -p gov_api -s gov/openapi.yaml -o gov --backend $BACKEND"
  "$TONIK_BINARY -p simple_encoding_api -s simple_encoding/openapi.yaml -o simple_encoding --backend $BACKEND"
  "$TONIK_BINARY -p fastify_type_provider_zod_api -s fastify_type_provider_zod/openapi.json -o fastify_type_provider_zod --backend $BACKEND"
  "$TONIK_BINARY -p composition_api -s composition/openapi.yaml -o composition --backend $BACKEND"
  "$TONIK_BINARY -p query_parameters_api -s query_parameters/openapi.yaml -o query_parameters --backend $BACKEND"
  "$TONIK_BINARY -p allow_reserved_api -s allow_reserved/openapi.yaml -o allow_reserved --backend $BACKEND"
  "$TONIK_BINARY -p path_encoding_api -s path_encoding/openapi.yaml -o path_encoding --backend $BACKEND"
  "$TONIK_BINARY --config binary_models/tonik.yaml -p binary_models_api -s binary_models/openapi.yaml -o binary_models --backend $BACKEND"
  "$TONIK_BINARY -p structured_syntax_suffix_api -s structured_syntax_suffix/openapi.yaml -o structured_syntax_suffix --backend $BACKEND"
  "$TONIK_BINARY --config form_urlencoded/tonik_custom.yaml --backend $BACKEND"
  "$TONIK_BINARY -p boolean_schemas_api -s boolean_schemas/openapi.yaml -o boolean_schemas --backend $BACKEND"
  "$TONIK_BINARY -p type_arrays_api -s type_arrays/openapi.yaml -o type_arrays --backend $BACKEND"
  "$TONIK_BINARY -p medama_api -s medama/openapi.yaml -o medama --backend $BACKEND"
  "$TONIK_BINARY -p inference_api -s inference/openapi.json -o inference --backend $BACKEND"
  "$TONIK_BINARY -p ref_siblings_api -s ref_siblings/openapi.yaml -o ref_siblings --backend $BACKEND"
  "$TONIK_BINARY -p defs_api -s defs/openapi.yaml -o defs --backend $BACKEND"
  "$TONIK_BINARY -p server_variables_api -s server_variables/openapi.yaml -o server_variables --backend $BACKEND"
  "$TONIK_BINARY -p cookies_api -s cookies/openapi.yaml -o cookies --backend $BACKEND"
  "$TONIK_BINARY -p read_write_only_api -s read_write_only/openapi.yaml -o read_write_only --backend $BACKEND"
  "$TONIK_BINARY -p nullable_bodies_api -s nullable_bodies/openapi.yaml -o nullable_bodies --backend $BACKEND"
  "$TONIK_BINARY --config multipart/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config multipart/tonik_3_1.yaml --backend $BACKEND"
  "$TONIK_BINARY -p adversarial_strings_api -s adversarial_strings/openapi.yaml -o adversarial_strings --backend $BACKEND"
  "$TONIK_BINARY --config figma/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config totem/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY --config immutable_collections/tonik.yaml --backend $BACKEND"
  "$TONIK_BINARY -p naming_api -s naming/openapi.yaml -o naming --backend $BACKEND"
  "$TONIK_BINARY -p recursive_map_api -s recursive_map/openapi.yaml -o recursive_map --backend $BACKEND"
)

if [ "${#GENERATED_DIRS[@]}" -ne 44 ] || [ "${#GENERATION_COMMANDS[@]}" -ne 44 ]; then
  echo "Error: integration fixture inventory must contain exactly 44 entries." >&2
  exit 1
fi

echo "Integration backend: $BACKEND"
echo "Compiling Tonik..."
dart compile exe "$REPO_ROOT/packages/tonik/bin/tonik.dart" -o "$TONIK_BINARY"

cd "$INTEGRATION_TEST_DIR"
echo "Cleaning 44 generated API packages..."
for directory in "${GENERATED_DIRS[@]}"; do
  rm -rf "$directory"
done

echo "Generating 44 API packages for $BACKEND (max $SETUP_JOBS jobs)..."
run_commands "$SETUP_JOBS" "${GENERATION_COMMANDS[@]}"

generated_count=0
for directory in "${GENERATED_DIRS[@]}"; do
  if [ ! -f "$directory/pubspec.yaml" ]; then
    echo "Error: generation did not create $directory/pubspec.yaml" >&2
    exit 1
  fi
  generated_count=$((generated_count + 1))
done

TEST_MANIFESTS=()
while IFS= read -r manifest; do
  TEST_MANIFESTS+=("$manifest")
done < <(find . -mindepth 3 -maxdepth 3 -type f -path '*_test/pubspec.yaml' -print | sort)

if [ "${#TEST_MANIFESTS[@]}" -ne 40 ]; then
  echo "Error: expected 40 checked-in test packages, found ${#TEST_MANIFESTS[@]}." >&2
  exit 1
fi

PUB_GET_COMMANDS=()
for directory in "${GENERATED_DIRS[@]}"; do
  add_tonik_util_override "$directory/pubspec.yaml" "../../../packages/tonik_util"
  PUB_GET_COMMANDS+=("cd '$directory' && dart pub get")
done
for manifest in "${TEST_MANIFESTS[@]}"; do
  add_tonik_util_override "$manifest" "../../../packages/tonik_util"
  PUB_GET_COMMANDS+=("cd '${manifest%/pubspec.yaml}' && dart pub get")
done
PUB_GET_COMMANDS+=("cd 'test_helpers' && dart pub get")

echo "Resolving dependencies for 44 generated, 40 test, and 1 helper package..."
run_commands "$SETUP_JOBS" "${PUB_GET_COMMANDS[@]}"

if [ ! -f imposter.jar ]; then
  echo "Downloading Imposter JAR..."
  curl -fL \
    https://github.com/imposter-project/imposter-jvm-engine/releases/download/v4.6.8/imposter-4.6.8.jar \
    -o imposter.jar
fi

if ! java -jar imposter.jar --version >/dev/null 2>&1; then
  echo "Error: failed to execute Imposter JAR." >&2
  exit 1
fi

echo "Setup complete: backend=$BACKEND generated=$generated_count tests=${#TEST_MANIFESTS[@]}"
