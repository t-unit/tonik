import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';

void main() {
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;
  final emitter = DartEmitter(useNullSafetySyntax: true);

  group('generateCopyWith', () {
    test('returns null when properties are empty', () {
      final result = generateCopyWith(
        className: 'TestClass',
        properties: const [],
      );

      expect(result, isNull);
    });

    test('returns a getter with typed nullable named parameters', () {
      final copyWith = generateCopyWith(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'name',
            typeRef: TypeReference(
              (b) => b
                ..symbol = 'String'
                ..url = 'dart:core',
            ),
            isNullable: false,
            skipCast: false,
          ),
          (
            normalizedName: 'count',
            typeRef: TypeReference(
              (b) => b
                ..symbol = 'int'
                ..url = 'dart:core'
                ..isNullable = true,
            ),
            isNullable: true,
            skipCast: false,
          ),
        ],
      )!;

      expect(copyWith.name, 'copyWith');
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'TestClass');
      expect(functionType.namedParameters.keys, ['name', 'count']);
      expect(functionType.requiredParameters, isEmpty);
      expect(functionType.namedRequiredParameters, isEmpty);
      expect(
        functionType.namedParameters['name']?.accept(emitter).toString(),
        'String?',
      );
      expect(
        functionType.namedParameters['count']?.accept(emitter).toString(),
        'int?',
      );
      const expected = '''
        TestClass Function({String? name, int? count}) get copyWith {
          const Object _sentinel = Object();
          return ({String? name, Object? count = _sentinel}) =>
            TestClass(
              name: name ?? this.name,
              count: identical(count, _sentinel) ? this.count : (count as int?),
            );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'preserves null for an any alias without an explicit nullable type',
      () {
        final copyWith = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'anyValue',
              typeRef: TypeReference(
                (b) => b
                  ..symbol = 'AnyValue'
                  ..url = 'package:my_api/src/model/any_value.dart',
              ),
              isNullable: true,
              skipCast: true,
            ),
          ],
        )!;

        const expected = '''
        TestClass Function({AnyValue? anyValue}) get copyWith {
          const Object _sentinel = Object();
          return ({Object? anyValue = _sentinel}) => TestClass(
            anyValue: identical(anyValue, _sentinel) ? this.anyValue : anyValue,
          );
        }
      ''';
        expect(
          collapseWhitespace(format(copyWith.accept(emitter).toString())),
          collapseWhitespace(format(expected)),
        );
      },
    );

    test('skips the cast for dart:core Object?', () {
      final copyWith = generateCopyWith(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'value',
            typeRef: TypeReference(
              (b) => b
                ..symbol = 'Object'
                ..url = 'dart:core'
                ..isNullable = true,
            ),
            isNullable: true,
            skipCast: false,
          ),
        ],
      )!;

      const expected = '''
        TestClass Function({Object? value}) get copyWith {
          const Object _sentinel = Object();
          return ({Object? value = _sentinel}) => TestClass(
            value: identical(value, _sentinel) ? this.value : value,
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('retains the cast for an imported class named Object', () {
      final copyWith = generateCopyWith(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'object',
            typeRef: TypeReference(
              (b) => b
                ..symbol = 'Object'
                ..url = 'package:my_api/src/model/object.dart'
                ..isNullable = true,
            ),
            isNullable: true,
            skipCast: false,
          ),
        ],
      )!;

      const expected = '''
        TestClass Function({Object? object}) get copyWith {
          const Object _sentinel = Object();
          return ({Object? object = _sentinel}) => TestClass(
            object: identical(object, _sentinel) ? this.object : (object as Object?),
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('preserves generic collection types', () {
      final copyWith = generateCopyWith(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'items',
            typeRef: TypeReference(
              (b) => b
                ..symbol = 'List'
                ..url = 'dart:core'
                ..types.add(refer('String', 'dart:core')),
            ),
            isNullable: false,
            skipCast: false,
          ),
        ],
      )!;

      const expected = '''
        TestClass Function({List<String>? items}) get copyWith {
          return ({List<String>? items}) => TestClass(
            items: items ?? this.items,
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('preserves Never? in the signature and cast', () {
      final copyWith = generateCopyWith(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'impossible',
            typeRef: TypeReference(
              (b) => b
                ..symbol = 'Never'
                ..url = 'dart:core'
                ..isNullable = true,
            ),
            isNullable: true,
            skipCast: false,
          ),
        ],
      )!;

      const expected = '''
        TestClass Function({Never? impossible}) get copyWith {
          const Object _sentinel = Object();
          return ({Object? impossible = _sentinel}) => TestClass(
            impossible: identical(impossible, _sentinel) ? this.impossible : (impossible as Never?),
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });
  });
}
