# Roadmap

- Normalize allOf with only added description (see https://github.com/sonallux/spotify-web-api/blob/main/official-spotify-open-api.yml#L4180) to be regular class model
- Discriminator support for allOf
- Proper OpenAPI 3.2 support
  - [Sequential/streaming media types](https://spec.openapis.org/oas/v3.2.0.html#complete-vs-streaming-content)
- Support for `additionalProperties`
- Advanced OpenAPI 3.1 features:
  - Support for `if/then/else` schemas (via custom encoding/decoding checks)
  - Support for `const` schemas (could map to single-value enum)
- Server Templating support 
- Default values
- Optionally generate code with https://pub.dev/packages/fast_immutable_collections
- Supporting the `not` keyword
- Cookies
- multipart/form-data

## Non-goals
- `allowReserved` support for query parameters - Dart's `Uri` class always percent-encodes reserved characters per RFC 3986 (see [URI Encoding Limitations](uri_encoding_limitations.md))
- Parameter encoding via content, see [schema vs content](https://swagger.io/docs/specification/v3_0/describing-parameters/#schema-vs-content)
- XML de- and encoding
- Min, Max and multiple validation
- Pattern validation
- Remote and URL references
- Direct security/authentication code generation - authentication must be handled through ServerConfig interceptors (see [Authentication Guide](authentication.md))
- Code generation for [webhooks](https://spec.openapis.org/oas/v3.1.0.html#oasWebhooks)
