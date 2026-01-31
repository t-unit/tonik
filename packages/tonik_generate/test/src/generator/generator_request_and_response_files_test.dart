import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator request/response files', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('generates request body file (multi-content) and response files', () {
      final multiBodyRequest = RequestBodyObject(
        name: 'MultiBody',
        context: ctx,
        description: 'multiple',
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: ctx),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
          RequestContent(
            model: StringModel(context: ctx),
            contentType: ContentType.json,
            rawContentType: 'application/problem+json',
          ),
        },
      );

      final multiBodyResponse = ResponseObject(
        name: 'MultiBodyResponse',
        context: ctx,
        description: 'multiple',
        bodies: {
          ResponseBody(
            model: StringModel(context: ctx),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
          ResponseBody(
            model: StringModel(context: ctx),
            rawContentType: 'application/problem+json',
            contentType: ContentType.json,
          ),
        },
        headers: const {},
      );

      final headersResponse = ResponseObject(
        name: 'HeaderResponse',
        context: ctx,
        description: 'headers',
        bodies: {
          ResponseBody(
            model: StringModel(context: ctx),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
        headers: {
          'X-Rate-Limit': ResponseHeaderObject(
            name: 'X-Rate-Limit',
            context: ctx,
            description: 'rate',
            model: IntegerModel(context: ctx),
            isRequired: true,
            isDeprecated: false,
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
          ),
        },
      );

      final apiDoc = ApiDocument(
        title: 'Test',
        version: '0.0.1',
        description: 'Test',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: {multiBodyResponse, headersResponse},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: {multiBodyRequest},
      );

      const packageName = 'test_package';
      const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final requestDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'request_body',
      );
      expect(Directory(requestDir).existsSync(), isTrue);

      expect(
        File(path.join(requestDir, 'multi_body.dart')).existsSync(),
        isTrue,
      );

      final responseDir = path.join(
        tempDir.path,
        packageName,
        'lib',
        'src',
        'response',
      );
      expect(Directory(responseDir).existsSync(), isTrue);
      expect(
        File(path.join(responseDir, 'multi_body_response.dart')).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(responseDir, 'header_response.dart')).existsSync(),
        isTrue,
      );
    });
  });
}
