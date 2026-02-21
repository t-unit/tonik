# Sub-plan 6: Generate — Array Properties (ListModel)

## Context

`ListModel` properties iterate items and add multiple entries following RFC 7578 §4.3.

### Encoding Behavior (version-agnostic)

Sub-plan 0 ensures the parser fully normalizes `style`, `explode`, and `allowReserved` based on the OAS version. The generator is **completely version-agnostic** — it just reads the encoding values and acts on them:

- `explode: true` (default) -> one entry per item with the same key.
- `explode: false` with `style: form` -> comma-separated value in a single field.
- `style: spaceDelimited`, `explode: false` -> space-separated value in a single field.
- `style: pipeDelimited`, `explode: false` -> pipe-separated value in a single field.
- `style: deepObject` -> undefined per spec for arrays; throw `UnsupportedError`.

OAS 3.0 specs will always arrive with `explode: true` / `style: form` because the parser enforces this (see sub-plan 0). OAS 3.1 specs will arrive with whatever the spec declares (or defaults). The generator doesn't need to know or care why.

## Changes

### Modify: `to_multipart_expression_generator.dart`

Add `ListModel` branch. Use `refer('MultipartFile', 'package:dio/dio.dart')`, `refer('DioMediaType', 'package:dio/dio.dart')`, `refer('MapEntry', 'dart:core')`, and `refer('jsonEncode', 'dart:convert')` per the convention established in sub-plan 1.

Dispatch on the list's `content` model type:
- List of primitives -> multiple `fields` entries (or delimited string based on `style` + `explode`)
- List of enums -> multiple `fields` entries with `.toJson().toString()` per item (or delimited string)
- List of binary -> multiple `files` entries (always one per item — `explode` flag is irrelevant for binary parts, since binary data cannot be meaningfully comma/space/pipe-delimited; if `explode: false` is set, treat as `explode: true`)
- List of complex objects -> multiple JSON `files` entries

**Empty list guard for `explode: false`**: When joining zero items with a delimiter, the result is an empty string. For `explode: false`, explicitly guard against adding an empty-string entry — an empty list should produce no entries (zero fields, zero files), not a single field with an empty value.

For non-exploded arrays (`explode: false`), respect the delimiter based on `style`:
- `form` -> `,` (comma)
- `spaceDelimited` -> ` ` (literal space — multipart parts are NOT URL-encoded)
- `pipeDelimited` -> `|` (literal pipe — multipart parts are NOT URL-encoded)
- `deepObject` -> throw `UnsupportedError` (undefined per spec for arrays)

### Modify: `to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Tests:
- List of strings (explode: true) -> one field entry per item
- List of strings (explode: true, style: spaceDelimited) -> still one field entry per item (style is irrelevant when exploding)
- List of strings (explode: false, style: form) -> comma-separated single field
- List of strings (explode: false, style: spaceDelimited) -> space-separated
- List of strings (explode: false, style: pipeDelimited) -> pipe-separated
- List of strings (explode: false, style: deepObject) -> throws UnsupportedError
- List of enums (explode: true) -> one field entry per item with `.toJson().toString()`
- List of enums (explode: false, style: form) -> comma-separated single field of enum wire values
- Empty list -> produces no entries (zero fields, zero files)
- List of binary files (explode: true) -> one file entry per item
- List of binary files (explode: false) -> still one file entry per item (binary cannot be delimited; treated as explode: true)
- List of complex objects -> one JSON file entry per item
- Optional list property -> null-check wrapping
- Required-but-nullable list property -> null-check wrapping

When using string-based assertions on generated code, format the complete method body with `DartFormatter` before comparison (per testing skill).

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart analyze packages/tonik_generate
```
