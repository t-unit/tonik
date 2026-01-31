# Roadmap

- Proper OpenAPI 3.2 support
  - [Sequential/streaming media types](https://spec.openapis.org/oas/v3.2.0.html#complete-vs-streaming-content)
- Support for `additionalProperties`
- Advanced OpenAPI 3.1 features:
  - Support for `if/then/else` schemas (via custom encoding/decoding checks)
  - Support for `const` schemas
  - `prefixItems` for tuple validation
  - `dependentRequired` / `dependentSchemas`
- Default values
- Optionally generate code with https://pub.dev/packages/fast_immutable_collections
- Supporting the `not` keyword
- Cookies
- multipart/form-data

## Non-goals

**Validation**:
- `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`
- `minLength`, `maxLength`, `pattern`
- `minItems`, `maxItems`, `uniqueItems`
- `minProperties`, `maxProperties`

**Encoding & Content:**
- `allowReserved` support for query parameters - Dart's `Uri` class always percent-encodes reserved characters per RFC 3986 (see [URI Encoding Limitations](uri_encoding_limitations.md))
- Parameter encoding via content - only `schema` supported (see [schema vs content](https://swagger.io/docs/specification/v3_0/describing-parameters/#schema-vs-content))
- XML de- and encoding

**References:**
- External/remote `$ref` references (to other files or URLs)
- `$id`, `$anchor` for schema identification (not needed without external refs)
- `$dynamicRef`, `$dynamicAnchor` (advanced JSON Schema feature)

**Advanced JSON Schema:**
- `unevaluatedProperties`, `unevaluatedItems`

**Other:**
- Direct security/authentication code generation - authentication must be handled through ServerConfig interceptors (see [Authentication Guide](authentication.md))
- Code generation for [webhooks](https://spec.openapis.org/oas/v3.1.0.html#oasWebhooks) - server→client callbacks, not relevant for client libs
