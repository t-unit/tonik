#!/bin/bash

set -e

# Version update script for Tonik monorepo
# Usage: ./scripts/set_version.sh 0.0.9

if [ -z "$1" ]; then
  echo "Error: Version number required"
  echo "Usage: ./scripts/set_version.sh <version>"
  echo "Example: ./scripts/set_version.sh 0.0.9"
  exit 1
fi

VERSION=$1

echo "🔄 Setting version to $VERSION"
echo ""

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Error: Working directory is not clean"
  echo "Please commit or stash your changes first"
  git status --short
  exit 1
fi

# Check if on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "⚠️  Warning: You are on branch '$CURRENT_BRANCH', not 'main'"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "📦 Running tests before versioning..."
melos run test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Aborting version update."
  exit 1
fi
echo "✅ Tests passed"
echo ""

echo "🔄 Versioning packages with Melos..."
fvm dart run melos version \
  --all \
  --yes \
  --manual-version="tonik_util:$VERSION" \
  --manual-version="tonik_core:$VERSION" \
  --manual-version="tonik_parse:$VERSION" \
  --manual-version="tonik_generate:$VERSION" \
  --manual-version="tonik:$VERSION"

if [ $? -ne 0 ]; then
  echo "❌ Melos version command failed"
  exit 1
fi
echo "✅ Packages versioned"
echo ""

echo "🔍 Updating root workspace dependencies..."
# Update root pubspec.yaml dependencies
sed -i.bak -E "s/(tonik[_a-z]*: \^)[0-9]+\.[0-9]+\.[0-9]+/\1$VERSION/g" pubspec.yaml
rm pubspec.yaml.bak

# Check if there were changes
if [ -n "$(git diff pubspec.yaml)" ]; then
  echo "✅ Updated root workspace dependencies"
  git add pubspec.yaml
  git commit --amend --no-edit
else
  echo "✅ Root workspace dependencies already up to date"
fi
echo ""

echo "🧪 Bootstrapping and testing..."
fvm dart run melos bootstrap
melos run test
fvm dart analyze

if [ $? -ne 0 ]; then
  echo "❌ Tests or analysis failed after versioning"
  echo "Rolling back..."
  git reset --hard HEAD~1
  exit 1
fi
echo "✅ All checks passed"
echo ""

echo "📋 Version Update Summary:"
echo "-------------------------"
git log -1 --oneline
echo ""
echo "Tags created:"
git tag -l "*-v$VERSION"
echo ""
echo "✅ Version set to $VERSION"
echo ""
echo "Next steps:"
echo "  1. Review changes: git show HEAD"
echo "  2. Push changes: git push origin main && git push origin --tags"
echo "  3. Publish packages: ./scripts/publish.sh"
