import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';
import 'package:tonik_generate/src/library_generator.dart';

void main() {
  group('Generator library metadata', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generates library with comprehensive API metadata', () async {
      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          examples: const [],
        ),
      };

      final apiDoc = ApiDocument(
        title: 'Pet Store API',
        version: '1.0.27-SNAPSHOT',
        description:
            'A sample Pet Store Server based on the OpenAPI 3.0 '
            'specification.',
        contact: const Contact(
          name: 'API Support',
          url: 'https://example.com/support',
          email: 'apiteam@swagger.io',
        ),
        license: const License(
          name: 'Apache 2.0',
          url: 'https://www.apache.org/licenses/LICENSE-2.0.html',
        ),
        termsOfService: 'https://swagger.io/terms/',
        externalDocs: const ExternalDocumentation(
          description: 'Find out more about Swagger',
          url: 'https://swagger.io',
        ),
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const packageName = 'petstore_api';
      await const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      expect(libraryFile.existsSync(), isTrue);
      final content = libraryFile.readAsStringSync();

      // Check that all metadata is included in the generated library
      expect(content, contains('/// Pet Store API'));
      expect(content, contains('/// Version 1.0.27-SNAPSHOT'));
      expect(
        content,
        contains(
          '/// A sample Pet Store Server based on the OpenAPI 3.0 '
          'specification.',
        ),
      );

      // Contact information
      expect(content, contains('/// Contact: API Support'));
      expect(content, contains('/// URL: https://example.com/support'));
      expect(content, contains('/// Email: apiteam@swagger.io'));

      // License information
      expect(content, contains('/// License: Apache 2.0'));
      expect(
        content,
        contains(
          '/// License URL: https://www.apache.org/licenses/LICENSE-2.0.html',
        ),
      );

      // Terms of Service
      expect(
        content,
        contains('/// Terms of Service: https://swagger.io/terms/'),
      );

      // External Documentation
      expect(
        content,
        contains('/// Documentation: Find out more about Swagger'),
      );
      expect(content, contains('/// Documentation URL: https://swagger.io'));
    });

    test('keeps multiline metadata and security fields in doc comments', () {
      final apiDoc = ApiDocument(
        title: 'Metadata',
        version: '1.0\nclass Injected {}\n',
        contact: const Contact(
          name: 'Support',
          email: 'support@example.com\r\nemail continuation',
          url: 'https://example.com\ncontact continuation',
        ),
        license: const License(
          name: 'License',
          url: 'https://example.com/license\nlicense continuation',
          identifier: 'MIT\ridentifier\n',
        ),
        externalDocs: const ExternalDocumentation(
          description: 'Documentation',
          url: 'https://example.com/docs\ndocs continuation',
        ),
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {
          Operation(
            operationId: 'getData',
            context: ctx,
            tags: const {},
            isDeprecated: false,
            path: '/data',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {
              HttpSecurityScheme(
                type: SecuritySchemeType.http,
                description: null,
                scheme: 'custom\nsecond',
                bearerFormat: 'JWT\r\nclass BearerDocumentation {}\n',
              ),
              HttpSecurityScheme(
                type: SecuritySchemeType.http,
                description: 'Details\ncontinued',
                scheme: 'other\r\nkind',
                bearerFormat: null,
              ),
              OAuth2SecurityScheme(
                type: SecuritySchemeType.oauth2,
                description: null,
                flows: OAuth2Flows(
                  authorizationCode: OAuth2Flow(
                    authorizationUrl: 'https://example.com/auth\nauth',
                    tokenUrl: 'https://example.com/token\rtoken\n',
                    scopes: {'read\nwrite': 'Access'},
                    refreshUrl: null,
                  ),
                  implicit: null,
                  password: null,
                  clientCredentials: null,
                ),
              ),
              OpenIdConnectSecurityScheme(
                type: SecuritySchemeType.openIdConnect,
                description: null,
                openIdConnectUrl: 'https://example.com/discovery\ndiscovery',
              ),
            },
          ),
        },
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      generateLibraryFile(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'metadata_api',
        publicArtifacts: const [],
      );
      final content = File(
        path.join(tempDir.path, 'metadata_api', 'lib', 'metadata_api.dart'),
      ).readAsStringSync();
      final format = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

      const expected = '''
// Generated code - do not modify by hand
// ignore_for_file: lines_longer_than_80_chars

/// Metadata
/// Version 1.0
/// class Injected {}
///
///
/// Contact: Support
/// Email: support@example.com
/// email continuation
/// URL: https://example.com
/// contact continuation
///
/// License: License
/// License URL: https://example.com/license
/// license continuation
/// SPDX Identifier: MITidentifier
///
///
/// Documentation: Documentation
/// Documentation URL: https://example.com/docs
/// docs continuation
///
/// Security Schemes:
/// - HTTP CUSTOM
/// SECOND
///   Format: JWT
/// class BearerDocumentation {}
///
/// - HTTP OTHER
/// KIND: Details
/// continued
/// - OAuth2
///   Authorization URL: https://example.com/auth
/// auth
///   Token URL: https://example.com/tokentoken
///
///   Scopes: read
/// write
/// - OpenID Connect
///   Discovery URL: https://example.com/discovery
/// discovery

library;
''';
      expect(format(content), format(expected));
    });

    test('handles missing optional metadata gracefully', () async {
      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          examples: const [],
        ),
      };

      final apiDoc = ApiDocument(
        title: 'Simple API',
        version: '1.0.0',
        description: 'A simple API',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const packageName = 'simple_api';
      await const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      expect(libraryFile.existsSync(), isTrue);
      final content = libraryFile.readAsStringSync();

      // Should contain basic info
      expect(content, contains('/// Simple API'));
      expect(content, contains('/// Version 1.0.0'));
      expect(content, contains('/// A simple API'));

      // Should NOT contain missing metadata sections
      expect(content, isNot(contains('/// Contact:')));
      expect(content, isNot(contains('/// License:')));
      expect(content, isNot(contains('/// Terms of Service:')));
      expect(content, isNot(contains('/// Documentation:')));
    });

    test('generates library with summary (OAS 3.1)', () async {
      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          examples: const [],
        ),
      };

      final apiDoc = ApiDocument(
        title: 'Pet Store API',
        version: '1.0.0',
        summary: 'A short summary of the Pet Store API',
        description: 'A longer description with more details.',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const packageName = 'petstore_summary_api';
      await const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      expect(libraryFile.existsSync(), isTrue);
      final content = libraryFile.readAsStringSync();

      expect(content, contains('/// A short summary of the Pet Store API'));
      expect(content, contains('/// A longer description with more details.'));
    });

    test('generates library with license identifier (OAS 3.1)', () async {
      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          examples: const [],
        ),
      };

      final apiDoc = ApiDocument(
        title: 'API with SPDX License',
        version: '1.0.0',
        license: const License(name: 'Apache 2.0', identifier: 'Apache-2.0'),
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const packageName = 'spdx_license_api';
      await const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      expect(libraryFile.existsSync(), isTrue);
      final content = libraryFile.readAsStringSync();

      expect(content, contains('/// License: Apache 2.0'));
      expect(content, contains('/// SPDX Identifier: Apache-2.0'));
    });
  });
}
