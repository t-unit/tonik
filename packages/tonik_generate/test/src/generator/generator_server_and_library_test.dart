import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator server and library', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generates server file and library exports', () {
      final servers = {
        const Server(url: 'https://api.example.com', description: 'Prod'),
        const Server(
          url: 'https://staging.example.com',
          description: 'Staging',
        ),
      };

      final models = <Model>{
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
        ),
      };

      final apiDoc = ApiDocument(
        title: 'Test',
        version: '0.0.1',
        description: 'Test',
        models: models,
        responseHeaders: const {},
        requestHeaders: const {},
        servers: servers,
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      const packageName = 'test_package';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final serverDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'server',
      );
      expect(Directory(serverDir).existsSync(), isTrue);
      expect(Directory(serverDir).listSync().length, 1);

      final libraryFile = File(
        path.join(tempDir.path, packageName, 'lib', '$packageName.dart'),
      );
      expect(libraryFile.existsSync(), isTrue);
      final content = libraryFile.readAsStringSync();
      expect(content.contains('library;'), isTrue);
      expect(content.contains("export 'src/model/user.dart';"), isTrue);
    });
  });
}
