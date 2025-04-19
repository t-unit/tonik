<br/>
<p align="center">                    
<img  src="https://raw.githubusercontent.com/t-unit/tonik/main/resources/logo_no_bg_small.png" height="120" alt="tonik logo">                    
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

## Motivation
There are already numerous projects available to generate Dart code from OpenAPI documents. But all lack certain, most often critical features. They might not support integer enums, composable data types (oneOf, anyOf, allOf), fail if you use existing class names in Dart or dependencies (e.g. `Response` of dio) or handle only success responses. 

This package aims to overcome these shortcomings.

## Features

## Usage


## Roadmap

### Short term goals
- `allowReserved` support for query parameters
- `format: uri` mapping to Dart `Uri`
- Add custom `Date` model in util package to handle `format: date` properly
- E2E tests (using imposter?)
- Full decoding and encoding support for all of, any of and one of
- Support for `x-dart-name`, `x-dart-type` and `x-dart-enums`
- Annotate deprecated fields methods and classes.

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
