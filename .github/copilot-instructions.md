## Quick instructions for AI coding agents

This repository (Tonik) is a Dart monorepo managed with melos. It contains a CLI tool that generates Dart client packages from OpenAPI 3.0/3.1 specs. The guidance below focuses on the minimal, actionable information an AI assistant needs to be immediately productive.

Keep suggestions tightly scoped to the codebase: prefer edits under `packages/*` when changing generation logic, and edits under `integration_test/*` when improving tests or examples. Avoid broad stylistic churn unless requested.

### Big picture (what edits affect what)
- `packages/tonik`: CLI wrapper and helpers. Entry point: `packages/tonik/bin/tonik.dart` — parses args, loads spec, calls importer + generator.
- `packages/tonik_parse`, `packages/tonik_core`, `packages/tonik_generate`, `packages/tonik_util`: internal packages that implement parsing, AST/model structures, and code generation. Changes that affect generation behavior typically live in these packages.
- `integration_test/*`: small sample OpenAPI projects and end-to-end tests. These show intended runtime of the generator and are useful for integration-level changes.

### Key files to inspect for context
- `packages/tonik/bin/tonik.dart` — CLI flow and logging. Use this to see how command-line flags map to internals.
- `packages/tonik/lib/src/openapi_loader.dart` — how YAML/JSON specs are loaded and validated.
- `scripts/setup_integration_tests.sh` — orchestrates generating API packages and running Imposter tests; documents prerequisite tools (Java, Imposter JAR) and dependency overrides for local packages.
- `pubspec.yaml` (workspace root) — melos workspace and useful scripts (e.g., `melos run test-integration-composition`). Use these scripts in examples and tests.
- `integration_test/*/*/pubspec.yaml` — generated client packages; the tests under `integration_test/*/*/test` are authoritative usage examples for generated code.

### Developer workflows (commands that matter)
- Install CLI globally (developer):
  - `dart pub global activate tonik`
- Run generator locally (used by CI and setup):
  - `dart run packages/tonik/bin/tonik.dart -p <package_name> -s <spec_path> -o <output_dir> --log-level verbose`
- Workspace-level scripts via melos (run from repository root):
  - `melos run test` — runs `dart test` for the selected package via melos scripts
  - `melos run generate` — invokes build_runner for packages that require code generation
  - `melos run generate-integration-tests` — runs `scripts/setup_integration_tests.sh` (must have Java and network access)
  - Individual integration test runners are available in `pubspec.yaml` under `melos.scripts` (e.g. `test-integration-petstore`). Prefer using `melos run <script>` for reproducibility.

### Integration tests and external dependencies
- `scripts/setup_integration_tests.sh` regenerates example client packages using the local `tonik` binary and then runs tests. It requires:
  - Dart SDK
  - Java 11+ (used to run Imposter JAR for mock HTTP servers)
  - Network access to download `imposter.jar` (the script caches the jar in the `integration_test` folder)

When changing generated code shapes, update the corresponding integration tests in `integration_test/*/*/test` to document expected usage. The integration harness also adds `dependency_overrides` for local `packages/tonik_util` when generating sample packages — keep that behavior in mind if refactoring APIs.

### Conventions & patterns specific to this repo
- Generator behavior: the CLI produces a package per OpenAPI tag. The generated client classes follow the pattern `XxxApi` (e.g., `PetApi`). See examples in `integration_test/*/*/test` to learn returned response discriminated union shape (`TonikSuccess<T>` / `TonikError`).
- Package layout: generated packages are placed under the target integration test directory (e.g., `integration_test/petstore/petstore_api`). Scripts then run `dart pub get` inside generated packages — don't assume a single `pub get` at workspace root is sufficient for integration tests.
- Logging levels: CLI supports `--log-level` (verbose|info|warn|silent). For debugging parse/generation issues, run with `--log-level verbose`.

### What to change where (practical rules)
- Fix parsing or spec normalization issues → edit `packages/tonik/lib/src/openapi_loader.dart` or parsing package (`packages/tonik_parse`).
- Change data structures used by generator → edit `packages/tonik_core`.
- Change code template or generation logic → edit `packages/tonik_generate`.
- Add utilities and shared helpers → edit `packages/tonik_util`.
- Update CLI behavior, flags, or argument validation → edit `packages/tonik/bin/tonik.dart`.

### Tests & verification
- Unit tests live under each package `test/` directory. Run package tests via `melos` or `dart test` inside a package.
- Integration tests: run the setup script then run `dart test` in the generated package test directories, or use the melos helper scripts listed in root `pubspec.yaml`.

### Examples from the codebase
- Loading OpenAPI docs (YAML/JSON): see `packages/tonik/lib/src/openapi_loader.dart` — convert YAML to Map and raise `OpenApiLoaderException` on malformed input.
- CLI entrypoint: `packages/tonik/bin/tonik.dart` shows try/catch flow around parse → import → generate with helpful `--log-level` mapping.
- Integration setup: `scripts/setup_integration_tests.sh` demonstrates practical steps the repo expects when regenerating and running tests: dependency overrides, `dart pub get` per generated package, and Imposter JAR management.

### Small, safe defaults for the AI
- When adding dependencies to generated packages in tests, follow the existing `dependency_overrides` pattern in `scripts/setup_integration_tests.sh` (override `tonik_util` path to `../../../packages/tonik_util`).
- When introducing public API changes across packages, prefer bumping locally referenced versions in integration test generated pubspecs or use dependency_overrides rather than changing global versions.

### Where to look for more context
- `docs/` contains conceptual docs on data types and composite data types. These pages explain why certain generation rules exist and are useful when changing code generation semantics.
- Integration tests under `integration_test/*/*/test` show end-to-end expected behavior of generated clients and are the best executable spec.

If anything here is unclear or you want more examples (e.g., a small patch that updates generation of integer enums), tell me which area to expand and I will iterate.

## Cursor rules for Copilot

This repository includes a set of repository-specific agent rules under `.cursor/rules/`. These are intended to guide interactive AI agents (Copilot) about behavior, test-driven flow, and project conventions.

Files present (authoritative):
- `.cursor/rules/ask-and-wait.mdc`
- `.cursor/rules/code-organization.mdc`
- `.cursor/rules/fvm-usage.mdc`
- `.cursor/rules/matchers.mdc`
- `.cursor/rules/test-driven-development.mdc`
- `.cursor/rules/working-with-code-builder.mdc`

Action for AI agents:
- Read the files in `.cursor/rules/` before making changes. Treat them as authoritative behavior and style guidance for interactive sessions.
- When producing edits or tests, prefer the patterns and workflows described in those rules (e.g., project layout, test matchers, FVM usage, and code-builder patterns).
- If a rule is ambiguous or conflicts with other repository guidance, ask the human maintainer (use the "ask-and-wait" pattern).

If you want, I can inline summaries of each rule file into this document — tell me whether you prefer exact file text included or short summaries.
