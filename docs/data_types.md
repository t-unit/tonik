# Data Types

This document provides information about how Tonik is mapping data types in OpenAPI into Dart.


## Primitive Types

| OAS Type | OAS Format | Dart Type | Dart Package | Comment |
|----------|------------|-----------|--------------|---------|
| `string` | `date-time` | `DateTime` | `dart:core` | ISO 8601 datetime format |
| `string` | `date` | `Date` | `tonik_util` | RFC3339 date format (YYYY-MM-DD) |
| `string` | `decimal`, `currency`, `money`, `number` | `BigDecimal` | `big_decimal` | High-precision decimal numbers |
| `string` | `enum` | `enum` | Generated | Custom enum type |
| `string` | (default) | `String` | `dart:core` | Standard string type |
| `number` | `float`, `double` | `double` | `dart:core` | 64-bit floating point |
| `number` | (default) | `num` | `dart:core` | Generic number type |
| `integer` | `enum` | `enum` | Generated | Custom enum type |
| `integer` | (default) | `int` | `dart:core` | 64-bit integer |
| `boolean` | (any) | `bool` | `dart:core` | Boolean type |
| `array` | (any) | `List<T>` | `dart:core` | List of specified type |

