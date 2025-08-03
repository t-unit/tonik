#!/bin/bash
set -e

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

# Function to add dependency overrides to generated packages
add_dependency_overrides() {
    local pubspec_file="$1"
    
    if [ -f "$pubspec_file" ]; then
        echo "Adding dependency overrides to $pubspec_file"
        
        # Add dependency_overrides section if it doesn't exist
        if ! grep -q "dependency_overrides:" "$pubspec_file"; then
            echo "" >> "$pubspec_file"
            echo "dependency_overrides:" >> "$pubspec_file"
            echo "  tonik_util:" >> "$pubspec_file"
            echo "    path: ../../../packages/tonik_util" >> "$pubspec_file"
        fi
    else
        echo "Warning: $pubspec_file not found"
    fi
}

# Remove existing generated API projects before regenerating
echo "Cleaning up existing generated API projects..."
rm -rf petstore/petstore_api
rm -rf music_streaming/music_streaming_api
rm -rf gov/gov_api

# Generate API code with automatic dependency overrides for local tonik_util
dart run ../packages/tonik/bin/tonik.dart -p petstore_api -s petstore/openapi.yaml -o petstore  --log-level verbose
add_dependency_overrides "petstore/petstore_api/pubspec.yaml"
cd petstore/petstore_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p music_streaming_api -s music_streaming/openapi.yaml -o music_streaming --log-level verbose
add_dependency_overrides "music_streaming/music_streaming_api/pubspec.yaml"
cd music_streaming/music_streaming_api && dart pub get && cd ../..

dart run ../packages/tonik/bin/tonik.dart -p gov_api -s gov/openapi.yaml -o gov --log-level verbose
add_dependency_overrides "gov/gov_api/pubspec.yaml"
cd gov/gov_api && dart pub get && cd ../..

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

echo "Setup completed successfully!"