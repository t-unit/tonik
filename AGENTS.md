# AI Agent Instructions for Tonik

This repository (Tonik) is a Dart monorepo managed with melos. It contains a CLI tool that generates Dart client packages from OpenAPI 3.0/3.1 specs.

Keep suggestions tightly scoped to the codebase: prefer edits under `packages/*` when changing generation logic, and edits under `integration_test/*` when improving tests or examples. Avoid broad stylistic churn unless requested.

---

## Project Overview

### Package Architecture (what edits affect what)

| Package | Purpose |
|---------|---------|
| `packages/tonik` | CLI wrapper and helpers. Entry point: `packages/tonik/bin/tonik.dart` — parses args, loads spec, calls importer + generator. |
| `packages/tonik_parse` | Parsing logic for OpenAPI specs. |
| `packages/tonik_core` | AST/model structures used by the generator. |
| `packages/tonik_generate` | Code templates and generation logic. |
| `packages/tonik_util` | Utilities and shared helpers used by generated code. |
| `integration_test/*` | Small sample OpenAPI projects and end-to-end tests. |

### Key Files to Inspect for Context

- `packages/tonik/bin/tonik.dart` — CLI flow and logging. See how command-line flags map to internals.
- `packages/tonik/lib/src/openapi_loader.dart` — how YAML/JSON specs are loaded and validated.
- `scripts/setup_integration_tests.sh` — orchestrates generating API packages and running Imposter tests; documents prerequisite tools and dependency overrides.
- `pubspec.yaml` (workspace root) — melos workspace and useful scripts.
- `integration_test/*/*/test` — authoritative usage examples for generated code.

### Conventions & Patterns

- The CLI produces a package per OpenAPI tag. Generated client classes follow the pattern `XxxApi` (e.g., `PetApi`).
- Response discriminated union shape: `TonikSuccess<T>` / `TonikError`.
- Logging levels: `--log-level` (verbose|info|warn|silent). Use `--log-level verbose` for debugging.

### What to Change Where

| Issue | Where to Edit |
|-------|---------------|
| Parsing or spec normalization | `packages/tonik_parse` or `packages/tonik/lib/src/openapi_loader.dart` |
| Data structures used by generator | `packages/tonik_core` |
| Code template or generation logic | `packages/tonik_generate` |
| Utilities and shared helpers | `packages/tonik_util` |
| CLI behavior, flags, or argument validation | `packages/tonik/bin/tonik.dart` |

---

## Development Environment (FVM)

This project uses Flutter Version Management (FVM). **Always prefix Flutter and Dart commands with `fvm`.**

| Action | Command |
|--------|---------|
| Running tests | `fvm dart test` |
| Running Flutter | `fvm flutter` |
| Pub commands | `fvm dart pub get` |
| Build runner | `fvm dart pub run build_runner build` |

---

## Developer Workflows & Commands

### Install CLI globally (developer)

```bash
fvm dart pub global activate tonik
```

### Run generator locally

```bash
fvm dart run packages/tonik/bin/tonik.dart -p <package_name> -s <spec_path> -o <output_dir> --log-level verbose
```

### Workspace-level scripts via melos (run from repository root)

| Script | Purpose |
|--------|---------|
| `melos run test` | Runs `dart test` for the selected package. |
| `melos run generate` | Invokes build_runner for packages that require code generation. |
| `melos run generate-integration-tests` | Runs `scripts/setup_integration_tests.sh` (requires Java and network access). |
| `melos run test-integration-[name]` | Runs specific integration test suite (e.g., `test-integration-petstore`). |

---

## Code Style & Organization

### Comments

- Comments should explain **"why"**, not **"what"**.
- Never add comments explaining the next line or lines.
- Use comments for bigger methods to separate sections dealing with different things.
- Keep comments short and precise.
- End all comments with a period or colon.

### Documentation

- Document all public APIs.
- Don't state the obvious.
- Explain parameters and arguments.
- Keep documentation short.

### Private and Protected Methods

- Use the [meta](https://pub.dev/packages/meta) package to annotate private and protected methods.
- Keep public interfaces as small as possible.

### Class Member Ordering

1. Public constructors.
2. Non-public constructors.
3. Public static properties.
4. Public regular properties.
5. Private static properties.
6. Private regular properties.
7. Public methods.
8. Private and protected methods.

---

## Agent Behavior

### Clarity and Confirmation

- Make sure the prompt is clear before proceeding.
- Rather ask for feedback if unsure how something should be built.
- **Exception:** Do not ask permission to run the integration test regeneration script — just run it.

### Test-Driven Development

When implementing features, follow TDD:

1. Create minimal skeleton code structure if needed.
2. Write tests that verify the expected functionality.
3. **CHECKPOINT**: Wait for explicit user confirmation before proceeding to implementation.
4. Only after confirmation, implement the actual code to pass those tests.

- Never skip directly to implementation without tests.
- When asked to implement a feature, respond with: "Following TDD, let's write tests first."
- Explicitly ask for confirmation with: "Tests written. Shall I proceed with implementation?"
- If user requests direct implementation, remind them about TDD workflow.

---

## Additional Resources

- `docs/` — conceptual docs on data types and composite data types. Useful when changing code generation semantics.
- `integration_test/*/*/test` — end-to-end expected behavior of generated clients (best executable spec).
