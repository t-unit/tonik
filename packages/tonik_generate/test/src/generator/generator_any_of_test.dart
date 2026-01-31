import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator anyOf integration', () {
    late Directory tempDir;
    late Context testContext;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      testContext = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generates file for anyOf model', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: testContext)),
          (discriminatorValue: null, model: IntegerModel(context: testContext)),
        },
        context: testContext,
      );

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: {anyOfModel},
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

      const packageName = 'test_package';

      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final modelDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'model',
      );
      final generatedFile = File(path.join(modelDir, 'flexible_model.dart'));

      expect(Directory(modelDir).existsSync(), isTrue);
      expect(generatedFile.existsSync(), isTrue);
    });
  });
}
