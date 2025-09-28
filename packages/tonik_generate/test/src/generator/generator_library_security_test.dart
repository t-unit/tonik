import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator library security information', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('includes security schemes information in library documentation', () {
      final models = <Model>{
        ClassModel(name: 'User', properties: const [], context: ctx),
      };

      final apiDoc = ApiDocument(
        title: 'Pet Store API',
        version: '1.0.0',
        description: 'A sample Pet Store API',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {
          Operation(
            operationId: 'getPet',
            context: ctx,
            summary: 'Get pet',
            description: 'Get pet by ID',
            tags: {const Tag(name: 'pets')},
            isDeprecated: false,
            path: '/pets/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
            requestBody: null,
            securitySchemes: const {
              ApiKeySecurityScheme(
                type: SecuritySchemeType.apiKey,
                description: 'API Key authentication',
                $in: ApiKeyLocation.header,
              ),
              HttpSecurityScheme(
                type: SecuritySchemeType.http,
                description: 'Bearer token authentication',
                scheme: 'bearer',
                bearerFormat: 'JWT',
              ),
            },
          ),
        },
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      const packageName = 'petstore_api';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      expect(libraryFile.existsSync(), isTrue);

      final content = libraryFile.readAsStringSync();
      
      // Check that security schemes are documented
      expect(content, contains('/// Security Schemes:'));
      expect(content, contains('/// - API Key (header): API Key authentication'));
      expect(content, contains('/// - HTTP Bearer: Bearer token authentication'));
    });

    test('includes OAuth2 security scheme information', () {
      final models = <Model>{
        ClassModel(name: 'User', properties: const [], context: ctx),
      };

      final apiDoc = ApiDocument(
        title: 'OAuth API',
        version: '1.0.0',
        description: 'An API with OAuth2',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {
          Operation(
            operationId: 'getUser',
            context: ctx,
            summary: 'Get user',
            description: 'Get user info',
            tags: {const Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/me',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
            requestBody: null,
            securitySchemes: const {
              OAuth2SecurityScheme(
                type: SecuritySchemeType.oauth2,
                description: 'OAuth2 authentication',
                flows: OAuth2Flows(
                  authorizationCode: OAuth2Flow(
                    authorizationUrl: 'https://example.com/auth',
                    tokenUrl: 'https://example.com/token',
                    scopes: {'read': 'Read access', 'write': 'Write access'},
                  ),
                ),
              ),
            },
          ),
        },
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      const packageName = 'oauth_api';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      final content = libraryFile.readAsStringSync();
      
      expect(content, contains('/// Security Schemes:'));
      expect(content, contains('/// - OAuth2: OAuth2 authentication'));
      expect(content, contains('///   Authorization URL: https://example.com/auth'));
      expect(content, contains('///   Token URL: https://example.com/token'));
      expect(content, contains('///   Scopes: read, write'));
    });

    test('handles empty security schemes', () {
      final models = <Model>{
        ClassModel(name: 'User', properties: const [], context: ctx),
      };

      final apiDoc = ApiDocument(
        title: 'Simple API',
        version: '1.0.0',
        description: 'An API without security',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {
          Operation(
            operationId: 'getPublicData',
            context: ctx,
            summary: 'Get public data',
            description: 'Get public data',
            tags: {const Tag(name: 'public')},
            isDeprecated: false,
            path: '/public',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
            requestBody: null,
            securitySchemes: const {},
          ),
        },
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      const packageName = 'simple_api';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      final content = libraryFile.readAsStringSync();
      
      // Should not include security schemes section when empty
      expect(content, isNot(contains('/// Security Schemes:')));
    });

    test('omits description when none provided', () {
      final models = <Model>{
        ClassModel(name: 'User', properties: const [], context: ctx),
      };

      final apiDoc = ApiDocument(
        title: 'API without descriptions',
        version: '1.0.0',
        description: 'An API with security schemes without descriptions',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {
          Operation(
            operationId: 'getSecureData',
            context: ctx,
            summary: 'Get secure data',
            description: 'Get secure data',
            tags: {const Tag(name: 'secure')},
            isDeprecated: false,
            path: '/secure',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
            requestBody: null,
            securitySchemes: const {
              ApiKeySecurityScheme(
                type: SecuritySchemeType.apiKey,
                description: null, // No description
                $in: ApiKeyLocation.header,
              ),
              HttpSecurityScheme(
                type: SecuritySchemeType.http,
                description: '', // Empty description
                scheme: 'bearer',
              ),
            },
          ),
        },
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      const packageName = 'no_desc_api';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      final content = libraryFile.readAsStringSync();
      
      expect(content, contains('/// Security Schemes:'));
      expect(content, contains('/// - API Key (header)'));
      expect(content, contains('/// - HTTP Bearer'));
      // Should not contain "No description"
      expect(content, isNot(contains('No description')));
      // Should not have descriptions after the scheme names
      expect(content, isNot(contains('/// - API Key (header):')));
      expect(content, isNot(contains('/// - HTTP Bearer:')));
    });
  });
}
