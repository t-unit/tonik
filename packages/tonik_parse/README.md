# tonik_parse

OpenAPI specification parser for [Tonik](https://pub.dev/packages/tonik).

This package parses OpenAPI 3.0 and 3.1 specifications, with partial OpenAPI 3.2 support, and converts supported features into Tonik's internal data structures. It resolves supported local schema and object references; it is not a specification validator.

Supported 3.2 features include `itemSchema` response streams, reusable Media Type Objects under `components.mediaTypes`, and inline `dataValue` examples. Version reporting recognizes 3.0, 3.1, and 3.2; unknown versions log a warning while parsing continues permissively. See the [support matrix](https://github.com/t-unit/tonik/blob/main/docs/features.md#openapi-version-support) for details.

## Usage

This is an internal package used by Tonik's code generation pipeline. You typically don't need to interact with it directly unless you're extending Tonik's functionality.

## Documentation

For complete documentation and usage examples, see the main [Tonik package](https://pub.dev/packages/tonik).

## License

See [LICENSE](LICENSE) file.
