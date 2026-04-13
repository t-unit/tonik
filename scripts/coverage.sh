#!/bin/bash
set -euo pipefail

# Collect test coverage for all workspace packages and produce an lcov report.
#
# Usage:
#   ./scripts/coverage.sh                  # full coverage report
#   ./scripts/coverage.sh --diff main      # show only lines changed vs a branch
#   ./scripts/coverage.sh --package tonik_generate  # single package

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIFF_BASE=""
SINGLE_PACKAGE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --diff)
      DIFF_BASE="$2"
      shift 2
      ;;
    --package)
      SINGLE_PACKAGE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--diff <branch>] [--package <name>]"
      exit 1
      ;;
  esac
done

PACKAGES=(tonik_util tonik_core tonik_parse tonik_generate tonik)

if [ -n "$SINGLE_PACKAGE" ]; then
  PACKAGES=("$SINGLE_PACKAGE")
fi

# Use fvm dart if available, otherwise plain dart
if command -v fvm &> /dev/null; then
  DART="fvm dart"
else
  DART="dart"
fi

COMBINED_LCOV="$REPO_ROOT/coverage/lcov.info"
mkdir -p "$REPO_ROOT/coverage"
rm -f "$COMBINED_LCOV"
touch "$COMBINED_LCOV"

echo "Collecting coverage..."

for pkg in "${PACKAGES[@]}"; do
  PKG_DIR="$REPO_ROOT/packages/$pkg"
  if [ ! -d "$PKG_DIR/test" ]; then
    continue
  fi
  echo "  $pkg..."
  TEST_OUTPUT=$(cd "$PKG_DIR" && $DART test --coverage-path=coverage/lcov.info --coverage-package="$pkg" 2>&1) || {
    echo "$TEST_OUTPUT"
    echo "ERROR: Tests failed for $pkg"
    exit 1
  }
  echo "$TEST_OUTPUT" | tail -1
  if [ -f "$PKG_DIR/coverage/lcov.info" ]; then
    cat "$PKG_DIR/coverage/lcov.info" >> "$COMBINED_LCOV"
  fi
done

echo ""
echo "Combined lcov written to: $COMBINED_LCOV"

# If --diff is set, filter to only changed lines and show uncovered ones
if [ -n "$DIFF_BASE" ]; then
  echo ""
  echo "=== Patch coverage vs $DIFF_BASE ==="
  echo ""

  # Get list of changed source files (not test files)
  CHANGED_FILES=$(git diff "$DIFF_BASE" --name-only -- 'packages/*/lib/**/*.dart')

  TOTAL_NEW=0
  TOTAL_COVERED=0
  TOTAL_MISSED=0

  for file in $CHANGED_FILES; do
    ABS_FILE="$REPO_ROOT/$file"
    if [ ! -f "$ABS_FILE" ]; then
      continue
    fi

    # Get new line numbers from diff
    NEW_LINES=$(git diff "$DIFF_BASE" --unified=0 -- "$file" | grep '^@@' | \
      sed -n 's/.*+\([0-9]*\),\{0,1\}\([0-9]*\).*/\1 \2/p' | \
      while read start count; do
        count=${count:-1}
        for ((i=start; i<start+count; i++)); do
          echo "$i"
        done
      done)

    if [ -z "$NEW_LINES" ]; then
      continue
    fi

    # Find this file in the lcov data
    FILE_COVERAGE=$(awk -v f="$ABS_FILE" '
      /^SF:/ { active = ($0 == "SF:" f) }
      active && /^DA:/ { print }
      active && /^end_of_record/ { active = 0 }
    ' "$COMBINED_LCOV")

    if [ -z "$FILE_COVERAGE" ]; then
      # File not in coverage data at all — count all new lines as missed
      COUNT=$(echo "$NEW_LINES" | wc -l | tr -d ' ')
      TOTAL_NEW=$((TOTAL_NEW + COUNT))
      TOTAL_MISSED=$((TOTAL_MISSED + COUNT))
      echo "  $file: NO COVERAGE DATA ($COUNT new lines)"
      continue
    fi

    MISSED_LINES=""
    FILE_NEW=0
    FILE_COVERED=0
    FILE_MISSED=0

    for lineno in $NEW_LINES; do
      # Check if this line appears in coverage data
      HIT=$(echo "$FILE_COVERAGE" | grep "^DA:${lineno}," | head -1 | cut -d, -f2 || true)
      if [ -n "$HIT" ]; then
        FILE_NEW=$((FILE_NEW + 1))
        TOTAL_NEW=$((TOTAL_NEW + 1))
        if [ "$HIT" = "0" ]; then
          FILE_MISSED=$((FILE_MISSED + 1))
          TOTAL_MISSED=$((TOTAL_MISSED + 1))
          MISSED_LINES="$MISSED_LINES $lineno"
        else
          FILE_COVERED=$((FILE_COVERED + 1))
          TOTAL_COVERED=$((TOTAL_COVERED + 1))
        fi
      fi
      # Lines not in DA (comments, blank lines, declarations) are not executable — skip
    done

    if [ "$FILE_NEW" -gt 0 ]; then
      if [ "$FILE_MISSED" -gt 0 ]; then
        PCT=$(( (FILE_COVERED * 100) / FILE_NEW ))
        echo "  $file: ${PCT}% ($FILE_MISSED missed)"
        echo "    Missing lines:$MISSED_LINES"
      else
        echo "  $file: 100%"
      fi
    fi
  done

  echo ""
  TOTAL_EXEC=$((TOTAL_COVERED + TOTAL_MISSED))
  if [ "$TOTAL_EXEC" -gt 0 ]; then
    PATCH_PCT=$(( (TOTAL_COVERED * 100) / TOTAL_EXEC ))
    echo "Patch coverage: ${PATCH_PCT}% ($TOTAL_COVERED/$TOTAL_EXEC executable lines covered, $TOTAL_MISSED missed)"
  else
    echo "No executable lines changed."
  fi
else
  # Generate HTML report
  if command -v genhtml &> /dev/null; then
    echo "Generating HTML report..."
    genhtml "$COMBINED_LCOV" -o "$REPO_ROOT/coverage/html" --no-function-coverage -q 2>&1 | tail -3
    echo "Open: $REPO_ROOT/coverage/html/index.html"
  else
    echo "Install lcov (brew install lcov) for HTML reports."
  fi
fi
