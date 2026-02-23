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
  - **ALWAYS test full method/function bodies**, never fragments or individual lines.
  - Format both expected and actual with `DartFormatter` before comparing.
  - Compare using `collapseWhitespace(actual) == collapseWhitespace(expected)` for full body equality.
  - When a generator returns `List<Code>` (statements), wrap them in a `Method` to produce a complete formattable body, then test the full body.
  - When a generator returns an `Expression`, wrap it in a complete method context before comparing.
  - **NEVER use bare `contains()` for generated code** — always use full body comparison or `contains(collapseWhitespace(...))` on a formatted complete body.
  - **NEVER test code fragments** (e.g., checking if output "contains 'FormData()'" or "contains '.toJson()'"). Always assert on the complete expected output.
