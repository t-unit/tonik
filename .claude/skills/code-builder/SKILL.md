---
name: code-builder
description: >
  Rules for using the code_builder Dart package. Use when editing code generation
  logic in packages/tonik_generate, writing or modifying generator methods, or
  working with refer(), Code, Block, or DartEmitter.
user-invocable: false
---

# Code Generation with code_builder

When working with the [code_builder](https://pub.dev/packages/code_builder) package:

## Critical Rules — Never Violate

1. **NEVER use `Code.scope`.**
2. **ALWAYS use `refer` with package URL for ALL types** — even `dart:core` types.
3. **NEVER mix `refer` and string interpolation** — they are incompatible.
4. **Use `Code` with `Block.of`** — never use `StringBuilder`.
5. **NEVER use `DartEmitter` inside generator methods** — only the main `generate` method is allowed to use it.

## Examples

```dart
// CORRECT - Build code in separate Code objects
statements
  ..add(Code('if (condition != '))
  ..add(refer('String', 'dart:core').code)
  ..add(Code(') {'))

// CORRECT - Use refer with package URL
refer('EncodingShape.simple', 'package:tonik_util/tonik_util.dart')

// WRONG - Don't use Code.scope
Code.scope((allocate) => '...')

// WRONG - Don't mix refer with string interpolation
Code('if (condition != ${refer('String', 'dart:core').code})')

// WRONG - Don't use refer without package URL
refer('String') // Missing 'dart:core'

// WRONG - Don't use DartEmitter in generator methods
Code('${nullableType.accept(emitter)} $variableName;') // emitter not allowed

// CORRECT - Build code in separate Code objects
Block.of([
  nullableType.code,
  Code(' $variableName;'),
])
```
