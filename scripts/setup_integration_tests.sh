#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root (parent of scripts directory)
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Integration test directory
INTEGRATION_TEST_DIR="$REPO_ROOT/integration_test"

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "Error: Java is not installed. Please install Java to run the tests."
    exit 1
fi

# Check Java version (Imposter requires Java 11 or higher)
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [[ $(echo "$JAVA_VERSION" | cut -d. -f1) -lt 11 ]]; then
    echo "Error: Java 11 or higher is required. Found version $JAVA_VERSION"
    exit 1
fi

# Compile Tonik to native executable for faster generation
# Native compilation eliminates Dart JIT overhead, resulting in 7-8x faster generation
# (e.g., ~4s -> ~0.5s for typical specs)
echo "Compiling Tonik to native executable..."
TONIK_BINARY="$REPO_ROOT/.dart_tool/tonik_compiled"
dart compile exe "$REPO_ROOT/packages/tonik/bin/tonik.dart" -o "$TONIK_BINARY"
echo "Tonik compiled successfully: $TONIK_BINARY"

# Change to integration test directory
cd "$INTEGRATION_TEST_DIR"
echo "Working directory: $(pwd)"

# Function to restore local dependency overrides to test packages
# This reverts changes made by verify_published_version.sh
restore_test_package_overrides() {
    local test_pubspec="$1"
    local override_path="$2"
    
    if [ -f "$test_pubspec" ]; then
        echo "Restoring local dependency overrides in $test_pubspec"
        
        # Add dependency_overrides section if it doesn't exist
        if ! grep -q "dependency_overrides:" "$test_pubspec"; then
            echo "" >> "$test_pubspec"
            echo "dependency_overrides:" >> "$test_pubspec"
            echo "  tonik_util:" >> "$test_pubspec"
            echo "    path: $override_path" >> "$test_pubspec"
        fi
    fi
}

# Function to add dependency overrides to generated packages
add_dependency_overrides() {
    local pubspec_file="$1"
    local relative_path="$2"
    
    if [ -f "$pubspec_file" ]; then
        echo "Adding dependency overrides to $pubspec_file"
        
        # Add dependency_overrides section if it doesn't exist
        if ! grep -q "dependency_overrides:" "$pubspec_file"; then
            echo "" >> "$pubspec_file"
            echo "dependency_overrides:" >> "$pubspec_file"
            echo "  tonik_util:" >> "$pubspec_file"
            echo "    path: $relative_path" >> "$pubspec_file"
        fi
    else
        echo "Warning: $pubspec_file not found"
    fi
}

# Function to add dependency overrides to all pubspec files in a directory
add_dependency_overrides_recursive() {
    local base_dir="$1"
    
    # Find all pubspec.yaml files in the directory
    find "$base_dir" -name "pubspec.yaml" -type f | while read -r pubspec_file; do
        # Calculate relative path depth from pubspec location to packages/tonik_util
        local depth=$(echo "$pubspec_file" | sed "s|$base_dir||" | grep -o "/" | wc -l)
        local relative_path=""
        for ((i=0; i<depth+2; i++)); do
            relative_path="../$relative_path"
        done
        relative_path="${relative_path}packages/tonik_util"
        
        add_dependency_overrides "$pubspec_file" "$relative_path"
    done
}

# Remove existing generated API projects before regenerating
echo "Cleaning up existing generated API projects..."
rm -rf additional_properties/additional_properties_api
rm -rf defaulted/defaulted_api
rm -rf petstore/petstore_api
rm -rf petstore_config/petstore_api
rm -rf petstore_config/petstore_filtering_api
rm -rf petstore_config/petstore_overrides_api
rm -rf petstore_config/petstore_deprecation_api
rm -rf music_streaming/music_streaming_api
rm -rf gov/gov_api
rm -rf simple_encoding/simple_encoding_api
rm -rf fastify_type_provider_zod/fastify_type_provider_zod_api
rm -rf composition/composition_api
rm -rf query_parameters/query_parameters_api
rm -rf allow_reserved/allow_reserved_api
rm -rf path_encoding/path_encoding_api
rm -rf binary_models/binary_models_api
rm -rf structured_syntax_suffix/structured_syntax_suffix_api
rm -rf form_urlencoded/form_urlencoded_api
rm -rf boolean_schemas/boolean_schemas_api
rm -rf type_arrays/type_arrays_api
rm -rf medama/medama_api
rm -rf inference/inference_api
rm -rf ref_siblings/ref_siblings_api
rm -rf defs/defs_api
rm -rf server_variables/server_variables_api
rm -rf cookies/cookies_api
rm -rf read_write_only/read_write_only_api
rm -rf multipart/multipart_api
rm -rf multipart/multipart_3_1_api
rm -rf adversarial_strings/adversarial_strings_api
rm -rf figma/figma_api
rm -rf stripe/stripe_api
rm -rf github/github_api
rm -rf openai/openai_full_api
rm -rf asana/asana_api
rm -rf twilio/twilio_api
rm -rf shopify/shopify_api
rm -rf kubernetes/kubernetes_api
rm -rf cloudflare/cloudflare_api
rm -rf totem/totem_api
rm -rf immutable_collections/immutable_collections_api
rm -rf naming/naming_api
rm -rf recursive_map/recursive_map_api

# Generate API code with automatic dependency overrides for local tonik_util.
# Using the compiled binary for much faster generation. Generations are
# independent, so run them in bounded-parallel batches (one slot per CPU core)
# instead of sequentially. Largest specs come first so the long poles overlap
# rather than serialising at the tail.
if command -v nproc &> /dev/null; then
    GEN_JOBS=$(nproc)
elif command -v sysctl &> /dev/null; then
    GEN_JOBS=$(sysctl -n hw.ncpu)
else
    GEN_JOBS=4
fi
echo "Generating API packages in parallel (max $GEN_JOBS jobs)..."

GEN_CMDS=(
  "$TONIK_BINARY --config cloudflare/tonik.yaml"
  "$TONIK_BINARY --config github/tonik.yaml"
  "$TONIK_BINARY --config stripe/tonik.yaml"
  "$TONIK_BINARY --config shopify/tonik.yaml"
  "$TONIK_BINARY --config asana/tonik.yaml"
  "$TONIK_BINARY --config kubernetes/tonik.yaml"
  "$TONIK_BINARY --config twilio/tonik.yaml"
  "$TONIK_BINARY --config openai/tonik_full.yaml"
  "$TONIK_BINARY -p additional_properties_api -s additional_properties/openapi.yaml -o additional_properties"
  "$TONIK_BINARY -p defaulted_api -s defaulted/openapi.yaml -o defaulted"
  "$TONIK_BINARY --config petstore/tonik.yaml"
  "$TONIK_BINARY -p petstore_api -s petstore_config/openapi.yaml -o petstore_config"
  "$TONIK_BINARY --config petstore_config/tonik_filtering.yaml"
  "$TONIK_BINARY --config petstore_config/tonik_overrides.yaml"
  "$TONIK_BINARY --config petstore_config/tonik_deprecation.yaml"
  "$TONIK_BINARY -p music_streaming_api -s music_streaming/openapi.yaml -o music_streaming"
  "$TONIK_BINARY -p gov_api -s gov/openapi.yaml -o gov"
  "$TONIK_BINARY -p simple_encoding_api -s simple_encoding/openapi.yaml -o simple_encoding"
  "$TONIK_BINARY -p fastify_type_provider_zod_api -s fastify_type_provider_zod/openapi.json -o fastify_type_provider_zod"
  "$TONIK_BINARY -p composition_api -s composition/openapi.yaml -o composition"
  "$TONIK_BINARY -p query_parameters_api -s query_parameters/openapi.yaml -o query_parameters"
  "$TONIK_BINARY -p allow_reserved_api -s allow_reserved/openapi.yaml -o allow_reserved"
  "$TONIK_BINARY -p path_encoding_api -s path_encoding/openapi.yaml -o path_encoding"
  "$TONIK_BINARY --config binary_models/tonik.yaml -p binary_models_api -s binary_models/openapi.yaml -o binary_models"
  "$TONIK_BINARY -p structured_syntax_suffix_api -s structured_syntax_suffix/openapi.yaml -o structured_syntax_suffix"
  "$TONIK_BINARY --config form_urlencoded/tonik_custom.yaml"
  "$TONIK_BINARY -p boolean_schemas_api -s boolean_schemas/openapi.yaml -o boolean_schemas"
  "$TONIK_BINARY -p type_arrays_api -s type_arrays/openapi.yaml -o type_arrays"
  "$TONIK_BINARY -p medama_api -s medama/openapi.yaml -o medama"
  "$TONIK_BINARY -p inference_api -s inference/openapi.json -o inference"
  "$TONIK_BINARY -p ref_siblings_api -s ref_siblings/openapi.yaml -o ref_siblings"
  "$TONIK_BINARY -p defs_api -s defs/openapi.yaml -o defs"
  "$TONIK_BINARY -p server_variables_api -s server_variables/openapi.yaml -o server_variables"
  "$TONIK_BINARY -p cookies_api -s cookies/openapi.yaml -o cookies"
  "$TONIK_BINARY -p read_write_only_api -s read_write_only/openapi.yaml -o read_write_only"
  "$TONIK_BINARY --config multipart/tonik.yaml"
  "$TONIK_BINARY --config multipart/tonik_3_1.yaml"
  "$TONIK_BINARY -p adversarial_strings_api -s adversarial_strings/openapi.yaml -o adversarial_strings"
  "$TONIK_BINARY --config figma/tonik.yaml"
  "$TONIK_BINARY --config totem/tonik.yaml"
  "$TONIK_BINARY --config immutable_collections/tonik.yaml"
  "$TONIK_BINARY -p naming_api -s naming/openapi.yaml -o naming"
  "$TONIK_BINARY -p recursive_map_api -s recursive_map/openapi.yaml -o recursive_map"
)

gen_pids=()
for cmd in "${GEN_CMDS[@]}"; do
    bash -c "$cmd" &
    gen_pids+=("$!")
    if [ "${#gen_pids[@]}" -ge "$GEN_JOBS" ]; then
        for pid in "${gen_pids[@]}"; do
            wait "$pid" || { echo "Error: API generation failed"; exit 1; }
        done
        gen_pids=()
    fi
done
for pid in "${gen_pids[@]}"; do
    wait "$pid" || { echo "Error: API generation failed"; exit 1; }
done
echo "All API packages generated"

# Add local tonik_util dependency overrides to every generated package.
add_dependency_overrides_recursive "additional_properties/additional_properties_api"
add_dependency_overrides_recursive "defaulted/defaulted_api"
add_dependency_overrides_recursive "petstore/petstore_api"
add_dependency_overrides_recursive "petstore_config/petstore_api"
add_dependency_overrides_recursive "petstore_config/petstore_filtering_api"
add_dependency_overrides_recursive "petstore_config/petstore_overrides_api"
add_dependency_overrides_recursive "petstore_config/petstore_deprecation_api"
add_dependency_overrides_recursive "music_streaming/music_streaming_api"
add_dependency_overrides_recursive "gov/gov_api"
add_dependency_overrides_recursive "simple_encoding/simple_encoding_api"
add_dependency_overrides_recursive "fastify_type_provider_zod/fastify_type_provider_zod_api"
add_dependency_overrides_recursive "composition/composition_api"
add_dependency_overrides_recursive "query_parameters/query_parameters_api"
add_dependency_overrides_recursive "allow_reserved/allow_reserved_api"
add_dependency_overrides_recursive "path_encoding/path_encoding_api"
add_dependency_overrides_recursive "binary_models/binary_models_api"
add_dependency_overrides_recursive "structured_syntax_suffix/structured_syntax_suffix_api"
add_dependency_overrides_recursive "form_urlencoded/form_urlencoded_api"
add_dependency_overrides_recursive "boolean_schemas/boolean_schemas_api"
add_dependency_overrides_recursive "type_arrays/type_arrays_api"
add_dependency_overrides_recursive "medama/medama_api"
add_dependency_overrides_recursive "inference/inference_api"
add_dependency_overrides_recursive "ref_siblings/ref_siblings_api"
add_dependency_overrides_recursive "defs/defs_api"
add_dependency_overrides_recursive "server_variables/server_variables_api"
add_dependency_overrides_recursive "cookies/cookies_api"
add_dependency_overrides_recursive "read_write_only/read_write_only_api"
add_dependency_overrides_recursive "multipart/multipart_api"
add_dependency_overrides_recursive "multipart/multipart_3_1_api"
add_dependency_overrides_recursive "adversarial_strings/adversarial_strings_api"
add_dependency_overrides_recursive "figma/figma_api"
add_dependency_overrides_recursive "stripe/stripe_api"
add_dependency_overrides_recursive "github/github_api"
add_dependency_overrides_recursive "openai/openai_full_api"
add_dependency_overrides_recursive "asana/asana_api"
add_dependency_overrides_recursive "twilio/twilio_api"
add_dependency_overrides_recursive "shopify/shopify_api"
add_dependency_overrides_recursive "kubernetes/kubernetes_api"
add_dependency_overrides_recursive "cloudflare/cloudflare_api"
add_dependency_overrides_recursive "totem/totem_api"
add_dependency_overrides_recursive "immutable_collections/immutable_collections_api"
add_dependency_overrides_recursive "naming/naming_api"
add_dependency_overrides_recursive "recursive_map/recursive_map_api"

# Run dart pub get for all generated packages in parallel
echo "Running dart pub get for all generated packages in parallel..."
(
  cd additional_properties/additional_properties_api && dart pub get &
  cd defaulted/defaulted_api && dart pub get &
  cd petstore/petstore_api && dart pub get &
  cd petstore_config/petstore_api && dart pub get &
  cd petstore_config/petstore_filtering_api && dart pub get &
  cd petstore_config/petstore_overrides_api && dart pub get &
  cd petstore_config/petstore_deprecation_api && dart pub get &
  cd music_streaming/music_streaming_api && dart pub get &
  cd gov/gov_api && dart pub get &
  cd simple_encoding/simple_encoding_api && dart pub get &
  cd fastify_type_provider_zod/fastify_type_provider_zod_api && dart pub get &
  cd composition/composition_api && dart pub get &
  cd query_parameters/query_parameters_api && dart pub get &
  cd allow_reserved/allow_reserved_api && dart pub get &
  cd path_encoding/path_encoding_api && dart pub get &
  cd binary_models/binary_models_api && dart pub get &
  cd structured_syntax_suffix/structured_syntax_suffix_api && dart pub get &
  cd form_urlencoded/form_urlencoded_api && dart pub get &
  cd boolean_schemas/boolean_schemas_api && dart pub get &
  cd type_arrays/type_arrays_api && dart pub get &
  cd medama/medama_api && dart pub get &
  cd inference/inference_api && dart pub get &
  cd ref_siblings/ref_siblings_api && dart pub get &
  cd defs/defs_api && dart pub get &
  cd server_variables/server_variables_api && dart pub get &
  cd cookies/cookies_api && dart pub get &
  cd read_write_only/read_write_only_api && dart pub get &
  cd multipart/multipart_api && dart pub get &
  cd multipart/multipart_3_1_api && dart pub get &
  cd adversarial_strings/adversarial_strings_api && dart pub get &
  cd figma/figma_api && dart pub get &
  cd stripe/stripe_api && dart pub get &
  cd github/github_api && dart pub get &
  cd openai/openai_full_api && dart pub get &
  cd asana/asana_api && dart pub get &
  cd twilio/twilio_api && dart pub get &
  cd shopify/shopify_api && dart pub get &
  cd kubernetes/kubernetes_api && dart pub get &
  cd cloudflare/cloudflare_api && dart pub get &
  cd totem/totem_api && dart pub get &
  cd immutable_collections/immutable_collections_api && dart pub get &
  cd naming/naming_api && dart pub get &
  cd recursive_map/recursive_map_api && dart pub get &
  wait
)
echo "All dart pub get operations completed"

# Download Imposter JAR only if it doesn't exist
if [ ! -f imposter.jar ]; then
    echo "Downloading Imposter JAR..."
    curl -L https://github.com/imposter-project/imposter-jvm-engine/releases/download/v4.6.8/imposter-4.6.8.jar \
         -o imposter.jar
else
    echo "Imposter JAR already exists, skipping download."
fi

# Verify Imposter JAR can be executed
echo "Verifying Imposter JAR..."
if ! java -jar imposter.jar --version &> /dev/null; then
    echo "Error: Failed to execute Imposter JAR. Please check the download."
    exit 1
fi

# Restore local dependency overrides to test packages
# This ensures test packages use local tonik_util during development
# (reverts any changes made by verify_published_version.sh)
echo "Restoring local dependency overrides in test packages..."
restore_test_package_overrides "additional_properties/additional_properties_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "defaulted/defaulted_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "petstore/petstore_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "petstore_config/petstore_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "music_streaming/music_streaming_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "gov/gov_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "simple_encoding/simple_encoding_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "fastify_type_provider_zod/fastify_type_provider_zod_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "composition/composition_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "query_parameters/query_parameters_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "allow_reserved/allow_reserved_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "path_encoding/path_encoding_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "binary_models/binary_models_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "structured_syntax_suffix/structured_syntax_suffix_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "form_urlencoded/form_urlencoded_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "boolean_schemas/boolean_schemas_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "type_arrays/type_arrays_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "medama/medama_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "inference/inference_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "ref_siblings/ref_siblings_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "defs/defs_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "server_variables/server_variables_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "cookies/cookies_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "read_write_only/read_write_only_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "multipart/multipart_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "adversarial_strings/adversarial_strings_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "figma/figma_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "stripe/stripe_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "github/github_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "openai/openai_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "asana/asana_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "twilio/twilio_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "shopify/shopify_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "kubernetes/kubernetes_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "cloudflare/cloudflare_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "totem/totem_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "immutable_collections/immutable_collections_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "naming/naming_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "recursive_map/recursive_map_test/pubspec.yaml" "../../../packages/tonik_util"

# Run dart pub get for all test packages in parallel
echo "Running dart pub get for all test packages in parallel..."
(
  cd additional_properties/additional_properties_test && dart pub get &
  cd defaulted/defaulted_test && dart pub get &
  cd petstore/petstore_test && dart pub get &
  cd petstore_config/petstore_test && dart pub get &
  cd music_streaming/music_streaming_test && dart pub get &
  cd gov/gov_test && dart pub get &
  cd simple_encoding/simple_encoding_test && dart pub get &
  cd fastify_type_provider_zod/fastify_type_provider_zod_test && dart pub get &
  cd composition/composition_test && dart pub get &
  cd query_parameters/query_parameters_test && dart pub get &
  cd allow_reserved/allow_reserved_test && dart pub get &
  cd path_encoding/path_encoding_test && dart pub get &
  cd binary_models/binary_models_test && dart pub get &
  cd structured_syntax_suffix/structured_syntax_suffix_test && dart pub get &
  cd form_urlencoded/form_urlencoded_test && dart pub get &
  cd boolean_schemas/boolean_schemas_test && dart pub get &
  cd type_arrays/type_arrays_test && dart pub get &
  cd medama/medama_test && dart pub get &
  cd inference/inference_test && dart pub get &
  cd ref_siblings/ref_siblings_test && dart pub get &
  cd defs/defs_test && dart pub get &
  cd server_variables/server_variables_test && dart pub get &
  cd cookies/cookies_test && dart pub get &
  cd read_write_only/read_write_only_test && dart pub get &
  cd multipart/multipart_test && dart pub get &
  cd adversarial_strings/adversarial_strings_test && dart pub get &
  cd figma/figma_test && dart pub get &
  cd stripe/stripe_test && dart pub get &
  cd github/github_test && dart pub get &
  cd openai/openai_test && dart pub get &
  cd asana/asana_test && dart pub get &
  cd twilio/twilio_test && dart pub get &
  cd shopify/shopify_test && dart pub get &
  cd kubernetes/kubernetes_test && dart pub get &
  cd cloudflare/cloudflare_test && dart pub get &
  cd totem/totem_test && dart pub get &
  cd immutable_collections/immutable_collections_test && dart pub get &
  cd naming/naming_test && dart pub get &
  cd recursive_map/recursive_map_test && dart pub get &
  wait
)
echo "All test package dependencies resolved"

echo "Setup completed successfully!"
