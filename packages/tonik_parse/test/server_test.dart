import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const simpleServer = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'servers': [
      {'url': 'https://api.example.com'},
    ],
  };

  const complexServer = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'servers': [
      {
        'url': 'https://api.example.com',
        'description': 'Test server description',
      },
      {'url': 'https://dev.example.com', 'description': 'Dev server'},
    ],
  };

  const templatedServer = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'servers': [
      {
        'url': 'https://{username}.example.com:{port}/{basePath}',
        'description': 'Templated server',
        'variables': {
          'username': {
            'default': 'demo',
            'description': 'Username for the server',
          },
          'port': {
            'enum': ['443', '8443'],
            'default': '443',
          },
          'basePath': {
            'default': 'v2',
          },
        },
      },
    ],
  };

  test('imports server', () {
    final api = Importer().import(simpleServer);
    expect(api.servers, hasLength(1));
    expect(api.servers.first.url, 'https://api.example.com');
  });

  test('imports server description', () {
    final api = Importer().import(complexServer);
    expect(api.servers.first.description, 'Test server description');
  });

  test('imports multiple servers', () {
    final api = Importer().import(complexServer);
    expect(api.servers, hasLength(2));
    expect(api.servers.first.url, 'https://api.example.com');
    expect(api.servers.last.url, 'https://dev.example.com');
  });

  group('server variables', () {
    test('imports server with variables', () {
      final api = Importer().import(templatedServer);
      expect(api.servers, hasLength(1));

      final server = api.servers.first;
      expect(
        server.url,
        'https://{username}.example.com:{port}/{basePath}',
      );
      expect(server.variables, hasLength(3));
    });

    test('imports variable with default value', () {
      final api = Importer().import(templatedServer);
      final server = api.servers.first;

      final usernameVar = server.variables.firstWhere(
        (v) => v.name == 'username',
      );
      expect(usernameVar.defaultValue, 'demo');
      expect(usernameVar.description, 'Username for the server');
      expect(usernameVar.enumValues, isNull);
    });

    test('imports variable with enum values', () {
      final api = Importer().import(templatedServer);
      final server = api.servers.first;

      final portVar = server.variables.firstWhere((v) => v.name == 'port');
      expect(portVar.defaultValue, '443');
      expect(portVar.enumValues, ['443', '8443']);
    });

    test('imports variable without description', () {
      final api = Importer().import(templatedServer);
      final server = api.servers.first;

      final basePathVar = server.variables.firstWhere(
        (v) => v.name == 'basePath',
      );
      expect(basePathVar.defaultValue, 'v2');
      expect(basePathVar.description, isNull);
      expect(basePathVar.enumValues, isNull);
    });

    test('server without variables has empty list', () {
      final api = Importer().import(simpleServer);
      expect(api.servers.first.variables, isEmpty);
    });
  });
}
