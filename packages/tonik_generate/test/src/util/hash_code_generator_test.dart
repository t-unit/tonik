import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';

void main() {
  late DartEmitter emitter;
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String formatMethod(Method method) {
    final clazz = Class(
      (b) => b
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

      const expectedClass = '''
        class Temp {
          @override
          int get hashCode => this.runtimeType.hashCode;
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        collapseWhitespace(format(expectedClass)),
      );
    });

    test(
      'generates hash code method for class with single primitive property',
      () {
        final method = generateHashCodeMethod(
          properties: [(normalizedName: 'value', hasCollectionValue: false)],
        );

        const expectedClass = '''
          class Temp {
            @override
            int get hashCode => this.value.hashCode;
          }
        ''';

        expect(
          collapseWhitespace(formatMethod(method)),
          collapseWhitespace(format(expectedClass)),
        );
      },
    );

    test(
      'generates hash code method for class with single collection property',
      () {
        final method = generateHashCodeMethod(
          properties: [(normalizedName: 'values', hasCollectionValue: true)],
        );

        const expectedClass = '''
          class Temp {
            @override
            int get hashCode {
              const deepEquals = DeepCollectionEquality();
              return deepEquals.hash(this.values);
            }
          }
        ''';

        expect(
          collapseWhitespace(formatMethod(method)),
          collapseWhitespace(format(expectedClass)),
        );
      },
    );

    test('qualifies a single collection named deepEquals', () {
      final method = generateHashCodeMethod(
        properties: [(normalizedName: 'deepEquals', hasCollectionValue: true)],
      );

      const expectedClass = '''
        class Temp {
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality();
            return deepEquals.hash(this.deepEquals);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        collapseWhitespace(format(expectedClass)),
      );
    });

    test('qualifies a scalar named deepEquals alongside a collection', () {
      final method = generateHashCodeMethod(
        properties: [
          (normalizedName: 'deepEquals', hasCollectionValue: false),
          (normalizedName: 'items', hasCollectionValue: true),
        ],
      );

      const expectedClass = '''
        class Temp {
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality();
            return Object.hashAll([this.deepEquals, deepEquals.hash(this.items)]);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        collapseWhitespace(format(expectedClass)),
      );
    });

    test('qualifies a collection named deepEquals alongside a scalar', () {
      final method = generateHashCodeMethod(
        properties: [
          (normalizedName: 'deepEquals', hasCollectionValue: true),
          (normalizedName: 'name', hasCollectionValue: false),
        ],
      );

      const expectedClass = '''
        class Temp {
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality();
            return Object.hashAll([deepEquals.hash(this.deepEquals), this.name]);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        collapseWhitespace(format(expectedClass)),
      );
    });

    test('generates hash code method for class with mixed properties', () {
      final method = generateHashCodeMethod(
        properties: [
          (normalizedName: 'id', hasCollectionValue: false),
          (normalizedName: 'items', hasCollectionValue: true),
          (normalizedName: 'name', hasCollectionValue: false),
        ],
      );

      const expectedClass = '''
        class Temp {
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality();
            return Object.hashAll([this.id, deepEquals.hash(this.items), this.name]);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        collapseWhitespace(format(expectedClass)),
      );
    });

    test('generates hash code method for class with many properties', () {
      final method = generateHashCodeMethod(
        properties: [
          (normalizedName: 'prop0', hasCollectionValue: true),
          (normalizedName: 'prop1', hasCollectionValue: false),
          (normalizedName: 'prop2', hasCollectionValue: true),
          (normalizedName: 'prop3', hasCollectionValue: false),
          (normalizedName: 'prop4', hasCollectionValue: true),
          (normalizedName: 'prop5', hasCollectionValue: false),
          (normalizedName: 'prop6', hasCollectionValue: true),
          (normalizedName: 'prop7', hasCollectionValue: false),
          (normalizedName: 'prop8', hasCollectionValue: true),
          (normalizedName: 'prop9', hasCollectionValue: false),
          (normalizedName: 'prop10', hasCollectionValue: true),
          (normalizedName: 'prop11', hasCollectionValue: false),
          (normalizedName: 'prop12', hasCollectionValue: true),
          (normalizedName: 'prop13', hasCollectionValue: false),
          (normalizedName: 'prop14', hasCollectionValue: true),
          (normalizedName: 'prop15', hasCollectionValue: false),
          (normalizedName: 'prop16', hasCollectionValue: true),
          (normalizedName: 'prop17', hasCollectionValue: false),
          (normalizedName: 'prop18', hasCollectionValue: true),
          (normalizedName: 'prop19', hasCollectionValue: false),
          (normalizedName: 'prop20', hasCollectionValue: true),
          (normalizedName: 'prop21', hasCollectionValue: false),
          (normalizedName: 'prop22', hasCollectionValue: true),
          (normalizedName: 'prop23', hasCollectionValue: false),
          (normalizedName: 'prop24', hasCollectionValue: true),
        ],
      );

      const expectedClass = '''
        class Temp {
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality();
            return Object.hashAll([
              deepEquals.hash(this.prop0),
              this.prop1,
              deepEquals.hash(this.prop2),
              this.prop3,
              deepEquals.hash(this.prop4),
              this.prop5,
              deepEquals.hash(this.prop6),
              this.prop7,
              deepEquals.hash(this.prop8),
              this.prop9,
              deepEquals.hash(this.prop10),
              this.prop11,
              deepEquals.hash(this.prop12),
              this.prop13,
              deepEquals.hash(this.prop14),
              this.prop15,
              deepEquals.hash(this.prop16),
              this.prop17,
              deepEquals.hash(this.prop18),
              this.prop19,
              deepEquals.hash(this.prop20),
              this.prop21,
              deepEquals.hash(this.prop22),
              this.prop23,
              deepEquals.hash(this.prop24),
            ]);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatMethod(method)),
        collapseWhitespace(format(expectedClass)),
      );
    });
  });
}
