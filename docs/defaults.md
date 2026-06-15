# Default Values

Tonik translates the JSON Schema / OpenAPI `default` keyword into Dart-side
defaults. Every defaulted field gets a public static member named
`<field>Default` on its containing class — and, where Dart allows it, the
constructor parameter is wired to that same member so `const MyClass()`
just works.

Defaults are supported on:

- model class properties (`components.schemas.*.properties.*.default`),
- operation parameters (the parameter's `schema.default`) for path, query,
  header, and cookie locations,
- `$ref` siblings (a property `$ref`-ing an aliased schema with a sibling
  `default` overrides the target's default — OAS 3.1+).

## Behaviour

### Apply on decode

Generated `fromJson` constructors use a `containsKey` template:

```dart
field: _$map.containsKey('field')
    ? /* decode _$map['field'] */
    : ContainingClass.fieldDefault,
```

`containsKey` preserves the difference between **missing** and **explicit
null**. On a nullable defaulted field, `{"field": null}` decodes to `null`,
not to the default — the wire sent `null` explicitly, so the user gets
`null`.

### Two emission shapes

Defaults split into two emission shapes based on whether the value is a
Dart compile-time constant. Both shapes share the same decoder template
and the same `<field>Default` naming.

**Compile-time constant default (`static const`)**

For primitives, enums, `AnyModel`, and collections of the above the
generator emits a `static const` field. The constructor parameter is
wired to it via `defaultTo`:

```dart
class DefaultedPrimitives {
  const DefaultedPrimitives({this.name = nameDefault, /* … */});

  static const String nameDefault = 'anon';

  final String name;

  factory DefaultedPrimitives.fromJson(Object? json) { /* containsKey */ }
}
```

`const DefaultedPrimitives()` works and the field gets the default. The
constant is the single source of truth — both the constructor `defaultTo`
and the decoder reference `nameDefault`.

**Computed-getter default (`static get`)**

For composites (`ClassModel`, `AllOfModel`, `OneOfModel`, `AnyOfModel`)
and non-const leaf types (`DateTime`, `Date`, `Uri`, `BigDecimal`,
`Binary`, `Base64`) — including collections whose leaves are any of the
above — the generator emits a computed getter:

```dart
class Subscription {
  const Subscription({required this.startsAt, /* … */});

  static DateTime get startsAtDefault =>
      r'2024-01-01T00:00:00Z'.decodeJsonDateTime(
        context: r'Subscription.startsAt',
      );

  final DateTime startsAt;

  factory Subscription.fromJson(Object? json) { /* containsKey */ }
}
```

The constructor parameter stays `required`. Decoding still applies the
default on missing keys, but Dart-side construction without the field
requires the caller to reference the getter explicitly:

```dart
final s = Subscription(startsAt: Subscription.startsAtDefault);
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
class DefaultedPrimitives {
  const DefaultedPrimitives({
    this.name = nameDefault,
    this.count = countDefault,
    this.active = activeDefault,
  });

  static const String nameDefault = 'anon';
  static const int countDefault = 0;
  static const bool activeDefault = true;

  final String name;
  final int? count;
  final bool? active;
}
```

The `name` field stays non-nullable because the constructor still defaults
it when the caller omits it — required + default makes the constructor
parameter optional but leaves the field type unchanged. `count` and
`active` are not `required`, so their fields stay nullable.

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
class Subscription {
  const Subscription({this.priority = priorityDefault});

  static const SubscriptionPriorityModel priorityDefault =
      SubscriptionPriorityModel.medium;

  final SubscriptionPriorityModel? priority;
}
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
class Filters {
  const Filters({
    this.tags = tagsDefault,
    this.counts = countsDefault,
  });

  static const List<String> tagsDefault = ['new', 'featured'];
  static const Map<String, int> countsDefault = {'x': 1, 'y': 2};

  final List<String>? tags;
  final Map<String, int>? counts;
}
```

`const` collections are shared by reference — `identical(a.tags, b.tags)`
is true across instances created with the default.

### DateTime default (computed getter)

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
class Subscription {
  const Subscription({required this.startsAt});

  static DateTime get startsAtDefault =>
      r'2024-01-01T00:00:00Z'.decodeJsonDateTime(
        context: r'Subscription.startsAt',
      );

  final DateTime startsAt;
}
```

`DateTime` values can't be parsed from ISO 8601 strings at compile time,
so the default is a computed getter. Construction without the field
calls the getter explicitly:

```dart
final s = Subscription(startsAt: Subscription.startsAtDefault);
```

### Nested class default (computed getter)

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
class Subscription {
  const Subscription({this.pricing});

  static Pricing get pricingDefault => Pricing.fromJson(
        const <String, Object?>{'amount': '9.99', 'currency': 'USD'},
      );

  final Pricing? pricing;
}
```

The raw JSON literal is `const`; only the decoded `Pricing` instance
allocates. The existing `Pricing.fromJson` handles the BigDecimal decode
and `required` validation.

## Edge cases

### Type-mismatched compile-time defaults are dropped

```yaml
properties:
  count:
    type: integer
    default: "not a number"   # warning + drop
```

The generator logs a warning and emits no `static const`. The decoder
falls back to its normal no-default path for `count`. Spec authors fix
the type to opt back into a default.

This only fires on compile-time-constant candidates. Composites and
non-const leaves never pre-validate — see the next two bullets.

### Composite defaults always use a computed getter

`ClassModel`, `AllOfModel`, `OneOfModel`, `AnyOfModel` defaults — and any
collection whose leaf is composite — always emit as `static T get
fieldDefault => T.fromJson(const {...});`. Variant routing, AllOf member
merging, and `additionalProperties` extras are handled by the existing
runtime decoder; the generator never recursively materializes a composite
default at codegen time.

A class with `additionalProperties: false` does not get an extras field
at all, so spec defaults containing extra entries beyond the declared
properties have those entries structurally dropped on decode — there is
no AP field to hold them, so they simply do not exist on the resulting
instance and do not survive a round-trip. No warning is emitted; the
drop is a structural property of the class shape.

A practical consequence: a bad composite default (e.g. a `oneOf` default
that matches no variant, an `allOf` default missing a required member
property) only fails at runtime on first access of the getter — not at
generation time.

### `required` + default — ergonomic gap with computed getters

A compile-time-constant default makes a `required` property with a default
into an optional constructor parameter:

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

A computed-getter default does **not** do this. Constructor parameters
stay `required this.field`, because there is no compile-time constant to
attach as `defaultTo`. Nullable+`??` is deliberately avoided (it would
break `required this.field`'s mental model). To construct without
supplying the field, reference the static getter:

```dart
Subscription(startsAt: Subscription.startsAtDefault);
```

## Limitations

- **Non-const leaf types never get a compile-time-constant default.**
  `DateTime`, `Date`, `Uri`, `BigDecimal`, `Binary`, `Base64` have no
  const constructors. Defaults of these types fall to a computed
  getter; they apply on decode but cannot be inlined into the constructor
  `defaultTo`.
- **Computed getters are not cached.** Each access of
  `MyClass.fieldDefault` runs `fromJson` afresh. The const raw-JSON
  literal is shared, only the decoded value allocates. If you need
  identity (`identical(a, b)`) or want to avoid the per-call decode
  cost, capture in a local: `final d = MyClass.fieldDefault;`.
- **Sibling `default` on `$ref` is OAS 3.1+ semantics.** OAS 3.0
  technically forbids sibling keywords next to `$ref`. Tonik supports
  the sibling-default pattern in both 3.0 and 3.1, but some validators
  may reject the 3.0 spec as non-conformant.
- **External `$ref`s are not supported.** Defaults declared in an
  external file cannot propagate, because tonik does not load external
  files at all.
- **Top-level component schema defaults are pure metadata.** A
  component schema with `default: "us"` only takes effect through
  `$ref`. Tonik does not emit a top-level `Region.regionDefault` const
  for unreferenced component schemas, and does not generate a registry
  of component-level defaults.
- **`default` on schema positions tonik does not consume is silently
  dropped.** Examples include `default` on a `oneOf` member schema
  itself (rather than on the property whose type is the `oneOf`),
  `default` on the `additionalProperties` subschema (i.e. "fill
  unspecified extra entries with this" — there is no Dart construction
  hook for unspecified map entries), or `default` on an unused
  component schema. Per the permissive-parser philosophy, no warning
  is emitted.
- **`nullable: true, default: null` collapses to no default.** The
  generator emits no static member and no decoder default branch — the
  user-observable behavior is identical to having no `default` keyword
  at all (a missing key already decodes as `null` on a nullable field).
- **Self-referential composite defaults are a known limitation.** A
  schema like `Node { next: { $ref: '#/.../Node', default: {} } }`
  declares "decode the default `{}` as a `Node` whose `next` itself
  defaults to `{}` …" — infinite recursion at first access of
  `Node.nextDefault`. The generator currently emits the getter
  unchanged; calling it overflows the stack. Use `nullable: true,
  default: null` (or omit the default keyword) on self-referential
  properties instead.
