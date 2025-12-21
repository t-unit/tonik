#!/bin/bash
set -e

# Script to verify a published version of tonik works correctly
# Usage: ./scripts/verify_published_version.sh <version>
# Example: ./scripts/verify_published_version.sh 0.1.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
INTEGRATION_TEST_DIR="$REPO_ROOT/integration_test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <version> [--generate-only] [--test-only]"
    echo ""
    echo "Arguments:"
    echo "  version        The version of tonik to verify (e.g., 0.1.0)"
    echo ""
    echo "Options:"
    echo "  --generate-only  Only generate API packages, don't run tests"
    echo "  --test-only      Only run tests (assumes packages are already generated)"
    echo ""
    echo "Examples:"
    echo "  $0 0.1.0                    # Generate and run all tests"
    echo "  $0 0.1.0 --generate-only    # Only generate API packages"
    echo "  $0 0.1.0 --test-only        # Only run tests"
    exit 1
fi

VERSION="$1"
GENERATE_ONLY=false
TEST_ONLY=false

# Parse additional arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --generate-only)
            GENERATE_ONLY=true
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$GENERATE_ONLY" = true ] && [ "$TEST_ONLY" = true ]; then
    print_error "Cannot use --generate-only and --test-only together"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       Tonik Published Version Verification Script              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Version to verify: $VERSION"
echo ""

# Check prerequisites
print_step "Checking prerequisites..."

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    print_error "Dart is not installed. Please install Dart SDK."
    exit 1
fi
print_success "Dart SDK found: $(dart --version 2>&1 | head -n1)"

# Check if Java is installed (required for Imposter mock server)
if ! command -v java &> /dev/null; then
    print_error "Java is not installed. Please install Java to run the tests."
    exit 1
fi

# Check Java version (Imposter requires Java 11 or higher)
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
JAVA_MAJOR=$(echo "$JAVA_VERSION" | cut -d. -f1)
if [[ "$JAVA_MAJOR" -lt 11 ]]; then
    print_error "Java 11 or higher is required. Found version $JAVA_VERSION"
    exit 1
fi
print_success "Java found: version $JAVA_VERSION"

# Activate the specific version of tonik globally
print_step "Activating tonik version $VERSION from pub.dev..."
dart pub global activate tonik "$VERSION"

# Verify tonik is available and correct version
INSTALLED_VERSION=$(dart pub global run tonik --version 2>&1 || echo "unknown")
print_success "tonik activated: $INSTALLED_VERSION"

cd "$INTEGRATION_TEST_DIR"

# Function to update tonik_util version in a pubspec file
update_tonik_util_version() {
    local pubspec_file="$1"
    local target_version="$2"
    
    if [ -f "$pubspec_file" ] && grep -q "tonik_util:" "$pubspec_file"; then
        # Update tonik_util version constraint
        sed -i '' "s/tonik_util: \^[0-9]*\.[0-9]*\.[0-9]*/tonik_util: ^$target_version/" "$pubspec_file"
    fi
}

# Function to generate API package using published tonik
generate_api() {
    local name="$1"
    local spec_file="$2"
    local output_dir="$3"
    local extra_args="${4:-}"
    
    print_step "Generating $name..."
    rm -rf "$output_dir/${name}"
    
    # Change to the spec directory to allow tonik to discover tonik.yaml if it exists
    local spec_dir=$(dirname "$spec_file")
    local spec_basename=$(basename "$spec_file")
    cd "$spec_dir"
    
    # Run tonik from the spec directory (relative paths)
    dart pub global run tonik -p "$name" -s "$spec_basename" -o "../$output_dir" $extra_args
    
    # Return to integration test directory
    cd "$INTEGRATION_TEST_DIR"
    
    # Verify tonik_util version in generated package matches expected version
    local generated_pubspec="$output_dir/$name/pubspec.yaml"
    if [ -f "$generated_pubspec" ]; then
        local actual_version=$(grep "tonik_util: \^" "$generated_pubspec" | sed -E 's/.*tonik_util: \^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
        if [ "$actual_version" != "$VERSION" ]; then
            print_error "Generated package has wrong tonik_util version!"
            print_error "  Expected: ^$VERSION"
            print_error "  Found:    ^$actual_version"
            print_error "  File:     $generated_pubspec"
            exit 1
        fi
        print_success "Verified tonik_util version: ^$VERSION"
    fi
    
    # Run pub get in generated package
    cd "$output_dir/$name"
    dart pub get
    cd "$INTEGRATION_TEST_DIR"
    
    print_success "$name generated successfully"
}

# Function to update test package pubspec to use published tonik_util
update_test_pubspec_for_published() {
    local pubspec_file="$1"
    local tonik_util_version="$VERSION"
    
    if [ -f "$pubspec_file" ]; then
        print_step "Updating $pubspec_file for published version $tonik_util_version..."
        
        # Update tonik_util version constraint to match the version being tested
        # This handles version constraints like "^0.0.8" or "^0.1.0"
        if grep -q "tonik_util:" "$pubspec_file"; then
            sed -i '' "s/tonik_util: \^[0-9]*\.[0-9]*\.[0-9]*/tonik_util: ^$tonik_util_version/" "$pubspec_file"
            print_success "Updated tonik_util to ^$tonik_util_version"
        fi
        
        # Remove dependency_overrides section if it exists
        # This ensures we use the published version of tonik_util
        if grep -q "dependency_overrides:" "$pubspec_file"; then
            # Create a temp file without the dependency_overrides section
            awk '
                /^dependency_overrides:/ { skip = 1; next }
                skip && /^[^ ]/ { skip = 0 }
                !skip { print }
            ' "$pubspec_file" > "${pubspec_file}.tmp"
            mv "${pubspec_file}.tmp" "$pubspec_file"
            print_success "Removed dependency_overrides from $pubspec_file"
        fi
    fi
}

# Function to run tests for a test package
run_tests() {
    local test_dir="$1"
    local test_name="$2"
    
    print_step "Running tests for $test_name..."
    
    cd "$test_dir"
    
    # Update pubspec to use published versions
    update_test_pubspec_for_published "pubspec.yaml"
    
    # Get dependencies
    dart pub get
    
    # Run tests with concurrency=1 to avoid port conflicts with Imposter mock servers
    if dart test --concurrency=1; then
        print_success "$test_name tests passed"
        cd "$INTEGRATION_TEST_DIR"
        return 0
    else
        print_error "$test_name tests failed"
        cd "$INTEGRATION_TEST_DIR"
        return 1
    fi
}

# Download Imposter JAR if needed
if [ "$TEST_ONLY" = false ]; then
    print_step "Checking Imposter JAR..."
    if [ ! -f imposter.jar ]; then
        print_step "Downloading Imposter JAR..."
        curl -L https://github.com/imposter-project/imposter-jvm-engine/releases/download/v4.6.8/imposter-4.6.8.jar \
             -o imposter.jar
        print_success "Imposter JAR downloaded"
    else
        print_success "Imposter JAR already exists"
    fi
    
    # Verify Imposter JAR can be executed
    if ! java -jar imposter.jar --version &> /dev/null; then
        print_error "Failed to execute Imposter JAR. Please check the download."
        exit 1
    fi
fi

# Array to track test results
declare -a FAILED_TESTS=()

if [ "$TEST_ONLY" = false ]; then
    echo ""
    print_step "Generating API packages using tonik $VERSION..."
    echo ""
    
    # Clean up existing generated API projects
    print_step "Cleaning up existing generated API projects..."
    rm -rf petstore/petstore_api
    rm -rf music_streaming/music_streaming_api
    rm -rf gov/gov_api
    rm -rf simple_encoding/simple_encoding_api
    rm -rf fastify_type_provider_zod/fastify_type_provider_zod_api
    rm -rf composition/composition_api
    rm -rf query_parameters/query_parameters_api
    rm -rf path_encoding/path_encoding_api
    
    # Generate all API packages
    generate_api "petstore_api" "petstore/openapi.yaml" "petstore" "--log-level verbose"
    generate_api "music_streaming_api" "music_streaming/openapi.yaml" "music_streaming" "--log-level verbose"
    generate_api "gov_api" "gov/openapi.yaml" "gov"
    generate_api "simple_encoding_api" "simple_encoding/openapi.yaml" "simple_encoding" "--log-level verbose"
    generate_api "fastify_type_provider_zod_api" "fastify_type_provider_zod/openapi.json" "fastify_type_provider_zod" "--log-level verbose"
    generate_api "composition_api" "composition/openapi.yaml" "composition" "--log-level verbose"
    generate_api "query_parameters_api" "query_parameters/openapi.yaml" "query_parameters" "--log-level verbose"
    generate_api "path_encoding_api" "path_encoding/openapi.yaml" "path_encoding" "--log-level verbose"
    
    echo ""
    print_success "All API packages generated successfully!"
fi

if [ "$GENERATE_ONLY" = true ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    Generation Complete                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "API packages have been generated using tonik $VERSION"
    echo "Run with --test-only to execute tests"
    exit 0
fi

echo ""
print_step "Running integration tests..."
echo ""

# Run tests for each test package
TEST_PACKAGES=(
    "petstore/petstore_test:Petstore"
    "music_streaming/music_streaming_test:Music Streaming"
    "gov/gov_test:Gov"
    "simple_encoding/simple_encoding_test:Simple Encoding"
    "fastify_type_provider_zod/fastify_type_provider_zod_test:Fastify Type Provider Zod"
    "composition/composition_test:Composition"
    "query_parameters/query_parameters_test:Query Parameters"
    "path_encoding/path_encoding_test:Path Encoding"
)

for test_entry in "${TEST_PACKAGES[@]}"; do
    IFS=':' read -r test_dir test_name <<< "$test_entry"
    
    if [ -d "$test_dir" ]; then
        if ! run_tests "$test_dir" "$test_name"; then
            FAILED_TESTS+=("$test_name")
        fi
        echo ""
    else
        print_warning "Test directory not found: $test_dir"
    fi
done

# Print summary
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Test Summary                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Tonik version tested: $VERSION"
echo ""

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    print_success "All integration tests passed!"
    echo ""
    echo "🎉 Version $VERSION is verified and working correctly!"
    exit 0
else
    print_error "Some tests failed:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo "Please investigate the failures before using version $VERSION in production."
    exit 1
fi
