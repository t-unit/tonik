#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../integration_test/streaming_response/streaming_response_test"
dart run tool/run_browser_tests.dart
