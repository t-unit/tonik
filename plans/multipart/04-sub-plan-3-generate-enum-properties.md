# Sub-plan 3: Generate — Enum Properties

## Context

Enum properties serialize via `.toJson()` (returns the wire-format string value) then `.toString()` or as a JSON fragment depending on encoding.

Note: `.toJson()` returns `dynamic` (the OAS enum wire value — typically `String` but could be `int` for numeric enums). Calling `.toString()` normalizes it to a string for the multipart text field. For `application/json` encoding, use `jsonEncode(body.prop.toJson())` which handles all JSON-compatible types.

## Changes

### Modify: `to_multipart_expression_generator.dart`

Add `EnumModel` branch. Serialize as `body.prop.toJson().toString()` for text/plain, or `jsonEncode(body.prop.toJson())` for application/json. Use the `_isJsonContentType()` helper established in sub-plan 1 for content type comparison.

**Unrecognized contentType fallback**: If the encoding contentType is neither `text/plain` nor `application/json` (e.g., `application/xml`), fall back to `.toJson().toString()` serialization (same as `text/plain`). There is no meaningful way to encode an enum value as XML or other formats.

### Modify: `to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Add enum property test cases:
- Required enum property with `text/plain` encoding
- Required enum property with `application/json` encoding
- Optional enum property -> null-check wrapping
- Required-but-nullable enum property -> null-check wrapping
- Enum property with unrecognized contentType (e.g. `application/xml`) -> falls back to `.toJson().toString()` serialization

When using string-based assertions on generated code, format the complete method body with `DartFormatter` before comparison (per testing skill).

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart analyze packages/tonik_generate
```
