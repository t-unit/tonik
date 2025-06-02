<br/>
<p align="center">                    
<img  src="https://raw.githubusercontent.com/t-unit/tonik/refs/heads/main/resources/logo_no_bg_small.png" height="120" alt="tonik logo">                    
</p>                    

<p align="center">                    
<a href="https://img.shields.io/badge/License-MIT-green"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"></a>                    
<a href="https://pub.dev/packages/tonik"><img src="https://img.shields.io/pub/v/tonik?logo=dart" alt="pub verion"></a>                    
<a href="https://pub.dev/packages/tonik"><img src="https://img.shields.io/pub/likes/tonik?logo=dart" alt="pub likes"></a>
<a href="https://github.com/t-unit/tonik"><img src="https://img.shields.io/github/stars/t-unit/tonik?logo=github" alt="stars on github"></a> 
<a href="https://github.com/t-unit/tonik"><img src="https://github.com/t-unit/tonik/actions/workflows/test.yml/badge.svg?branch=main" alt="tests"></a>                  
</p>                    




# Tonik
A Dart code generator for OpenAPI 3.0 and 3.1 specifications.

## ⚠️ Warning
This project is currently in an early development phase. Users should expect:
- Breaking changes in future releases
- Potential bugs and issues
- Missing features (see Roadmap section below)


## Motivation
There are already numerous projects available to generate Dart code from OpenAPI documents. But all lack certain, most often critical features. They might not support integer enums, composable data types (oneOf, anyOf, allOf), fail if you use existing class names in Dart or dependencies (e.g. `Response` of dio) or handle only success responses. 

This package aims to overcome these shortcomings.

## Features

coming soon


## Quick-Start Guide

### Installation

Activate the tonik CLI via:
```bash
dart pub global activate tonik
```

### Client Code Generation

To generate client code you need the path to your OpenAPI specification file ready and define a name for the client package. 

The package name should be snake_case following the official [guidelines](https://dart.dev/tools/pub/pubspec#name).
The supplied API specification file can be written in json or yaml, and must use version 3.0.x or 3.1.x.

```bash
tonik --package-name=my_api_client --spec=path/to/openapi.[yaml|json]
```

### Usage of Generated Code

Add the genearted package as a dependency to your project.

```bash
dart pub add "my_client_api:{path: path/to/package}"
```

Tonik generates an `Api` class per tag defined in the specification.
To use the generated client, simply import it and create an instance.

Here we define a custom server URL (servers defined in the specification file are also available). Afterward we  perform a network call. Finally, we check if the request was successfull or failed.

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

Take a look at the [pet store integration tests](https://github.com/t-unit/tonik/blob/main/integration_test/petstore/petstore_test/test/pet_test.dart) and our full usage guide (coming soon) for more information.

## Changelog

For a full list of changes of each release, refer to [release notes](https://github.com/t-unit/tonik/blob/main/CHANGELOG.md).

## Roadmap

### Short term goals
- `allowReserved` support for query parameters
- `format: uri` mapping to Dart `Uri`
- Add custom `Date` model in util package to handle `format: date` properly
- More E2E tests
- Full decoding and encoding support for any of and one of
- Support for `x-dart-name`, `x-dart-type` and `x-dart-enums`
- Annotate deprecated fields, methods and classes.
- Respect `nullable` property on schema objects
- Add doc strings based on fields in the spec to fields, classes and methods
- Rework parameter encoding by generating and using methods like `fromSimple` and `toSimple` for other encodings
- Normalize allOf with only added description (see https://github.com/sonallux/spotify-web-api/blob/main/official-spotify-open-api.yml#L4180) to be regular class model
- Discriminator support for allOf

### Long term goals
- Supporting the `not` keyword
- Encoding and decoding of `application/x-www-form-urlencoded` and `text/plain`
- Optionally generating `unknown` enum case
- Support for `additionalProperties`
- Server Templating support 
- Remove build_runner dependency from all packages
- Default values
- Supporting `byte` and `binary` formatted strings

### Non-goals
- Parameter encoding via content, see [schema vs content](https://swagger.io/docs/specification/v3_0/describing-parameters/#schema-vs-content)
- XML de- and encoding
- Min, Max and multiple validation
- Pattern validation 
- Remote and URL references
