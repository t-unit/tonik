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

    test('emits one regular model for an inline multipart value', () async {
      final model = ClassModel(
        context: ctx.pushAll(['upload', 'body']),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final content = MultipartRequestContent(
        model: model,
        encoding: const {},
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final document = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        models: {model},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: {
          RequestBodyObject(
            name: null,
            context: ctx.push('upload'),
            description: null,
            isRequired: true,
            content: {content},
          ),
        },
      );

      await const Generator().generate(
        apiDocument: document,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final lib = path.join(tempDir.path, 'test_package', 'lib');
      expect(
        File(
          path.join(lib, 'src', 'model', 'upload_body_model.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(path.join(lib, 'src', 'request_body')).existsSync(),
        isFalse,
      );
      final exports = RegExp(r"^export '([^']+)';$", multiLine: true)
          .allMatches(
            File(path.join(lib, 'test_package.dart')).readAsStringSync(),
          )
          .map((match) => match.group(1)!)
          .toList();
      expect(exports, [
        'src/model/upload_body_model.dart',
        'src/server/server.dart',
      ]);
    });

    test(
      'generates request body file (multi-content) and response files',
      () async {
        final multiBodyRequest = RequestBodyObject(
          name: 'MultiBody',
          context: ctx,
          description: 'multiple',
          isRequired: true,
          content: {
            ModelRequestContent(
              model: StringModel(context: ctx),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            ModelRequestContent(
              model: StringModel(context: ctx),
              contentType: ContentType.json,
              rawContentType: 'application/problem+json',
              examples: const [],
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
              examples: const [],
            ),
            ResponseBody(
              model: StringModel(context: ctx),
              rawContentType: 'application/problem+json',
              contentType: ContentType.json,
              examples: const [],
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
              examples: const [],
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
              examples: const [],
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
        await const Generator().generate(
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
      },
    );
  });
}
