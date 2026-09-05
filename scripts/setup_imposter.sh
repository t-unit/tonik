#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMPOSTER_JAR="$REPO_ROOT/integration_test/imposter.jar"

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

if [ ! -f "$IMPOSTER_JAR" ]; then
  echo "Downloading Imposter JAR..."
  trap 'rm -f "$IMPOSTER_JAR.part"' EXIT
  curl -fL --retry 3 \
    https://github.com/imposter-project/imposter-jvm-engine/releases/download/v4.9.3/imposter-4.9.3.jar \
    -o "$IMPOSTER_JAR.part"
  mv "$IMPOSTER_JAR.part" "$IMPOSTER_JAR"
fi

if ! java -jar "$IMPOSTER_JAR" --version >/dev/null 2>&1; then
  echo "Error: failed to execute Imposter JAR." >&2
  exit 1
fi
