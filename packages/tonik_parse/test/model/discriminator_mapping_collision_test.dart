import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.3',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'Circle': {'type': 'object'},
        'Square': {'type': 'object'},
        'Shape': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Circle'},
            {r'$ref': '#/components/schemas/Square'},
          ],
          'discriminator': {
            'propertyName': 'shapeType',
            'mapping': {
              'square': '#/components/schemas/Square',
              'Circle': '#/components/schemas/Square',
            },
          },
        },
        'ReversedShape': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Square'},
            {r'$ref': '#/components/schemas/Circle'},
          ],
          'discriminator': {
            'propertyName': 'shapeType',
            'mapping': {
              'square': '#/components/schemas/Square',
              'Circle': '#/components/schemas/Square',
            },
          },
        },
        'FirstKeyCollision': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Circle'},
            {r'$ref': '#/components/schemas/Square'},
          ],
          'discriminator': {
            'propertyName': 'shapeType',
            'mapping': {'Circle': '#/components/schemas/Square'},
          },
        },
        'ShapeAnyOf': {
          'anyOf': [
            {r'$ref': '#/components/schemas/Circle'},
            {r'$ref': '#/components/schemas/Square'},
          ],
          'discriminator': {
            'propertyName': 'shapeType',
            'mapping': {
              'square': '#/components/schemas/Square',
              'Circle': '#/components/schemas/Square',
            },
          },
        },
      },
    },
  };

  test('explicit alias suppresses another member implicit value', () {
    final api = Importer().import(fileContent);
    final shape = api.models.whereType<OneOfModel>().singleWhere(
      (model) => model.name == 'Shape',
    );

    expect(shape.models.first.discriminatorValue, isNull);
    expect(shape.models.last.discriminatorValue, 'square');
    expect(shape.discriminatorAliases, {'Circle': 'square'});
  });

  test(
    'explicit alias suppresses implicit value regardless of member order',
    () {
      final api = Importer().import(fileContent);
      final shape = api.models.whereType<OneOfModel>().singleWhere(
        (model) => model.name == 'ReversedShape',
      );

      expect(shape.models.first.discriminatorValue, 'square');
      expect(shape.models.last.discriminatorValue, isNull);
      expect(shape.discriminatorAliases, {'Circle': 'square'});
    },
  );

  test('first explicit mapping key also suppresses an implicit value', () {
    final api = Importer().import(fileContent);
    final shape = api.models.whereType<OneOfModel>().singleWhere(
      (model) => model.name == 'FirstKeyCollision',
    );

    expect(shape.models.first.discriminatorValue, isNull);
    expect(shape.models.last.discriminatorValue, 'Circle');
    expect(shape.discriminatorAliases, isEmpty);
  });

  test('anyOf does not inject an implicitly shadowed discriminator value', () {
    final api = Importer().import(fileContent);
    final shape = api.models.whereType<AnyOfModel>().single;

    expect(shape.models.first.discriminatorValue, isNull);
    expect(shape.models.last.discriminatorValue, 'square');
    expect(shape.discriminatorAliases, {'Circle': 'square'});
  });
}
