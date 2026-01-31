# Composite Data Types

OpenAPI's composition keywords (`oneOf`, `anyOf`, `allOf`) let you describe complex type relationships. Tonik generates idiomatic Dart code for each pattern: sealed classes for `oneOf`, nullable fields for `anyOf`, and composition classes for `allOf`. This guide shows what gets generated and how to use it.

For primitive type mappings, see [Data Types](data_types.md).

---

## oneOf: Exactly One Of

Use `oneOf` when a value must be **exactly one** of several types - like a tagged union or sum type.

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
- Each variant subclass wraps the inner type in a `value` field (e.g., `ResultSuccess` holds a `Success`)
- Construct via the variant subclass (`ResultSuccess(...)`), not the base `Result`
- With a discriminator, the value is preserved on encode and used on decode to select the variant

**Limitations:**
- Without a discriminator, overlapping shapes may cause ambiguous decoding
- Discriminator values must be present and consistent in payloads

### Inherited Discriminators

When your `oneOf` references schemas that inherit from a common parent with a discriminator, Tonik automatically detects and uses that discriminator. This is common in polymorphic APIs where a base type defines the discriminator and child types extend it via `allOf`.

OAS input (example):
```yaml
components:
  schemas:
    Pet:
      type: object
      required: [name, petType]
      properties:
        name: { type: string }
        petType: { type: string }
      discriminator:
        propertyName: petType
        mapping:
          cat: '#/components/schemas/Cat'
          dog: '#/components/schemas/Dog'
    Cat:
      allOf:
        - $ref: '#/components/schemas/Pet'
        - type: object
          properties:
            meow: { type: string }
    Dog:
      allOf:
        - $ref: '#/components/schemas/Pet'
        - type: object
          properties:
            bark: { type: string }
    PetChoice:
      oneOf:
        - $ref: '#/components/schemas/Cat'
        - $ref: '#/components/schemas/Dog'
```

**Example usage:**
```dart
// Cat is an allOf composition: Pet + CatModel
// IMPORTANT: Set the discriminator value to match the variant you're using
final cat = PetChoiceCat(
  Cat(
    pet: Pet(petType: 'cat', name: 'Whiskers'),  // Must be 'cat' for PetChoiceCat
    catModel: CatModel(meow: 'purr'),
  ),
);

// Encoding produces a flat JSON with all properties merged
final json = cat.toJson();
// => {"petType": "cat", "name": "Whiskers", "meow": "purr"}

// Decoding uses the discriminator for fast O(1) dispatch
final parsed = PetChoice.fromJson({'petType': 'cat', 'name': 'Whiskers', 'meow': 'purr'});
// => PetChoiceCat(...)

// Unknown discriminator values fall back to trying all variants
final fallback = PetChoice.fromJson({'petType': 'unknown', 'name': 'X', 'meow': 'y'});
// => PetChoiceCat(...) - first variant that successfully parses
```

> ⚠️ **Important:** When constructing a variant, you must set the discriminator property value to match the variant type. For example, when creating a `PetChoiceCat`, always use `petType: 'cat'`. Setting an incorrect value (e.g., `petType: 'dog'` inside a `PetChoiceCat`) will produce JSON that won't roundtrip correctly - decoding will dispatch to the wrong variant based on the discriminator value.

**How it works:**
- Tonik detects when `oneOf`/`anyOf` variants inherit from a parent with a discriminator via `allOf`
- The discriminator property and mappings are inherited automatically
- If a variant's schema name matches a mapping value, that mapping is used
- On encode, the discriminator value from the inner type is preserved in the JSON output
- On decode, the discriminator enables fast O(1) dispatch to the correct variant
- If the discriminator value is unknown, all variants are tried as fallback
- Missing discriminator property will cause a `DecodingException` (since it's required)

---

## anyOf: Any Combination

Use `anyOf` when a value could match **one or more** schemas - though typically you'll use just one.

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

## allOf: Compose Multiple Schemas

Use `allOf` to **combine multiple schemas** into one - like mixing in traits or extending a base type.

**What Tonik generates:** A composition class with one field per member schema:

```dart
class Entity {
  const Entity({required this.base, required this.timestamps});
  final Base base;
  final Timestamps timestamps;
}
```

JSON encoding merges all member fields into a single flat object; decoding parses the same JSON into each member.

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


