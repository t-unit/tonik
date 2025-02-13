import 'package:test/test.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const simpleInfo = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
  };

  const infoWithDescription = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
      'description': 'Test API description',
    },
    'paths': <String, dynamic>{},
  };

  test('imports title', () {
    final api = Importer().import(simpleInfo);
    expect(api.title, 'Test API');
  });

  test('imports version', () {
    final api = Importer().import(simpleInfo);
    expect(api.version, '1.0.0');
  });

  test('imports description', () {
    final api = Importer().import(infoWithDescription);
    expect(api.description, 'Test API description');
  });
}
