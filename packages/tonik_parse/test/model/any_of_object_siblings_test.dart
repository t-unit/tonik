import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('named anyOf combines required sibling properties with the union', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Contacts', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Contact': {
            'type': 'object',
            'required': ['name'],
            'properties': {
              'name': {'type': 'string'},
            },
            'anyOf': [
              {
                'type': 'object',
                'properties': {
                  'email': {'type': 'string'},
                },
              },
              {
                'type': 'object',
                'properties': {
                  'phone': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    });
    final contact = api.models.whereType<AllOfModel>().single;
    expect(contact.name, 'Contact');
    final siblings = contact.models.whereType<ClassModel>().single;
    expect(siblings.properties.single.name, 'name');
    expect(siblings.properties.single.isRequired, isTrue);
    final union = contact.models.whereType<AnyOfModel>().single;
    expect(union.models.length, 2);
    expect(
      (union.models.first.model as ClassModel).properties.single.name,
      'email',
    );
    expect(
      (union.models.last.model as ClassModel).properties.single.name,
      'phone',
    );
  });

  test(
    'inline anyOf preserves sibling properties and recursive references',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Contacts', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Contact': {
              'type': 'object',
              'properties': {
                'details': {
                  'type': 'object',
                  'properties': {
                    'parent': {r'$ref': '#/components/schemas/Contact'},
                  },
                  'anyOf': [
                    {
                      'type': 'object',
                      'properties': {
                        'email': {'type': 'string'},
                      },
                    },
                    {
                      'type': 'object',
                      'properties': {
                        'phone': {'type': 'string'},
                      },
                    },
                  ],
                },
              },
            },
          },
        },
      });
      final contact = api.models.whereType<ClassModel>().singleWhere(
        (model) => model.name == 'Contact',
      );
      final details = contact.properties.single.model as AllOfModel;
      final siblings = details.models.whereType<ClassModel>().single;
      expect(siblings.properties.single.name, 'parent');
      expect(siblings.properties.single.model, same(contact));
      expect(details.models.whereType<AnyOfModel>().single.models.length, 2);
    },
  );

  test(
    'typeless anyOf keeps primitive alternatives with sibling properties',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Contacts', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Contact': {
              'properties': {
                'name': {'type': 'string'},
              },
              'anyOf': [
                {'type': 'string'},
                {
                  'type': 'object',
                  'properties': {
                    'email': {'type': 'string'},
                  },
                },
              ],
            },
          },
        },
      });
      final contact = api.models.whereType<AnyOfModel>().single;
      expect(contact.name, 'Contact');
      expect(contact.models.first.model, isA<StringModel>());
      expect(contact.models.last.model, isA<ClassModel>());
    },
  );

  test('nullable object siblings preserve named and inline nullability', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Contacts', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Contact': {
            'type': ['object', 'null'],
            'properties': {
              'name': {'type': 'string'},
            },
            'anyOf': [
              {'type': 'null'},
              {
                'type': 'object',
                'properties': {
                  'email': {'type': 'string'},
                },
              },
            ],
          },
          'Holder': {
            'type': 'object',
            'required': ['named', 'inline'],
            'properties': {
              'named': {r'$ref': '#/components/schemas/Contact'},
              'inline': {
                'type': ['object', 'null'],
                'properties': {
                  'name': {'type': 'string'},
                },
                'anyOf': [
                  {'type': 'null'},
                  {
                    'type': 'object',
                    'properties': {
                      'email': {'type': 'string'},
                    },
                  },
                ],
              },
            },
          },
        },
      },
    });
    final contact = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'Contact',
    );
    expect(contact.isNullable, isTrue);
    final holder = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Holder',
    );
    expect(holder.properties.first.model, same(contact));
    expect(holder.properties.first.model.isEffectivelyNullable, isTrue);
    expect(holder.properties.last.model, isA<AllOfModel>());
    expect(holder.properties.last.model.isEffectivelyNullable, isTrue);
  });

  test('object siblings skip a direct anyOf self-reference', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Contacts', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Contact': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
            'anyOf': [
              {r'$ref': '#/components/schemas/Contact'},
              {
                'type': 'object',
                'properties': {
                  'email': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    });
    final contact = api.models.whereType<AllOfModel>().single;
    final union = contact.models.whereType<AnyOfModel>().single;
    expect(union.models.length, 1);
    final alternative = union.models.single.model as ClassModel;
    expect(alternative.properties.single.name, 'email');
  });
}
