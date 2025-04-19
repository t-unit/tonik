import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/name_generator.dart';
import 'package:tonik_generate/src/util/name_manager.dart';

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
      final name1 = manager.requestBodyName(requestBody);
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
      final name2 = manager.requestBodyName(requestBody2);
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
      final name3 = manager.requestBodyName(requestBody3);
      expect(name3, 'TestRequestBody2');

      expect(manager.requestBodyNames.length, 3);
      expect(manager.requestBodyNames.containsKey(requestBody), isTrue);
      expect(manager.requestBodyNames.containsKey(requestBody2), isTrue);
      expect(manager.requestBodyNames.containsKey(requestBody3), isTrue);
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
      expect(manager.requestBodyNames.length, 1);
      expect(manager.requestBodyNames.containsKey(multiContentBody), isTrue);
      expect(manager.requestBodyNames.containsKey(emptyBody), isFalse);
      expect(manager.requestBodyNames.containsKey(singleContentBody), isFalse);
      expect(manager.requestBodyNames.containsKey(bodyAlias), isFalse);

      // And: Verify name generation still works consistently
      final emptyName1 = manager.requestBodyName(emptyBody);
      final emptyName2 = manager.requestBodyName(emptyBody);
      expect(emptyName1, emptyName2);

      final singleName1 = manager.requestBodyName(singleContentBody);
      final singleName2 = manager.requestBodyName(singleContentBody);
      expect(singleName1, singleName2);

      final multiName1 = manager.requestBodyName(multiContentBody);
      final multiName2 = manager.requestBodyName(multiContentBody);
      expect(multiName1, multiName2);
      expect(multiName1, 'Multi');

      final aliasName1 = manager.requestBodyName(bodyAlias);
      final aliasName2 = manager.requestBodyName(bodyAlias);
      expect(aliasName1, aliasName2);
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
