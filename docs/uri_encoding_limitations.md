# URI Encoding Limitations

## Overview

Tonik generates API clients that use Dart's standard `Uri` class for URL construction. This has important implications for how query parameters are encoded, particularly for OpenAPI's `pipeDelimited` and `spaceDelimited` parameter styles and the `allowReserved` property.

## The Limitation

**Dart's `Uri` class always percent-encodes reserved characters in query strings according to RFC 3986.** This means:

- Pipe characters (`|`) are always encoded as `%7C`
- Space characters are always encoded as `%20`
- Other reserved characters (like `&`, `=`, `#`, etc.) are also percent-encoded

This behavior is fundamental to Dart's URI handling and cannot be disabled or customized.

## Impact on OpenAPI Features

### `allowReserved: true`

OpenAPI 3.0 allows parameters to specify `allowReserved: true`, which indicates that reserved characters should NOT be percent-encoded. **Tonik cannot implement this feature** because Dart's `Uri` class does not support unencoded reserved characters in query strings.

```yaml
# This OpenAPI parameter specification...
parameters:
  - name: path
    in: query
    schema:
      type: string
    allowReserved: true  # ← Cannot be honored in Dart
```

### `pipeDelimited` Style

For array parameters with `style: pipeDelimited`, the OpenAPI specification expects values to be separated by unencoded pipe characters:

```
Expected:  ?colors=red|green|blue
Actual:    ?colors=red%7Cgreen%7Cblue
```

Tonik generates code that produces the encoded form (`%7C`) because that's what Dart's `Uri` class produces.

### `spaceDelimited` Style

Similarly, for `style: spaceDelimited`, spaces are encoded as `%20`:

```
Expected:  ?colors=red green blue
Actual:    ?colors=red%20green%20blue
```

### `deepObject` Style

For `style: deepObject`, square brackets are used as structural syntax to denote nested object properties:

```
Expected:  ?filter[color]=red&filter[size]=large
Actual:    ?filter%5Bcolor%5D=red&filter%5Bsize%5D=large
```

The square brackets `[` and `]` are encoded as `%5B` and `%5D` respectively. While these brackets are part of the parameter name syntax in deepObject encoding, Dart's `Uri` class treats them as reserved characters that must be encoded.

## Why This Works in Practice

Despite these encoding differences, **the generated clients work correctly** with most servers because:

1. **HTTP servers automatically decode query parameters**: When a server receives `%7C`, it decodes it back to `|` before processing the parameter value.

2. **RFC 3986 compliance**: Percent-encoding reserved characters is the standard, safe way to transmit data in URLs. Most servers expect and handle this correctly.

3. **Functional equivalence**: From the server's perspective, `red%7Cgreen%7Cblue` and `red|green|blue` represent the same data after URL decoding.

## Industry Context

This limitation is **not unique to Tonik**. It affects the entire Dart ecosystem:

- The official `openapi-generator` for Dart (both `dart` and `dart-dio` generators) have the same limitation
- All Dart HTTP clients that use the standard `Uri` class are affected
- This is a conscious trade-off: Dart prioritizes RFC 3986 compliance over OpenAPI's optional `allowReserved` feature

## Workarounds

If you absolutely need unencoded reserved characters in URLs, you have limited options:

### 1. Server-Side Acceptance (Recommended)

Ensure your API server correctly decodes percent-encoded query parameters. This is the standard behavior for most HTTP servers and frameworks.

### 2. Custom HTTP Client Adapter

You could implement a custom Dio `HttpClientAdapter` that manipulates the raw HTTP request string before sending it. However, this is complex, fragile, and not recommended.

## Testing Considerations

When writing tests for Tonik-generated clients, expect percent-encoded values in query strings:

```dart
// In your tests, expect encoded pipes:
expect(
  response.requestOptions.uri.query,
  'colors=red%7Cgreen%7Cblue',  // Not 'colors=red|green|blue'
);
```

## Related OpenAPI Issues

This limitation has been discussed in the OpenAPI community:

- [OpenAPI Generator Issue #812](https://github.com/OpenAPITools/openapi-generator/issues/812) - Dart generator doesn't support allowReserved
- [OpenAPI Specification Issue #1840](https://github.com/OAI/OpenAPI-Specification/issues/1840) - Discussion about allowReserved implementation challenges

## Summary

- Tonik correctly implements `pipeDelimited`, `spaceDelimited`, and `deepObject` parameter serialization
- Generated clients work with standard HTTP servers
- Reserved characters (including `|`, spaces, and `[]`) are percent-encoded (cannot be disabled)
- `allowReserved: true` is not supported
- This is a Dart ecosystem limitation, not a Tonik limitation

If your API requires unencoded reserved characters in query strings, you may need to reconsider your API design or use a different programming language for client generation.

