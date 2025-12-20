# Data Types

This document provides information about how Tonik is mapping data types in OpenAPI into Dart.


## Primitive Types

| OAS Type | OAS Format | Dart Type | Dart Package | Comment |
|----------|------------|-----------|--------------|---------|
| `string` | `date-time` | `DateTime` / `OffsetDateTime` | `dart:core` / `tonik_util` | See [Timezone-Aware DateTime Parsing](#timezone-aware-datetime-parsing) |
| `string` | `date` | `Date` | `tonik_util` | RFC3339 date format (YYYY-MM-DD) |
| `string` | `decimal`, `currency`, `money`, `number` | `BigDecimal` | `big_decimal` | High-precision decimal numbers |
| `string` | `uri`, `url` | `Uri` | `dart:core` | URI/URL parsing and validation |
| `string` | `binary` | `List<int>` | `dart:core` | See [Binary Data](#binary-data) |
| `string` | `byte` | `String` | `dart:core` | Base64 encoded data (kept as string) |
| `string` | `enum` | `enum` | Generated | Custom enum type |
| `string` | (default) | `String` | `dart:core` | Standard string type |
| `number` | `float`, `double` | `double` | `dart:core` | 64-bit floating point |
| `number` | (default) | `num` | `dart:core` | Generic number type |
| `integer` | `enum` | `enum` | Generated | Custom enum type |
| `integer` | (default) | `int` | `dart:core` | 64-bit integer |
| `boolean` | (any) | `bool` | `dart:core` | Boolean type |
| `array` | (any) | `List<T>` | `dart:core` | List of specified type |

### Timezone-Aware DateTime Parsing

Tonik provides timezone-aware parsing for `date-time` format strings using the `OffsetDateTime` class. The parsing behavior depends on the timezone information present in the input:

All generated code will always expose Dart `DateTime` objects in the generated code. However, internally Tonik uses `OffsetDateTime.parse()` to provide consistent timezone handling. The `OffsetDateTime` class extends Dart's `DateTime` interface while preserving timezone offset information:

| Input Format | Return Type | Example | Description |
|--------------|-------------|---------|-------------|
| UTC (with Z) | `OffsetDateTime` (UTC) | `2023-12-25T15:30:45Z` | OffsetDateTime with zero offset (UTC) |
| Local (no timezone) | `OffsetDateTime` (system timezone) | `2023-12-25T15:30:45` | OffsetDateTime with system timezone offset |
| Timezone offset | `OffsetDateTime` (specified offset) | `2023-12-25T15:30:45+05:00` | OffsetDateTime with the specified offset |

### Binary and Text Bodies

Tonik supports binary and plain text content types for request/response bodies:

| Content Type | Dart Type | Description |
|--------------|-----------|-------------|
| `application/octet-stream`, `image/*` | `List<int>` | Raw binary data (files, images) |
| `text/plain`, `text/html` | `String` | Plain text content |

For `format: binary` fields nested in JSON objects, Tonik auto UTF-8 encodes/decodes.
For `format: byte`, Tonik keeps the base64-encoded string as-is.

**Example: Binary file download/upload**
```dart
// Download
final result = await filesApi.getFile(id: 'my-file');
final bytes = (result as TonikSuccess).value.body; // List<int>

// Upload
final fileData = await File('photo.png').readAsBytes();
await filesApi.uploadFile(id: 'my-file', body: fileData);
```

**Example: Plain text**
```dart
// text/plain bodies are typed as String
final result = await api.getMessage();
final text = (result as TonikSuccess).value.body; // String
```
