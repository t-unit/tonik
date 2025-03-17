import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

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
    expect((stringProperty.model as EnumModel).values, ['a', 'b', 'c']);
  });

  test('imports enum for integer', () {
    final api = Importer().import(fileContent);
    final model = api.models.first as ClassModel;
    final integerProperty = model.properties.firstWhere(
      (p) => p.name == 'integer',
    );

    expect(integerProperty.model, isA<EnumModel<int>>());
    expect((integerProperty.model as EnumModel).values, [10, 22, 77]);
  });

  test('imports enum for int32', () {
    final api = Importer().import(fileContent);
    final model = api.models.first as ClassModel;
    final int32Property = model.properties.firstWhere((p) => p.name == 'int32');

    expect(int32Property.model, isA<EnumModel<int>>());
    expect((int32Property.model as EnumModel).values, [1, 2, 3]);
  });

  test('imports enum for string', () {
    final api = Importer().import(fileContent);
    final model = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'SimpleEnum',
    );

    expect(model, isA<EnumModel<String>>());
    expect((model as EnumModel).values, ['a', 'b', 'c']);
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
}
