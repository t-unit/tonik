#!/bin/bash

set -e

# Publish script for Tonik monorepo
# Usage: ./scripts/publish.sh

echo "📤 Publishing Tonik packages to pub.dev"
echo ""

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  Warning: Working directory is not clean"
  git status --short
  echo ""
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "⚠️  Warning: You are on branch '$CURRENT_BRANCH', not 'main'"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "🔍 Checking what will be published (dry run)..."
echo ""
fvm dart run melos publish --dry-run

if [ $? -ne 0 ]; then
  echo "❌ Dry run failed"
  exit 1
fi

echo ""
echo "📋 Publish Summary:"
echo "-------------------"
echo "The packages listed above will be published to pub.dev"
echo "They will be published in dependency order:"
echo "  tonik_util → tonik_core → tonik_parse/tonik_generate → tonik"
echo ""

read -p "Proceed with publishing? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "ℹ️  Publishing cancelled"
  exit 0
fi

echo ""
echo "📤 Publishing to pub.dev..."
fvm dart run melos publish --no-dry-run --yes

if [ $? -ne 0 ]; then
  echo "❌ Publishing failed"
  echo ""
  echo "You can retry with:"
  echo "  ./scripts/publish.sh"
  exit 1
fi

echo ""
echo "🎉 Successfully published packages to pub.dev!"
echo ""
echo "Next steps:"
echo "  1. Verify packages on pub.dev"
echo "  2. Create GitHub release (optional)"
