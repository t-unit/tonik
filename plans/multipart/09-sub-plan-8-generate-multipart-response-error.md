# Sub-plan 8: Generate — Multipart Response Decoding (Graceful Error)

## Context

Multipart responses are extremely rare. Instead of crashing the generator, generate a runtime error so the generated API client can still be used for other operations.

## Changes

### Modify: `packages/tonik_generate/lib/src/operation/parse_generator.dart`

Find the `throw UnimplementedError(...)` for multipart response decoding (search for `Multipart response body decoding`) and replace with:
```dart
ContentType.multipart => _createMultipartBodyDecodeError(),
```

Add method that generates a throw expression using the existing `generateResponseDecodingExceptionExpression()` helper from `exception_code_generator.dart`. This helper already produces a throw expression with the correct `refer` import for `package:tonik_util/tonik_util.dart`. Use message: `'Multipart response body decoding is not supported.'`. This matches the pattern already used elsewhere in `parse_generator.dart` (e.g., line 72).

### Modify: `packages/tonik_generate/test/src/operation/parse_generator_test.dart`

**TDD: Write these tests first, then implement.**

Tests:
- Operation with multipart response generates code that compiles (does not crash at generation time)
- Generated code throws a `ResponseDecodingException` (from `tonik_util`) at runtime, not an `UnimplementedError`
- Exception message contains `'Multipart response body decoding is not supported.'`
- Prefer object introspection: verify the generated method exists and is well-formed. Use `contains(collapseWhitespace(...))` to verify the throw expression contains the correct exception type and message string. Format the complete method body with `DartFormatter` before string comparison (per testing skill).

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/operation/parse_generator_test.dart
dart analyze packages/tonik_generate
```
