# Contributing to Tonik

Thanks for your interest in contributing!

## Prerequisites

- **Dart SDK** 3.10+
- **[FVM](https://fvm.app/)** (recommended) – run `fvm use` to switch to the pinned SDK version
- **[Melos](https://melos.invertase.dev/)** – install with `dart pub global activate melos`

## Setup

```bash
fvm use              # optional, use pinned SDK
melos bootstrap      # install dependencies for all packages
```

## Common Commands

See `melos.scripts` in the root [pubspec.yaml](pubspec.yaml) for all available commands:

```bash
melos run test                        # run tests for a package
melos run generate                    # run build_runner where needed
melos run generate-integration-tests  # regenerate integration test packages
```

## Architecture

For an overview of which package does what and how changes propagate, see [.github/copilot-instructions.md](.github/copilot-instructions.md).

## Conventions

Code style and development patterns are documented in [.cursor/rules/](.cursor/rules/):

- Test-driven development workflow
- Code organization patterns
- Working with `code_builder`
- Custom test matchers

## Pull Requests

1. **Tests** – add or update tests for your changes
2. **Style** – code must pass `very_good_analysis` (run `melos run analyze`)
3. **Scope** – keep PRs focused; split large changes into smaller PRs

## Questions?

Open an issue or start a discussion on GitHub.
