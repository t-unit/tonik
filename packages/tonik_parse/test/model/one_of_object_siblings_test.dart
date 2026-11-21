import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('object oneOf keeps discriminator mappings and sibling properties', () {
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
            'discriminator': {
              'propertyName': 'kind',
              'mapping': {
                'email': '#/components/schemas/Email',
                'phone': '#/components/schemas/Phone',
              },
            },
            'oneOf': [
              {r'$ref': '#/components/schemas/Email'},
              {r'$ref': '#/components/schemas/Phone'},
            ],
          },
          'Email': {
            'type': 'object',
            'properties': {
              'address': {'type': 'string'},
            },
          },
          'Phone': {
            'type': 'object',
            'properties': {
              'number': {'type': 'string'},
            },
          },
        },
      },
    });

    final contact = api.models.whereType<AllOfModel>().single;
    expect(contact.name, 'Contact');
    final sibling = contact.models.whereType<ClassModel>().single;
    expect(sibling.name, isNull);
    expect(sibling.properties.single.name, 'name');
    expect(sibling.properties.single.isRequired, isTrue);
    final union = contact.models.whereType<OneOfModel>().single;
    expect(union.discriminator, 'kind');
    expect(union.models, hasLength(2));
    expect(union.models.first.discriminatorValue, 'email');
    expect((union.models.first.model as ClassModel).name, 'Email');
    expect(union.models.last.discriminatorValue, 'phone');
    expect((union.models.last.model as ClassModel).name, 'Phone');
  });

  test('typeless oneOf keeps a scalar alternative with sibling properties', () {
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
            'oneOf': [
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

    final contact = api.models.whereType<OneOfModel>().single;
    expect(contact.name, 'Contact');
    expect(contact.models, hasLength(2));
    expect(contact.models.first.model, isA<StringModel>());
    expect(contact.models.last.model, isA<ClassModel>());
  });

  test('object oneOf with empty properties keeps the union model', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Contacts', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Contact': {
            'type': 'object',
            'properties': <String, dynamic>{},
            'oneOf': [
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

    final contact = api.models.whereType<OneOfModel>().single;
    expect(contact.name, 'Contact');
    final email = contact.models.single.model as ClassModel;
    expect(email.properties.single.name, 'email');
  });
}
