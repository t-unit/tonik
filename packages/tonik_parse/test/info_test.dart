import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const simpleInfo = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
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

  const infoWithContact = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
      'contact': {
        'name': 'API Support',
        'url': 'https://example.com/support',
        'email': 'support@example.com',
      },
    },
    'paths': <String, dynamic>{},
  };

  const infoWithLicense = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
      'license': {
        'name': 'MIT',
        'url': 'https://opensource.org/licenses/MIT',
      },
    },
    'paths': <String, dynamic>{},
  };

  const infoWithTermsOfService = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
      'termsOfService': 'https://example.com/terms',
    },
    'paths': <String, dynamic>{},
  };

  const infoWithExternalDocs = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'externalDocs': {
      'description': 'Find out more about our API',
      'url': 'https://example.com/docs',
    },
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

  test('imports contact', () {
    final api = Importer().import(infoWithContact);
    expect(api.contact?.name, 'API Support');
    expect(api.contact?.url, 'https://example.com/support');
    expect(api.contact?.email, 'support@example.com');
  });

  test('imports license', () {
    final api = Importer().import(infoWithLicense);
    expect(api.license?.name, 'MIT');
    expect(api.license?.url, 'https://opensource.org/licenses/MIT');
  });

  test('imports termsOfService', () {
    final api = Importer().import(infoWithTermsOfService);
    expect(api.termsOfService, 'https://example.com/terms');
  });

  test('imports externalDocs', () {
    final api = Importer().import(infoWithExternalDocs);
    expect(api.externalDocs?.description, 'Find out more about our API');
    expect(api.externalDocs?.url, 'https://example.com/docs');
  });
}
