import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'StringList': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'IntegerList': {
          'type': 'array',
          'items': {'type': 'integer', 'format': 'int32'},
        },
        'UserList': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer', 'format': 'int64'},
              'email': {'type': 'string'},
            },
          },
        },
        'User': {
          'type': 'object',
          'properties': {
            'id': {'type': 'integer', 'format': 'int64'},
          },
        },
        'UserReferenceList': {
          'type': 'array',
          'items': {r'$ref': '#/components/schemas/User'},
        },
        'MixedList': {
          'type': 'array',
          'items': {
            'oneOf': [
              {'type': 'string'},
              {r'$ref': '#/components/schemas/User'},
            ],
            'discriminator': {'propertyName': 'name'},
          },
        },
      },
    },
  };

  final api = Importer().import(fileContent);

  test('imports string list model', () {
    final model = api.models
        .whereType<ListModel>()
        .firstWhere((m) => m.name == 'StringList');

    expect(model, isA<ListModel>());
    expect(model.content, isA<StringModel>());
  });

  test('imports integer list model', () {
    final model = api.models
        .whereType<ListModel>()
        .firstWhere((m) => m.name == 'IntegerList');

    expect(model, isA<ListModel>());
    expect(model.content, isA<IntegerModel>());
  });

  test('imports inline object list model', () {
    final model = api.models
        .whereType<ListModel>()
        .firstWhere((m) => m.name == 'UserList');

    expect(model, isA<ListModel>());
    expect(model.content, isA<ClassModel>());
    expect((model.content as ClassModel).properties.length, 2);

    expect(api.models, contains(model.content));

    final properties = (model.content as ClassModel).properties;
    expect(properties.first.name, 'id');
    expect(properties.first.model, isA<IntegerModel>());
    expect(properties.last.name, 'email');
    expect(properties.last.model, isA<StringModel>());
  });

  test('imports reference object list model', () {
    final model = api.models
        .whereType<ListModel>()
        .firstWhere((m) => m.name == 'UserReferenceList');

    expect(model, isA<ListModel>());
    expect(model.content, isA<ClassModel>());
    expect((model.content as ClassModel).name, 'User');

    expect(api.models, contains(model.content));
  });

  test('imports mixed list model', () {
    final model = api.models
        .whereType<ListModel>()
        .firstWhere((m) => m.name == 'MixedList');

    expect(model, isA<ListModel>());
    expect(model.content, isA<OneOfModel>());

    final oneOf = model.content as OneOfModel;
    expect(oneOf.models.length, 2);

    expect(oneOf.models.first.model, isA<StringModel>());
    expect(oneOf.models.first.discriminatorValue, isNull);
    expect(oneOf.models.last.model, isA<ClassModel>());
    expect((oneOf.models.last.model as ClassModel).name, 'User');
    expect(oneOf.models.last.discriminatorValue, 'User');

    expect(api.models, contains(oneOf.models.last.model));
  });
}
