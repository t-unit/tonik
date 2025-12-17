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
        
        # Run pub get to apply the overrides
        local test_dir=$(dirname "$test_pubspec")
        echo "Running dart pub get in $test_dir"
        (cd "$test_dir" && dart pub get)
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
rm -rf petstore/petstore_api
rm -rf petstore_config/petstore_api
rm -rf petstore_config/petstore_filtering_api
rm -rf petstore_config/petstore_overrides_api
rm -rf music_streaming/music_streaming_api
rm -rf gov/gov_api
rm -rf simple_encoding/simple_encoding_api
rm -rf fastify_type_provider_zod/fastify_type_provider_zod_api
rm -rf composition/composition_api
rm -rf query_parameters/query_parameters_api
rm -rf path_encoding/path_encoding_api

# Generate API code with automatic dependency overrides for local tonik_util
dart run ../packages/tonik/bin/tonik.dart -p petstore_api -s petstore/openapi.yaml -o petstore --log-level verbose
add_dependency_overrides_recursive "petstore/petstore_api"
cd petstore/petstore_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p petstore_api -s petstore_config/openapi.yaml -o petstore_config --log-level verbose
add_dependency_overrides_recursive "petstore_config/petstore_api"
cd petstore_config/petstore_api && dart pub get && cd ../..

# Generate petstore_config with filtering configuration
dart run ../packages/tonik/bin/tonik.dart --config petstore_config/tonik_filtering.yaml --log-level verbose
add_dependency_overrides_recursive "petstore_config/petstore_filtering_api"
cd petstore_config/petstore_filtering_api && dart pub get && cd ../..

# Generate petstore_config with overrides configuration
dart run ../packages/tonik/bin/tonik.dart --config petstore_config/tonik_overrides.yaml --log-level verbose
add_dependency_overrides_recursive "petstore_config/petstore_overrides_api"
cd petstore_config/petstore_overrides_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p music_streaming_api -s music_streaming/openapi.yaml -o music_streaming --log-level verbose
add_dependency_overrides_recursive "music_streaming/music_streaming_api"
cd music_streaming/music_streaming_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p gov_api -s gov/openapi.yaml -o gov
add_dependency_overrides_recursive "gov/gov_api"
cd gov/gov_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p simple_encoding_api -s simple_encoding/openapi.yaml -o simple_encoding --log-level verbose
add_dependency_overrides_recursive "simple_encoding/simple_encoding_api"
cd simple_encoding/simple_encoding_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p fastify_type_provider_zod_api -s fastify_type_provider_zod/openapi.json -o fastify_type_provider_zod --log-level verbose
add_dependency_overrides_recursive "fastify_type_provider_zod/fastify_type_provider_zod_api"
cd fastify_type_provider_zod/fastify_type_provider_zod_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p composition_api -s composition/openapi.yaml -o composition --log-level verbose
add_dependency_overrides_recursive "composition/composition_api"
cd composition/composition_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p query_parameters_api -s query_parameters/openapi.yaml -o query_parameters --log-level verbose
add_dependency_overrides_recursive "query_parameters/query_parameters_api"
cd query_parameters/query_parameters_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p path_encoding_api -s path_encoding/openapi.yaml -o path_encoding --log-level verbose
add_dependency_overrides_recursive "path_encoding/path_encoding_api"
cd path_encoding/path_encoding_api && dart pub get && cd ../..

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
restore_test_package_overrides "petstore/petstore_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "petstore_config/petstore_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "music_streaming/music_streaming_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "gov/gov_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "simple_encoding/simple_encoding_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "fastify_type_provider_zod/fastify_type_provider_zod_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "composition/composition_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "query_parameters/query_parameters_test/pubspec.yaml" "../../../packages/tonik_util"
restore_test_package_overrides "path_encoding/path_encoding_test/pubspec.yaml" "../../../packages/tonik_util"

echo "Setup completed successfully!"
