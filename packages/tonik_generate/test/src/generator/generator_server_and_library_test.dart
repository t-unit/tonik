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

      print('[TEST] ===== BEFORE GENERATOR =====');
      print('[TEST] tempDir.path: ${tempDir.path}');
      print('[TEST] packageName: $packageName');

      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      print('[TEST] ===== AFTER GENERATOR =====');

      final serverDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'server',
      );

      print('[TEST] Checking serverDir: $serverDir');
      final serverDirExists = Directory(serverDir).existsSync();
      print('[TEST] serverDir exists: $serverDirExists');
      expect(serverDirExists, isTrue);

      final serverFiles = Directory(serverDir).listSync();
      print('[TEST] serverDir file count: ${serverFiles.length}');
      for (final f in serverFiles) {
        print('[TEST]   server file: ${f.path}');
      }
      expect(serverFiles.length, 1);

      final libraryFilePath = path.join(
        tempDir.path,
        packageName,
        'lib',
        '$packageName.dart',
      );
      print('[TEST] ===== LIBRARY FILE CHECK =====');
      print('[TEST] Constructed path: $libraryFilePath');

      final libraryFile = File(libraryFilePath);
      print('[TEST] File object path: ${libraryFile.path}');
      print('[TEST] File object absolute.path: ${libraryFile.absolute.path}');

      // Check multiple times to rule out timing issues
      final exists1 = libraryFile.existsSync();
      print('[TEST] libraryFile.existsSync() call 1: $exists1');

      final exists2 = File(libraryFilePath).existsSync();
      print('[TEST] new File(path).existsSync() call 2: $exists2');

      final exists3 = libraryFile.existsSync();
      print('[TEST] libraryFile.existsSync() call 3: $exists3');

      print('[TEST] Listing lib directory:');
      final libDir = Directory(path.join(tempDir.path, packageName, 'lib'));
      print('[TEST] libDir path: ${libDir.path}');
      print('[TEST] libDir exists: ${libDir.existsSync()}');

      if (libDir.existsSync()) {
        final entities = libDir.listSync();
        print('[TEST] libDir entity count: ${entities.length}');
        for (final entity in entities) {
          print('[TEST]   - ${entity.path} (${entity.runtimeType})');
          if (entity is File) {
            print('[TEST]     absolute: ${entity.absolute.path}');
            print('[TEST]     exists: ${entity.existsSync()}');
            print('[TEST]     length: ${entity.lengthSync()} bytes');
            print(
              '[TEST]     matches libraryFile path: ${entity.path == libraryFile.path}',
            );
            print(
              '[TEST]     matches libraryFile absolute: ${entity.absolute.path == libraryFile.absolute.path}',
            );
          }
        }
      } else {
        print('[TEST] libDir does not exist!');
      }

      print('[TEST] ===== ABOUT TO ASSERT =====');
      print('[TEST] Value to assert: $exists1');
      expect(libraryFile.existsSync(), isTrue);

      print('[TEST] ===== AFTER FIRST EXPECT =====');
      print('[TEST] File still exists: ${libraryFile.existsSync()}');

      final content = libraryFile.readAsStringSync();
      print('[TEST] File content length: ${content.length}');
      print('[TEST] File content (first 500 chars):');
      print(content.substring(0, content.length > 500 ? 500 : content.length));
      print('[TEST] File content (full):');
      print(content);
      print('[TEST] Contains "library;": ${content.contains('library;')}');
      print(
        '[TEST] Contains "export \'src/model/user.dart\';": ${content.contains("export 'src/model/user.dart';")}',
      );

      expect(content.contains('library;'), isTrue);
      expect(content.contains("export 'src/model/user.dart';"), isTrue);
    });
  });
}
