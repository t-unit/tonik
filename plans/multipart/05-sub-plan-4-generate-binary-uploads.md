# Sub-plan 4: Generate — Binary File Uploads

## Context

`BinaryModel` properties (OAS `type: string, format: binary`) represent file uploads. These are `List<int>` in Dart and become `MultipartFile.fromBytes()` in `FormData.files`.

## Changes

### Modify: `to_multipart_expression_generator.dart`

Add `BinaryModel` branch:
```dart
formData.files.add(MapEntry(
  'rawName',
  MultipartFile.fromBytes(body.dartName, filename: 'rawName'),
));
```

Use property name as filename. If encoding specifies a `contentType`, pass it as `contentType: DioMediaType.parse(...)` where `DioMediaType` is referenced via `refer('DioMediaType', 'package:dio/dio.dart')` (it's a typedef for `MediaType` from `package:http_parser`). The default for binary is `application/octet-stream` (already populated by sub-plan 0). Use `refer('MultipartFile', 'package:dio/dio.dart')` and `refer('MapEntry', 'dart:core')` per the convention established in sub-plan 1.

### Modify: `to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Tests:
- Required binary property -> `MultipartFile.fromBytes` in `FormData.files`
- Optional binary property -> null-check wrapping
- Required-but-nullable binary property -> null-check wrapping
- Binary with explicit contentType encoding (e.g. `image/png`)
- Binary with default contentType (`application/octet-stream`)

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart analyze packages/tonik_generate
```
