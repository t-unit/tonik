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

### Boolean Schemas (OAS 3.1)

OpenAPI 3.1 allows `schema: true` (accepts any value) and `schema: false` (accepts no value).

| Schema | Dart Type | Use Case |
|--------|-----------|----------|
| `true` | `Object?` | Flexible fields accepting any JSON |
| `false` | `Never` | Unreachable fields (always null) |

#### Encoding (sending requests)

Since `Object?` has no static type, Tonik checks the runtime type and encodes accordingly:

| Value Type | JSON Body | Path/Query/Header | Form-urlencoded Body |
|------------|-----------|-------------------|----------------------|
| Primitives (`String`, `int`, `double`, `bool`) | ✅ | ✅ | ✅ (via `toString()`) |
| `DateTime`, `Uri`, `BigDecimal` | ✅ | ✅ | ✅ (via `toString()`) |
| `List`, `Map` | ✅ recursive | ❌ throws | ✅ (via `toString()`) |
| Generated models (`JsonEncodable` / `ParameterEncodable`) | ✅ | ✅ | ✅ (via `toString()`) |
| `Map<String, String>` with `deepObject` style | — | ✅ | — |

Form-urlencoded bodies encode boolean schema fields using `toString()`, which works for any value but loses type information for complex structures.

#### Decoding (parsing responses)

| Context | Behavior |
|---------|----------|
| JSON body | Returns parsed value as-is (`Object?`) |
| Parameters | Passes through raw value as `Object?` |

Parameter decoding works when a class contains only primitives and boolean schema fields. 
If a class also contains nested objects, `fromSimple`/`fromForm` throw because the nested structure cannot be reconstructed from a flat string.

> **Recommendation:** Avoid boolean schemas when possible. Without a concrete schema, Tonik cannot decode values into typed objects — responses arrive as raw `Object?`. Encoding is also limited since there's no schema to guide serialization. Prefer explicit schema types for reliable round-trip behavior.

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

### Form URL-Encoded Bodies

Tonik supports `application/x-www-form-urlencoded` for flat object schemas. Arrays use exploded syntax (repeated keys). Nested objects throw runtime errors.

```dart
const form = SimpleForm(name: 'John Doe', age: 30);
final response = await api.postSimpleForm(body: form);
// Encoded as: name=John+Doe&age=30

const arrayForm = ArrayForm(colors: ['red', 'green']);
// Encoded as: colors=red&colors=green
```

Map custom content types to form encoding in [configuration](configuration.md#content-type-mapping).

### $ref with Siblings (OAS 3.1)

OpenAPI 3.1 adopts JSON Schema 2020-12 behavior where `$ref` can have sibling keywords applied alongside the referenced schema. This differs from OAS 3.0 where `$ref` consumed the entire schema object.

#### Annotation Siblings

| Sibling | Effect |
|---------|--------|
| `description` | Overrides referenced schema's description |
| `deprecated` | Adds `@Deprecated` annotation |

```yaml
LegacyPet:
  $ref: '#/components/schemas/Pet'
  deprecated: true
  description: 'Use NewPet instead'
```

Generates an alias with deprecation and custom docs.

#### Nullable References

Make a referenced type nullable using the OAS 3.1 type array syntax:

```yaml
OptionalPet:
  $ref: '#/components/schemas/Pet'
  type: ['object', 'null']
```

Generates `Pet?` (nullable alias).

#### Structural Siblings

Add properties or compose with other schemas:

```yaml
# $ref + properties → merged class
ExtendedPet:
  $ref: '#/components/schemas/Pet'
  properties:
    nickname:
      type: string

# $ref + allOf → combined allOf
EnhancedPet:
  $ref: '#/components/schemas/Pet'
  allOf:
    - $ref: '#/components/schemas/Trackable'
```

Both patterns generate `AllOfModel` compositions that merge the referenced schema with additional structure.

#### Summary

| Pattern | Generated Type |
|---------|----------------|
| `$ref` only | Direct reference (existing behavior) |
| `$ref` + `description`/`deprecated` | `AliasModel` with metadata |
| `$ref` + `type: [T, null]` | Nullable alias |
| `$ref` + `properties` | `AllOfModel` (ref + inline class) |
| `$ref` + `allOf`/`oneOf`/`anyOf` | `AllOfModel` with nested composition |

### `$defs` Local Definitions (OAS 3.1)

OpenAPI 3.1's alignment with JSON Schema 2020-12 allows `$defs` for local schema definitions within any schema. This enables grouping related types without polluting the global `components/schemas` namespace.

#### Basic Usage

```yaml
components:
  schemas:
    Order:
      type: object
      properties:
        id:
          type: string
        status:
          $ref: '#/components/schemas/Order/$defs/OrderStatus'
        items:
          type: array
          items:
            $ref: '#/components/schemas/Order/$defs/LineItem'
      $defs:
        OrderStatus:
          type: string
          enum: [pending, confirmed, shipped]
        LineItem:
          type: object
          properties:
            productId:
              type: string
            quantity:
              type: integer
```

Generates `Order`, `OrderStatus`, and `LineItem` as separate Dart types.

#### Namespace Schemas

Use `$defs` without a parent type to create logical groupings:

```yaml
components:
  schemas:
    UserTypes:
      description: User-related type definitions
      $defs:
        CreateUserRequest:
          type: object
          properties:
            email: { type: string }
            name: { type: string }
        UserResponse:
          type: object
          properties:
            id: { type: string }
            email: { type: string }
```

Reference via `$ref: '#/components/schemas/UserTypes/$defs/CreateUserRequest'`.

#### Cross-Schema References

`$defs` schemas can reference other component schemas and vice versa:

```yaml
Report:
  type: object
  properties:
    order:
      $ref: '#/components/schemas/Order'
    metadata:
      $ref: '#/components/schemas/Report/$defs/ReportMetadata'
  $defs:
    ReportMetadata:
      type: object
      properties:
        format:
          $ref: '#/components/schemas/Report/$defs/ReportFormat'
    ReportFormat:
      type: string
      enum: [pdf, csv, json]
```
