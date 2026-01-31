# AI Agent Instructions for Tonik

This repository (Tonik) is a Dart monorepo managed with melos. It contains a CLI tool that generates Dart client packages from OpenAPI 3.0/3.1 specs. This document provides all guidance an AI assistant needs to be immediately productive.

Keep suggestions tightly scoped to the codebase: prefer edits under `packages/*` when changing generation logic, and edits under `integration_test/*` when improving tests or examples. Avoid broad stylistic churn unless requested.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Development Environment (FVM)](#development-environment-fvm)
3. [Developer Workflows & Commands](#developer-workflows--commands)
4. [Integration Tests (Critical)](#integration-tests-critical)
5. [Code Style & Organization](#code-style--organization)
6. [Code Generation with code_builder](#code-generation-with-code_builder)
7. [Testing Conventions](#testing-conventions)
8. [Agent Behavior](#agent-behavior)
9. [Quick Reference](#quick-reference)

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

---

## Development Environment (FVM)

This project uses Flutter Version Management (FVM). **Always prefix Flutter and Dart commands with `fvm`.**

### Command Examples

| Action | Command |
|--------|---------|
| Running tests | `fvm dart test` |
| Running Flutter | `fvm flutter` |
| Pub commands | `fvm dart pub get` |
| Build runner | `fvm dart pub run build_runner build` |

### Rationale

- Ensures consistent Flutter/Dart SDK version across all developers.
- Prevents version-related issues and test failures.
- The project has specific SDK version requirements that FVM manages.

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

## Integration Tests (Critical)

### ⚠️ CRITICAL: Always Use the Setup Script

**NEVER manually regenerate individual integration tests. ALWAYS use the setup script.**

### Required Command

```bash
./scripts/setup_integration_tests.sh
```

Or via melos:

```bash
melos run generate-integration-tests
```

### Why This Matters

- The setup script handles dependency overrides for local packages.
- It downloads and manages the Imposter JAR for mock servers.
- It runs `fvm dart pub get` in each generated package directory.
- It ensures consistent generation across all integration test suites.
- It properly configures test environments.

### What NOT To Do

- ❌ Do NOT run `fvm dart run packages/tonik/bin/tonik.dart` manually for individual tests.
- ❌ Do NOT try to regenerate a single integration test in isolation.
- ❌ Do NOT skip the setup script "to save time."

### When To Regenerate

Run the setup script whenever:

- You change code generation logic in `packages/tonik_generate`.
- You modify model structures in `packages/tonik_core`.
- You update parsing logic in `packages/tonik_parse`.
- You add new utilities to `packages/tonik_util` used by generated code.
- You change the CLI behavior in `packages/tonik`.
- The user asks to "regenerate integration tests."
- Integration tests are failing after generator changes.

### After Regeneration

1. Check generated code in `integration_test/*/[name]_api/`.
2. Run specific integration tests: `melos run test-integration-[name]`.
3. Or run all tests: `melos run test`.

### External Dependencies

- **Dart SDK** (via FVM).
- **Java 11+** (used to run Imposter JAR for mock HTTP servers).
- **Network access** to download `imposter.jar` (cached in `integration_test` folder).

### Default Assumption

Unless the user explicitly states otherwise, **assume you should regenerate ALL integration tests** when making generator changes. Do not ask permission—just run the script.

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

## Code Generation with code_builder

When working with the [code_builder](https://pub.dev/packages/code_builder) package:

### Critical Rules — Never Violate

1. **NEVER use `Code.scope`.**
2. **ALWAYS use `refer` with package URL for ALL types** — even `dart:core` types.
3. **NEVER mix `refer` and string interpolation** — they are incompatible.
4. **Use `Code` with `Block.of`** — never use `StringBuilder`.
5. **NEVER use `DartEmitter` inside generator methods** — only the main `generate` method is allowed to use it.

### Examples

```dart
// ✅ CORRECT - Build code in separate Code objects
statements
  ..add(Code('if (condition != '))
  ..add(refer('String', 'dart:core').code)
  ..add(Code(') {'))

// ✅ CORRECT - Use refer with package URL
refer('EncodingShape.simple', 'package:tonik_util/tonik_util.dart')

// ❌ WRONG - Don't use Code.scope
Code.scope((allocate) => '...')

// ❌ WRONG - Don't mix refer with string interpolation  
Code('if (condition != ${refer('String', 'dart:core').code})')

// ❌ WRONG - Don't use refer without package URL
refer('String') // Missing 'dart:core'

// ❌ WRONG - Don't use DartEmitter in generator methods
Code('${nullableType.accept(emitter)} $variableName;') // emitter not allowed

// ✅ CORRECT - Build code in separate Code objects
Block.of([
  nullableType.code,
  Code(' $variableName;'),
])
```

---

## Testing Conventions

### Matchers

- Always use `isTrue` and `isFalse` matchers instead of bare `true` and `false`.
- Never use `equals()`; test against the value directly.

### Code Generation Testing

- **PREFER object introspection** over string testing for generated code:
  - Test constructor/method existence: `combinedClass.constructors.firstWhere((c) => c.name == 'fromSimple')`.
  - Test parameter types: `parameter.type?.accept(emitter).toString()`.
  - Test method properties: `method.lambda`, `method.returns`.
  - Test field names: `combinedClass.fields.map((f) => f.name)`.

- **Only use `contains(collapseWhitespace(...))` when absolutely necessary** for testing specific generated code content.
- **NEVER use bare `contains()` without `collapseWhitespace()`** for generated code — formatting differences will cause flaky tests.
- Use `collapseWhitespace` from [test package](https://pub.dev/packages/test): `import 'package:test/test.dart';`.
- When testing generated code strings, format both expected and actual with `DartFormatter`.

### String Testing Guidelines

- When testing generated code strings:
  - Format the entire method/constructor body with `DartFormatter` first.
  - Use `contains(collapseWhitespace(...))` for testing complete code blocks.
  - Acceptable: Testing patterns in a formatted complete method body.
  - NOT acceptable: Testing individual lines without formatting the complete context.

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

#### AI Assistant Instructions

- Never skip directly to implementation without tests.
- When asked to implement a feature, respond with: "Following TDD, let's write tests first."
- Explicitly ask for confirmation with: "✅ Tests written. Shall I proceed with implementation?"
- If user requests direct implementation, remind them about TDD workflow.

---

## Quick Reference

### What to Change Where

| Issue | Where to Edit |
|-------|---------------|
| Parsing or spec normalization | `packages/tonik_parse` or `packages/tonik/lib/src/openapi_loader.dart` |
| Data structures used by generator | `packages/tonik_core` |
| Code template or generation logic | `packages/tonik_generate` |
| Utilities and shared helpers | `packages/tonik_util` |
| CLI behavior, flags, or argument validation | `packages/tonik/bin/tonik.dart` |

### Common Commands Cheat Sheet

```bash
# Run all tests for a package
fvm dart test

# Run melos test script
melos run test

# Regenerate all integration tests (ALWAYS use this)
./scripts/setup_integration_tests.sh

# Run specific integration test
melos run test-integration-petstore

# Run generator with verbose logging
fvm dart run packages/tonik/bin/tonik.dart -p my_api -s spec.yaml -o ./output --log-level verbose
```

### Dependency Overrides Pattern

When adding dependencies to generated packages in tests, follow the existing pattern in `scripts/setup_integration_tests.sh`:

```yaml
dependency_overrides:
  tonik_util:
    path: ../../../packages/tonik_util
```

---

## Additional Resources

- `docs/` — conceptual docs on data types and composite data types. Useful when changing code generation semantics.
- `integration_test/*/*/test` — end-to-end expected behavior of generated clients (best executable spec).

If anything here is unclear or you want more examples, ask the human maintainer for clarification.
