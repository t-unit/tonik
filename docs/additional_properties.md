# Additional Properties

Tonik supports `additionalProperties` on object schemas. When set, generated classes include an extra `Map` field that captures any JSON keys not defined as named properties.

---

## Basic Usage

Define `additionalProperties` on an object schema:

```yaml
UserMetadata:
  type: object
  required: [name]
  properties:
    name:
      type: string
  additionalProperties:
    type: string
```

The generated class has a typed map field alongside the named properties:

```dart
final user = UserMetadata(
  name: 'Jane',
  additionalProperties: {'role': 'admin', 'team': 'backend'},
);

print(user.additionalProperties['role']); // admin
```

The field defaults to an empty map and is included in `==`, `hashCode`, `copyWith`, and `toString`.

---

## Variants

### Typed Values

When `additionalProperties` points to a schema, the map values are typed accordingly:

```yaml
additionalProperties:
  type: integer
```

Generates `Map<String, int>` — values are decoded and encoded with full type safety.

### Untyped Values

`additionalProperties: true` or `additionalProperties: {}` generates `Map<String, Object?>`, accepting any JSON value.

### Disabled

`additionalProperties: false` is a no-op — no map field is generated, matching the behavior of schemas without `additionalProperties`.

---

## Pure Maps (No Named Properties)

When an object schema has `additionalProperties` but no named `properties`, Tonik generates a type alias instead of a class:

```yaml
StringMap:
  type: object
  additionalProperties:
    type: string
```

```dart
// Generated as a typedef:
typedef StringMap = Map<String, String>;
```

This applies to all value types — primitives, enums, nested objects, arrays, and maps.

---

## allOf with Additional Properties

`additionalProperties` on an `allOf` schema captures keys beyond those contributed by all member schemas:

```yaml
ExtendedPet:
  allOf:
    - $ref: '#/components/schemas/Pet'
    - type: object
      properties:
        vaccinated:
          type: boolean
  additionalProperties:
    type: string
```

The generated class includes fields from all members plus the additional properties map.

---

## Field Name Collisions

If a schema has a property literally named `additionalProperties`, Tonik renames the generated map field to `additionalProperties2` (incrementing as needed) to avoid conflicts.

---

## Encoding Behavior

### JSON

Additional properties are spread into the JSON output alongside named properties. Round-tripping through `toJson` / `fromJson` preserves all entries.

### Parameters (query, path, header)

Additional properties with **primitive value types** (string, int, number, bool, DateTime, Date, Uri, BigDecimal) are captured from parameter strings and encoded back. Complex value types (objects, maps, arrays) throw an `EncodingException` at runtime when encoding non-empty additional properties via parameter styles.

---

## Limitations

| | |
|---|---|
| Default when omitted | Schemas without `additionalProperties` do not generate a map field, even though the spec defaults to `true`. This matches the behavior of most code generators. |
| `oneOf` / `anyOf` | `additionalProperties` alongside `oneOf` or `anyOf` is not supported — the field is ignored. |
| Complex parameter encoding | Objects, maps, and arrays as additional property values cannot be encoded in query/path/header parameters. JSON encoding always works. |
