import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';

void main() {
  group('CorePrefixedAllocator', () {
    late DartEmitter emitter;
    late CorePrefixedAllocator allocator;

    setUp(() {
      allocator = CorePrefixedAllocator();
      emitter = DartEmitter(allocator: allocator, useNullSafetySyntax: true);
    });

    test('prefixes dart:core types', () {
      final code =
          Class(
            (b) =>
                b
                  ..name = 'Example'
                  ..fields.addAll([
                    Field(
                      (b) =>
                          b
                            ..name = 'name'
                            ..type = refer('String', 'dart:core')
                            ..modifier = FieldModifier.final$,
                    ),
                    Field(
                      (b) =>
                          b
                            ..name = 'age'
                            ..type = refer('int', 'dart:core')
                            ..modifier = FieldModifier.final$,
                    ),
                    Field(
                      (b) =>
                          b
                            ..name = 'items'
                            ..type = TypeReference(
                              (b) =>
                                  b
                                    ..symbol = 'List'
                                    ..url = 'dart:core'
                                    ..types.add(refer('String', 'dart:core')),
                            )
                            ..modifier = FieldModifier.final$,
                    ),
                  ]),
          ).accept(emitter).toString();

      final imports = allocator.imports.map(
        (i) => i.accept(emitter).toString(),
      );

      expect(imports, contains("import 'dart:core' as _i1;"));
      expect(code, contains('_i1.String'));
      expect(code, contains('_i1.int'));
      expect(code, contains('_i1.List<_i1.String>'));
    });

    test('prefixes different libraries with different prefixes', () {
      final library = Library(
        (b) =>
            b
              ..body.add(
                Class(
                  (b) =>
                      b
                        ..name = 'Example'
                        ..fields.addAll([
                          Field(
                            (b) =>
                                b
                                  ..name = 'name'
                                  ..type = refer('String', 'dart:core')
                                  ..modifier = FieldModifier.final$,
                          ),
                          Field(
                            (b) =>
                                b
                                  ..name = 'data'
                                  ..type = refer('File', 'dart:io')
                                  ..modifier = FieldModifier.final$,
                          ),
                        ]),
                ),
              ),
      );

      final code = library.accept(emitter).toString();
      final imports = allocator.imports
          .map((i) => i.accept(emitter).toString())
          .join('\n');

      expect(imports, contains("import 'dart:core' as _i"));
      expect(imports, contains("import 'dart:io' as _i"));
      expect(
        code.contains('_i1.String') || code.contains('_i2.String'),
        isTrue,
      );
      expect(code.contains('_i1.File') || code.contains('_i2.File'), isTrue);

      // Ensure they have different prefixes
      final prefixes =
          RegExp(
            r'_i(\d+)',
          ).allMatches(imports).map((m) => m.group(1)).toList();
      expect(prefixes.toSet().length, 2);
    });
  });
}
