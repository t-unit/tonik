# Sub-plan 1: Generate — Scaffold + String Fields

## Context

This is the first code generation step. Create the new multipart expression generator and wire it into `DataGenerator`, replacing `UnimplementedError`. Handle `StringModel` properties, plus `AliasModel`, `AnyModel`, and `NeverModel` for exhaustive switch coverage. Exclude `readOnly` properties from serialization.

## Changes

### New: `packages/tonik_generate/lib/src/util/to_multipart_expression_generator.dart`

Create two public entry points:

**`buildMultipartBodyStatements`** — for the single-content path. Returns `List<Code>` (statements including `FormData()` construction and field additions, WITHOUT the `return` — the caller adds that):
```dart
List<Code> buildMultipartBodyStatements(
  RequestContent content,
  String bodyAccessor,       // e.g., 'body'
  NameManager nameManager,
  String package,
)
```

**`buildMultipartBodyExpression`** — for the multi-content path. Returns an `Expression` that evaluates to a `FormData` instance (using an IIFE pattern: `() { final formData = FormData(); ...; return formData; }()`):
```dart
Expression buildMultipartBodyExpression(
  RequestContent content,
  String bodyAccessor,       // e.g., 'value'
  NameManager nameManager,
  String package,
)
```

Both delegate to a shared private helper `_buildMultipartFields(...)` that generates the FormData field/file additions.

### `refer()` Convention for External Types

Per project rules: **ALWAYS use `refer()` with package URL for ALL external types**. The multipart generator must use `refer()` for every Dio, dart:core, and dart:convert type in generated code. Key references used across sub-plans 1–6:

| Symbol | Package URL | Used For |
|---|---|---|
| `FormData` | `package:dio/dio.dart` | Multipart form container |
| `MultipartFile` | `package:dio/dio.dart` | Binary/string file parts |
| `MapEntry` | `dart:core` | Field/file entry construction |
| `DioMediaType` | `package:dio/dio.dart` | Content type for MultipartFile (typedef for `MediaType` from `package:http_parser`) |
| `jsonEncode` | `dart:convert` | JSON serialization of objects/primitives |

Example: instead of raw `FormData()`, use `refer('FormData', 'package:dio/dio.dart').call([])`. This ensures code_builder emits the correct import in generated files.

This function:
- Resolves the model: if `AliasModel`, call `.resolved` to get the underlying model. Note: `.resolved` recursively unwraps nested alias chains (`AliasModel` → `AliasModel` → `StringModel`), so a single call is sufficient.
- If the resolved model is **not** a `ClassModel`, generate a `throw UnsupportedError('Multipart request bodies require an object schema (ClassModel). Got: <type>.')` statement and return early. This keeps the generator working (no build-time crash) while giving a clear runtime error. Bare schemas (e.g., `type: string, format: binary` directly under `multipart/form-data`) are uncommon — the standard pattern wraps properties in an object.
- Uses `normalizeProperties()` to map raw names <-> Dart names.
- Filters out `readOnly` properties (they must not be serialized in requests).
- Reads `content.encoding` (non-null after sub-plan 0) for each property.
- Generates a `FormData()` construction and field additions.
- Dispatches on each property's model type:
  - `StringModel`: `formData.fields.add(MapEntry('rawName', body.dartName))`
  - `AliasModel`: resolve via `.resolved` and recurse into the underlying model type.
  - `AnyModel`: serialize via `.toString()` as a field entry.
  - `NeverModel`: throw encoding exception (impossible type).
  - Any other model type: throw `UnimplementedError` (filled in subsequent sub-plans).
- Returns the list of `Code` statements.

### Nullable Wrapping (shared infrastructure)

The nullable wrapping logic lives in `_buildMultipartFields` (the shared private helper). For each property, the helper determines whether a null check is needed based on the property's `isRequired` and `isNullable` flags:
- **Required + non-nullable**: No null check. Direct field access (`body.prop`).
- **Required + nullable**: Wrap in `if (body.prop != null) { ... body.prop! ... }`.
- **Optional (not required)**: Wrap in `if (body.prop != null) { ... body.prop! ... }` (property may be absent regardless of nullability).

This logic is implemented ONCE in sub-plan 1 and all subsequent sub-plans (2–7) inherit it automatically — each sub-plan only adds the model-type-specific serialization expression, not the null-check wrapping.

### Content-Type MIME Comparison Helper

Create a private helper `_isJsonContentType(String contentType)` that compares only the MIME type portion, stripping parameters (e.g., `application/json; charset=utf-8` → `application/json`). Implementation: split on `;`, trim, compare. This helper is used by sub-plans 2–6 to decide between text serialization and JSON serialization. Establish it here so subsequent sub-plans can use it directly.

### Modify: `packages/tonik_generate/lib/src/operation/data_generator.dart`

Replace both `throw UnimplementedError` blocks with calls to the new generator:

**Single-content path** (content.length == 1): Call `buildMultipartBodyStatements(...)` with `bodyAccessor = 'body'`. The caller appends `return formData;`.

**Multi-content path** (hasMultipleContent): Call `buildMultipartBodyExpression(...)` with `bodyAccessor = 'value'` (the unwrapped sealed union value). The returned `Expression` is used directly in the switch case arm — it evaluates to a `FormData` via an IIFE.

### Modify: `packages/tonik_generate/lib/src/operation/options_generator.dart`

**Critical — Dio boundary handling**: When Dio receives `FormData` as the request body, it auto-sets `Content-Type: multipart/form-data; boundary=<generated>` via a `??=` check. If the options generator explicitly sets `contentType: 'multipart/form-data'`, Dio's `??=` finds the header already set and **skips boundary addition** — breaking the request.

Fix: When the content type is `ContentType.multipart`, emit `null` instead of the raw content type string. This lets Dio handle boundary generation automatically.

**Single-content path** (`requestBody.contentCount == 1`): If `content.contentType == ContentType.multipart`, return `literalNull` instead of `literalString(rawContentType)`.

**Multi-content path** (switch arms): For multipart entries, emit `literalNull.code` instead of `literalString(content.rawContentType).code`. The switch expression return type becomes `String?` (nullable), which is already handled by the existing `contentType` parameter on Dio `Options`.

**Note on custom multipart content types**: For custom types mapped to multipart (e.g., `application/vnd.custom-multipart`), emitting `null` means Dio will set `multipart/form-data` instead of the custom type. This is a known limitation — documented in the "Out of Scope" section of the master plan.

### New: `packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Tests (prefer object introspection; use `contains(collapseWhitespace(...))` only when testing specific generated code blocks):
- ClassModel with required + non-nullable String property -> direct field access (no null check)
- ClassModel with required + nullable String property (`isRequired: true, isNullable: true`) -> null-check wrapping
- ClassModel with optional + non-nullable String property (`isRequired: false`) -> null-check wrapping (property may be absent)
- ClassModel with optional + nullable String property -> null-check wrapping
- ClassModel with zero properties -> produces empty `FormData` (no fields, no files)
- Non-ClassModel body (e.g. BinaryModel) -> generates runtime `UnsupportedError` throw
- AliasModel wrapping a non-ClassModel -> resolves and generates runtime `UnsupportedError` throw
- AliasModel wrapping a ClassModel -> resolves and generates correctly
- readOnly String property -> excluded from generated code
- writeOnly String property -> INCLUDED in generated code (writeOnly is valid in requests)
- AnyModel property -> serialized via `.toString()`
- NeverModel property -> throws encoding exception

### Modify: `packages/tonik_generate/test/src/operation/data_generator_test.dart`

Add tests:
- Single-content multipart with string properties
- Multi-content request body including multipart variant

### Modify: `packages/tonik_generate/test/src/operation/options_generator_test.dart`

Add tests:
- Single-content multipart request body -> `contentType` is `null` (not `'multipart/form-data'`)
- Multi-content with one multipart entry -> multipart switch arm returns `null`, other arms return their raw content type string

**CHECKPOINT**: Wait for user confirmation before implementing.

## Target Generated Code

### Single-content path:
```dart
Object? _data({required CreateUserForm body}) {
  final formData = FormData();
  formData.fields.add(MapEntry('name', body.name));
  if (body.nickname != null) {
    formData.fields.add(MapEntry('nickname', body.nickname!));
  }
  return formData;
}
```

### Multi-content path (switch arm):
```dart
MultiContentCreateUser value => () {
  final formData = FormData();
  formData.fields.add(MapEntry('name', value.name));
  return formData;
}(),
```

## Key Files
- `packages/tonik_generate/lib/src/util/to_form_value_expression_generator.dart` — pattern reference (exhaustive switch on Model)
- `packages/tonik_generate/lib/src/operation/data_generator.dart` — wire-in point (lines 82–85, 148–150)
- `packages/tonik_generate/lib/src/operation/options_generator.dart` — content type emission (lines 88, 107–120)
- `packages/tonik_generate/lib/src/naming/property_name_normalizer.dart` — `normalizeProperties()`

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart test packages/tonik_generate/test/src/operation/data_generator_test.dart
dart test packages/tonik_generate/test/src/operation/options_generator_test.dart
dart analyze packages/tonik_generate
```
