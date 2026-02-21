# Sub-plan 5: Generate — Complex Object Properties

## Context

`ClassModel`, `AllOfModel`, `OneOfModel`, `AnyOfModel` properties are serialized as JSON and sent as `MultipartFile.fromString()` with `contentType: application/json`.

Note: `AliasModel` resolution is already handled in sub-plan 1's scaffold (resolves via `.resolved` before dispatching). This sub-plan only needs to add the branches for the complex types themselves.

### `deepObject` Style

In OAS 3.1, `style: deepObject` CAN be explicitly set on object properties in multipart encoding. `deepObject` serializes nested objects as flattened key-value pairs (e.g., `color[R]=100&color[G]=200`). This is complex to implement and rare in practice. For now, **throw `UnsupportedError`** when `style: deepObject` is encountered on a complex object property. Log a warning message. This matches the approach for `deepObject` on arrays in sub-plan 6.

After sub-plan 0, `encoding.style` is guaranteed non-null for multipart ClassModel bodies (defaults to `form`). The generator force-unwraps (`!`) this field per the encoding non-null guarantee from the master plan. If style is `deepObject`, throw `UnsupportedError`. For all other styles (`form`, `spaceDelimited`, `pipeDelimited`), proceed with JSON encoding — style is irrelevant for complex objects.

## Changes

### Modify: `to_multipart_expression_generator.dart`

Add branches for complex model types. The generated code should look like:
```dart
formData.files.add(MapEntry(
  'rawName',
  MultipartFile.fromString(
    jsonEncode(body.dartName.toJson()),
    contentType: DioMediaType.parse('application/json'),
  ),
));
```

Use `refer('MultipartFile', 'package:dio/dio.dart')`, `refer('DioMediaType', 'package:dio/dio.dart')`, `refer('jsonEncode', 'dart:convert')`, and `refer('MapEntry', 'dart:core')` per the convention established in sub-plan 1. `DioMediaType` is a typedef for `MediaType` from `package:http_parser` — it IS exported from `package:dio/dio.dart` in Dio 5.9.0.

Use the `contentType` from encoding (default `application/json` for objects, populated by sub-plan 0). Do NOT hardcode `application/json` — read from encoding to support overrides like `application/xml`.

**Unrecognized contentType fallback**: Objects are always serialized via `jsonEncode(value.toJson())` regardless of content type. The content type from encoding is passed to `DioMediaType.parse(...)` on the `MultipartFile` so the server sees whatever the spec declared. Even `application/xml` will get the JSON-serialized body — the OAS encoding object doesn't change the serialization format, only the MIME type label on the multipart part.

Before serializing, check `encoding.style`: if it is `deepObject`, throw `UnsupportedError('deepObject style is not supported for complex object properties in multipart encoding.')`. All other styles (`form`, `spaceDelimited`, `pipeDelimited`) are irrelevant for complex objects (they are JSON-encoded regardless) — ignore them silently.

### Modify: `to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Tests:
- ClassModel property -> JSON-encoded file part with encoding's contentType
- AllOfModel, OneOfModel, AnyOfModel properties
- Optional complex property -> null-check wrapping
- Required-but-nullable complex property -> null-check wrapping
- Complex property with custom contentType encoding (e.g. `application/xml`) -> still JSON-serialized, but with custom MIME type on the MultipartFile
- Complex property with `style: deepObject` -> throws `UnsupportedError`
- AliasModel wrapping a complex type (verify alias resolution from sub-plan 1 works end-to-end)

When using string-based assertions on generated code, format the complete method body with `DartFormatter` before comparison (per testing skill).

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart analyze packages/tonik_generate
```
