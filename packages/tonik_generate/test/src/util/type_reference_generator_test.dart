import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

void main() {
  group('buildMapStringStringType', () {
    test('returns a Map<String, String> TypeReference', () {
      final type = buildMapStringStringType();

      expect(type.symbol, 'Map');
      expect(type.url, 'dart:core');
      expect(type.types, hasLength(2));

      final keyType = type.types.first as TypeReference;
      final valueType = type.types.last as TypeReference;

      expect(keyType.symbol, 'String');
      expect(keyType.url, 'dart:core');
      expect(valueType.symbol, 'String');
      expect(valueType.url, 'dart:core');
    });

    test('emits with core-prefixed import when rendered', () {
      final allocator = CorePrefixedAllocator();
      final emitter = DartEmitter(
        allocator: allocator,
        useNullSafetySyntax: true,
      );

      final type = buildMapStringStringType();

      // Force emission to register imports
      final code =
          Field(
            (b) =>
                b
                  ..name = 'm'
                  ..type = type
                  ..modifier = FieldModifier.final$,
          ).accept(emitter).toString();

      final imports = allocator.imports.map(
        (i) => i.accept(emitter).toString(),
      );

      expect(imports.join('\n'), contains("import 'dart:core' as _i1;"));
      expect(code, startsWith('final _i1.Map'));
      expect(code, contains('_i1.String'));
      // Ensure both generic arguments are core-prefixed String
      final stringOccurrences = RegExp(r'_i1\.String').allMatches(code).length;
      expect(stringOccurrences, 2);
    });
  });
}
