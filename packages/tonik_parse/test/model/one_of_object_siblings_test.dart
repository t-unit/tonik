import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
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
