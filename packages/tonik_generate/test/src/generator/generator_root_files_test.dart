import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator root files', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generates pubspec.yaml and analysis_options.yaml', () {
      const apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test',
        models: {},
        responseHeaders: {},
        requestHeaders: {},
        servers: {},
        operations: {},
        responses: <Response>{},
        queryParameters: {},
        pathParameters: {},
        requestBodies: {},
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      const packageName = 'test_package';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final pkgDir = path.join(tempDir.path, packageName);
      expect(File(path.join(pkgDir, 'pubspec.yaml')).existsSync(), isTrue);
      expect(
        File(path.join(pkgDir, 'analysis_options.yaml')).existsSync(),
        isTrue,
      );
    });
  });
}
