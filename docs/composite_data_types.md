# Composite Data Types

OpenAPI's composition keywords (`oneOf`, `anyOf`, `allOf`) let you describe complex type relationships. Tonik generates idiomatic Dart code for each pattern using sealed classes and nullable fields. This guide shows what gets generated and how to use it.

For primitive type mappings, see [Data Types](data_types.md).

---

## oneOf: Exactly One Of

Use `oneOf` when a value must be **exactly one** of several types—like a tagged union or sum type.

**What Tonik generates:** A sealed base class with a subclass for each variant. Pattern matching lets you handle each case safely.

OAS input (example):
```yaml
components:
  schemas:
    Result:
      oneOf:
        - $ref: '#/components/schemas/Success'
        - $ref: '#/components/schemas/Error'
      discriminator:
        propertyName: type
        mapping:
          success: '#/components/schemas/Success'
          error: '#/components/schemas/Error'
    Success:
      type: object
      required: [type, message]
      properties:
        type: { type: string, enum: [success] }
        message: { type: string }
    Error:
      type: object
      required: [type, code]
      properties:
        type: { type: string, enum: [error] }
        code: { type: integer }
```

**Example usage:**
```dart
// Construct a variant (use the variant subclass, not the base type)
final r1 = ResultSuccess(Success(type: 'success', message: 'done'));
final r2 = ResultError(Error(type: 'error', code: 404));

// Encode / decode
final json = r1.toJson();
final roundtrip = Result.fromJson(json);

// Work with the result
final text = switch (roundtrip) {
  ResultSuccess(:final value) => value.message,
  ResultError(:final value) => 'error ${value.code}',
};
```

**Tips:**
- Construct via the variant subclass (`ResultSuccess(...)`), not the base `Result`
- With a discriminator, the value is preserved on encode and used on decode to select the variant

**Limitations:**
- Without a discriminator, overlapping shapes may cause ambiguous decoding
- Discriminator values must be present and consistent in payloads

---

## anyOf: Any Combination

Use `anyOf` when a value could match **one or more** schemas—though typically you'll use just one.

**What Tonik generates:** A single class with nullable fields for each alternative. Set the field(s) that apply.

OAS input (example):
```yaml
components:
  schemas:
    SearchKey:
      anyOf:
        - type: string
        - $ref: '#/components/schemas/User'
    User:
      type: object
      required: [id]
      properties:
        id: { type: integer }
```

**Example usage:**
```dart
// As a primitive
final k1 = SearchKey(string: 'alice');
final json1 = k1.toJson();
final back1 = SearchKey.fromJson(json1);

// As an object
final k2 = SearchKey(user: User(id: 1));
final json2 = k2.toJson();
final back2 = SearchKey.fromJson(json2);
```

**Limitations:**
- Setting multiple alternatives with incompatible representations causes ambiguous encoding
- Overlapping object alternatives without a discriminator may fail to decode

---

## allOf: Merge All

Use `allOf` to **combine multiple schemas** into one—like mixing in traits or extending a base type.

**What Tonik generates:** A class with one field per member schema. JSON encoding merges all members into a single object.

OAS input (example):
```yaml
components:
  schemas:
    Entity:
      allOf:
        - $ref: '#/components/schemas/Base'
        - $ref: '#/components/schemas/Timestamps'
    Base:
      type: object
      required: [id]
      properties:
        id: { type: string }
    Timestamps:
      type: object
      required: [createdAt]
      properties:
        createdAt: { type: string, format: date-time }
        updatedAt: { type: string, format: date-time }
```

**Example usage:**
```dart
final e = Entity(
  base: Base(id: '42'),
  timestamps: Timestamps(createdAt: DateTime.now()),
);
final json = e.toJson();
final parsed = Entity.fromJson(json);
```

**Limitations:**
- Member schemas with conflicting JSON keys will fail to encode/decode
- Complex nested structures may not support query/path parameter encoding

---

## Arrays and Nesting

Compositions can appear inside arrays and other models. For example, an array of a `oneOf` generates a list of the union type; you create elements using the generated variant subclasses.

## Naming

- Generated names derive from your schema names
- `oneOf` variants are prefixed by their base type (e.g., `ResultSuccess`, `ResultError`)
- Discriminator values influence variant naming when present
- Override any name with `x-dart-name` or [configuration](configuration.md)


