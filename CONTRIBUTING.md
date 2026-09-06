# Contributing to Tonik

Thanks for your interest in contributing!

## Prerequisites

- **Dart SDK** 3.10+
- **[FVM](https://fvm.app/)** (recommended) – run `fvm use` to switch to the pinned SDK version
- **[Melos](https://melos.invertase.dev/)** – install with `dart pub global activate melos`

## Setup

```bash
fvm use                        # optional, use pinned SDK
melos bootstrap                # install dependencies for all packages
melos run setup-git-hooks      # enforce Conventional Commit subjects
```

## Common Commands

See `melos.scripts` in the root [pubspec.yaml](pubspec.yaml) for all available commands:

```bash
melos run test                        # all unit tests and both integration backends
melos run generate                    # run build_runner where needed
melos run generate-integration-tests  # regenerate integration test packages
```

Local integration runs analyze every generated client, test package, and the
helper package using four parallel workers. All analysis must pass before tests
start. Adjust the worker limit to suit available CPU and memory:

```bash
INTEGRATION_ANALYSIS_JOBS=2 melos run test
```

The same setting applies to `melos run test-integration-current` and
`melos run test-integration-all`. The CI analysis script defaults to one worker
and accepts the same override. Each worker resolves a package's dependencies
before analyzing it; failures are collected with their package diagnostics.

## Architecture

For an overview of which package does what and how changes propagate, see [.github/copilot-instructions.md](.github/copilot-instructions.md).

## Conventions

Code style and development patterns are documented in [.cursor/rules/](.cursor/rules/):

- Test-driven development workflow
- Code organization patterns
- Working with `code_builder`
- Custom test matchers

Non-merge commits must use a [Conventional Commit](https://www.conventionalcommits.org/) subject. The tracked `commit-msg` hook validates subjects after running `melos run setup-git-hooks`. Merge commits are exempt because Melos ignores them when generating changelogs.

```text
feat: add HTTP transport support
fix(tonik_generate): preserve parameter names
feat!: remove the legacy transport API
```

## Pull Requests

1. **Tests** – add or update tests for your changes
2. **Style** – code must pass `very_good_analysis` (run `melos run analyze`)
3. **Scope** – keep PRs focused; split large changes into smaller PRs

## Questions?

Open an issue or start a discussion on GitHub.
