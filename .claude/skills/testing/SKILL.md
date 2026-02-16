---
name: testing
description: >
  Testing conventions for this project. Use when writing tests, modifying test
  files, or testing generated code output in any package.
user-invocable: false
---

# Testing Conventions

## Matchers

- Always use `isTrue` and `isFalse` matchers instead of bare `true` and `false`.
- Never use `equals()`; test against the value directly.

## Code Generation Testing

- **PREFER object introspection** over string testing for generated code:
  - Test constructor/method existence: `combinedClass.constructors.firstWhere((c) => c.name == 'fromSimple')`.
  - Test parameter types: `parameter.type?.accept(emitter).toString()`.
  - Test method properties: `method.lambda`, `method.returns`.
  - Test field names: `combinedClass.fields.map((f) => f.name)`.

- **Only use `contains(collapseWhitespace(...))` when absolutely necessary** for testing specific generated code content.
- **NEVER use bare `contains()` without `collapseWhitespace()`** for generated code — formatting differences will cause flaky tests.
- Use `collapseWhitespace` from [test package](https://pub.dev/packages/test): `import 'package:test/test.dart';`.
- When testing generated code strings, format both expected and actual with `DartFormatter`.

## String Testing Guidelines

- When testing generated code strings:
  - Format the entire method/constructor body with `DartFormatter` first.
  - Use `contains(collapseWhitespace(...))` for testing complete code blocks.
  - Acceptable: Testing patterns in a formatted complete method body.
  - NOT acceptable: Testing individual lines without formatting the complete context.
