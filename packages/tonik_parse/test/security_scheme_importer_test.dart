import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/security_scheme_importer.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.1.0',
    'info': {'title': 'Test', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'securitySchemes': {
        'api_key_header': {
          'type': 'apiKey',
          'description': 'API Key authentication',
          'name': 'X-API-Key',
          'in': 'header',
        },
        'api_key_query': {
          'type': 'apiKey',
          'description': 'API Key in query parameter',
          'name': 'api_key',
          'in': 'query',
        },
        'api_key_cookie': {
          'type': 'apiKey',
          'description': 'API Key in cookie',
          'name': 'session_id',
          'in': 'cookie',
        },
        'bearer_auth': {
          'type': 'http',
          'description': 'HTTP Bearer authentication',
          'scheme': 'bearer',
          'bearerFormat': 'JWT',
        },
        'basic_auth': {
          'type': 'http',
          'description': 'HTTP Basic authentication',
          'scheme': 'basic',
        },
        'oauth2': {
          'type': 'oauth2',
          'description': 'OAuth2 authentication',
          'flows': {
            'authorizationCode': {
              'authorizationUrl': 'https://example.com/auth',
              'tokenUrl': 'https://example.com/token',
              'refreshUrl': 'https://example.com/refresh',
              'scopes': {
                'read': 'Read access',
                'write': 'Write access',
              },
            },
            'implicit': {
              'authorizationUrl': 'https://example.com/auth',
              'scopes': {
                'read': 'Read access',
              },
            },
          },
        },
        'openid': {
          'type': 'openIdConnect',
          'description': 'OpenID Connect authentication',
          'openIdConnectUrl':
              'https://example.com/.well-known/openid_configuration',
        },
        'mutual_tls': {
          'type': 'mutualTLS',
          'description': 'Mutual TLS authentication',
        },
      },
    },
  };

  group('SecuritySchemeImporter', () {
    test('imports API key security scheme in header', () {
      Importer().import(fileContent);
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      expect(importer.securitySchemes, hasLength(8));
      expect(
        importer.securitySchemes['api_key_header'],
        isA<core.ApiKeySecurityScheme>(),
      );

      final scheme =
          importer.securitySchemes['api_key_header']!
              as core.ApiKeySecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.apiKey);
      expect(scheme.description, 'API Key authentication');
      expect(scheme.location, core.ApiKeyLocation.header);
    });

    test('imports API key security scheme in query', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['api_key_query']!
              as core.ApiKeySecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.apiKey);
      expect(scheme.description, 'API Key in query parameter');
      expect(scheme.location, core.ApiKeyLocation.query);
    });

    test('imports API key security scheme in cookie', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['api_key_cookie']!
              as core.ApiKeySecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.apiKey);
      expect(scheme.description, 'API Key in cookie');
      expect(scheme.location, core.ApiKeyLocation.cookie);
    });

    test('imports HTTP Bearer security scheme', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['bearer_auth']! as core.HttpSecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.http);
      expect(scheme.description, 'HTTP Bearer authentication');
      expect(scheme.scheme, 'bearer');
      expect(scheme.bearerFormat, 'JWT');
    });

    test('imports HTTP Basic security scheme', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['basic_auth']! as core.HttpSecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.http);
      expect(scheme.description, 'HTTP Basic authentication');
      expect(scheme.scheme, 'basic');
      expect(scheme.bearerFormat, isNull);
    });

    test('imports OAuth2 security scheme with multiple flows', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['oauth2']! as core.OAuth2SecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.oauth2);
      expect(scheme.description, 'OAuth2 authentication');

      expect(scheme.flows.authorizationCode, isNotNull);
      expect(
        scheme.flows.authorizationCode!.authorizationUrl,
        'https://example.com/auth',
      );
      expect(
        scheme.flows.authorizationCode!.tokenUrl,
        'https://example.com/token',
      );
      expect(
        scheme.flows.authorizationCode!.refreshUrl,
        'https://example.com/refresh',
      );
      expect(scheme.flows.authorizationCode!.scopes['read'], 'Read access');
      expect(scheme.flows.authorizationCode!.scopes['write'], 'Write access');

      expect(scheme.flows.implicit, isNotNull);
      expect(
        scheme.flows.implicit!.authorizationUrl,
        'https://example.com/auth',
      );
      expect(scheme.flows.implicit!.scopes['read'], 'Read access');

      expect(scheme.flows.password, isNull);
      expect(scheme.flows.clientCredentials, isNull);
    });

    test('imports OpenID Connect security scheme', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['openid']!
              as core.OpenIdConnectSecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.openIdConnect);
      expect(scheme.description, 'OpenID Connect authentication');
      expect(
        scheme.openIdConnectUrl,
        'https://example.com/.well-known/openid_configuration',
      );
    });

    test('imports mutual TLS security scheme', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      final scheme =
          importer.securitySchemes['mutual_tls']!
              as core.MutualTlsSecurityScheme;
      expect(scheme.type, core.SecuritySchemeType.mutualTLS);
      expect(scheme.description, 'Mutual TLS authentication');
    });

    test('imports all defined security schemes', () {
      final openApiObject = OpenApiObject.fromJson(fileContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      expect(importer.securitySchemes, hasLength(8));
      expect(
        importer.securitySchemes.keys,
        containsAll([
          'api_key_header',
          'api_key_query',
          'api_key_cookie',
          'bearer_auth',
          'basic_auth',
          'oauth2',
          'openid',
          'mutual_tls',
        ]),
      );
    });

    test('handles empty security schemes', () {
      final emptyContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'securitySchemes': <String, dynamic>{},
        },
      };

      final openApiObject = OpenApiObject.fromJson(emptyContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      expect(importer.securitySchemes, isEmpty);
    });

    test('handles missing components', () {
      final noComponentsContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      };

      final openApiObject = OpenApiObject.fromJson(noComponentsContent);
      final importer = SecuritySchemeImporter(openApiObject)..import();

      expect(importer.securitySchemes, isEmpty);
    });

    test('throws ArgumentError for invalid security scheme type', () {
      final invalidTypeContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'securitySchemes': {
            'invalid_scheme': {
              'type': 'invalidType',
              'description': 'Invalid security scheme type',
            },
          },
        },
      };

      expect(
        () => OpenApiObject.fromJson(invalidTypeContent),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for invalid API key location', () {
      final invalidLocationContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'securitySchemes': {
            'invalid_location': {
              'type': 'apiKey',
              'name': 'X-API-Key',
              'in': 'invalidLocation',
            },
          },
        },
      };

      expect(
        () => OpenApiObject.fromJson(invalidLocationContent),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
