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
</p>                  


# Tonik

A Dart code generator for OpenAPI specifications that produces complete, ready-to-use client code. Tonik handles the tricky parts other generators miss: `oneOf`/`anyOf`/`allOf` composition, multiple response content types or status codes, integer enums, schema names that clash with Dart built-ins (like `Error` or `List`), and proper encoding for all OpenAPI parameter styles.

**Supported versions:** OpenAPI 3.0 (full), 3.1 (partial/planned), 3.2 (partial/planned)


## Motivation
There are already numerous projects available to generate Dart code from OpenAPI documents. But all lack certain, most often critical features. They might not support integer enums, composable data types (oneOf, anyOf, allOf), fail if you use existing class names in Dart or dependencies (e.g. `Response` of dio) or handle only success responses. 

This package aims to overcome these shortcomings.

Special thanks goes out to [felixwoestmann](https://github.com/felixwoestmann), as this project would not have been possible without him.

## Features and Documentation

- [Features Overview](https://github.com/t-unit/tonik/blob/main/docs/features.md)
- [Configuration](https://github.com/t-unit/tonik/blob/main/docs/configuration.md)
- [Data Types](https://github.com/t-unit/tonik/blob/main/docs/data_types.md)
- [Composite Data Type](https://github.com/t-unit/tonik/blob/main/docs/composite_data_types.md)
- [Authentication](https://github.com/t-unit/tonik/blob/main/docs/authentication.md)
- [Uri Encoding Limitations](https://github.com/t-unit/tonik/blob/main/docs/uri_encoding_limitations.md)

## Quick-Start Guide

### Installation

Activate the tonik CLI via:
```bash
dart pub global activate tonik
```

### Client Code Generation

To generate client code you need the path to your OpenAPI specification file ready and define a name for the client package. 

The package name should be snake_case following the official [guidelines](https://dart.dev/tools/pub/pubspec#name).
The supplied API specification file can be written in json or yaml.

```bash
tonik --package-name=my_api_client --spec=path/to/openapi.[yaml|json]
```

Fore more information on how to configure the code generation see [configuration]([https:](https://github.com/t-unit/tonik/blob/main/docs/configuration.md)).

### Usage of Generated Code

Add the generated package as a dependency to your project.

```bash
dart pub add "my_client_api:{path: path/to/package}"
```

Tonik generates an `Api` class per tag defined in the specification.
To use the generated client, simply import it and create an instance.

Here we define a custom server URL (servers defined in the specification file are also available). Afterward we  perform a network call. Finally, we check if the request was successful or failed.

```dart
import 'package:my_api_client/my_api_client.dart';

final api = PetApi(
  CustomServer(baseUrl: 'https://api.example.com'),
);

// Make API calls with type-safe responses
final response = await api.getPetById(petId: 1);
switch (response) {
  case TonikSuccess<GetPetByIdResponse>(:final value):
    print('Server response: $value');
  case TonikError():
    print('Network error occurred');
}
```

Take a look at the [pet store integration tests](https://github.com/t-unit/tonik/blob/main/integration_test/petstore/petstore_test/test/pet_test.dart). Furthermore check [features](https://github.com/t-unit/tonik/blob/main/docs/features.md) for more information.

## Changelog

For a full list of changes of each release, refer to [release notes](https://github.com/t-unit/tonik/blob/main/CHANGELOG.md).


## Roadmap

See [roadmap](https://github.com/t-unit/tonik/blob/main/docs/roadmap.md)