# Roadmap

## Short term goals
- `allowReserved` support for query parameters
- More E2E tests
- Support for `x-dart-name`, `x-dart-type` and `x-dart-enums`
- Annotate deprecated fields, methods and classes.
- Respect `nullable` property on schema objects
- Add doc strings based on fields in the spec to fields, classes and methods
- Rework parameter encoding by generating and using methods like `fromSimple` and `toSimple` for other encodings
- Normalize allOf with only added description (see https://github.com/sonallux/spotify-web-api/blob/main/official-spotify-open-api.yml#L4180) to be regular class model
- Discriminator support for allOf

## Long term goals
- Proper OpenAPI 3.1 support including JSON Schema Draft 2020-12
- Supporting the `not` keyword
- Encoding and decoding of `application/x-www-form-urlencoded` and `text/plain`
- Optionally generating `unknown` enum case
- Support for `additionalProperties`
- Server Templating support 
- Remove build_runner dependency from all packages
- Default values
- Supporting `byte` and `binary` formatted strings

## Non-goals
- Parameter encoding via content, see [schema vs content](https://swagger.io/docs/specification/v3_0/describing-parameters/#schema-vs-content)
- XML de- and encoding
- Min, Max and multiple validation
- Pattern validation
- Remote and URL references
- Direct security/authentication code generation - authentication must be handled through ServerConfig interceptors (see [Authentication Guide](authentication.md))
