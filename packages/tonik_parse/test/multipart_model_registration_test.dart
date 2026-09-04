import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('registers an inline multipart body as a regular class model', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'requestBodies': {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'object',
                  'required': ['name'],
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      },
    });

    expect(api.models.whereType<ClassModel>(), hasLength(1));
    final model = api.models.whereType<ClassModel>().single;
    expect(model.properties.single.name, 'name');
    expect(model.properties.single.isRequired, isTrue);
    expect(model.properties.single.model, isA<StringModel>());
  });
}
