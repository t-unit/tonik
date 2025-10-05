# tonik_generate

Code generation engine for [Tonik](https://pub.dev/packages/tonik).

This package generates Dart code from OpenAPI specifications. It creates type-safe API clients, models, request/response classes, and serialization code based on Tonik's internal data structures.

## Usage

This is an internal package used by Tonik's code generation pipeline. You typically don't need to interact with it directly unless you're extending Tonik's functionality.

## Documentation

For complete documentation and usage examples, see the main [Tonik package](https://pub.dev/packages/tonik).

## Features

- Generates type-safe Dart models from OpenAPI schemas
- Supports oneOf, anyOf, and allOf composition
- Generates API client classes with methods for each operation
- Handles various content types and serialization formats
- Generates request and response wrapper classes
- Supports authentication schemes

## License

See [LICENSE](LICENSE) file.