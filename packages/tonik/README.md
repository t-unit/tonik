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
</p>                    


# Tonik
A Dart code generator for OpenAPI 3.x specifications.

## ⚠️ Warning
This project is currently in the development phase. Users should expect:
- Breaking changes in future releases
- Potential bugs and issues
- Missing features (see Roadmap)


## Motivation
There are already numerous projects available to generate Dart code from OpenAPI documents. But all lack certain, most often critical features. They might not support integer enums, composable data types (oneOf, anyOf, allOf), fail if you use existing class names in Dart or dependencies (e.g. `Response` of dio) or handle only success responses. 

This package aims to overcome these shortcomings.

Special thanks goes out to [felixwoestmann](https://github.com/felixwoestmann), as this project would not have been possible without him.

## Features and Documentation

- [Configuration]([https:](https://github.com/t-unit/tonik/blob/main/docs/configuration.md))
- [Data Types](https://github.com/t-unit/tonik/blob/main/docs/data_types.md)
- [Composite Data Type](https://github.com/t-unit/tonik/blob/main/docs/composite_data_types.md)
- [Authentication](https://github.com/t-unit/tonik/blob/main/docs/authentication.md)
- [Uri Encoding Limitations](https://github.com/t-unit/tonik/blob/main/docs/uri_encoding_limitations.md)

more coming soon


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

Take a look at the [pet store integration tests](https://github.com/t-unit/tonik/blob/main/integration_test/petstore/petstore_test/test/pet_test.dart) and our full usage guide (coming soon) for more information.

## Changelog

For a full list of changes of each release, refer to [release notes](https://github.com/t-unit/tonik/blob/main/CHANGELOG.md).


## Roadmap

See [roadmap](https://github.com/t-unit/tonik/blob/main/docs/roadmap.md)