#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/tonik-published-test.XXXXXX")"
trap 'rm -rf "$TEST_DIRECTORY"' EXIT
trap 'echo "Published-version verification test failed at line $LINENO" >&2' ERR

# Exercise the CLI in a disposable repository without activating packages or
# changing the checkout's integration manifests.
mkdir -p "$TEST_DIRECTORY/template/scripts" \
    "$TEST_DIRECTORY/template/integration_test/test_helpers" \
    "$TEST_DIRECTORY/template/integration_test/petstore/petstore_test" \
    "$TEST_DIRECTORY/bin"
cp "$SCRIPT_DIR/verify_published_version.sh" "$TEST_DIRECTORY/template/scripts/"

cat > "$TEST_DIRECTORY/template/integration_test/test_helpers/pubspec.yaml" <<'EOF'
name: test_helpers
dependencies:
  tonik_util: ^0.9.0
dependency_overrides:
  tonik_util:
    path: ../../packages/tonik_util
EOF
cat > "$TEST_DIRECTORY/template/integration_test/petstore/petstore_test/pubspec.yaml" <<'EOF'
name: petstore_test
dependencies:
  test_helpers:
    path: ../../test_helpers
  tonik_util: ^0.9.0
dependency_overrides:
  tonik_util:
    path: ../../../packages/tonik_util
EOF

cat > "$TEST_DIRECTORY/bin/java" <<'EOF'
#!/usr/bin/env bash
echo 'java version "21"' >&2
EOF
cat > "$TEST_DIRECTORY/bin/dart" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$VERIFY_TEST_LOG"
case "$*" in
    --version)
        echo 'Dart SDK version: test'
        ;;
    'pub global activate tonik 0.10.0')
        ;;
    'pub global run tonik --version')
        echo 'tonik 0.10.0'
        ;;
    'pub get')
        # Check the helper before resolving the fixture's dependencies.
        grep -q '^  tonik_util: \^0\.10\.0$' ../../test_helpers/pubspec.yaml
        if grep -q '^dependency_overrides:' ../../test_helpers/pubspec.yaml; then
            exit 1
        fi
        grep -q '^  tonik_util: \^0\.10\.0$' pubspec.yaml
        if grep -q '^dependency_overrides:' pubspec.yaml; then
            exit 1
        fi
        if [ "${VERIFY_FAIL_PUB_GET:-false}" = true ]; then
            echo 'Version solving failed.' >&2
            exit 65
        fi
        ;;
    test)
        ;;
    *)
        echo "Unexpected Dart command: $*" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$TEST_DIRECTORY/bin/dart" "$TEST_DIRECTORY/bin/java"
export PATH="$TEST_DIRECTORY/bin:$PATH"

# --test-only still prepares both the shared helper and the fixture manifest.
cp -R "$TEST_DIRECTORY/template" "$TEST_DIRECTORY/success"
VERIFY_TEST_LOG="$TEST_DIRECTORY/success-commands" \
    bash "$TEST_DIRECTORY/success/scripts/verify_published_version.sh" 0.10.0 --test-only \
    > "$TEST_DIRECTORY/success-output" 2>&1
cat > "$TEST_DIRECTORY/expected-success-commands" <<'EOF'
--version
pub global activate tonik 0.10.0
pub global run tonik --version
pub get
test
EOF
diff -u "$TEST_DIRECTORY/expected-success-commands" "$TEST_DIRECTORY/success-commands"
grep -q 'All integration tests passed!' "$TEST_DIRECTORY/success-output"

# A dependency-resolution failure must fail verification without running tests,
# even though run_tests is invoked inside a conditional in the verifier.
cp -R "$TEST_DIRECTORY/template" "$TEST_DIRECTORY/failure"
status=0
VERIFY_TEST_LOG="$TEST_DIRECTORY/failure-commands" VERIFY_FAIL_PUB_GET=true \
    bash "$TEST_DIRECTORY/failure/scripts/verify_published_version.sh" 0.10.0 --test-only \
    > "$TEST_DIRECTORY/failure-output" 2>&1 || status=$?
[ "$status" = 1 ]
cat > "$TEST_DIRECTORY/expected-failure-commands" <<'EOF'
--version
pub global activate tonik 0.10.0
pub global run tonik --version
pub get
EOF
diff -u "$TEST_DIRECTORY/expected-failure-commands" "$TEST_DIRECTORY/failure-commands"
grep -q 'Petstore dependency resolution failed' "$TEST_DIRECTORY/failure-output"
grep -q 'Some tests failed:' "$TEST_DIRECTORY/failure-output"

echo "Published-version verification tests passed."
