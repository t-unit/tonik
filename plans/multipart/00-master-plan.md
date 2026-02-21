# Multipart/Form-Data Support — Master Plan

## Context

Parsing for `multipart/form-data` is complete (enum, models, encoding metadata, tests). Code generation throws `UnimplementedError`. This master plan breaks multipart generation into independent, sequentially-executed sub-plans. Each sub-plan is self-contained and mergeable on its own.

## OAS Encoding Object Default Rules (Critical)

Per the OAS 3.0.4 (§4.7.15.1.1) and OAS 3.1.1 (§4.8.15.1.1) specs, the default `contentType` for multipart properties is determined by the **property schema type**, not the OAS version:

| Property Schema | Default `contentType` |
|---|---|
| `string` with `format: binary` (3.0) or `contentEncoding` (3.1) (`BinaryModel`) | `application/octet-stream` |
| `string` (no binary format/encoding) (`StringModel`) | `text/plain` |
| `number`, `integer`, `boolean` (and `DateTimeModel`, `DateModel`, `DecimalModel`, `UriModel`) | `text/plain` |
| `EnumModel` | `text/plain` |
| `AnyModel` (untyped / `{}` schema) | `text/plain` |
| `object` (`ClassModel`, `AllOfModel`, `OneOfModel`, `AnyOfModel`) | `application/json` |
| `array` (`ListModel`) | according to the `items` schema type (recursive resolution — see sub-plan 0) |
| `NeverModel` | `text/plain` |

These defaults are **the same in OAS 3.0 and 3.1**. The version difference only affects how binary is detected (`format: binary`/`format: byte` in 3.0 vs `contentEncoding` in 3.1), which is already handled by the parse layer's model resolution.

### OAS Version Difference for `style`/`explode`

- **OAS 3.0**: `style`, `explode`, and `allowReserved` on the Encoding Object SHALL be **ignored** for multipart (they only apply to `x-www-form-urlencoded`).
- **OAS 3.1**: `style`, `explode`, and `allowReserved` DO apply to multipart.

The **parse layer** must fully normalize encoding per OAS version so the **generate layer** is completely version-agnostic:
- For OAS 3.0 multipart: parser forces `style: form`, `explode: true`, `allowReserved: false` (discarding any explicit values).
- For OAS 3.1 multipart: parser reads explicit values or fills defaults.

The generator just reads `encoding.style` and `encoding.explode` and acts on them — it never sees or needs the OAS version.

### Encoding Non-Null Guarantee

After sub-plan 0, `RequestContent.encoding` is always non-null for multipart `ClassModel` bodies, and every property entry has non-null `contentType`, `style`, `explode`, and `allowReserved`. Generators in sub-plans 1–8 can safely force-unwrap (`!`) these fields without defensive null checks. The `MultipartPropertyEncoding` model keeps its fields nullable (it's also used before sub-plan 0 populates defaults), but the contract is: by the time the generator runs, defaults are filled.

## Dependency Graph

```
Sub-plan 0 (parse defaults)
    │
    ├── Sub-plan 1 (scaffold + strings + options_generator)
    │       │
    │       ├── Sub-plan 2 (primitives)
    │       ├── Sub-plan 3 (enums)
    │       ├── Sub-plan 4 (binary)
    │       ├── Sub-plan 5 (complex objects)
    │       ├── Sub-plan 6 (arrays)
    │       └── Sub-plan 7 (per-part headers)
    │
    ├── Sub-plan 8 (multipart response error) — independent of sub-plan 1
    │
    └── Sub-plan 9 (integration test) — depends on ALL of 0–8

Sub-plan 10 (documentation) — depends on ALL of 0–9
```

Sub-plans 2–7 are independent of each other but all require sub-plan 1's scaffold. Sub-plan 8 only modifies `ParseGenerator` and can be done in parallel with sub-plans 1–7.

## Intermediate State UX

Between sub-plans 1 and 7, some model types still throw `UnimplementedError` in the multipart generator. This is acceptable — each sub-plan is self-contained and mergeable. The `UnimplementedError` message clearly identifies which model type is unsupported (e.g., `'IntegerModel is not yet supported in multipart encoding.'`), guiding users to track progress or file issues. Each sub-plan removes one or more `UnimplementedError` branches until all types are covered after sub-plan 6.

## TDD Workflow

Every sub-plan follows Test-Driven Development:
1. Create minimal skeleton code structure if needed.
2. Write tests that verify the expected functionality.
3. **CHECKPOINT**: Wait for explicit user confirmation before proceeding to implementation.
4. Only after confirmation, implement the actual code to pass those tests.

**Exception**: Sub-plan 9 (integration test) does not follow TDD — the integration tests ARE the tests. There is no separate implementation to gate behind a checkpoint.

**Logging assertions**: When a plan requires testing that a warning was logged, register a `Logger.root.onRecord` listener (or inject a mock `Logger`) and verify the log record contains the expected warning message. Do not rely on stdout capture.

## Roadmap Overview

### Sub-plan 0: Parse — Populate default encoding per property type
Set default `MultipartPropertyEncoding.contentType` for each property of a multipart body based on the property schema type, so generators don't need type-inference logic. Guard: only populate per-property defaults when the model is a `ClassModel`.

### Sub-plan 1: Generate — Scaffold + primitive string fields
Create `to_multipart_expression_generator.dart`, wire into `DataGenerator`. Provide two entry points: `buildMultipartBodyStatements` for single-content paths (returns statements) and `buildMultipartBodyExpression` for multi-content paths (returns an expression suitable for switch arms). Handle `StringModel`, `AliasModel` (resolve and recurse), `AnyModel` (pass through as `.toString()`), and `NeverModel` (throw encoding exception). All other model types throw `UnimplementedError`. For non-ClassModel top-level bodies (e.g. bare `BinaryModel`), generate a runtime `UnsupportedError` instead of crashing the generator. Support both single-content and multi-content code paths. Exclude `readOnly` properties from serialization. Also modify `OptionsGenerator` to emit `null` for multipart content types (letting Dio auto-set `Content-Type` with the correct boundary). Establish the shared content-type MIME comparison helper and nullable wrapping infrastructure used by sub-plans 2–7.

### Sub-plan 2: Generate — All primitive types
Extend to handle `IntegerModel`, `DoubleModel`, `NumberModel`, `BooleanModel`, `DateTimeModel`, `DateModel`, `DecimalModel`, `UriModel`. Serialize based on encoding contentType (JSON fragment vs plain text).

### Sub-plan 3: Generate — Enum properties
Handle `EnumModel` properties — serialize via `.toJson()` (which returns the wire value).

### Sub-plan 4: Generate — Binary file uploads
Handle `BinaryModel` properties as `MultipartFile.fromBytes()` entries in `FormData.files`. Use property name as filename.

### Sub-plan 5: Generate — Complex object properties (JSON-encoded)
Handle `ClassModel`, `AllOfModel`, `OneOfModel`, `AnyOfModel` — serialize via `jsonEncode(value.toJson())` as `MultipartFile.fromString()` with appropriate content type from encoding. Throw `UnsupportedError` for `style: deepObject` on complex object properties (rare, complex to implement — deferred).

### Sub-plan 6: Generate — Array properties (ListModel)
Handle `ListModel` — iterate items, dispatch per-item serialization. Respect `explode` flag (true = one part per item, false = delimited string). Support `spaceDelimited` and `pipeDelimited` styles for non-exploded arrays. The generator is version-agnostic — OAS 3.0 vs 3.1 differences are fully normalized by the parser in sub-plan 0.

### Sub-plan 7: Generate — Per-part headers (deferred / limited scope)
Encoding `headers` define the *schema* of per-part headers, not literal values. Expose per-part header parameters on the generated method or document as unsupported. See sub-plan for options.

### Sub-plan 8: Generate — Multipart response decoding (graceful error)
Replace `throw UnimplementedError` in `ParseGenerator` with generated code that throws at runtime, so the generator doesn't crash on specs with multipart responses.

### Sub-plan 9: Integration test — End-to-end multipart validation
Create a multipart integration test under `integration_test/multipart/` with an OpenAPI spec covering all supported property types, binary uploads, arrays, mixed content types, and multi-content request bodies. Include both an OAS 3.0.3 spec and a small OAS 3.1.0 spec to verify end-to-end that the parser's version-aware normalization (`style`/`explode` differences) produces correct generated code. Include at least one operation with a multipart response body to verify the graceful runtime error from sub-plan 8. Run via `./scripts/setup_integration_tests.sh`.

### Sub-plan 10: Documentation updates
Update `docs/features.md` to list multipart/form-data as a supported feature. Update `docs/uri_encoding_limitations.md` (or create a new `docs/multipart_limitations.md`) to document known limitations: `deepObject` unsupported for complex objects and arrays, per-part headers deferred, custom multipart subtypes may not work correctly. Add CHANGELOG entry for the multipart feature.

## Out of Scope

The following are explicitly not covered by this plan:

- **`style: deepObject` for complex object properties** — OAS 3.1 allows `deepObject` on object properties in multipart encoding (flattens to `color[R]=100`). Sub-plan 5 throws `UnsupportedError` for this case. Can be implemented later if there's demand.
- **Non-form-data multipart subtypes** (e.g., `multipart/mixed`) — Users can map custom content types to `multipart` via `tonik.yaml` (e.g., `multipart/mixed: multipart`). The encoding semantics assume `multipart/form-data` structure. Custom multipart subtypes mapped this way may not behave correctly for all features (particularly per-part encoding rules).
- **`additionalProperties` / map-type schemas** in multipart bodies — `additionalProperties` is not supported by tonik globally, not just for multipart.
- **`Content-Transfer-Encoding`** — RFC 7578 §4.7 says senders SHOULD NOT generate this header for HTTP multipart. HTTP is 8-bit clean (unlike SMTP/MIME). Dio correctly omits it.
- **OAS 3.1 `contentEncoding`** for binary detection — already handled by the parse layer's model resolution (produces `BinaryModel` regardless of OAS version).
- **Multipart response decoding** — sub-plan 8 generates a graceful runtime error, not actual decoding.
- **`allowReserved` for multipart parts** — Multipart parts are NOT URL-encoded (unlike `x-www-form-urlencoded`), so `allowReserved` has no effect. Sub-plan 0 normalizes it to `false` for consistency, but generators ignore it entirely. This is correct per RFC 7578.
