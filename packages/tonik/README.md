<br/>
<p align="center">                    
<img  src="https://raw.githubusercontent.com/t-unit/tonik/refs/heads/main/resources/logo_no_bg_small.png" height="120" alt="tonik logo">                    
</p>                    

<p align="center">                    
<a href="https://img.shields.io/badge/License-MIT-green"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"></a>                    
<a href="https://pub.dev/packages/tonik"><img src="https://img.shields.io/pub/v/tonik?logo=dart" alt="pub version"></a>                    
<a href="https://pub.dev/packages/tonik"><img src="https://img.shields.io/pub/likes/tonik?logo=dart" alt="pub likes"></a>
<a href="https://github.com/t-unit/tonik"><img src="https://img.shields.io/github/stars/t-unit/tonik?logo=github" alt="stars on github"></a> 
<a href="https://github.com/t-unit/tonik"><img src="https://github.com/t-unit/tonik/actions/workflows/test.yml/badge.svg?branch=main" alt="tests"></a>  
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg"></a>
<a href="https://github.com/invertase/melos"><img src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square"></a>
<a href="https://zread.ai/t-unit/tonik" target="_blank"><img src="https://img.shields.io/badge/Ask_Zread-_.svg?style=flat&color=00b0aa&labelColor=000000&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTQuOTYxNTYgMS42MDAxSDIuMjQxNTZDMS44ODgxIDEuNjAwMSAxLjYwMTU2IDEuODg2NjQgMS42MDE1NiAyLjI0MDFWNC45NjAxQzEuNjAxNTYgNS4zMTM1NiAxLjg4ODEgNS42MDAxIDIuMjQxNTYgNS42MDAxSDQuOTYxNTZDNS4zMTUwMiA1LjYwMDEgNS42MDE1NiA1LjMxMzU2IDUuNjAxNTYgNC45NjAxVjIuMjQwMUM1LjYwMTU2IDEuODg2NjQgNS4zMTUwMiAxLjYwMDEgNC45NjE1NiAxLjYwMDFaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00Ljk2MTU2IDEwLjM5OTlIMi4yNDE1NkMxLjg4ODEgMTAuMzk5OSAxLjYwMTU2IDEwLjY4NjQgMS42MDE1NiAxMS4wMzk5VjEzLjc1OTlDMS42MDE1NiAxNC4xMTM0IDEuODg4MSAxNC4zOTk5IDIuMjQxNTYgMTQuMzk5OUg0Ljk2MTU2QzUuMzE1MDIgMTQuMzk5OSA1LjYwMTU2IDE0LjExMzQgNS42MDE1NiAxMy43NTk5VjExLjAzOTlDNS42MDE1NiAxMC42ODY0IDUuMzE1MDIgMTAuMzk5OSA0Ljk2MTU2IDEwLjM5OTlaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik0xMy43NTg0IDEuNjAwMUgxMS4wMzg0QzEwLjY4NSAxLjYwMDEgMTAuMzk4NCAxLjg4NjY0IDEwLjM5ODQgMi4yNDAxVjQuOTYwMUMxMC4zOTg0IDUuMzEzNTYgMTAuNjg1IDUuNjAwMSAxMS4wMzg0IDUuNjAwMUgxMy43NTg0QzE0LjExMTkgNS42MDAxIDE0LjM5ODQgNS4zMTM1NiAxNC4zOTg0IDQuOTYwMVYyLjI0MDFDMTQuMzk4NCAxLjg4NjY0IDE0LjExMTkgMS42MDAxIDEzLjc1ODQgMS42MDAxWiIgZmlsbD0iI2ZmZiIvPgo8cGF0aCBkPSJNNCAxMkwxMiA0TDQgMTJaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00IDEyTDEyIDQiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K&logoColor=ffffff" alt="zread"/></a>
<a href="https://codecov.io/gh/t-unit/tonik" > 
 <img src="https://codecov.io/gh/t-unit/tonik/graph/badge.svg?token=RWSKCAYLO1"/> 
 </a>
</p>                  


# Tonik

A Dart code generator for OpenAPI 3.0 and 3.1 specifications.

Generate type-safe API client packages for Dart and Flutter. Tonik produces idiomatic code with sealed classes for `oneOf`, exhaustive pattern matching for responses, and full OpenAPI encoding support.

## Key Features

### Type-Safe Response Handling by Status Code and Content Type

Tonik generates distinct types for each response defined in your spec. When an endpoint returns different schemas for 200, 400, and 404—you get separate, strongly-typed classes for each:

```dart
final response = await petApi.updatePet(body: pet);

switch (response) {
  case TonikSuccess(:final value):
    switch (value) {
      case UpdatePetResponse200(:final body):
        print('Updated: ${body.name}');
      case UpdatePetResponse400():
        print('Invalid input');
      case UpdatePetResponse404():
        print('Pet not found');
    }
  case TonikError(:final error):
    print('Network error: $error');
}
```

Different content types (JSON, url encode, plain text) on the same status code? Each gets its own typed accessor.

### Composition with Sealed Classes

`oneOf`, `anyOf`, and `allOf` generate idiomatic Dart code:

- **`oneOf`** - Sealed class with one subclass per variant
- **`anyOf`** - Class with nullable fields for each alternative  
- **`allOf`** - Class with a field for each member schema

See [Composite Data Types](https://github.com/t-unit/tonik/blob/main/docs/composite_data_types.md) for usage examples.

### No Name Conflicts

Use `Error`, `Response`, `List`, or any Dart built-in as schema names. Tonik uses scoped code emission to properly qualify all type references—no naming collisions with `dart:core` or Dio.

### Integer and String Enums

Both work out of the box, with optional unknown-value handling for forward compatibility:

```yaml
status:
  type: integer
  enum: [0, 1, 2]
  x-dart-enum: [pending, active, closed]
```

### All Parameter Encoding Styles

Path, query, and header parameters support all OpenAPI styles: `simple`, `label`, `matrix`, `form`, `spaceDelimited`, `pipeDelimited`, and `deepObject`.

### Pure Dart

Install with `dart pub global activate tonik` and run. No JVM, no Docker, no external dependencies.

### Universal Platform Support

Generated packages are pure Dart with no platform dependencies. Use them in Flutter apps targeting iOS, Android, web, desktop, or in server-side Dart—the same generated code works everywhere.

## Documentation

- [Features Overview](https://github.com/t-unit/tonik/blob/main/docs/features.md) – Complete feature reference
- [Configuration](https://github.com/t-unit/tonik/blob/main/docs/configuration.md) – `tonik.yaml` options, name overrides, filtering
- [Data Types](https://github.com/t-unit/tonik/blob/main/docs/data_types.md) – OpenAPI to Dart type mappings
- [Composite Data Types](https://github.com/t-unit/tonik/blob/main/docs/composite_data_types.md) – `oneOf`, `anyOf`, `allOf` usage
- [Authentication](https://github.com/t-unit/tonik/blob/main/docs/authentication.md) – Interceptor patterns for auth
- [URI Encoding Limitations](https://github.com/t-unit/tonik/blob/main/docs/uri_encoding_limitations.md) – Dart URI class constraints

## Quick Start

### Install

```bash
dart pub global activate tonik
```

### Generate

```bash
tonik --package-name=my_api --spec=openapi.yaml
```

### Use

Add the generated package to your project:

```bash
dart pub add my_api:{'path':'./my_api'}
```

Then import and use:

```dart
import 'package:my_api/my_api.dart';

final api = PetApi(CustomServer(baseUrl: 'https://api.example.com'));

final response = await api.getPetById(petId: 1);
switch (response) {
  case TonikSuccess(:final value):
    print('Pet: ${value.body.name}');
  case TonikError(:final error):
    print('Failed: $error');
}
```

See the [petstore integration tests](https://github.com/t-unit/tonik/blob/main/integration_test/petstore/petstore_test/test/pet_test.dart) for more examples.

## Feature Summary

| Category | What's Supported |
|----------|------------------|
| **Responses** | Multiple status codes, multiple content types, response headers, `default` and range codes (`2XX`) |
| **Composition** | `oneOf` (sealed classes), `anyOf`, `allOf`, discriminators, nested composition |
| **Types** | Integer/string enums, `date`, `date-time` with timezone, `decimal`/`BigDecimal`, `uri`, `binary` |
| **Parameters** | Path, query, header; all encoding styles (`form`, `simple`, `label`, `matrix`, `deepObject`, etc.) |
| **Request Bodies** | `application/json`, `application/x-www-form-urlencoded`, `application/octet-stream`, `text/plain` |
| **Configuration** | Name overrides, filtering by tag/operation/schema, deprecation handling, content-type mapping |
| **OAS 3.1** | `$ref` with siblings, `$defs` local definitions, boolean schemas, nullable type arrays |

## Acknowledgments

Special thanks to [felixwoestmann](https://github.com/felixwoestmann), without whom this project would not exist.

## Links

- [Changelog](https://github.com/t-unit/tonik/blob/main/CHANGELOG.md)
- [Roadmap](https://github.com/t-unit/tonik/blob/main/docs/roadmap.md)