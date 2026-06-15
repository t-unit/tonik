# Default Values

Tonik translates the JSON Schema / OpenAPI `default` keyword into Dart-side
defaults. Every defaulted field becomes a public `<field>Default` member on
the generated class — and, when the value is a compile-time constant, also
becomes the constructor parameter's default value so `const MyClass()`
just works.

Defaults are supported on:

- model class properties (`components.schemas.*.properties.*.default`),
- operation parameters (the parameter's `schema.default`) for path, query,
  header, and cookie locations,
- `$ref` siblings — a property `$ref`-ing another schema can carry a
  sibling `default` that overrides the target's default (OAS 3.1+).

## Behaviour

### Applied on decode when the key is missing

When you decode JSON that omits a defaulted key, the generated `fromJson`
fills the field from the default:

```dart
final value = MyClass.fromJson(<String, Object?>{});
// value.<field> equals MyClass.<field>Default
```

When the JSON sends the key with an explicit `null`, the generated
`fromJson` honours that — it does **not** substitute the default:

```dart
// `title` is `{ type: string, nullable: true, default: "Mx." }`
MyClass.fromJson({}).title;                 // "Mx." (default applied)
MyClass.fromJson({'title': null}).title;    // null (explicit null wins)
```

The distinction matters for nullable defaulted fields. If you need
`null` on the wire to mean "use the default", flatten it on the caller
side before decoding.

### Two value shapes

Whether the default is also reachable through `const MyClass()` depends
on whether the value can be expressed as a Dart compile-time constant.

**Compile-time constant default** — for primitives, enums, and
collections built from them. The generated class exposes the default as
a `static const` member, and the constructor parameter defaults to it:

```dart
class DefaultedPrimitives {
  const DefaultedPrimitives({this.name = nameDefault, /* … */});

  static const String nameDefault = 'anon';

  final String name;
}

const value = DefaultedPrimitives();   // value.name == 'anon'
DefaultedPrimitives.nameDefault;       // 'anon' — reachable directly too
```

**Computed default** — for `DateTime`, `Uri`, `BigDecimal`, file
content, and any composite (`allOf` / `oneOf` / `anyOf` / nested object)
default. These values can't exist at compile time, so the generated
class exposes the default as a `static` getter that builds a fresh
value on each access:

```dart
class Subscription {
  // ...

  static DateTime get startsAtDefault => /* parses '2024-01-01T00:00:00Z' */;
}

Subscription.startsAtDefault;          // 2024-01-01T00:00:00Z, fresh each call
```

Computed defaults still apply on decode the same way — a missing key
in JSON populates the field from the getter:

```dart
Subscription.fromJson({}).startsAt;    // 2024-01-01T00:00:00Z
```

But `const Subscription()` does **not** work when the field is
required, because there's no compile-time value to attach. To
construct from Dart without supplying the field, reach for the getter:

```dart
Subscription(startsAt: Subscription.startsAtDefault, /* … */);
```

This is deliberate — see [Edge cases](#edge-cases) below.

## Examples

### Primitive default

```yaml
DefaultedPrimitives:
  type: object
  required:
    - name
  properties:
    name:
      type: string
      default: "anon"
    count:
      type: integer
      default: 0
    active:
      type: boolean
      default: true
```

```dart
const value = DefaultedPrimitives();
// value.name == 'anon', value.count == 0, value.active == true

DefaultedPrimitives.nameDefault;      // 'anon'
DefaultedPrimitives.countDefault;     // 0
DefaultedPrimitives.activeDefault;    // true
```

`name` is marked `required` in the schema but still defaults at
construction — when a defaulted property is required, the field type
stays non-nullable and the constructor parameter becomes optional. The
default fills in if you omit it.

### Enum default

```yaml
Subscription:
  type: object
  properties:
    priority:
      type: string
      enum: [low, medium, high]
      default: medium
```

```dart
const value = Subscription();
// value.priority == SubscriptionPriority.medium

Subscription.priorityDefault;        // SubscriptionPriority.medium
```

### Collection default

```yaml
Filters:
  type: object
  properties:
    tags:
      type: array
      items: { type: string }
      default: ["new", "featured"]
    counts:
      type: object
      additionalProperties: { type: integer }
      default:
        x: 1
        y: 2
```

```dart
const value = Filters();
// value.tags == ['new', 'featured']
// value.counts == {'x': 1, 'y': 2}

Filters.tagsDefault;                 // ['new', 'featured']
Filters.countsDefault;               // {'x': 1, 'y': 2}
```

The defaults are `const` collections, so `identical(a.tags, b.tags)`
holds across instances created from the default.

### DateTime default (computed)

```yaml
Subscription:
  type: object
  required: [startsAt]
  properties:
    startsAt:
      type: string
      format: date-time
      default: "2024-01-01T00:00:00Z"
```

```dart
Subscription.startsAtDefault;        // 2024-01-01T00:00:00Z

// fromJson still applies it on missing keys:
Subscription.fromJson({}).startsAt;  // 2024-01-01T00:00:00Z
```

`DateTime` values can't be Dart compile-time constants, so
`const Subscription()` won't compile. Construct explicitly:

```dart
Subscription(startsAt: Subscription.startsAtDefault);
```

### Nested object default (computed)

```yaml
Subscription:
  type: object
  properties:
    pricing:
      $ref: '#/components/schemas/Pricing'
      default:
        amount: "9.99"
        currency: "USD"

Pricing:
  type: object
  required: [amount, currency]
  properties:
    amount:
      type: string
      format: decimal
    currency:
      type: string
```

```dart
Subscription.pricingDefault;
// Pricing(amount: BigDecimal('9.99'), currency: 'USD')

Subscription.fromJson({}).pricing;   // same Pricing instance, freshly built
```

The default is decoded through the target class's own `fromJson`, so
`oneOf` variant routing, `allOf` member merging, and
`additionalProperties` extras all behave exactly as they would on any
other inbound payload.

## Edge cases

### Type-mismatched compile-time defaults are dropped

```yaml
properties:
  count:
    type: integer
    default: "not a number"   # warning + drop
```

Tonik logs a warning and emits no `countDefault` static member. The
field decodes as if no default were declared. Fix the type to opt back
in.

This only applies to primitives, enums, and collections of those.
Composite and non-const-leaf defaults aren't pre-validated — see the
next two bullets.

### Composite defaults are decoded at access time

A default on an `allOf` / `oneOf` / `anyOf` property, or on a property
whose type is a generated class, is delivered as a `static` getter
that decodes the value on each call. Variant routing, `allOf` member
merging, and `additionalProperties` extras all flow through the target
class's existing `fromJson`.

A class declared with `additionalProperties: false` has no place to
hold extra entries, so any extras in a spec default are dropped on
decode and never survive a round-trip. No warning is emitted; the drop
is a structural property of the generated class.

A bad composite default (e.g. a `oneOf` default that matches no
variant, an `allOf` default missing a required member property) only
fails at runtime when the getter is first accessed — either by
direct reference or by a `fromJson` that triggers the default
fall-through.

### `required` + default — only compile-time defaults reach the constructor

A compile-time-constant default makes a `required` property's
constructor parameter optional:

```yaml
DefaultedPrimitives:
  type: object
  required: [name]
  properties:
    name: { type: string, default: "anon" }
```

```dart
const DefaultedPrimitives();   // works — name is 'anon'
```

A computed default does **not**. The constructor parameter stays
`required this.field` because there's no compile-time value to attach.
To construct without supplying the field, reach for the getter:

```dart
Subscription(startsAt: Subscription.startsAtDefault);
```

## Limitations

- **Non-const value types never get a compile-time-constant default.**
  `DateTime`, `Date`, `Uri`, `BigDecimal`, and file content can't be
  Dart compile-time constants. Defaults of these types are delivered
  as computed getters; they apply on decode but cannot be inlined into
  the constructor.
- **Computed getters are not cached.** Each access of
  `MyClass.fieldDefault` rebuilds the value. If you need identity
  (`identical(a, b)`) or want to avoid the per-call decode cost,
  capture in a local: `final d = MyClass.fieldDefault;`.
- **Sibling `default` on `$ref` is OAS 3.1+ semantics.** OAS 3.0
  technically forbids sibling keywords next to `$ref`. Tonik accepts
  the sibling-default pattern in both 3.0 and 3.1, but some validators
  may reject the 3.0 spec as non-conformant.
- **External `$ref`s are not supported.** Defaults declared in an
  external file cannot propagate, because tonik does not load external
  files at all.
- **Top-level component schema defaults are pure metadata.** A
  component schema with `default: "us"` only takes effect when another
  schema `$ref`s it. Tonik does not emit standalone constants for
  unreferenced component schemas.
- **`default` is silently dropped in positions tonik can't act on.**
  Examples: `default` on a `oneOf` member schema itself (rather than on
  the property whose type is the `oneOf`), `default` on the
  `additionalProperties` subschema (there's no Dart construction hook
  for unspecified map entries), or `default` on an unused component
  schema. No warning is emitted.
- **`nullable: true, default: null` collapses to no default.** No
  static member is emitted; the field behaves exactly as if no
  `default` were declared (a missing key already decodes as `null` on
  a nullable field).
- **Self-referential composite defaults are a known limitation.** A
  schema like `Node { next: { $ref: '#/.../Node', default: {} } }`
  declares "decode the default `{}` as a `Node` whose `next` itself
  defaults to `{}` …" — infinite recursion at first access of
  `Node.nextDefault`. Use `nullable: true, default: null` (or omit the
  default keyword) on self-referential properties instead.
