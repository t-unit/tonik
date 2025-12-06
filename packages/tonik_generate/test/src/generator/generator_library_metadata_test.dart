import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

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

    test('generates library with comprehensive API metadata', () {
      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          description: null,
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
        requestBodies: const {},
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

    test('handles missing optional metadata gracefully', () {
      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          description: null,
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
  });
}
