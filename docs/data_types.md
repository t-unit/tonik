# Data Types

This document provides information about how Tonik is mapping data types in OpenAPI into Dart.


## Primitive Types

| OAS Type | OAS Format | Dart Type | Dart Package | Comment |
|----------|------------|-----------|--------------|---------|
| `string` | `date-time` | `DateTime` / `OffsetDateTime` | `dart:core` / `tonik_util` | See [Timezone-Aware DateTime Parsing](#timezone-aware-datetime-parsing) |
| `string` | `date` | `Date` | `tonik_util` | RFC3339 date format (YYYY-MM-DD) |
| `string` | `decimal`, `currency`, `money`, `number` | `BigDecimal` | `big_decimal` | High-precision decimal numbers |
| `string` | `uri`, `url` | `Uri` | `dart:core` | URI/URL parsing and validation |
| `string` | `enum` | `enum` | Generated | Custom enum type |
| `string` | (default) | `String` | `dart:core` | Standard string type |
| `number` | `float`, `double` | `double` | `dart:core` | 64-bit floating point |
| `number` | (default) | `num` | `dart:core` | Generic number type |
| `integer` | `enum` | `enum` | Generated | Custom enum type |
| `integer` | (default) | `int` | `dart:core` | 64-bit integer |
| `boolean` | (any) | `bool` | `dart:core` | Boolean type |
| `array` | (any) | `List<T>` | `dart:core` | List of specified type |

### Timezone-Aware DateTime Parsing

Tonik provides intelligent timezone-aware parsing for `date-time` format strings using the `OffsetDateTime` class. The parsing behavior depends on the timezone information present in the input:

All generated code will always expose Dart `DateTime` objects through the standard decoder methods. However, internally Tonik uses `OffsetDateTime.parse()` to provide consistent timezone handling. The `OffsetDateTime` class extends Dart's `DateTime` interface while preserving timezone offset information:

| Input Format | Return Type | Example | Description |
|--------------|-------------|---------|-------------|
| UTC (with Z) | `OffsetDateTime` (UTC) | `2023-12-25T15:30:45Z` | OffsetDateTime with zero offset (UTC) |
| Local (no timezone) | `OffsetDateTime` (system timezone) | `2023-12-25T15:30:45` | OffsetDateTime with system timezone offset |
| Timezone offset | `OffsetDateTime` (specified offset) | `2023-12-25T15:30:45+05:00` | OffsetDateTime with the specified offset |

#### OffsetDateTime Benefits

The `OffsetDateTime` class provides several advantages over standard `DateTime` objects:

- **Preserves timezone offset information**: Unlike `DateTime`, `OffsetDateTime` retains the original timezone offset
- **Consistent API**: Implements the complete `DateTime` interface, so it can be used as a drop-in replacement
- **Fixed offset semantics**: Uses fixed timezone offsets rather than location-based timezones, avoiding DST ambiguity
- **Auto-generated timezone names**: Provides human-readable timezone names like `UTC+05:30`, `UTC-08:00`, or `UTC`

#### Local Time Preservation

For strings without timezone information (e.g., `2023-12-25T15:30:45`), `OffsetDateTime.parse()` preserves the local timezone behavior by using the system's timezone offset for that specific date and time. This ensures consistency with Dart's `DateTime.parse()` while providing the additional timezone offset information.
