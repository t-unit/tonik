import 'package:test/test.dart';
import 'package:tonic_parse/tonic_parse.dart';

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
}
