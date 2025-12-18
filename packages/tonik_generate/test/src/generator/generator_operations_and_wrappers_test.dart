import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator operations and wrappers', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generates operation files, wrappers, and API clients', () {
      final successResponse = ResponseObject(
        name: 'Ok',
        context: ctx,
        description: 'ok',
        bodies: {
          ResponseBody(
            model: StringModel(context: ctx),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
        headers: const {},
      );

      final errorResponse = ResponseObject(
        name: 'Err',
        context: ctx,
        description: 'err',
        bodies: {
          ResponseBody(
            model: StringModel(context: ctx),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
        headers: const {},
      );

      final opWithWrappers = Operation(
        operationId: 'GetUser',
        context: ctx,
        summary: 'get user',
        description: 'get user',
        tags: {Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): successResponse,
          const ExplicitResponseStatus(statusCode: 400): errorResponse,
        },
      );

      final opUntagged = Operation(
        operationId: 'Ping',
        context: ctx,
        summary: 'ping',
        description: 'ping',
        tags: const {},
        isDeprecated: false,
        path: '/ping',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        securitySchemes: const {},
        responses: const {},
      );

      final apiDoc = ApiDocument(
        title: 'Test',
        version: '0.0.1',
        description: 'Test',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {opWithWrappers, opUntagged},
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

      final operationDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'operation',
      );
      expect(Directory(operationDir).existsSync(), isTrue);
      expect(Directory(operationDir).listSync().length, 2);

      final wrapperDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'response_wrapper',
      );
      expect(Directory(wrapperDir).existsSync(), isTrue);
      expect(Directory(wrapperDir).listSync().length, 1);

      final apiClientDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'api_client',
      );
      expect(Directory(apiClientDir).existsSync(), isTrue);
      expect(Directory(apiClientDir).listSync().length, 2);
    });
  });
}
