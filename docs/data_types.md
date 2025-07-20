# Data Types

This document provides information about how Tonik is mapping data types in OpenAPI into Dart.


## Primitive Types

| OAS Type | OAS Format | Dart Type | Dart Package | Comment |
|----------|------------|-----------|--------------|---------|
| `string` | `date-time` | `DateTime` | `dart:core` | See [Timezone-Aware DateTime Parsing](#timezone-aware-datetime-parsing) |
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

Tonik provides intelligent timezone-aware parsing for `date-time` format strings. The parsing behavior depends on the timezone information present in the input:

> **⚠️ Important:** Before using timezone-aware parsing features, you must initialize the timezone database by calling `tz.initializeTimeZones()` from the `timezone` package. This is typically done in your application's setup code.

All generated code will always expose Dart `DateTime` objects. However, standard Dart `DateTime` objects do not preserve timezone information, which is why Tonik uses `TZDateTime` internally during parsing to maintain timezone location data. During parsing, Tonik selects the most appropriate type to represent the date and time value:

| Input Format | Return Type | Example | Description |
|--------------|-------------|---------|-------------|
| UTC (with Z) | `DateTime` (UTC) | `2023-12-25T15:30:45Z` | Standard Dart DateTime in UTC |
| Local (no timezone) | `DateTime` (local) | `2023-12-25T15:30:45` | Standard Dart DateTime in local timezone |
| Timezone offset | `TZDateTime` | `2023-12-25T15:30:45+05:00` | Timezone-aware DateTime with proper location |



#### Timezone Location Selection

For strings with timezone offsets (e.g., `+05:00`), Tonik intelligently selects the best matching timezone location:

1. **Prefers common locations** from the timezone package's curated list of 535+ well-known timezones
2. **Accounts for DST changes** by checking the offset at the specific timestamp
3. **Avoids deprecated locations** (e.g., `US/Eastern` → `America/New_York`)
4. **Attempts fixed offset locations** (`Etc/GMT±N`) for standard hour offsets when no timezone match is found
5. **Falls back to UTC** for non-standard offsets or when `Etc/GMT±N` locations are unavailable

