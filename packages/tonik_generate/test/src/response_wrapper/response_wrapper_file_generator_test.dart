import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_file_generator.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_generator.dart';

void main() {
  late Directory tempDir;
  late NameManager nameManager;
  late ResponseWrapperGenerator generator;
  late ResponseWrapperFileGenerator fileGenerator;
  late Context testContext;
  late Operation opWithOneStatus;
  late Operation opWithTwoStatuses;
  late ApiDocument apiDocument;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    nameManager = NameManager(generator: NameGenerator());
    generator = ResponseWrapperGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    fileGenerator = ResponseWrapperFileGenerator(
      responseWrapperGenerator: generator,
    );
    testContext = Context.initial();

    opWithOneStatus = Operation(
      operationId: 'oneStatus',
      context: testContext,
      tags: const {},
      isDeprecated: false,
      path: '/one',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      responses: {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'Success',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        ),
      },
      securitySchemes: const {},
    );

    opWithTwoStatuses = Operation(
      operationId: 'twoStatuses',
      context: testContext,
      tags: const {},
      isDeprecated: false,
      path: '/two',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      responses: {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'Success',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        ),
        const ExplicitResponseStatus(statusCode: 404): ResponseObject(
          name: 'NotFound',
          context: testContext,
          description: 'Not found',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        ),
      },
      securitySchemes: const {},
    );

    apiDocument = ApiDocument(
      title: 'Test',
      version: '1.0.0',
      models: const {},
      responseHeaders: const {},
      requestHeaders: const {},
      servers: const {},
      operations: {opWithOneStatus, opWithTwoStatuses},
      responses: const {},
      queryParameters: const {},
      pathParameters: const {},
      requestBodies: const {},
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('generates file for operation with two or more statuses', () {
    fileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: tempDir.path,
      package: 'test_package',
    );
    final wrapperDir = path.join(
      tempDir.path,
      'test_package',
      'lib',
      'src',
      'response_wrapper',
    );
    final files =
        Directory(
          wrapperDir,
        ).listSync(recursive: true).whereType<File>().toList();
    expect(
      files.any((f) => f.path.endsWith('two_statuses_response.dart')),
      isTrue,
    );
  });

  test('does not generate file for operation with fewer than two statuses', () {
    fileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: tempDir.path,
      package: 'test_package',
    );
    final wrapperDir = path.join(
      tempDir.path,
      'test_package',
      'lib',
      'src',
      'response_wrapper',
    );
    final files =
        Directory(
          wrapperDir,
        ).listSync(recursive: true).whereType<File>().toList();
    expect(
      files.any((f) => f.path.endsWith('one_status_response_wrapper.dart')),
      isFalse,
    );
  });
}
