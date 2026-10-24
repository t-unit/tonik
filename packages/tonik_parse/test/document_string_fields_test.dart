import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('numeric info versions name the field and required type', () {
    expect(
      () => Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': 1.0},
        'paths': <String, dynamic>{},
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'info.version must be a string. Quote numeric versions.',
        ),
      ),
    );
  });

  test('numeric server defaults identify the variable and required type', () {
    expect(
      () => Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0'},
        'paths': <String, dynamic>{},
        'servers': [
          {
            'url': 'https://example.com:{port}',
            'variables': {
              'port': {'default': 8080},
            },
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'server.variables.port.default must be a string. '
              'Quote numeric defaults.',
        ),
      ),
    );
  });

  test('quoted numeric strings retain their exact values', () {
    final api = Importer().import({
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0'},
      'paths': <String, dynamic>{},
      'servers': [
        {
          'url': 'https://example.com:{port}',
          'variables': {
            'port': {'default': '8080'},
          },
        },
      ],
    });

    expect(api.version, '1.0');
    expect(api.servers.single.variables.single.defaultValue, '8080');
  });
}
