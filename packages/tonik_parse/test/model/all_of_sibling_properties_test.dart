import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('named allOf with an object member imports sibling properties', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Labeled': {
            'allOf': [
              {
                'allOf': [
                  {r'$ref': '#/components/schemas/BaseAlias'},
                ],
              },
            ],
            'required': ['label'],
            'properties': {
              'label': {'type': 'string', 'readOnly': true},
            },
            'description': 'A labeled item',
            'additionalProperties': {'type': 'integer'},
          },
          'BaseAlias': {r'$ref': '#/components/schemas/Base'},
          'Base': {
            'type': 'object',
            'required': ['id'],
            'properties': {
              'id': {'type': 'integer'},
            },
          },
        },
      },
    });

    final labeled = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'Labeled',
    );
    expect(labeled.name, 'Labeled');
    expect(labeled.description, 'A labeled item');
    expect(labeled.models, hasLength(2));
    final inherited = labeled.models.first as AllOfModel;
    expect((inherited.models.single.resolved as ClassModel).name, 'Base');
    final siblings = labeled.models.last as ClassModel;
    expect(siblings.name, isNull);
    expect(siblings.description, isNull);
    final label = siblings.properties.single;
    expect(label.name, 'label');
    expect(label.model, isA<StringModel>());
    expect(label.isRequired, isTrue);
    expect(label.isReadOnly, isTrue);
    expect(
      labeled.additionalPropertiesPolicy,
      isA<AllowedAdditionalProperties>().having(
        (policy) => policy.valueModel,
        'value model',
        isA<IntegerModel>(),
      ),
    );
    expect(
      siblings.additionalPropertiesPolicy,
      isA<AllowedAdditionalProperties>().having(
        (policy) => policy.origin,
        'origin',
        AdditionalPropertiesOrigin.implicitDefault,
      ),
    );
  });

  test('inline allOf preserves the target of a recursive property', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Holder': {
            'type': 'object',
            'properties': {
              'item': {
                'type': 'object',
                'allOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'id': {'type': 'integer'},
                    },
                  },
                ],
                'properties': {
                  'next': {
                    r'$ref': '#/components/schemas/Holder/properties/item',
                  },
                },
              },
            },
          },
        },
      },
    });

    final holder = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Holder',
    );
    final item = holder.properties.single.model as AllOfModel;
    expect(item.models, hasLength(2));
    final siblings = item.models.last as ClassModel;
    expect(siblings.name, isNull);
    expect(siblings.properties.single.name, 'next');
    expect(siblings.properties.single.isRequired, isFalse);
    expect(siblings.properties.single.model, same(item));
  });

  test('typeless allOf keeps a scalar member despite sibling properties', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Text': {
            'allOf': [
              {r'$ref': '#/components/schemas/Text'},
              {'type': 'string'},
            ],
            'properties': {
              'label': {'type': 'string'},
            },
          },
        },
      },
    });

    final text = api.models.whereType<AllOfModel>().single;
    expect(text.models.single, isA<StringModel>());
  });

  test('nullable allOf requires every member to permit null', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'NullableItem': {
            'type': ['object', 'null'],
            'allOf': [
              {r'$ref': '#/components/schemas/NullableBaseAlias'},
            ],
            'required': ['label'],
            'properties': {
              'label': {'type': 'string'},
            },
          },
          'NonNullableItem': {
            'type': ['object', 'null'],
            'allOf': [
              {
                'type': 'object',
                'allOf': [true],
              },
            ],
            'properties': {
              'label': {'type': 'string'},
            },
          },
          'NullableBaseAlias': {r'$ref': '#/components/schemas/NullableBase'},
          'NullableBase': {
            'type': ['object', 'null'],
            'properties': {
              'id': {'type': 'integer'},
            },
          },
        },
      },
    });

    final nullableItem = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'NullableItem',
    );
    expect(nullableItem.isNullable, isTrue);
    final siblings = nullableItem.models.last as ClassModel;
    expect(siblings.isNullable, isTrue);
    expect(siblings.properties.single.isRequired, isTrue);

    final nonNullableItem = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'NonNullableItem',
    );
    expect(nonNullableItem.isNullable, isFalse);
  });

  test('an explicit object union type excludes null through an alias', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Item': {
            'type': ['object', 'null'],
            'allOf': [
              {r'$ref': '#/components/schemas/ObjectUnionAlias'},
            ],
            'properties': {
              'label': {'type': 'string'},
            },
          },
          'IndirectItem': {
            'type': ['object', 'null'],
            'allOf': [
              {r'$ref': '#/components/schemas/OuterUnion'},
            ],
            'properties': {
              'label': {'type': 'string'},
            },
          },
          'OuterUnion': {
            'anyOf': [
              {r'$ref': '#/components/schemas/ObjectUnionAlias'},
              {'type': 'string'},
            ],
          },
          'ObjectUnionAlias': {r'$ref': '#/components/schemas/ObjectUnion'},
          'ObjectUnion': {
            'type': 'object',
            'anyOf': [true],
          },
        },
      },
    });

    final item = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'Item',
    );
    expect(item.isNullable, isFalse);
    final indirectItem = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'IndirectItem',
    );
    expect(indirectItem.isNullable, isFalse);
    final union = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'OuterUnion',
    );
    expect(union.isNullable, isTrue);
  });
}
