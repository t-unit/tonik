import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator transport backend', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'tonik_transport_backend_test_',
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('rejects http before writing output', () async {
      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: const {},
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
      final outputDirectory = path.join(tempDir.path, 'output');

      await expectLater(
        const Generator().generate(
          apiDocument: apiDocument,
          outputDirectory: outputDirectory,
          package: 'test_package',
          config: const TonikConfig(
            transport: TransportConfig(backend: TransportBackend.http),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('http'),
          ),
        ),
      );
      expect(Directory(outputDirectory).existsSync(), isFalse);
      expect(tempDir.listSync(), isEmpty);
    });
  });
}
