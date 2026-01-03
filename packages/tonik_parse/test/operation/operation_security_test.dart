import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.1.0',
    'info': {'title': 'Security Test API', 'version': '1.0.0'},
    'paths': {
      '/public': {
        'get': {
          'operationId': 'getPublic',
          'summary': 'Public endpoint with no security',
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/api-key-only': {
        'get': {
          'operationId': 'getApiKeyOnly',
          'summary': 'Endpoint requiring API key',
          'security': [
            {'api_key': <String>[]},
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/bearer-only': {
        'get': {
          'operationId': 'getBearerOnly',
          'summary': 'Endpoint requiring Bearer token',
          'security': [
            {'bearer_auth': <String>[]},
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/oauth-scoped': {
        'get': {
          'operationId': 'getOAuthScoped',
          'summary': 'Endpoint requiring OAuth with specific scopes',
          'security': [
            {
              'oauth2': <String>['read:users', 'read:profile'],
            },
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/multiple-options': {
        'get': {
          'operationId': 'getMultipleOptions',
          'summary': 'Endpoint with multiple security options (OR logic)',
          'security': [
            {'api_key': <String>[]},
            {'bearer_auth': <String>[]},
            {
              'oauth2': <String>['read:basic'],
            },
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/combined-requirements': {
        'post': {
          'operationId': 'postCombinedRequirements',
          'summary': 'Endpoint requiring multiple schemes (AND logic)',
          'security': [
            {
              'api_key': <String>[],
              'bearer_auth': <String>[],
            },
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/undefined-scheme': {
        'get': {
          'operationId': 'getUndefinedScheme',
          'summary': 'Endpoint referencing non-existent security scheme',
          'security': [
            {'nonexistent_scheme': <String>[]},
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
    },
    'components': {
      'securitySchemes': {
        'api_key': {
          'type': 'apiKey',
          'description': 'API Key authentication',
          'name': 'X-API-Key',
          'in': 'header',
        },
        'bearer_auth': {
          'type': 'http',
          'description': 'HTTP Bearer authentication',
          'scheme': 'bearer',
          'bearerFormat': 'JWT',
        },
        'oauth2': {
          'type': 'oauth2',
          'description': 'OAuth2 authentication',
          'flows': {
            'authorizationCode': {
              'authorizationUrl': 'https://example.com/auth',
              'tokenUrl': 'https://example.com/token',
              'scopes': {
                'read:users': 'Read user information',
                'read:profile': 'Read user profile',
                'read:basic': 'Basic read access',
                'write:users': 'Write user information',
              },
            },
          },
        },
        'mutual_tls': {
          'type': 'mutualTLS',
          'description': 'Mutual TLS authentication',
        },
      },
    },
  };

  group('Operation Security Requirements', () {
    test('operation with no security has empty security schemes', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'getPublic',
      );

      expect(operation.securitySchemes, isEmpty);
    });

    test('operation with single API key requirement', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'getApiKeyOnly',
      );

      expect(operation.securitySchemes, hasLength(1));

      final scheme = operation.securitySchemes.first;
      expect(scheme, isA<core.ApiKeySecurityScheme>());
      expect(scheme.type, core.SecuritySchemeType.apiKey);
      expect(scheme.description, 'API Key authentication');

      final apiKeyScheme = scheme as core.ApiKeySecurityScheme;
      expect(apiKeyScheme.location, core.ApiKeyLocation.header);
    });

    test('operation with single Bearer token requirement', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'getBearerOnly',
      );

      expect(operation.securitySchemes, hasLength(1));

      final scheme = operation.securitySchemes.first;
      expect(scheme, isA<core.HttpSecurityScheme>());
      expect(scheme.type, core.SecuritySchemeType.http);

      final httpScheme = scheme as core.HttpSecurityScheme;
      expect(httpScheme.scheme, 'bearer');
      expect(httpScheme.bearerFormat, 'JWT');
    });

    test('operation with OAuth2 scoped requirement', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'getOAuthScoped',
      );

      expect(operation.securitySchemes, hasLength(1));

      final scheme = operation.securitySchemes.first;
      expect(scheme, isA<core.OAuth2SecurityScheme>());
      expect(scheme.type, core.SecuritySchemeType.oauth2);

      final oauth2Scheme = scheme as core.OAuth2SecurityScheme;
      expect(oauth2Scheme.flows.authorizationCode, isNotNull);
      expect(
        oauth2Scheme.flows.authorizationCode!.scopes.keys,
        containsAll([
          'read:users',
          'read:profile',
          'read:basic',
          'write:users',
        ]),
      );
    });

    test('operation with multiple security options (OR logic)', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'getMultipleOptions',
      );

      expect(operation.securitySchemes, hasLength(3));

      final schemeTypes = operation.securitySchemes.map((s) => s.type).toSet();
      expect(
        schemeTypes,
        containsAll([
          core.SecuritySchemeType.apiKey,
          core.SecuritySchemeType.http,
          core.SecuritySchemeType.oauth2,
        ]),
      );
    });

    test('operation with combined requirements (AND logic)', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'postCombinedRequirements',
      );

      expect(operation.securitySchemes, hasLength(2));

      final schemeTypes = operation.securitySchemes.map((s) => s.type).toSet();
      expect(
        schemeTypes,
        containsAll([
          core.SecuritySchemeType.apiKey,
          core.SecuritySchemeType.http,
        ]),
      );
    });

    test('operation referencing undefined security scheme is ignored', () {
      final api = Importer().import(fileContent);

      final operation = api.operations.firstWhere(
        (o) => o.operationId == 'getUndefinedScheme',
      );

      // Undefined security schemes should be ignored, not cause errors
      expect(operation.securitySchemes, isEmpty);
    });

    test('ApiDocument.securitySchemes contains only used schemes', () {
      final api = Importer().import(fileContent);

      // All three defined schemes should be present because they're used
      expect(api.securitySchemes, hasLength(3));

      final schemeTypes = api.securitySchemes.map((s) => s.type).toSet();
      expect(
        schemeTypes,
        containsAll([
          core.SecuritySchemeType.apiKey,
          core.SecuritySchemeType.http,
          core.SecuritySchemeType.oauth2,
        ]),
      );
    });

    test('unused security schemes are filtered out', () {
      final contentWithUnusedScheme = {
        ...fileContent,
        'components': {
          'securitySchemes': {
            ...(fileContent['components']!
                    as Map<String, dynamic>)['securitySchemes']!
                as Map<String, dynamic>,
            'unused_scheme': {
              'type': 'http',
              'scheme': 'basic',
            },
          },
        },
      };

      final api = Importer().import(contentWithUnusedScheme);

      // Should still only have 3 schemes (unused one filtered out)
      expect(api.securitySchemes, hasLength(3));

      // Verify the unused scheme is not present
      final hasBasicAuth = api.securitySchemes.any(
        (s) => s is core.HttpSecurityScheme && s.scheme == 'basic',
      );
      expect(hasBasicAuth, isFalse);
    });
  });
}
