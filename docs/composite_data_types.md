### Composite Data Types (Tonik-generated code)

This guide shows, at a glance, what Tonik generates for OpenAPI `oneOf`, `anyOf`, and `allOf`, how you use the resulting Dart types, and when things can’t be encoded/decoded. It is user-focused and avoids internal details. See `docs/data_types.md` for primitives.

## oneOf: exclusive choice

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

What Tonik generates conceptually:
- A union-like base class `Result` with one subclass per variant (for example `ResultSuccess`, `ResultError`).
- Each subclass wraps the underlying model instance (`Success`, `Error`).

How to use it:
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

Notes:
- Construct via a variant subclass (for example `ResultSuccess(...)`), not the base `Result`.
- When a discriminator is present, the discriminator value is preserved on encode and used on decode to select the variant.

When things won’t work smoothly (high level):
- No discriminator and overlapping shapes: decoding may be ambiguous and fail.
- A discriminator that is missing or inconsistent in payloads: decoding fails.
- Arrays or primitives as variants are supported, but deeply overlapping shapes can still be ambiguous.

## anyOf: flexible choice

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

What Tonik generates conceptually:
- A single class `SearchKey` with nullable fields for each alternative (for example `string`, `user`). You typically set exactly one.

How to use it:
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

When things won’t work smoothly (high level):
- Multiple alternatives set at once that serialize to different representations: encoding fails as ambiguous.
- Mixing primitive and object alternatives at the same time: simple or JSON encoding can be ambiguous and fail.
- Overlapping object alternatives without a discriminator: decoding can be ambiguous and fail.

## allOf: composition

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

What Tonik generates conceptually:
- A class `Entity` containing one field for each member schema (for example `base`, `timestamps`).
- JSON/simple encoding merges the members’ representations.

How to use it:
```dart
final e = Entity(
  base: Base(id: '42'),
  timestamps: Timestamps(createdAt: DateTime.now()),
);
final json = e.toJson();
final parsed = Entity.fromJson(json);
```

When things won’t work smoothly (high level):
- Members that would conflict on the same JSON keys/types: encoding or decoding fails.
- Including complex nested structures might make simple (query/path) encoding unsupported.

## Arrays and nesting

Compositions can appear inside arrays and other models. For example, an array of a `oneOf` generates a list of the union type; you create elements using the generated variant subclasses.

## Naming notes

- Class and file names derive from your schema names; `oneOf` variants are prefixed by their base type.
- Discriminator values (when present) influence variant naming and decoding.


