import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const simpleApiWithExternalDocs = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'externalDocs': {
      'url': 'https://example.com/docs',
    },
  };

  const apiWithExternalDocsAndDescription = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'externalDocs': {
      'description': 'Find out more about our API',
      'url': 'https://example.com/docs',
    },
  };

  const apiWithoutExternalDocs = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
  };

  test('imports externalDocs with url only', () {
    final api = Importer().import(simpleApiWithExternalDocs);
    expect(api.externalDocs?.url, 'https://example.com/docs');
    expect(api.externalDocs?.description, isNull);
  });

  test('imports externalDocs with description and url', () {
    final api = Importer().import(apiWithExternalDocsAndDescription);
    expect(api.externalDocs?.description, 'Find out more about our API');
    expect(api.externalDocs?.url, 'https://example.com/docs');
  });

  test('handles missing externalDocs', () {
    final api = Importer().import(apiWithoutExternalDocs);
    expect(api.externalDocs, isNull);
  });

  test('externalDocs is properly typed as core ExternalDocumentation', () {
    final api = Importer().import(apiWithExternalDocsAndDescription);
    expect(api.externalDocs, isNotNull);
    expect(api.externalDocs?.url, isA<String>());
    expect(api.externalDocs?.description, isA<String?>());
  });
}
