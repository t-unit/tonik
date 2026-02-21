# Sub-plan 9: End-to-End Integration Test

## Context

No multipart integration test currently exists. Add one following the established pattern in `integration_test/`. The closest existing analog is `integration_test/form_urlencoded/`.

**Important**: Always use `./scripts/setup_integration_tests.sh` to regenerate. NEVER regenerate individual integration test packages manually.

Note: Generated code for sub-plans 2, 3, 5, and 6 uses `jsonEncode()` from `dart:convert`. The code-builder `refer('jsonEncode', 'dart:convert')` pattern ensures the import is automatically emitted. The integration test validates this works end-to-end (generated code compiles).

Note: When the request body is a `FormData` instance, Dio automatically sets the `Content-Type: multipart/form-data; boundary=...` header with a generated boundary — but only if the `contentType` option is not already set (Dio uses `??=`). Sub-plan 1's options_generator change ensures multipart requests emit `null` for `contentType`, letting Dio handle boundary generation. For the custom content type test (`application/vnd.custom-multipart`), emitting `null` means Dio sets `multipart/form-data` — the custom type is lost. This is a known limitation documented in the master plan's "Out of Scope" section.

## TDD Exception

The standard TDD workflow (write tests → checkpoint → implement) does not apply to this sub-plan. Integration tests ARE the tests — there is no separate "implementation" to gate behind a checkpoint. The work here is: create the OpenAPI spec, create the test project with assertions, regenerate, and run.

## Changes

### Create: `integration_test/multipart/openapi.yaml`

OpenAPI 3.0.3 spec with a single tag containing operations that exercise all implemented multipart features:

1. **Simple string fields** — `multipart/form-data` body with string, integer, boolean properties.
2. **Binary file upload** — property with `type: string, format: binary`.
3. **Enum property** — enum field in multipart body.
4. **Complex object property** — nested object serialized as JSON part (with encoding `contentType: application/json`).
5. **Array of strings** — list of strings (explode: true).
6. **Array of enums** — list of enum values to verify list-of-enums serialization path.
7. **Mixed required/optional** — some properties required, some optional.
8. **Explicit encoding overrides** — encoding object with custom contentType for a primitive field.
9. **Multiple binary files** — array of binary files.
10. **Multipart response** — an operation that declares a `multipart/form-data` response body, to verify sub-plan 8's graceful runtime error (the generated client should throw `ResponseDecodingException`, not crash).
11. **Custom content type mapped to multipart** — operation using `application/vnd.custom-multipart` as its request body content type, mapped to `multipart` via `tonik.yaml` config.

### Create: `integration_test/multipart/openapi_3_1.yaml`

A **small** OAS 3.1.0 spec to verify end-to-end that the parser's version-aware normalization produces correct generated code for OAS 3.1 multipart semantics. This spec should include:

1. **Array with `explode: false, style: pipeDelimited`** — verifies that OAS 3.1's style/explode on multipart encoding are honored (unlike OAS 3.0 where they're ignored).
2. **Array with `explode: true`** (default) — verifies default behavior matches OAS 3.0.
3. **Simple string + binary properties** — basic smoke test for OAS 3.1 multipart.

The `tonik.yaml` config should reference this spec as a second generation target, or a separate `tonik_3_1.yaml` config file should be created.

Keep both specs minimal — just enough to cover the generation paths from sub-plans 0–8.

### Create: `integration_test/multipart/tonik.yaml`

Config file with custom content type mapping:
```yaml
spec: multipart/openapi.yaml
packageName: multipart_api
outputDir: multipart

contentTypes:
  application/vnd.custom-multipart: multipart
```

This maps a custom MIME type to the `multipart` serialization format, following the same pattern as `integration_test/form_urlencoded/tonik_custom.yaml` (which maps `application/vnd.custom-form: form`).

The OpenAPI spec should include at least one operation that uses `application/vnd.custom-multipart` as its request body content type, so that the integration test verifies:
1. The custom content type is correctly recognized as multipart via config.
2. The generated code serializes the body as `FormData`, not raw JSON.
3. The request is sent with the custom content type header.

### Create: `integration_test/multipart/multipart_test/`

Test project following the `form_urlencoded_test/` pattern:
- `pubspec.yaml` — depends on the generated `multipart_api` package and `test`.
- `dart_test.yaml` — set `concurrency: 1` (Imposter server is shared across tests).
- `analysis_options.yaml` — standard analysis options.
- `imposter/imposter-config.json` — Imposter mock server config pointing to `../../openapi.yaml` and `response.groovy`.
- `imposter/response.groovy` — Groovy script for custom mock responses (echo back multipart fields/files for verification).
- `test/multipart_test.dart` — end-to-end tests using Imposter mock server.

Test cases:
- Send multipart request with string fields -> verify server receives correct parts.
- Send multipart request with binary file -> verify file is received.
- Send multipart request with complex object -> verify JSON encoding.
- Send multipart request with array of strings -> verify multiple parts.
- Send multipart request with array of enums -> verify enum wire values.
- Send multipart request with optional fields omitted -> verify only required fields sent.
- Multipart response -> call the operation, verify it throws `ResponseDecodingException` at runtime (not an `UnimplementedError`, not a generator crash).
- Custom content type (`application/vnd.custom-multipart`) -> verify request body is serialized as multipart FormData (note: Dio will set `Content-Type: multipart/form-data` with boundary, not the custom type — this is a known limitation).
- (OAS 3.1 spec) Array with `explode: false, style: pipeDelimited` -> verify pipe-delimited serialization.
- (OAS 3.1 spec) Array with default explode -> verify one entry per item.

### Modify: `scripts/setup_integration_tests.sh`

Add `multipart` entries in ALL FOUR sections of the script:

1. **Cleanup section** (~line 94): Add `rm -rf multipart/multipart_api` and `rm -rf multipart/multipart_3_1_api` (if using a separate OAS 3.1 package)
2. **Generation section** (~line 120): Add:
   ```bash
   $TONIK_BINARY --config multipart/tonik.yaml
   $TONIK_BINARY --config multipart/tonik_3_1.yaml
   add_dependency_overrides_recursive "multipart/multipart_api"
   add_dependency_overrides_recursive "multipart/multipart_3_1_api"
   ```
3. **Pub get for generated packages** (~line 195): Add `cd multipart/multipart_api && dart pub get &` and `cd multipart/multipart_3_1_api && dart pub get &`
4. **Restore test overrides + pub get for test packages** (~line 240+): Add:
   ```bash
   restore_test_package_overrides "multipart/multipart_test/pubspec.yaml" "../../../packages/tonik_util"
   ```
   And in the test pub get block: `cd multipart/multipart_test && dart pub get &`

### Modify: `pubspec.yaml` (root workspace)

Add BOTH:

1. Individual script entry:
   ```yaml
   test-integration-multipart:
     run: |
       cd integration_test/multipart/multipart_test
       dart test
   ```

2. Add `melos run test-integration-multipart` to the `test-integration-all` script block.

## Execution

```bash
./scripts/setup_integration_tests.sh
melos run test-integration-multipart
```

## Verification

All integration tests pass. Generated code compiles without errors. Imposter mock correctly validates multipart request structure.
