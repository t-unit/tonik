import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'string': {
              'type': 'string',
              'enum': ['a', 'b', 'c'],
            },
            'integer': {
              'type': 'integer',
              'enum': [10, 22, 77],
            },
            'int32': {
              'type': 'integer',
              'format': 'int32',
              'enum': [1, 2, 3],
            },
          },
        },
        'SimpleEnum': {
          'type': 'string',
          'enum': ['a', 'b', 'c'],
        },
        'NullableEnum': {
          'type': 'string',
          'enum': ['a', 'b', 'c', null],
        },
      },
    },
  };

  test('imports enum for string', () {
    final api = Importer().import(fileContent);
    final model = api.models.first as ClassModel;
    final stringProperty = model.properties.firstWhere(
      (p) => p.name == 'string',
    );

    expect(stringProperty.model, isA<EnumModel<String>>());
    expect(
      (stringProperty.model as EnumModel<String>).values.map((e) => e.value),
      ['a', 'b', 'c'],
    );
  });

  test('imports enum for integer', () {
    final api = Importer().import(fileContent);
    final model = api.models.first as ClassModel;
    final integerProperty = model.properties.firstWhere(
      (p) => p.name == 'integer',
    );

    expect(integerProperty.model, isA<EnumModel<int>>());
    expect(
      (integerProperty.model as EnumModel<int>).values.map((e) => e.value),
      [10, 22, 77],
    );
  });

  test('imports enum for int32', () {
    final api = Importer().import(fileContent);
    final model = api.models.first as ClassModel;
    final int32Property = model.properties.firstWhere((p) => p.name == 'int32');

    expect(int32Property.model, isA<EnumModel<int>>());
    expect(
      (int32Property.model as EnumModel<int>).values.map((e) => e.value),
      [1, 2, 3],
    );
  });

  test('imports enum for string', () {
    final api = Importer().import(fileContent);
    final model = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'SimpleEnum',
    );

    expect(model, isA<EnumModel<String>>());
    expect(
      (model as EnumModel<String>).values.map((e) => e.value),
      ['a', 'b', 'c'],
    );
  });

  test('parses nullability for enum', () {
    final api = Importer().import(fileContent);
    final nullable = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'NullableEnum',
    );

    expect(nullable, isA<EnumModel<String>>());
    expect((nullable as EnumModel).isNullable, isTrue);

    final required = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'SimpleEnum',
    );
    expect(required, isA<EnumModel<String>>());
    expect((required as EnumModel).isNullable, isFalse);
  });

  group('empty enum', () {
    test('adds typed fallback cases and warns', () {
      final logs = <LogRecord>[];
      final subscription = Logger('ModelImporter').onRecord.listen(logs.add);
      addTearDown(subscription.cancel);

      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'EmptyString': {'type': 'string', 'enum': <String>[]},
            'EmptyInteger': {'type': 'integer', 'enum': <int>[]},
            'EmptyNullable': {
              'type': 'string',
              'enum': <String>[],
              'nullable': true,
            },
          },
        },
      };

      final api = Importer().import(spec);
      final emptyString =
          api.models.firstWhere(
                (model) => model is NamedModel && model.name == 'EmptyString',
              )
              as EnumModel<String>;
      final emptyInteger =
          api.models.firstWhere(
                (model) => model is NamedModel && model.name == 'EmptyInteger',
              )
              as EnumModel<int>;
      final emptyNullable =
          api.models.firstWhere(
                (model) => model is NamedModel && model.name == 'EmptyNullable',
              )
              as EnumModel<String>;

      expect(emptyString.values, isEmpty);
      expect(
        emptyString.fallbackValue,
        const EnumEntry(value: 'unknown', nameOverride: 'unknown'),
      );
      expect(emptyInteger.values, isEmpty);
      expect(
        emptyInteger.fallbackValue,
        const EnumEntry(value: -1, nameOverride: 'unknown'),
      );
      expect(emptyNullable.values, isEmpty);
      expect(emptyNullable.isNullable, isTrue);
      expect(
        emptyNullable.fallbackValue,
        const EnumEntry(value: 'unknown', nameOverride: 'unknown'),
      );

      expect(
        logs
            .where((record) => record.level == Level.WARNING)
            .map((record) => record.message),
        [
          'Enum components/schemas/EmptyString has no values. Adding an unknown fallback case.',
          'Enum components/schemas/EmptyInteger has no values. Adding an unknown fallback case.',
          'Enum components/schemas/EmptyNullable has no values. Adding an unknown fallback case.',
        ],
      );
    });

    test('adds a fallback when type filtering removes every value', () {
      final logs = <LogRecord>[];
      final subscription = Logger('ModelImporter').onRecord.listen(logs.add);
      addTearDown(subscription.cancel);

      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'InvalidString': {
              'type': 'string',
              'enum': [1, 2],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model =
          api.models.firstWhere(
                (model) => model is NamedModel && model.name == 'InvalidString',
              )
              as EnumModel<String>;

      expect(model.values, isEmpty);
      expect(
        model.fallbackValue,
        const EnumEntry(value: 'unknown', nameOverride: 'unknown'),
      );
      expect(
        logs
            .where((record) => record.level == Level.WARNING)
            .map((record) => record.message),
        [
          'Found non-matching values in enum for components/schemas/InvalidString. Ignoring non-matching values.',
          'Enum components/schemas/InvalidString has no values. Adding an unknown fallback case.',
        ],
      );
    });
  });

  group('description', () {
    const enumWithDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Status': {
            'type': 'string',
            'description': 'The status of the order',
            'enum': ['pending', 'shipped', 'delivered'],
          },
        },
      },
    };

    const enumWithoutDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Priority': {
            'type': 'integer',
            'enum': [1, 2, 3],
          },
        },
      },
    };

    test('import enum with description', () {
      final api = Importer().import(enumWithDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Status',
              )
              as EnumModel<String>;

      expect(model.description, 'The status of the order');
    });

    test('import enum without description', () {
      final api = Importer().import(enumWithoutDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Priority',
              )
              as EnumModel<int>;

      expect(model.description, isNull);
    });
  });
}
