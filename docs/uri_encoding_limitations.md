# URI Encoding and `allowReserved`

## Overview

Tonik generates API clients that build URLs with Dart's standard `Uri` class.
For most parameter styles this means reserved characters in query strings are
percent-encoded according to RFC 3986. For **form-style query parameters**,
Tonik additionally honors OpenAPI's `allowReserved` property by encoding the
value itself before handing it to `Uri`, so the reserved set is preserved on the
wire. This applies to primitive, string, or byte values, arrays of primitive,
string, or byte items, free-form objects (`additionalProperties`), and free-form
(`Object`/`any`) values. Parameters whose schema is an object with defined
properties, an enum, a composition, an array of those, or an array of free-form
(`Object`/`any`) items do not yet honor it —
see [Styles and schemas that do not yet honor
`allowReserved`](#styles-and-schemas-that-do-not-yet-honor-allowreserved).

This document explains exactly which characters are kept literal, which are
encoded, and why.

## `allowReserved: true` for Form Query Parameters

OpenAPI 3.0 lets a query parameter set `allowReserved: true` to indicate that the
reserved characters defined in RFC 3986 should be sent literally instead of
percent-encoded.

```yaml
parameters:
  - name: path
    in: query
    style: form
    allowReserved: true
    schema:
      type: string
```

For form-style query parameters, Tonik honors this. Given a value such as
`a/b:c?d@e,f`, the generated client sends:

```
?path=a/b:c?d@e,f
```

The reserved characters `/ : ? @ ; ,` (and most other RFC 3986 reserved
characters) pass through literally; the exceptions — `& = +`, `# [ ]`, space, and
`%` — are percent-encoded as described under *Characters that are still encoded*
below. A sibling parameter **without** `allowReserved` keeps the default behavior
and is fully percent-encoded:

```
?path=a%2Fb%3Ac%3Fd%40e%2Cf
```

### Characters that are still encoded

Even with `allowReserved: true`, a few characters are always encoded. This is
required for the value to remain a well-formed query string — it is conformance,
not a Tonik shortfall.

| Character | Sent as | Reason |
|-----------|---------|--------|
| `&`       | `%26`   | Separates one parameter from the next. |
| `=`       | `%3D`   | Separates a parameter name from its value. |
| `+`       | `%2B`   | Reserved so a literal `+` is never confused with an encoded space. |
| space     | `%20`   | Spaces are not permitted literally in a URL. |
| `#`       | `%23`   | A literal `#` would start the URL fragment. |
| `[` `]`   | `%5B` `%5D` | The application is responsible for these; they are encoded for query strings. |
| `%`       | `%25`   | A `%` outside a valid percent-encoded triple must be encoded. |

The OpenAPI description of `allowReserved` makes the application responsible for
`& = +` (the form-urlencoded delimiters, per OAS Appendix E) as well as `[ ] #`.
Tonik encodes `& = +` **inside the value** itself (to `%26 %3D %2B`) rather than
relying on Dart's `Uri`, because `Uri` treats them as structural and would
otherwise leave a data `&` or `=` indistinguishable from a real delimiter.

### urlencoded request bodies

Encoding for `application/x-www-form-urlencoded` request bodies is planned for a
later release.

## Styles and Schemas That Do Not Yet Honor `allowReserved`

`allowReserved` is currently applied to **form-style** query parameters. The
`spaceDelimited`, `pipeDelimited`, and `deepObject` styles still percent-encode
reserved characters. The runtime already supports preserving the reserved set for
these styles; the generated clients do not yet thread `allowReserved` through to
them. A later release will wire it in.

Within form style, parameters whose schema is an **object with defined
properties**, an **enum**, or a **`oneOf` / `anyOf` / `allOf`** composition also
do not yet honor `allowReserved`. Their values are serialized by the model's own
encoding, which always percent-encodes the reserved set. The same applies to
**arrays whose items** are enums, objects, compositions, or free-form
(`Object`/`any`) values: these item types are not encoded with `allowReserved`.
Note the asymmetry — a scalar free-form
(`Object`/`any`) value is honored, but an array of free-form/`any` items is not:
each array element is serialized through an encoder that does not yet accept
`allowReserved`.

### `pipeDelimited` Style

```
Expected:  ?colors=red|green|blue
Actual:    ?colors=red%7Cgreen%7Cblue
```

### `spaceDelimited` Style

```
Expected:  ?colors=red green blue
Actual:    ?colors=red%20green%20blue
```

### `deepObject` Style

```
Expected:  ?filter[color]=red&filter[size]=large
Actual:    ?filter%5Bcolor%5D=red&filter%5Bsize%5D=large
```

The square brackets `[` and `]` are part of the parameter-name syntax in
`deepObject` encoding, but they are encoded as `%5B` and `%5D`.

## Null Array Elements in Parameters

OpenAPI's parameter styles (`form`, `simple`, `label`, `matrix`, `spaceDelimited`,
`pipeDelimited`, `deepObject`) are based on RFC 6570 URI Templates, which have
**no representation for a `null` element inside an array**. So when an array with
nullable items (`items: { nullable: true }`, or `type: [T, "null"]` in OAS 3.1)
is used as a path, query, or header parameter, there is no standard way to put
`null` on the wire.

Tonik handles this pragmatically:

- **Sending a request:** a `null` element is encoded as an empty string. For
  example, `['a', null, 'b']` becomes `a,,b`.
- **Reading a response:** an empty element cannot be reliably turned back into
  `null`. String items decode it as the empty string `''`; typed items (e.g.
  `List<int?>`) cannot decode an empty element and will report a decoding error.

Nullable array items are fully supported in **JSON request and response bodies**,
where `null` is a well-defined value. In **URL parameters** they are encoded
best-effort but are not round-trippable, because the parameter styles themselves
do not define null elements. If you control the API, prefer non-nullable array
items for parameters.

## Why Percent-Encoding Still Works in Practice

When a parameter is fully percent-encoded (no `allowReserved`, or a style that
does not yet honor it), the generated clients still work correctly with most
servers because:

1. **HTTP servers automatically decode query parameters.** When a server
   receives `%7C`, it decodes it back to `|` before processing the value.
2. **RFC 3986 compliance.** Percent-encoding reserved characters is the standard,
   safe way to transmit data in URLs.
3. **Functional equivalence.** From the server's perspective, `red%7Cgreen` and
   `red|green` represent the same data after URL decoding.

## Testing Considerations

When asserting on query strings, expect the reserved set to survive for
`allowReserved` form parameters and to be percent-encoded otherwise:

```dart
// allowReserved form parameter — reserved survivors stay literal:
expect(
  response.requestOptions.uri.query,
  'path=a/b:c?d@e,f',
);

// Default parameter — fully percent-encoded:
expect(
  response.requestOptions.uri.query,
  'path=a%2Fb%3Ac%3Fd%40e%2Cf',
);
```

## Related OpenAPI Discussion

- [OpenAPI Specification Issue #1840](https://github.com/OAI/OpenAPI-Specification/issues/1840) - Discussion about `allowReserved` implementation challenges
