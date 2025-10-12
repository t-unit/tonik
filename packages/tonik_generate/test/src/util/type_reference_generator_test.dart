import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

void main() {
  group('TypeReference Generator', () {
    group('buildBoolParameter', () {
      test('returns correct Parameter for bool with default value', () {
        final result = buildBoolParameter('explode');

        expect(result.name, equals('explode'));
        expect(result.type?.symbol, equals('bool'));
        expect(result.type?.url, equals('dart:core'));
        expect(result.named, isTrue);
        expect(result.required, isFalse);
        expect(result.defaultTo, isNotNull);
      });

      test('returns correct Parameter for bool with required true', () {
        final result = buildBoolParameter('explode', required: true);

        expect(result.name, equals('explode'));
        expect(result.type?.symbol, equals('bool'));
        expect(result.type?.url, equals('dart:core'));
        expect(result.named, isTrue);
        expect(result.required, isTrue);
        expect(result.defaultTo, isNull);
      });
    });

    group('buildStringParameter', () {
      test('returns correct Parameter for String with default value', () {
        final result = buildStringParameter('name', defaultValue: 'default');

        expect(result.name, equals('name'));
        expect(result.type?.symbol, equals('String'));
        expect(result.type?.url, equals('dart:core'));
        expect(result.named, isTrue);
        expect(result.required, isFalse);
        expect(result.defaultTo, isNotNull);
      });

      test('returns correct Parameter for String with required true', () {
        final result = buildStringParameter('name', required: true);

        expect(result.name, equals('name'));
        expect(result.type?.symbol, equals('String'));
        expect(result.type?.url, equals('dart:core'));
        expect(result.named, isTrue);
        expect(result.required, isTrue);
        expect(result.defaultTo, isNull);
      });

      test('returns correct Parameter for String without default value', () {
        final result = buildStringParameter('name');

        expect(result.name, equals('name'));
        expect(result.type?.symbol, equals('String'));
        expect(result.type?.url, equals('dart:core'));
        expect(result.named, isTrue);
        expect(result.required, isFalse);
        expect(result.defaultTo, isNull);
      });
    });

    group('buildMapStringObjectType', () {
      test('returns correct TypeReference for Map<String, Object?>', () {
        final result = buildMapStringObjectType();

        expect(result.symbol, equals('Map'));
        expect(result.url, equals('dart:core'));
        expect(result.isNullable, isNull);
        expect(result.types, hasLength(2));
        expect(result.types[0].symbol, equals('String'));
        expect(result.types[0].url, equals('dart:core'));
        expect(result.types[1].symbol, equals('Object?'));
        expect(result.types[1].url, equals('dart:core'));
      });
    });

    group('buildMapStringStringType', () {
      test('returns correct TypeReference for Map<String, String>', () {
        final result = buildMapStringStringType();

        expect(result.symbol, equals('Map'));
        expect(result.url, equals('dart:core'));
        expect(result.isNullable, isNull);
        expect(result.types, hasLength(2));
        expect(result.types[0].symbol, equals('String'));
        expect(result.types[0].url, equals('dart:core'));
        expect(result.types[1].symbol, equals('String'));
        expect(result.types[1].url, equals('dart:core'));
      });
    });

    group('buildEncodingParameters', () {
      test('returns correct list of encoding parameters', () {
        final result = buildEncodingParameters();

        expect(result, hasLength(2));

        final explodeParam = result[0];
        expect(explodeParam.name, equals('explode'));
        expect(explodeParam.type?.symbol, equals('bool'));
        expect(explodeParam.type?.url, equals('dart:core'));
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final allowEmptyParam = result[1];
        expect(allowEmptyParam.name, equals('allowEmpty'));
        expect(allowEmptyParam.type?.symbol, equals('bool'));
        expect(allowEmptyParam.type?.url, equals('dart:core'));
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);
      });
    });

    group('buildEmptyMapStringString', () {
      test(
        'returns correct LiteralMapExpression for empty Map<String, String>',
        () {
          final result = buildEmptyMapStringString();

          expect(result, isA<LiteralMapExpression>());
          expect(result.keyType?.symbol, equals('String'));
          expect(result.keyType?.url, equals('dart:core'));
          expect(result.valueType?.symbol, equals('String'));
          expect(result.valueType?.url, equals('dart:core'));
        },
      );
    });
  });
}
