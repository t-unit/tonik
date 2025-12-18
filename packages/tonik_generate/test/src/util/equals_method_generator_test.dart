import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';

void main() {
  late DartEmitter emitter;
  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String formatMethod(Method method) {
    final clazz = Class(
      (b) =>
          b
            ..name = 'Temp'
            ..methods.add(method),
    );
    final library = Library((b) => b..body.add(clazz));
    final code = library.accept(emitter).toString();
    return format(code);
  }

  group('EqualsMethodGenerator', () {
    test('generates equals method for class without properties', () {
      final method = generateEqualsMethod(
        className: 'TestClass',
        properties: const [],
      );

      const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is TestClass;
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates equals method for class with single primitive property',
      () {
        final method = generateEqualsMethod(
          className: 'TestClass',
          properties: [(normalizedName: 'value', hasCollectionValue: false)],
        );

        const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is TestClass && other.value == value;
        }
      ''';

        expect(
          collapseWhitespace(formatMethod(method)),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates equals method for class with collection property', () {
      final method = generateEqualsMethod(
        className: 'TestClass',
        properties: [(normalizedName: 'values', hasCollectionValue: true)],
      );

      const expectedMethod = r'''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          const _$deepEquals = DeepCollectionEquality();
          return other is TestClass && _$deepEquals.other.values, values;
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method for class with mixed properties', () {
      final method = generateEqualsMethod(
        className: 'TestClass',
        properties: [
          (normalizedName: 'id', hasCollectionValue: false),
          (normalizedName: 'items', hasCollectionValue: true),
          (normalizedName: 'name', hasCollectionValue: false),
        ],
      );

      const expectedMethod = r'''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          const _$deepEquals = DeepCollectionEquality();
          return other is TestClass && 
            other.id == id && 
            _$deepEquals.other.items, items && 
            other.name == name;
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
