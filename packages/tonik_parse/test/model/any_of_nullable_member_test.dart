import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('inline anyOf inherits nullability from a type array member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Profile': {
            'type': 'object',
            'required': ['externalId'],
            'properties': {
              'externalId': {
                'anyOf': [
                  {
                    'type': ['string', 'null'],
                  },
                  {'type': 'integer'},
                ],
              },
            },
          },
        },
      },
    });

    final profile = api.models.whereType<ClassModel>().single;
    final property = profile.properties.single;
    final model = property.model as AnyOfModel;
    expect(property.isRequired, isTrue);
    expect(model.isNullable, isTrue);
    expect(model.models, hasLength(2));
  });

  test('named anyOf inherits nullability through a referenced union', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Identifier': {
            'anyOf': [
              {r'$ref': '#/components/schemas/TextOrInteger'},
              {'type': 'boolean'},
            ],
          },
          'TextOrInteger': {
            'anyOf': [
              {r'$ref': '#/components/schemas/NullableText'},
              {'type': 'integer'},
            ],
          },
          'NullableText': {'type': 'string', 'nullable': true},
          'Nonnullable': {
            'anyOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
        },
      },
    });

    final identifier = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'Identifier',
    );
    final textOrInteger = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'TextOrInteger',
    );
    final nonnullable = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'Nonnullable',
    );
    expect(identifier.isNullable, isTrue);
    expect(textOrInteger.isNullable, isTrue);
    expect(nonnullable.isNullable, isFalse);
  });
}
