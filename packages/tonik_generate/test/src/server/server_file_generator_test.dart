import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/server/server_file_generator.dart';
import 'package:tonik_generate/src/server/server_generator.dart';

void main() {
  group('ServerFileGenerator', () {
    late Directory tempDir;
    late ServerFileGenerator generator;
    late NameManager nameManager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      nameManager = NameManager(generator: NameGenerator());
      final serverGenerator = ServerGenerator(
        nameManager: nameManager,
      );
      generator = ServerFileGenerator(
        serverGenerator: serverGenerator,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('creates server directory if it does not exist', () {
      final servers = {
        const Server(
          url: 'https://api.example.com',
          description: 'Production server',
        ),
      };

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: servers,
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final serverDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'server'),
      );
      expect(serverDir.existsSync(), isTrue);
    });

    test('generates server file with correct name and content', () {
      final servers = {
        const Server(
          url: 'https://production.example.com',
          description: 'Production server',
        ),
        const Server(
          url: 'https://staging.example.com',
          description: 'Staging server',
        ),
      };

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: servers,
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final serverDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'server'),
      );

      expect(serverDir.listSync(), hasLength(1));

      // Get file name and content
      final generatedFile = serverDir.listSync().first;
      final actualFileName = path.basename(generatedFile.path);
      final fileContent = File(generatedFile.path).readAsStringSync();

      // Check file name
      expect(actualFileName, 'server.dart');

      // Check file content
      expect(fileContent, contains('sealed class Server'));
      expect(fileContent, contains('class ProductionServer'));
      expect(fileContent, contains('class StagingServer'));
      expect(fileContent, contains('class CustomServer'));
      expect(fileContent, contains("'https://production.example.com'"));
      expect(fileContent, contains("'https://staging.example.com'"));
    });

    test('still generates file when no servers are defined', () {
      const apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: {},
        responseHeaders: {},
        requestHeaders: {},
        servers: {}, // Empty servers collection
        operations: {},
        responses: <Response>{},
        queryParameters: {},
        pathParameters: {},
        requestBodies: {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      // Server directory should be created even if there are no servers
      final serverDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'server'),
      );
      expect(serverDir.existsSync(), isTrue);
      expect(serverDir.listSync(), hasLength(1));

      // Get file content
      final generatedFile = serverDir.listSync().first;
      final fileContent = File(generatedFile.path).readAsStringSync();

      // Expect base class and custom class to be generated
      expect(fileContent, contains('sealed class Server'));
      expect(fileContent, contains('class CustomServer'));

      // No server-specific classes should be present
      expect(fileContent.split('class').length, 3);
    });
  });
}
