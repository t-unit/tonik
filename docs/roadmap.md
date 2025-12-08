# Roadmap

## Short term goals
- Support for `x-dart-name`, `x-dart-type` and `x-dart-enums`
- Optionally generating `unknown` enum case
- Respect `nullable` property on schema objects
- Normalize allOf with only added description (see https://github.com/sonallux/spotify-web-api/blob/main/official-spotify-open-api.yml#L4180) to be regular class model
- Discriminator support for allOf

## Long term goals
- Proper OpenAPI 3.1 support including JSON Schema Draft 2020-12
- Proper OpenAPI 3.2 support
- Supporting the `not` keyword
- Encoding and decoding of `application/x-www-form-urlencoded` and `text/plain`
- Support for `additionalProperties`
- Server Templating support 
- Remove build_runner dependency from all packages
- Default values
- Supporting `byte` and `binary` formatted strings
- Optionally generate code with https://pub.dev/packages/fast_immutable_collections
- Better support for nullable properties and copyWith

## Non-goals
- `allowReserved` support for query parameters - Dart's `Uri` class always percent-encodes reserved characters per RFC 3986 (see [URI Encoding Limitations](uri_encoding_limitations.md))
- Parameter encoding via content, see [schema vs content](https://swagger.io/docs/specification/v3_0/describing-parameters/#schema-vs-content)
- XML de- and encoding
- Min, Max and multiple validation
- Pattern validation
- Remote and URL references
- Direct security/authentication code generation - authentication must be handled through ServerConfig interceptors (see [Authentication Guide](authentication.md))
