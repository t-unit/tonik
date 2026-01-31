import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('Cookie parameter import', () {
    const fileContent = {
      'openapi': '3.0.4',
      'info': {'title': 'Cookie Parameter API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'parameters': {
          'sessionId': {
            'name': 'session_id',
            'in': 'cookie',
            'description': 'Session identifier',
            'required': true,
            'schema': {'type': 'string'},
          },
          'optionalCookie': {
            'name': 'optional_cookie',
            'in': 'cookie',
            'schema': {'type': 'string'},
          },
          'deprecatedCookie': {
            'name': 'deprecated_cookie',
            'in': 'cookie',
            'deprecated': true,
            'schema': {'type': 'string'},
          },
          'explodeCookie': {
            'name': 'explode_cookie',
            'in': 'cookie',
            'explode': true,
            'schema': {'type': 'string'},
          },
          'noExplodeCookie': {
            'name': 'no_explode_cookie',
            'in': 'cookie',
            'explode': false,
            'schema': {'type': 'string'},
          },
          'integerCookie': {
            'name': 'page_num',
            'in': 'cookie',
            'schema': {'type': 'integer'},
          },
          'booleanCookie': {
            'name': 'debug_mode',
            'in': 'cookie',
            'schema': {'type': 'boolean'},
          },
          'cookieReference': {r'$ref': '#/components/parameters/sessionId'},
        },
      },
    };
    late ApiDocument api;
    late Set<CookieParameter> cookieParameters;

    setUpAll(() {
      api = Importer().import(fileContent);
      cookieParameters = api.cookieParameters;
    });

    test('imports required string cookie parameter', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'sessionId');

      expect(parameter.rawName, 'session_id');
      expect(parameter.description, 'Session identifier');
      expect(parameter.isRequired, isTrue);
      expect(parameter.isDeprecated, isFalse);
      // Per OAS 3.0.4 §4.7.12.2.2: form style defaults to explode: true.
      expect(parameter.explode, isTrue);
      expect(parameter.model, isA<StringModel>());
      expect(parameter.encoding, CookieParameterEncoding.form);
    });

    test('imports optional cookie parameter with default explode true', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'optionalCookie');

      expect(parameter.rawName, 'optional_cookie');
      expect(parameter.isRequired, isFalse);
      // Per OAS 3.0.4 §4.7.12.2.2: form style defaults to explode: true.
      expect(parameter.explode, isTrue);
      expect(parameter.encoding, CookieParameterEncoding.form);
    });

    test('imports deprecated cookie parameter', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'deprecatedCookie');

      expect(parameter.rawName, 'deprecated_cookie');
      expect(parameter.isDeprecated, isTrue);
    });

    test('imports cookie parameter with explicit explode: true', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'explodeCookie');

      expect(parameter.rawName, 'explode_cookie');
      expect(parameter.explode, isTrue);
    });

    test('imports cookie parameter with explicit explode: false', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'noExplodeCookie');

      expect(parameter.rawName, 'no_explode_cookie');
      expect(parameter.explode, isFalse);
    });

    test('imports integer cookie parameter', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'integerCookie');

      expect(parameter.rawName, 'page_num');
      expect(parameter.model, isA<IntegerModel>());
    });

    test('imports boolean cookie parameter', () {
      final parameter = cookieParameters
          .whereType<CookieParameterObject>()
          .firstWhere((p) => p.name == 'booleanCookie');

      expect(parameter.rawName, 'debug_mode');
      expect(parameter.model, isA<BooleanModel>());
    });

    test('imports cookie parameter reference', () {
      final alias = cookieParameters
          .whereType<CookieParameterAlias>()
          .firstWhere(
            (p) => p.name == 'cookieReference',
            orElse: () => throw StateError(
              'Expected to find cookie reference parameter '
              'as CookieParameterAlias',
            ),
          );

      // The alias should resolve to the same rawName as sessionId.
      final resolved = alias.resolve();
      expect(resolved.rawName, 'session_id');
    });
  });

  group('Cookie parameter style validation', () {
    test('throws for non-form style cookie parameter', () {
      const fileContent = {
        'openapi': '3.0.4',
        'info': {'title': 'Invalid Cookie API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'parameters': {
            'invalidCookie': {
              'name': 'invalid_cookie',
              'in': 'cookie',
              'style': 'simple',
              'schema': {'type': 'string'},
            },
          },
        },
      };

      expect(
        () => Importer().import(fileContent),
        throwsArgumentError,
      );
    });

    test('accepts form style cookie parameter explicitly', () {
      const fileContent = {
        'openapi': '3.0.4',
        'info': {'title': 'Form Cookie API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'parameters': {
            'formCookie': {
              'name': 'form_cookie',
              'in': 'cookie',
              'style': 'form',
              'schema': {'type': 'string'},
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final cookie = api.cookieParameters.first as CookieParameterObject;
      expect(cookie.encoding, CookieParameterEncoding.form);
    });
  });

  group('Cookie parameter in operations', () {
    test('operation includes cookie parameters', () {
      const fileContent = {
        'openapi': '3.0.4',
        'info': {'title': 'Cookie Operation API', 'version': '1.0.0'},
        'paths': {
          '/test': {
            'get': {
              'operationId': 'testOp',
              'parameters': [
                {
                  'name': 'session_id',
                  'in': 'cookie',
                  'required': true,
                  'schema': {'type': 'string'},
                },
                {
                  'name': 'tracking_id',
                  'in': 'cookie',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {'description': 'Success'},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final operation = api.operations.first;

      expect(operation.cookieParameters.length, 2);

      final sessionCookie = operation.cookieParameters
          .map((p) => p.resolve())
          .firstWhere((p) => p.rawName == 'session_id');
      expect(sessionCookie.isRequired, isTrue);

      final trackingCookie = operation.cookieParameters
          .map((p) => p.resolve())
          .firstWhere((p) => p.rawName == 'tracking_id');
      expect(trackingCookie.isRequired, isFalse);
    });

    test('operation resolves cookie parameter reference', () {
      const fileContent = {
        'openapi': '3.0.4',
        'info': {'title': 'Cookie Reference API', 'version': '1.0.0'},
        'paths': {
          '/test': {
            'get': {
              'operationId': 'testOp',
              'parameters': [
                {r'$ref': '#/components/parameters/sessionId'},
              ],
              'responses': {
                '200': {'description': 'Success'},
              },
            },
          },
        },
        'components': {
          'parameters': {
            'sessionId': {
              'name': 'session_id',
              'in': 'cookie',
              'required': true,
              'schema': {'type': 'string'},
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final operation = api.operations.first;

      expect(operation.cookieParameters.length, 1);

      final resolved = operation.cookieParameters.first.resolve();
      expect(resolved.rawName, 'session_id');
      expect(resolved.isRequired, isTrue);
    });
  });
}
