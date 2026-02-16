---
name: integration-tests
description: >
  Integration test rules for this project. Use when working on integration tests,
  regenerating tests, changing code generation logic in tonik_generate, modifying
  models in tonik_core, updating parsing in tonik_parse, or adding utilities to
  tonik_util used by generated code.
user-invocable: false
---

# Integration Tests

## CRITICAL: Always Use the Setup Script

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

- Do NOT run `fvm dart run packages/tonik/bin/tonik.dart` manually for individual tests.
- Do NOT try to regenerate a single integration test in isolation.
- Do NOT skip the setup script "to save time."

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

Unless the user explicitly states otherwise, **assume you should regenerate ALL integration tests** when making generator changes. Do not ask permission — just run the script.

### Dependency Overrides Pattern

When adding dependencies to generated packages in tests, follow the existing pattern in `scripts/setup_integration_tests.sh`:

```yaml
dependency_overrides:
  tonik_util:
    path: ../../../packages/tonik_util
```
