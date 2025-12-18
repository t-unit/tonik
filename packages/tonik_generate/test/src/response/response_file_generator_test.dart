import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/response/response_file_generator.dart';
import 'package:tonik_generate/src/response/response_generator.dart';

void main() {
  group('ResponseFileGenerator', () {
    late Directory tempDir;
    late ResponseFileGenerator generator;
    late NameManager nameManager;
    late Context testContext;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      nameManager = NameManager(generator: NameGenerator());
      final responseGenerator = ResponseGenerator(
        nameManager: nameManager,
        package: 'test_package',
      );
      generator = ResponseFileGenerator(responseGenerator: responseGenerator);
      testContext = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('creates response directory if it does not exist', () {
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
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

      final responseDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'response'),
      );
      expect(responseDir.existsSync(), isTrue);
    });

    test('skips responses without headers and single body', () {
      final response = ResponseObject(
        name: 'TestResponse',
        context: testContext,
        description: 'Test response',
        bodies: {
          ResponseBody(
            model: StringModel(context: testContext),
            rawContentType: 'text/plain',
            contentType: ContentType.json,
          ),
        },
        headers: const {},
      );
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: {response},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final responseDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'response'),
      );
      expect(responseDir.listSync(), isEmpty);
    });

    test('generates file for response with headers', () {
      final response = ResponseObject(
        name: 'TestResponse',
        context: testContext,
        description: 'Test response',
        bodies: {
          ResponseBody(
            model: StringModel(context: testContext),
            rawContentType: 'text/plain',
            contentType: ContentType.json,
          ),
        },
        headers: {
          'Content-Type': ResponseHeaderObject(
            name: 'Content-Type',
            context: testContext,
            description: 'Content-Type header',
            model: StringModel(context: testContext),
            isRequired: true,
            isDeprecated: false,
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
          ),
        },
      );
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: {response},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final responseDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'response'),
      );
      expect(responseDir.listSync(), hasLength(1));
    });

    test('generates file for response with multiple bodies', () {
      final response = ResponseObject(
        name: 'TestResponse',
        context: testContext,
        description: 'Test response',
        bodies: {
          ResponseBody(
            model: StringModel(context: testContext),
            rawContentType: 'text/plain',
            contentType: ContentType.json,
          ),
          ResponseBody(
            model: IntegerModel(context: testContext),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
        headers: const {},
      );
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: {response},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final responseDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'response'),
      );
      expect(responseDir.listSync(), hasLength(1));
    });
  });
}
