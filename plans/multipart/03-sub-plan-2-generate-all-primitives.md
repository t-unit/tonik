# Sub-plan 2: Generate — All Primitive Types

## Context

Extend the multipart generator to handle all remaining primitive types. Serialization depends on the encoding contentType (populated by sub-plan 0):
- `text/plain` (the default for primitives) -> type-specific text serialization (see table below)
- `application/json` (if explicitly overridden) -> JSON fragment (use `jsonEncode()`)

Note: For multipart, the OAS spec defaults primitives to `text/plain` in both 3.0 and 3.1. The `application/json` encoding only applies if explicitly set in the encoding object.

### Text serialization per type

Not all types can use `.toString()` — some need format-specific serialization to produce the correct wire format:

| Model | `text/plain` serialization | Why |
|---|---|---|
| `IntegerModel` | `.toString()` | Dart `int.toString()` produces the correct integer string. |
| `DoubleModel` | `.toString()` | Dart `double.toString()` produces the correct number string. |
| `NumberModel` | `.toString()` | Dart `num.toString()` works correctly. |
| `BooleanModel` | `.toString()` | Produces `"true"` / `"false"`. |
| `DateTimeModel` | `.toTimeZonedIso8601String()` | Dart's `DateTime.toString()` produces a non-standard format. Must use `toTimeZonedIso8601String()` (from `tonik_util`) to produce RFC 3339 / ISO 8601 with timezone. |
| `DateModel` | `.toString()` | Custom `Date` class — `toString()` already produces `YYYY-MM-DD`. |
| `DecimalModel` | `.toString()` | `BigDecimal.toString()` produces the correct decimal string. |
| `UriModel` | `.toString()` | `Uri.toString()` produces the correct URI string. |

Reference: the existing `to_form_value_expression_generator.dart` routes all these types through `.toForm()` which internally calls `.uriEncode()`. For multipart, we don't need URI encoding (parts are not URL-encoded), but we do need the same underlying value formatting.

## Changes

### Modify: `packages/tonik_generate/lib/src/util/to_multipart_expression_generator.dart`

Add branches for: `IntegerModel`, `DoubleModel`, `NumberModel`, `BooleanModel`, `DateTimeModel`, `DateModel`, `DecimalModel`, `UriModel`.

For each, check `encoding.contentType`:
- If `text/plain` (default): serialize using the type-specific method from the table above.
- If `application/json`: serialize as JSON fragment string via `jsonEncode()` (use `refer('jsonEncode', 'dart:convert')`).

**Content type comparison**: Compare only the MIME type portion of the content type string, stripping any parameters (e.g., `application/json; charset=utf-8` should match `application/json`). Sub-plan 0 populates defaults as exact strings without parameters, but user-specified encoding overrides may include parameters. Use a simple prefix check or split on `;` and trim before comparing.

`DateTimeModel` is the critical case — it MUST use `.toTimeZonedIso8601String()`, not `.toString()`.

Note: `style` has no effect on scalar primitives — it only matters for arrays and objects. Explicitly ignore `style` for these types.

### Modify: `packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Add tests for each primitive type with both `text/plain` and `application/json` encoding. Prefer object introspection; use `contains(collapseWhitespace(...))` only when testing specific code blocks. When using string-based assertions on generated code, format the complete method body with `DartFormatter` before comparison (per testing skill).

Pay special attention to `DateTimeModel` — verify the generated code calls `.toTimeZonedIso8601String()` and not `.toString()`. Use `contains(collapseWhitespace(...))` to assert the specific method name in the generated output.

Also test:
- Required-but-nullable variant for at least one primitive type (e.g. nullable required integer) to verify null-check wrapping is applied correctly.
- Primitive with an encoding `contentType` that is neither `text/plain` nor `application/json` (e.g. `application/xml`) — the generator should fall back to `.toString()` serialization (same as `text/plain`), since there is no meaningful way to encode a primitive as XML.

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart analyze packages/tonik_generate
```
