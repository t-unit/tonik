#!/bin/bash

set -e

# Version update script for Tonik monorepo
# Usage: ./scripts/set_version.sh 0.0.9
# Usage (dry-run): ./scripts/set_version.sh 0.0.9 --dry-run

DRY_RUN=false
if [ "$2" = "--dry-run" ]; then
  DRY_RUN=true
fi

if [ -z "$1" ]; then
  echo "Error: Version number required"
  echo "Usage: ./scripts/set_version.sh <version> [--dry-run]"
  echo "Example: ./scripts/set_version.sh 0.0.9"
  echo "Example (dry-run): ./scripts/set_version.sh 0.0.9 --dry-run"
  exit 1
fi

VERSION=$1

if [ "$DRY_RUN" = true ]; then
  echo "🔍 DRY RUN MODE - Files will be updated and tests run, but no git commits/tags/push"
fi

echo "🔄 Setting version to $VERSION"
echo ""

# Check if working directory is clean (skip in dry-run)
if [ "$DRY_RUN" = false ]; then
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
fi

echo "📦 Running tests before versioning..."
melos run test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Aborting version update."
  exit 1
fi
echo "✅ Tests passed"
echo ""

if [ "$DRY_RUN" = false ]; then
  echo "🔄 Versioning packages with Melos (without tagging)..."
  fvm dart run melos version \
    --all \
    --yes \
    --no-git-tag-version \
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
  
  echo "🔗 Adding full changelog link to tonik package..."
  # Add link to root changelog after the version header
  TONIK_CHANGELOG="packages/tonik/CHANGELOG.md"
  if grep -q "^## $VERSION$" "$TONIK_CHANGELOG"; then
    # Check if link already exists
    if ! grep -q "For full changes across all packages" "$TONIK_CHANGELOG"; then
      # Add the link after the version header
      sed -i.bak "/^## $VERSION$/a\\
\\
For full changes across all tonik packages, see the [complete changelog](https://github.com/hatemake/tonik/blob/main/CHANGELOG.md).\\
" "$TONIK_CHANGELOG"
      rm "$TONIK_CHANGELOG.bak"
      git add "$TONIK_CHANGELOG"
      git commit --amend --no-edit
      echo "✅ Added full changelog link"
    else
      echo "✅ Full changelog link already present"
    fi
  else
    echo "⚠️  Version $VERSION not found in tonik changelog"
  fi
  echo ""
else
  echo "🔄 Skipping melos version (dry-run mode)"
  echo "  Note: Package pubspecs won't be updated, only root and generator"
  echo ""
fi

echo "🔍 Updating root workspace dependencies..."
# Update root pubspec.yaml dependencies
sed -i.bak -E "s/(tonik[_a-z]*: \^)[0-9]+\.[0-9]+\.[0-9]+/\1$VERSION/g" pubspec.yaml
rm pubspec.yaml.bak

# Update hardcoded tonik_util version in pubspec_generator.dart
sed -i.bak -E "s/(tonik_util: \^)[0-9]+\.[0-9]+\.[0-9]+/\1$VERSION/g" packages/tonik_generate/lib/src/pubspec_generator.dart
rm packages/tonik_generate/lib/src/pubspec_generator.dart.bak

if [ "$DRY_RUN" = false ]; then
  # Check if there were changes
  if [ -n "$(git diff pubspec.yaml packages/tonik_generate/lib/src/pubspec_generator.dart)" ]; then
    echo "✅ Updated root workspace dependencies and generator"
    git add pubspec.yaml packages/tonik_generate/lib/src/pubspec_generator.dart
    git commit --amend --no-edit
  else
    echo "✅ Root workspace dependencies and generator already up to date"
  fi
else
  echo "✅ Updated files (not committed):"
  echo "  - pubspec.yaml"
  echo "  - packages/tonik_generate/lib/src/pubspec_generator.dart"
fi
echo ""

echo "🧪 Bootstrapping and testing..."
fvm dart run melos bootstrap
melos run test
fvm dart analyze

if [ $? -ne 0 ]; then
  echo "❌ Tests or analysis failed after versioning"
  if [ "$DRY_RUN" = false ]; then
    echo "Rolling back..."
    git reset --hard HEAD~1
  fi
  exit 1
fi
echo "✅ All checks passed"
echo ""

if [ "$DRY_RUN" = false ]; then
  echo "🔄 Regenerating integration test packages with new version..."
  "$PWD/scripts/setup_integration_tests.sh"
  if [ $? -ne 0 ]; then
    echo "❌ Integration test regeneration failed"
    echo "Rolling back..."
    git reset --hard HEAD~1
    exit 1
  fi

  # Check if there were changes
  if [ -n "$(git status --porcelain integration_test)" ]; then
    echo "✅ Integration test packages regenerated"
    git add integration_test
    git commit --amend --no-edit
  else
    echo "✅ Integration test packages already up to date"
  fi
  echo ""
  
  # Create all tags after final commit
  echo "🏷️  Creating git tags..."
  for tag in tonik-v$VERSION tonik_util-v$VERSION tonik_core-v$VERSION tonik_parse-v$VERSION tonik_generate-v$VERSION; do
    git tag $tag
    echo "  ✅ Created $tag"
  done
  echo ""
else
  echo "🔄 Skipping integration test regeneration (dry-run mode)"
  echo ""
fi

if [ "$DRY_RUN" = false ]; then
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
else
  echo "📋 Dry Run Complete"
  echo "-------------------------"
  echo "✅ Version would be set to $VERSION"
  echo ""
  echo "To apply these changes, run:"
  echo "  ./scripts/set_version.sh $VERSION"
fi
