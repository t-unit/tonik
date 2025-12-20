import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

void main() {
  group('TypeReference Generator', () {
    group('buildBoolParameter', () {
      test('returns correct Parameter for bool with default value', () {
        final result = buildBoolParameter('explode');

        expect(result.name, 'explode');
        expect(result.type?.symbol, 'bool');
        expect(result.type?.url, 'dart:core');
        expect(result.named, isTrue);
        expect(result.required, isFalse);
        expect(result.defaultTo, isNotNull);
      });

      test('returns correct Parameter for bool with required true', () {
        final result = buildBoolParameter('explode', required: true);

        expect(result.name, 'explode');
        expect(result.type?.symbol, 'bool');
        expect(result.type?.url, 'dart:core');
        expect(result.named, isTrue);
        expect(result.required, isTrue);
        expect(result.defaultTo, isNull);
      });
    });

    group('buildStringParameter', () {
      test('returns correct Parameter for String with default value', () {
        final result = buildStringParameter('name', defaultValue: 'default');

        expect(result.name, 'name');
        expect(result.type?.symbol, 'String');
        expect(result.type?.url, 'dart:core');
        expect(result.named, isTrue);
        expect(result.required, isFalse);
        expect(result.defaultTo, isNotNull);
      });

      test('returns correct Parameter for String with required true', () {
        final result = buildStringParameter('name', required: true);

        expect(result.name, 'name');
        expect(result.type?.symbol, 'String');
        expect(result.type?.url, 'dart:core');
        expect(result.named, isTrue);
        expect(result.required, isTrue);
        expect(result.defaultTo, isNull);
      });

      test('returns correct Parameter for String without default value', () {
        final result = buildStringParameter('name');

        expect(result.name, 'name');
        expect(result.type?.symbol, 'String');
        expect(result.type?.url, 'dart:core');
        expect(result.named, isTrue);
        expect(result.required, isFalse);
        expect(result.defaultTo, isNull);
      });
    });

    group('buildMapStringObjectType', () {
      test('returns correct TypeReference for Map<String, Object?>', () {
        final result = buildMapStringObjectType();

        expect(result.symbol, 'Map');
        expect(result.url, 'dart:core');
        expect(result.isNullable, isNull);
        expect(result.types, hasLength(2));
        expect(result.types[0].symbol, 'String');
        expect(result.types[0].url, 'dart:core');
        expect(result.types[1].symbol, 'Object?');
        expect(result.types[1].url, 'dart:core');
      });
    });

    group('buildMapStringStringType', () {
      test('returns correct TypeReference for Map<String, String>', () {
        final result = buildMapStringStringType();

        expect(result.symbol, 'Map');
        expect(result.url, 'dart:core');
        expect(result.isNullable, isNull);
        expect(result.types, hasLength(2));
        expect(result.types[0].symbol, 'String');
        expect(result.types[0].url, 'dart:core');
        expect(result.types[1].symbol, 'String');
        expect(result.types[1].url, 'dart:core');
      });
    });

    group('buildEncodingParameters', () {
      test('returns correct list of encoding parameters', () {
        final result = buildEncodingParameters();

        expect(result, hasLength(2));

        final explodeParam = result[0];
        expect(explodeParam.name, 'explode');
        expect(explodeParam.type?.symbol, 'bool');
        expect(explodeParam.type?.url, 'dart:core');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final allowEmptyParam = result[1];
        expect(allowEmptyParam.name, 'allowEmpty');
        expect(allowEmptyParam.type?.symbol, 'bool');
        expect(allowEmptyParam.type?.url, 'dart:core');
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
          expect(result.keyType?.symbol, 'String');
          expect(result.keyType?.url, 'dart:core');
          expect(result.valueType?.symbol, 'String');
          expect(result.valueType?.url, 'dart:core');
        },
      );
    });

    group('typeReference', () {
      late Context context;
      late NameManager nameManager;
      const package = 'package:test/test.dart';

      setUp(() {
        context = Context.initial();
        nameManager = NameManager(generator: NameGenerator());
      });

      test('returns List<int> TypeReference for BinaryModel', () {
        final model = BinaryModel(context: context);

        final result = typeReference(model, nameManager, package);

        expect(result.symbol, 'List');
        expect(result.url, 'dart:core');
        expect(result.isNullable, isFalse);
        expect(result.types, hasLength(1));
        expect(result.types[0].symbol, 'int');
        expect(result.types[0].url, 'dart:core');
      });

      test(
        'returns nullable List<int> TypeReference for BinaryModel '
        'with isNullableOverride',
        () {
          final model = BinaryModel(context: context);

          final result = typeReference(
            model,
            nameManager,
            package,
            isNullableOverride: true,
          );

          expect(result.symbol, 'List');
          expect(result.url, 'dart:core');
          expect(result.isNullable, isTrue);
          expect(result.types, hasLength(1));
          expect(result.types[0].symbol, 'int');
          expect(result.types[0].url, 'dart:core');
        },
      );

      test(
        'returns List<List<int>> TypeReference for ListModel '
        'with BinaryModel content',
        () {
          final binaryModel = BinaryModel(context: context);
          final model = ListModel(
            content: binaryModel,
            context: context,
          );

          final result = typeReference(model, nameManager, package);

          expect(result.symbol, 'List');
          expect(result.url, 'dart:core');
          expect(result.isNullable, isFalse);
          expect(result.types, hasLength(1));

          final innerType = result.types[0] as TypeReference;
          expect(innerType.symbol, 'List');
          expect(innerType.url, 'dart:core');
          expect(innerType.types, hasLength(1));
          expect(innerType.types[0].symbol, 'int');
          expect(innerType.types[0].url, 'dart:core');
        },
      );
    });
  });
}
