import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';

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

  group('HashCodeGenerator', () {
    test('generates hash code method for class without properties', () {
      final method = generateHashCodeMethod(properties: const []);

      const expectedMethod = '''
        @override
        int get hashCode => runtimeType.hashCode;
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates hash code method for class with single primitive property',
      () {
        final method = generateHashCodeMethod(
          properties: [(normalizedName: 'value', hasCollectionValue: false)],
        );

        const expectedMethod = '''
        @override
        int get hashCode => value.hashCode;
      ''';

        expect(
          collapseWhitespace(formatMethod(method)),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates hash code method for class with single collection property',
      () {
        final method = generateHashCodeMethod(
          properties: [(normalizedName: 'values', hasCollectionValue: true)],
        );

        const expectedMethod = '''
        @override
        int get hashCode {
          const deepEquals = DeepCollectionEquality();
          return deepEquals.hash(values);
        }
      ''';

        expect(
          collapseWhitespace(formatMethod(method)),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates hash code method for class with mixed properties', () {
      final method = generateHashCodeMethod(
        properties: [
          (normalizedName: 'id', hasCollectionValue: false),
          (normalizedName: 'items', hasCollectionValue: true),
          (normalizedName: 'name', hasCollectionValue: false),
        ],
      );

      const expectedMethod = '''
        @override
        int get hashCode {
          const deepEquals = DeepCollectionEquality();
          return Object.hashAll([id, deepEquals.hash(items), name]);
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates hash code method for class with many properties', () {
      final method = generateHashCodeMethod(
        properties: List.generate(
          25,
          (i) => (
            normalizedName: 'prop$i',
            hasCollectionValue: i.isEven,
          ),
        ),
      );

      const expectedMethod = '''
        @override
        int get hashCode {
          const deepEquals = DeepCollectionEquality();
          return Object.hashAll([
            deepEquals.hash(prop0),
            prop1,
            deepEquals.hash(prop2),
            prop3,
            deepEquals.hash(prop4),
            prop5,
            deepEquals.hash(prop6),
            prop7,
            deepEquals.hash(prop8),
            prop9,
            deepEquals.hash(prop10),
            prop11,
            deepEquals.hash(prop12),
            prop13,
            deepEquals.hash(prop14),
            prop15,
            deepEquals.hash(prop16),
            prop17,
            deepEquals.hash(prop18),
            prop19,
            deepEquals.hash(prop20),
            prop21,
            deepEquals.hash(prop22),
            prop23,
            deepEquals.hash(prop24),
          ]);
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
