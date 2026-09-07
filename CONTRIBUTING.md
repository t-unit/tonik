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

Local and CI integration analysis check every generated client, test package,
and the helper package using four parallel workers. Local runs wait for all
analysis to pass before starting tests. Adjust the worker limit to suit
available CPU and memory:

```bash
INTEGRATION_ANALYSIS_JOBS=2 melos run test
```

The same setting applies to `melos run test-integration-current` and
`melos run test-integration-all`. The CI analysis script accepts the same
override. Each worker resolves a package's dependencies before analyzing it;
failures are collected with their package diagnostics.

Integration setup always recompiles Tonik and freshly generates all 44 clients.
It runs up to four generators at once, starting the next whenever a slot becomes
free. The default `TONIK_WORKERS` splits available CPUs between those generators.
An explicit `TONIK_WORKERS` reduces the default number of concurrent generators;
`INTEGRATION_SETUP_JOBS` overrides that number. Nonzero `workerCount` values in
fixture configuration files still take precedence over `TONIK_WORKERS`. Explicit
overrides can exceed the machine's CPU budget, so adjust both limits together:

```bash
INTEGRATION_SETUP_JOBS=2 TONIK_WORKERS=2 melos run generate-integration-tests
bash scripts/test_integration_setup.sh # verify the setup scheduler
```

CI runs all five unit suites on every existing OS/SDK variant and collects
coverage on Linux with stable Dart. Before every push or pull request, run all
unit suites and the complete integration suites on both backends with
`melos run test`.

Complete integration runs use one Dart runner for all packages. It starts one
fresh Imposter JVM per package and runs that package's test files sequentially.
Each file clears the fixture's request store before
using that server; a failed reset fails the file. The runner stops the JVM when
the package ends or the run is cancelled. Fixtures must finish their requests
before completing a test. Individual `dart test` and VS Code runs continue to
start their own servers and need no wrapper or extra setup.

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
