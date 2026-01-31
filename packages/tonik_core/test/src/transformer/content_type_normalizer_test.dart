import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ContentTypeNormalizer', () {
    late ContentTypeNormalizer normalizer;
    late List<LogRecord> logRecords;
    late Context context;

    setUp(() {
      logRecords = [];
      ContentTypeNormalizer.log.onRecord.listen(logRecords.add);
      normalizer = const ContentTypeNormalizer();
      context = Context.initial();
    });

    group('ResponseBody normalization', () {
      test(
        'replaces model with BinaryModel for ContentType.bytes responses',
        () {
          final response = ResponseObject(
            name: 'FileResponse',
            context: context,
            description: 'A file download',
            headers: const {},
            bodies: Set.unmodifiable({
              ResponseBody(
                model: ClassModel(
                  name: 'FileMetadata',
                  properties: const [],
                  context: context,
                  isDeprecated: false,
                ),
                rawContentType: 'application/octet-stream',
                contentType: ContentType.bytes,
              ),
            }),
          );

          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: const {},
            responses: {response},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            requestBodies: const {},
          );

          final transformed = normalizer.apply(document);
          final transformedResponse =
              transformed.responses.first as ResponseObject;
          final body = transformedResponse.bodies.first;

          expect(body.model, isA<BinaryModel>());
          expect(body.rawContentType, 'application/octet-stream');
          expect(body.contentType, ContentType.bytes);
        },
      );

      test(
        'replaces model with StringModel for ContentType.text responses',
        () {
          final response = ResponseObject(
            name: 'TextResponse',
            context: context,
            description: 'A text response',
            headers: const {},
            bodies: Set.unmodifiable({
              ResponseBody(
                model: IntegerModel(context: context),
                rawContentType: 'text/plain',
                contentType: ContentType.text,
              ),
            }),
          );

          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: const {},
            responses: {response},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            requestBodies: const {},
          );

          final transformed = normalizer.apply(document);
          final transformedResponse =
              transformed.responses.first as ResponseObject;
          final body = transformedResponse.bodies.first;

          expect(body.model, isA<StringModel>());
        },
      );

      test('keeps original model for ContentType.json responses', () {
        final originalModel = ClassModel(
          name: 'User',
          properties: const [],
          context: context,
          isDeprecated: false,
        );

        final response = ResponseObject(
          name: 'JsonResponse',
          context: context,
          description: 'A JSON response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: originalModel,
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: {response},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);
        final transformedResponse =
            transformed.responses.first as ResponseObject;
        final body = transformedResponse.bodies.first;

        expect(body.model, isA<ClassModel>());
        expect((body.model as ClassModel).name, 'User');
      });

      test('keeps original model for ContentType.form responses', () {
        final originalModel = ClassModel(
          name: 'FormData',
          properties: const [],
          context: context,
          isDeprecated: false,
        );

        final response = ResponseObject(
          name: 'FormResponse',
          context: context,
          description: 'A form-urlencoded response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: originalModel,
              rawContentType: 'application/x-www-form-urlencoded',
              contentType: ContentType.form,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: {response},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);
        final transformedResponse =
            transformed.responses.first as ResponseObject;
        final body = transformedResponse.bodies.first;

        expect(body.model, isA<ClassModel>());
        expect((body.model as ClassModel).name, 'FormData');
      });

      test(
        'keeps BinaryModel for ContentType.json responses (nested binary)',
        () {
          final binaryModel = BinaryModel(context: context);

          final response = ResponseObject(
            name: 'JsonWithBinaryResponse',
            context: context,
            description: 'JSON with binary field',
            headers: const {},
            bodies: {
              ResponseBody(
                model: binaryModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          );

          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: const {},
            responses: {response},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            requestBodies: const {},
          );

          final transformed = normalizer.apply(document);
          final transformedResponse =
              transformed.responses.first as ResponseObject;
          final body = transformedResponse.bodies.first;

          expect(body.model, isA<BinaryModel>());
        },
      );

      test('logs warning when replacing model for bytes content type', () {
        final response = ResponseObject(
          name: 'FileResponse',
          context: context.pushAll(['responses', 'FileResponse']),
          description: '',
          headers: const {},
          bodies: {
            ResponseBody(
              model: ClassModel(
                name: 'Wrong',
                properties: const [],
                context: context,
                isDeprecated: false,
              ),
              rawContentType: 'application/octet-stream',
              contentType: ContentType.bytes,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: {response},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        normalizer.apply(document);

        expect(logRecords, hasLength(1));
        expect(logRecords.first.level, Level.WARNING);
        expect(
          logRecords.first.message,
          contains('Replacing ClassModel with BinaryModel'),
        );
        expect(
          logRecords.first.message,
          contains('responses/FileResponse'),
        );
      });

      test('handles ResponseAlias by normalizing referenced response', () {
        final referencedResponse = ResponseObject(
          name: 'OriginalResponse',
          context: context,
          description: '',
          headers: const {},
          bodies: {
            ResponseBody(
              model: IntegerModel(context: context),
              rawContentType: 'application/octet-stream',
              contentType: ContentType.bytes,
            ),
          },
        );

        final aliasResponse = ResponseAlias(
          name: 'AliasResponse',
          context: context,
          response: referencedResponse,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: {referencedResponse, aliasResponse},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);
        final transformedOriginal =
            transformed.responses.firstWhere(
                  (r) => r.name == 'OriginalResponse',
                )
                as ResponseObject;

        expect(transformedOriginal.bodies.first.model, isA<BinaryModel>());
      });
    });

    group('RequestContent normalization', () {
      test(
        'replaces model with BinaryModel for ContentType.bytes requests',
        () {
          final requestBody = RequestBodyObject(
            name: 'FileUpload',
            context: context,
            description: 'Upload a file',
            isRequired: true,
            content: Set.unmodifiable({
              RequestContent(
                model: StringModel(context: context),
                rawContentType: 'application/octet-stream',
                contentType: ContentType.bytes,
              ),
            }),
          );

          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: const {},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            requestBodies: {requestBody},
          );

          final transformed = normalizer.apply(document);
          final transformedBody =
              transformed.requestBodies.first as RequestBodyObject;
          final content = transformedBody.content.first;

          expect(content.model, isA<BinaryModel>());
          expect(content.rawContentType, 'application/octet-stream');
          expect(content.contentType, ContentType.bytes);
        },
      );

      test('replaces model with StringModel for ContentType.text requests', () {
        final requestBody = RequestBodyObject(
          name: 'TextBody',
          context: context,
          description: 'Text body',
          isRequired: true,
          content: Set.unmodifiable({
            RequestContent(
              model: BooleanModel(context: context),
              rawContentType: 'text/plain',
              contentType: ContentType.text,
            ),
          }),
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: {requestBody},
        );

        final transformed = normalizer.apply(document);
        final transformedBody =
            transformed.requestBodies.first as RequestBodyObject;
        final content = transformedBody.content.first;

        expect(content.model, isA<StringModel>());
      });

      test('keeps original model for ContentType.json requests', () {
        final originalModel = ClassModel(
          name: 'CreateUserRequest',
          properties: const [],
          context: context,
          isDeprecated: false,
        );

        final requestBody = RequestBodyObject(
          name: 'CreateUser',
          context: context,
          description: 'Create user',
          isRequired: true,
          content: {
            RequestContent(
              model: originalModel,
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: {requestBody},
        );

        final transformed = normalizer.apply(document);
        final transformedBody =
            transformed.requestBodies.first as RequestBodyObject;
        final content = transformedBody.content.first;

        expect(content.model, isA<ClassModel>());
        expect((content.model as ClassModel).name, 'CreateUserRequest');
      });

      test('keeps original model for ContentType.form requests', () {
        final originalModel = ClassModel(
          name: 'FormRequest',
          properties: const [],
          context: context,
          isDeprecated: false,
        );

        final requestBody = RequestBodyObject(
          name: 'SubmitForm',
          context: context,
          description: 'Submit form data',
          isRequired: true,
          content: {
            RequestContent(
              model: originalModel,
              rawContentType: 'application/x-www-form-urlencoded',
              contentType: ContentType.form,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: {requestBody},
        );

        final transformed = normalizer.apply(document);
        final transformedBody =
            transformed.requestBodies.first as RequestBodyObject;
        final content = transformedBody.content.first;

        expect(content.model, isA<ClassModel>());
        expect((content.model as ClassModel).name, 'FormRequest');
      });

      test('handles RequestBodyAlias by normalizing referenced body', () {
        final referencedBody = RequestBodyObject(
          name: 'OriginalBody',
          context: context,
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: DoubleModel(context: context),
              rawContentType: 'text/plain',
              contentType: ContentType.text,
            ),
          },
        );

        final aliasBody = RequestBodyAlias(
          name: 'AliasBody',
          context: context,
          requestBody: referencedBody,
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: {referencedBody, aliasBody},
        );

        final transformed = normalizer.apply(document);
        final transformedOriginal =
            transformed.requestBodies.firstWhere(
                  (r) => r.name == 'OriginalBody',
                )
                as RequestBodyObject;

        expect(transformedOriginal.content.first.model, isA<StringModel>());
      });

      test('logs warning when replacing model for text content type', () {
        final requestBody = RequestBodyObject(
          name: 'TextBody',
          context: context.pushAll(['requestBodies', 'TextBody']),
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: IntegerModel(context: context),
              rawContentType: 'text/plain',
              contentType: ContentType.text,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: {requestBody},
        );

        normalizer.apply(document);

        expect(logRecords, hasLength(1));
        expect(logRecords.first.level, Level.WARNING);
        expect(
          logRecords.first.message,
          contains('Replacing IntegerModel with StringModel'),
        );
        expect(
          logRecords.first.message,
          contains('requestBodies/TextBody'),
        );
      });
    });

    group('edge cases', () {
      test('returns document unchanged when no normalization needed', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);
        expect(transformed.responses, isEmpty);
        expect(transformed.requestBodies, isEmpty);
        expect(transformed.title, document.title);
      });

      test('handles multiple bodies in single response', () {
        final response = ResponseObject(
          name: 'MultiResponse',
          context: context,
          description: '',
          headers: const {},
          bodies: {
            ResponseBody(
              model: IntegerModel(context: context),
              rawContentType: 'application/octet-stream',
              contentType: ContentType.bytes,
            ),
            ResponseBody(
              model: BooleanModel(context: context),
              rawContentType: 'text/plain',
              contentType: ContentType.text,
            ),
            ResponseBody(
              model: StringModel(context: context),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: {response},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        final transformed = normalizer.apply(document);
        final transformedResponse =
            transformed.responses.first as ResponseObject;
        final bodies = transformedResponse.bodies.toList();

        expect(
          bodies.where((b) => b.contentType == ContentType.bytes).first.model,
          isA<BinaryModel>(),
        );
        expect(
          bodies.where((b) => b.contentType == ContentType.text).first.model,
          isA<StringModel>(),
        );
        expect(
          bodies.where((b) => b.contentType == ContentType.json).first.model,
          isA<StringModel>(),
        );
      });
    });
  });
}
