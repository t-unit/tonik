# Release Process

## Automated Release Scripts

Use `set_version.sh` to update all package versions, inter-dependencies, and create git commit/tags. Then push changes and use `publish.sh` to publish to pub.dev:

```bash
./scripts/set_version.sh 0.0.9
git push origin main && git push origin --tags
./scripts/publish.sh
```

Both scripts include safety checks, run tests, and prompt for confirmation before making changes. The `set_version.sh` script uses melos to handle versioning and automatically updates the root workspace dependencies. The `publish.sh` script runs a dry-run first and publishes packages in dependency order.

## Package Dependency Chain

```
tonik_util (leaf)
  ↑
tonik_core
  ↑
tonik_parse    tonik_generate
  ↑                 ↑
  └────── tonik ────┘
```

## Quick Reference

```bash
# List packages
fvm dart run melos list

# Bootstrap workspace
fvm dart run melos bootstrap

# Test all packages
melos run test
```