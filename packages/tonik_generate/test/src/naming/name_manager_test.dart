import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('NameManager', () {
    late NameGenerator generator;
    late NameManager manager;
    late Context context;

    setUp(() {
      generator = NameGenerator();
      manager = NameManager(generator: generator);
      context = Context.initial();
    });

    test('caches generated names', () {
      const tag = Tag(name: 'pets');

      final name1 = manager.tagName(tag);
      final name2 = manager.tagName(tag);

      expect(name1, 'PetsApi');
      expect(name2, 'PetsApi', reason: 'Should return cached name');
    });

    group('responseWrapperNames', () {
      test('returns correct base and subclass names and caches result', () {
        final operation = Operation(
          operationId: '_testOperation',
          context: context,
          summary: null,
          description: null,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: 'SuccessResponse',
              context: context,
              description: 'Success',
              headers: const {},
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                ),
              },
            ),
            const ExplicitResponseStatus(statusCode: 404): ResponseObject(
              name: 'NotFoundResponse',
              context: context,
              description: 'Not found',
              headers: const {},
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'text/plain',
                  contentType: ContentType.json,
                ),
              },
            ),
          },
          requestBody: null,
        );
        final (baseName, subclassNames) = manager.responseWrapperNames(
          operation,
        );
        expect(baseName, 'TestOperationResponseWrapper');
        expect(subclassNames.keys, containsAll(operation.responses.keys));
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 200)],
          'TestOperationResponseWrapper200',
        );
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 404)],
          'TestOperationResponseWrapper404',
        );
        // Should be cached
        final (baseName2, subclassNames2) = manager.responseWrapperNames(
          operation,
        );
        expect(identical(subclassNames, subclassNames2), isTrue);
        expect(baseName2, baseName);
      });
    });

    test('primes names in correct order', () {
      final models = [
        ListModel(content: StringModel(context: context), context: context),
        ListModel(content: IntegerModel(context: context), context: context),
      ];
      final responses = [
        ResponseAlias(
          name: 'user',
          context: context,
          response: ResponseObject(
            name: 'users',
            context: context,
            description: 'A user response',
            headers: {
              'Content-Type': ResponseHeaderObject(
                name: 'Content-Type',
                description: '',
                isRequired: true,
                isDeprecated: false,
                explode: false,
                model: StringModel(context: context),
                encoding: ResponseHeaderEncoding.simple,
                context: context,
              ),
            },
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        ),
        ResponseObject(
          name: 'user',
          context: context,
          description: 'Another user response',
          headers: {
            'Content-Type': ResponseHeaderObject(
              name: 'Content-Type',
              description: '',
              isRequired: true,
              isDeprecated: false,
              explode: false,
              model: StringModel(context: context),
              encoding: ResponseHeaderEncoding.simple,
              context: context,
            ),
          },
          bodies: const {},
        ),
      ];
      const tags = [Tag(name: 'user')];

      manager.prime(
        models: models,
        responses: responses,
        operations: const [],
        tags: tags,
        requestBodies: const [],
      );

      // First model gets Anonymous
      expect(manager.modelName(models[0]), 'Anonymous');
      // Second model gets Model suffix
      expect(manager.modelName(models[1]), 'AnonymousModel');

      // Both responses have headers, so both should be cached
      expect(manager.responseNames.length, 2);
      expect(manager.responseName(responses[0]), 'User');
      expect(manager.responseName(responses[1]), 'UserResponse');

      // First tag gets Api suffix immediately
      expect(manager.tagName(tags[0]), 'UserApi');

      // Test request body naming
      final requestBody = RequestBodyObject(
        name: 'test',
        context: context,
        description: '',
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/vnd.api+json',
          ),
        },
      );

      // First request body gets base name
      final (name1, _) = manager.requestBodyNames(requestBody);
      expect(name1, 'Test');

      // Second request body with same name gets RequestBody suffix
      final requestBody2 = RequestBodyObject(
        name: 'test',
        context: context,
        description: '',
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/vnd.api+json',
          ),
        },
      );
      final (name2, _) = manager.requestBodyNames(requestBody2);
      expect(name2, 'TestRequestBody');

      // Third request body with same name gets numbered suffix
      final requestBody3 = RequestBodyObject(
        name: 'test',
        context: context,
        description: '',
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/vnd.api+json',
          ),
        },
      );
      final (name3, _) = manager.requestBodyNames(requestBody3);
      expect(name3, 'TestRequestBody2');

      expect(manager.requestBodyNameCache.length, 3);
      expect(manager.requestBodyNameCache.containsKey(requestBody), isTrue);
      expect(manager.requestBodyNameCache.containsKey(requestBody2), isTrue);
      expect(manager.requestBodyNameCache.containsKey(requestBody3), isTrue);

      // Verify subclass names are consistent
      final (_, subclassNames1) = manager.requestBodyNames(requestBody);
      expect(subclassNames1, {
        'application/json': 'TestJson',
        'application/vnd.api+json': 'TestVndApiJson',
      });

      final (_, subclassNames2) = manager.requestBodyNames(requestBody2);
      expect(subclassNames2, {
        'application/json': 'TestRequestBodyJson',
        'application/vnd.api+json': 'TestRequestBodyVndApiJson',
      });

      final (_, subclassNames3) = manager.requestBodyNames(requestBody3);
      expect(subclassNames3, {
        'application/json': 'TestRequestBody2Json',
        'application/vnd.api+json': 'TestRequestBody2VndApiJson',
      });
    });

    test('skips empty responses when priming', () {
      // Given: Create test responses
      final emptyResponse = ResponseObject(
        name: 'empty',
        context: context,
        headers: const {},
        description: '',
        bodies: const {},
      );

      final bodyOnlyResponse = ResponseObject(
        name: 'bodyOnly',
        context: context,
        headers: const {},
        description: '',
        bodies: {
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      final headersOnlyResponse = ResponseObject(
        name: 'headersOnly',
        context: context,
        headers: {
          'Content-Type': ResponseHeaderObject(
            name: 'Content-Type',
            description: '',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: ResponseHeaderEncoding.simple,
            context: context,
          ),
        },
        description: '',
        bodies: const {},
      );

      final completeResponse = ResponseObject(
        name: 'complete',
        context: context,
        headers: {
          'Content-Type': ResponseHeaderObject(
            name: 'Content-Type',
            description: '',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: ResponseHeaderEncoding.simple,
            context: context,
          ),
        },
        description: '',
        bodies: {
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      final emptyAlias = ResponseAlias(
        name: 'emptyAlias',
        context: context,
        response: emptyResponse,
      );

      // When: Prime the name manager
      manager.prime(
        models: const [],
        responses: [
          emptyResponse,
          bodyOnlyResponse,
          headersOnlyResponse,
          completeResponse,
          emptyAlias,
        ],
        operations: const [],
        tags: const [],
        requestBodies: const [],
      );

      // Then: Verify cache contents
      expect(manager.responseNames.length, 2);
      expect(manager.responseNames.containsKey(headersOnlyResponse), isTrue);
      expect(manager.responseNames.containsKey(completeResponse), isTrue);
      expect(manager.responseNames.containsKey(emptyResponse), isFalse);
      expect(manager.responseNames.containsKey(bodyOnlyResponse), isFalse);
      expect(manager.responseNames.containsKey(emptyAlias), isFalse);

      // And: Verify name generation still works consistently
      final emptyName1 = manager.responseName(emptyResponse);
      final emptyName2 = manager.responseName(emptyResponse);
      expect(emptyName1, emptyName2);

      final bodyOnlyName1 = manager.responseName(bodyOnlyResponse);
      final bodyOnlyName2 = manager.responseName(bodyOnlyResponse);
      expect(bodyOnlyName1, bodyOnlyName2);

      final headersOnlyName1 = manager.responseName(headersOnlyResponse);
      final headersOnlyName2 = manager.responseName(headersOnlyResponse);
      expect(headersOnlyName1, headersOnlyName2);
      expect(headersOnlyName1, 'HeadersOnly');

      final completeName1 = manager.responseName(completeResponse);
      final completeName2 = manager.responseName(completeResponse);
      expect(completeName1, completeName2);
      expect(completeName1, 'Complete');

      final emptyAliasName1 = manager.responseName(emptyAlias);
      final emptyAliasName2 = manager.responseName(emptyAlias);
      expect(emptyAliasName1, emptyAliasName2);
    });

    test('skips request bodies with single or no content when priming', () {
      final emptyBody = RequestBodyObject(
        name: 'empty',
        context: context,
        description: '',
        isRequired: true,
        content: const {},
      );

      final singleContentBody = RequestBodyObject(
        name: 'single',
        context: context,
        description: '',
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
        },
      );

      final multiContentBody = RequestBodyObject(
        name: 'multi',
        context: context,
        description: '',
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/vnd.api+json',
          ),
        },
      );

      final bodyAlias = RequestBodyAlias(
        name: 'alias',
        context: context,
        requestBody: singleContentBody,
      );

      manager.prime(
        models: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        requestBodies: [
          emptyBody,
          singleContentBody,
          multiContentBody,
          bodyAlias,
        ],
      );

      // Then: Verify cache contents
      expect(manager.requestBodyNameCache.length, 1);
      expect(
        manager.requestBodyNameCache.containsKey(multiContentBody),
        isTrue,
      );
      expect(manager.requestBodyNameCache.containsKey(emptyBody), isFalse);
      expect(
        manager.requestBodyNameCache.containsKey(singleContentBody),
        isFalse,
      );
      expect(manager.requestBodyNameCache.containsKey(bodyAlias), isFalse);

      // And: Verify name generation still works consistently
      final (emptyName1, _) = manager.requestBodyNames(emptyBody);
      final (emptyName2, _) = manager.requestBodyNames(emptyBody);
      expect(emptyName1, emptyName2);

      final (singleName1, _) = manager.requestBodyNames(singleContentBody);
      final (singleName2, _) = manager.requestBodyNames(singleContentBody);
      expect(singleName1, singleName2);

      final (multiName1, _) = manager.requestBodyNames(multiContentBody);
      final (multiName2, _) = manager.requestBodyNames(multiContentBody);
      expect(multiName1, multiName2);
      expect(multiName1, 'Multi');

      final (aliasName1, _) = manager.requestBodyNames(bodyAlias);
      final (aliasName2, _) = manager.requestBodyNames(bodyAlias);
      expect(aliasName1, aliasName2);

      // Verify subclass names for multi content body
      final (_, subclassNames) = manager.requestBodyNames(multiContentBody);
      expect(subclassNames, {
        'application/json': 'MultiJson',
        'application/vnd.api+json': 'MultiVndApiJson',
      });

      final (_, subclassNames2) = manager.requestBodyNames(multiContentBody);
      expect(subclassNames2, subclassNames);
    });

    test('caches and names responses with multiple bodies', () {
      final multiBodyResponse = ResponseObject(
        name: 'multiBody',
        context: context,
        description: '',
        headers: const {},
        bodies: {
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/xml',
            contentType: ContentType.json,
          ),
        },
      );

      manager.prime(
        models: const [],
        responses: [multiBodyResponse],
        operations: const [],
        tags: const [],
        requestBodies: const [],
      );

      expect(manager.responseNames.length, 1);
      expect(manager.responseName(multiBodyResponse), 'MultiBody');
    });
  });
}
