# URI Encoding

## Overview

Tonik-generated clients build URLs with Dart's standard `Uri` class and send
`application/x-www-form-urlencoded` request bodies as raw strings. This page describes how
tonik encodes query-parameter and form-body values, how it honors OpenAPI's `allowReserved`,
and the few cases that stay percent-encoded regardless.

When `allowReserved` is not set (the default), tonik percent-encodes reserved characters
following RFC 3986. This is the standard, safe behavior and is byte-for-byte identical to
earlier tonik releases.

## `allowReserved: true`

OpenAPI lets a query parameter — or a property of an `application/x-www-form-urlencoded`
request body, via the Encoding Object — set `allowReserved: true`, meaning the RFC 3986
reserved characters `:/?#[]@!$&'()*+,;=` should be sent literally rather than
percent-encoded. **Tonik honors `allowReserved: true`** for:

- query parameters of every supported style (`form`, `spaceDelimited`, `pipeDelimited`,
  `deepObject`), whether the value is a scalar, enum, array, object, or `oneOf` / `anyOf` /
  `allOf` composition;
- properties of an `application/x-www-form-urlencoded` request body.

Reserved characters in the **value** are then sent literally, with these exceptions that
always stay percent-encoded even under `allowReserved`:

| Character(s) | Sent as | Why |
|---|---|---|
| `&` `=` `+` | `%26` `%3D` `%2B` | These are `application/x-www-form-urlencoded` delimiters. A literal `&` or `=` would split the value into extra pairs, and a literal `+` decodes back to a space, so a data occurrence must stay encoded. |
| `%` | `%25` | Tonik encodes the decoded string you pass and cannot tell a literal `%` from an intended escape, so every `%` is encoded (see [Percent signs](#percent-signs-are-always-encoded)). |
| space, control characters, non-ASCII, and other unsafe characters | percent-encoded | Not part of the reserved set; unsafe in a URL. |

A space renders as `%20` in a query string and as `+` in a form body.

### Query strings vs. form bodies

The two surfaces differ only on `#`, `[`, and `]`:

- **Query strings** — `#`, `[`, and `]` are percent-encoded (`%23`, `%5B`, `%5D`). Dart's
  `Uri` always encodes these when it assembles the URL, which is exactly what the
  specification requires for query strings (an application is responsible for
  percent-encoding `[`, `]`, and `#`). Every other reserved character (`/ : ? @ ! $ ' ( ) * ,
  ;`) is sent literally.
- **Form bodies** (`application/x-www-form-urlencoded`) — `#`, `[`, and `]` are sent
  literally, because a request body is not a query string and does not pass through Dart's
  `Uri`.

For example, a query parameter `q` with the value `a/b c&d` and `allowReserved: true` is sent
as:

```
?q=a/b%20c%26d
```

The `/` stays literal, the space becomes `%20`, and the data `&` becomes `%26`.

## Structural delimiters are always encoded

`allowReserved` applies to characters **inside a value**, not to the separators a parameter
style uses to join values. Those separators come from Dart's `Uri` and stay encoded:

- **`pipeDelimited`** — the `|` between array items is `%7C`:
  ```
  ?colors=red%7Cgreen%7Cblue
  ```
- **`spaceDelimited`** — the space between array items is `%20`:
  ```
  ?colors=red%20green%20blue
  ```
- **`deepObject`** — the `[` and `]` around nested keys are `%5B` and `%5D`:
  ```
  ?filter%5Bcolor%5D=red&filter%5Bsize%5D=large
  ```

Under `allowReserved: true`, reserved characters **within** each item or value are sent
literally, but these structural delimiters are unaffected. Servers decode `%7C`, `%20`,
`%5B`, and `%5D` back to `|`, space, `[`, and `]`, so the data is received correctly.

## Percent signs are always encoded

RFC 6570 says an already-percent-encoded triple in the input should pass through unchanged.
Tonik does **not** honor this: it encodes the decoded value you provide, so a literal `%` in
your data always becomes `%25`. Pass decoded values (for example `a b`, not `a%20b`) and let
tonik encode them.

## Form-body array properties

For an `application/x-www-form-urlencoded` request body, an array (list-of-simple) property is
serialized according to its `style: form` Encoding Object, in particular `explode`:

- **`explode: true` (the default)** sends one repeated key per element:
  ```
  tags=a&tags=b&tags=c
  ```
- **`explode: false`** sends a single comma-joined entry:
  ```
  tags=a,b,c
  ```

Empty and absent arrays follow the shape of `explode`:

- An **empty array** under the default `explode: true` is omitted entirely — no key appears on
  the wire.
- An **empty array** with `explode: false` still emits the key with an empty value: `tags=`.
- A **`null` or absent nullable array** property behaves like an empty array: under the
  exploded default it is dropped from the wire.
- A body whose properties are **all empty exploded arrays** serializes to an empty body.

A single-element array follows the same rules — `['purple']` exploded is `colors=purple`, and
a single empty-string element `['']` is `tags=` (one empty-value entry).

The exploded default applies to **object and `allOf` form bodies**. In a `oneOf`/`anyOf` form
body, array properties are always comma-joined — `explode` and `allowReserved` set on such a
member array have no effect on the wire output.

Only the `form` style is honored for form bodies. With `explode` omitted, `spaceDelimited` and
`pipeDelimited` resolve to a comma-joined entry (not a space- or pipe-joined one); only `form`
retains the exploded default.

Dynamic `additionalProperties` keys carry no per-property encoding, so they never explode. Only
scalar `additionalProperties` values are supported in a form body; an array-valued
`additionalProperties` is rejected at encode time
(`Additional properties with complex types cannot be parameter encoded.`).

`allowReserved` is honored on scalar, enum, object, composition, and array properties. On an
array it keeps reserved characters literal within each element, whether the array is exploded
into repeated keys or comma-joined. A comma inside an element of an unflagged exploded array is
percent-encoded per element (`['a,b', 'c']` → `tags=a%2Cb&tags=c`); with `allowReserved: true`
that comma stays literal. Under `explode: false` the comma between items is the form-style value
separator (sent literally as `tags=a,b,c`, like the commas that join a `form`-style query array),
whereas a comma **inside** an element is data and is percent-encoded unless `allowReserved` is set.

## Null array elements in parameters

OpenAPI's parameter styles (`form`, `simple`, `label`, `matrix`, `spaceDelimited`,
`pipeDelimited`, `deepObject`) are based on RFC 6570 URI Templates, which have **no
representation for a `null` element inside an array**. So when an array with nullable items
(`items: { nullable: true }`, or `type: [T, "null"]` in OAS 3.1) is used as a path, query, or
header parameter, there is no standard way to put `null` on the wire.

Tonik handles this pragmatically:

- **Sending a request:** a `null` element is encoded as an empty string. For example,
  `['a', null, 'b']` becomes `a,,b`.
- **Reading a response:** an empty element cannot be reliably turned back into `null`. String
  items decode it as the empty string `''`; typed items (e.g. `List<int?>`) cannot decode an
  empty element and will report a decoding error.

Nullable array items are fully supported in **JSON request and response bodies**, where
`null` is a well-defined value. In **URL parameters** they are encoded best-effort but are not
round-trippable, because the parameter styles themselves do not define null elements. If you
control the API, prefer non-nullable array items for parameters.

## Testing considerations

When asserting the wire format in tests, expect the encodings described above. For example, a
`pipeDelimited` array keeps its delimiter encoded:

```dart
expect(
  response.requestOptions.uri.query,
  'colors=red%7Cgreen%7Cblue',
);
```

## Related OpenAPI references

- [Parameter Object — `allowReserved`](https://spec.openapis.org/oas/latest.html#parameter-object)
  and the Encoding Object field of the same name.
- [OpenAPI Specification Appendix E](https://spec.openapis.org/oas/latest.html) — reserved
  characters and the `application/x-www-form-urlencoded` delimiter set (`&`, `=`, `+`).
