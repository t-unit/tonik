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
        expect(baseName, 'TestOperationResponse');
        expect(subclassNames.keys, containsAll(operation.responses.keys));
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 200)],
          'TestOperationResponse200',
        );
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 404)],
          'TestOperationResponse404',
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
        servers: const [],
      );

      // First model gets Anonymous
      expect(manager.modelName(models[0]), 'Anonymous');
      // Second model gets Model suffix
      expect(manager.modelName(models[1]), 'AnonymousModel');

      // Both responses have headers, so both should be cached
      expect(manager.responseNames(responses[0]).baseName, 'User');
      expect(manager.responseNames(responses[1]).baseName, 'UserResponse');

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
        servers: const [],
      );

      // Then: Verify cache contents
      expect(manager.responsAndImplementationNames.length, 2);
      expect(
        manager.responsAndImplementationNames.containsKey(headersOnlyResponse),
        isTrue,
      );
      expect(
        manager.responsAndImplementationNames.containsKey(completeResponse),
        isTrue,
      );
      expect(
        manager.responsAndImplementationNames.containsKey(emptyResponse),
        isFalse,
      );
      expect(
        manager.responsAndImplementationNames.containsKey(bodyOnlyResponse),
        isFalse,
      );
      expect(
        manager.responsAndImplementationNames.containsKey(emptyAlias),
        isFalse,
      );

      // And: Verify name generation still works consistently
      final emptyName1 = manager.responseNames(emptyResponse).baseName;
      final emptyName2 = manager.responseNames(emptyResponse).baseName;
      expect(emptyName1, emptyName2);

      final bodyOnlyName1 = manager.responseNames(bodyOnlyResponse);
      final bodyOnlyName2 = manager.responseNames(bodyOnlyResponse);
      expect(bodyOnlyName1, bodyOnlyName2);

      final headersOnlyName1 = manager.responseNames(headersOnlyResponse);
      final headersOnlyName2 = manager.responseNames(headersOnlyResponse);
      expect(headersOnlyName1, headersOnlyName2);
      expect(headersOnlyName1.baseName, 'HeadersOnly');

      final completeName1 = manager.responseNames(completeResponse);
      final completeName2 = manager.responseNames(completeResponse);
      expect(completeName1, completeName2);
      expect(completeName1.baseName, 'Complete');

      final emptyAliasName1 = manager.responseNames(emptyAlias);
      final emptyAliasName2 = manager.responseNames(emptyAlias);
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
        servers: const [],
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
        servers: const [],
      );

      expect(manager.responsAndImplementationNames.length, 1);
      expect(manager.responseNames(multiBodyResponse).baseName, 'MultiBody');
    });

    test('responseNames returns base name and implementation names', () {
      final response = ResponseObject(
        name: 'UserResponse',
        context: context,
        description: 'A user response',
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

      final (:baseName, :implementationNames) = manager.responseNames(response);

      expect(baseName, 'UserResponse');
      expect(implementationNames, {
        'application/json': 'UserResponseJson',
        'application/xml': 'UserResponseXml',
      });

      // Verify caching
      final (
        baseName: baseName2,
        implementationNames: implementationNames2,
      ) = manager.responseNames(response);
      expect(baseName2, baseName);
      expect(identical(implementationNames, implementationNames2), isTrue);
    });

    test('responseNames handles content types with version numbers', () {
      final response = ResponseObject(
        name: 'UserResponse',
        context: context,
        description: 'A user response',
        headers: const {},
        bodies: {
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/json+v2',
            contentType: ContentType.json,
          ),
        },
      );

      final (:baseName, :implementationNames) = manager.responseNames(response);

      expect(baseName, 'UserResponse');
      expect(implementationNames, isEmpty);

      // Verify caching
      final (
        baseName: baseName2,
        implementationNames: implementationNames2,
      ) = manager.responseNames(response);
      expect(baseName2, baseName);
      expect(identical(implementationNames, implementationNames2), isTrue);
    });

    group('model naming behavior', () {
      late Context userContext;

      setUp(() {
        userContext = Context.initial().pushAll([
          'components',
          'schemas',
          'user',
        ]);
      });

      test(
        'named model keeps original name and anonymous model gets Model suffix',
        () {
          final models = [
            ClassModel(
              name: 'User',
              properties: const [],
              context: userContext,
            ),
            ClassModel(properties: const [], context: userContext),
          ];

          manager.prime(
            models: models,
            responses: const [],
            operations: const [],
            tags: const [],
            requestBodies: const [],
            servers: const [],
          );

          expect(manager.modelName(models[0]), 'User');
          expect(manager.modelName(models[1]), 'UserModel');
        },
      );

      test(
        'named model takes precedence over anonymous model with same context',
        () {
          final models = [
            ClassModel(properties: const [], context: userContext),
            ClassModel(
              name: 'User',
              properties: const [],
              context: userContext,
            ),
          ];

          manager.prime(
            models: models,
            responses: const [],
            operations: const [],
            tags: const [],
            requestBodies: const [],
            servers: const [],
          );

          expect(manager.modelName(models[0]), 'UserModel');
          expect(manager.modelName(models[1]), 'User');
        },
      );
    });
  });

  group('Server names with list-based caching', () {
    late NameGenerator generator;
    late NameManager manager;

    setUp(() {
      generator = NameGenerator();
      manager = NameManager(generator: generator);
    });

    test('caches and returns the same result for identical server lists', () {
      final servers = [
        const Server(url: 'https://api.example.com', description: null),
        const Server(url: 'https://staging.example.com', description: null),
        const Server(url: 'https://dev.example.com', description: null),
      ];

      // First call should generate names
      final result1 = manager.serverNames(servers);

      // Generate a new identical list to test content equality
      final identicalContentServers = [
        const Server(url: 'https://api.example.com', description: null),
        const Server(url: 'https://staging.example.com', description: null),
        const Server(url: 'https://dev.example.com', description: null),
      ];

      // Identity should be different but content equal
      expect(identical(servers, identicalContentServers), isFalse);

      // Second call with different list but same content should use cache
      final result2 = manager.serverNames(identicalContentServers);

      // Verify results match
      expect(result1.serverMap.length, result2.serverMap.length);
      expect(result1.baseName, result2.baseName);
      expect(result1.customName, result2.customName);

      // The cache should only have one entry despite using two different lists
      expect(manager.serverNamesCache.length, 1);

      // Check that corresponding servers in each list have the same names
      for (var i = 0; i < servers.length; i++) {
        final server1 = servers[i];
        final server2 = identicalContentServers[i];

        final name1 = result1.serverMap[server1];
        final name2 = result2.serverMap[server2];

        expect(name1, name2);
      }
    });

    test('primes names for a list of servers', () {
      final servers = [
        const Server(url: 'https://api.example.com', description: null),
        const Server(url: 'https://staging.example.com', description: null),
      ];

      // Prime the name manager
      manager.prime(
        models: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        requestBodies: const [],
        servers: servers,
      );

      // Create a cache key from the servers list
      final cacheKey = manager.createServerCacheKey(servers);

      // Verify the server names are cached
      expect(manager.serverNamesCache.length, 1);

      // Verify the cache contains the correct key
      expect(manager.serverNamesCache.containsKey(cacheKey), isTrue);

      // Get the cached result
      final cachedResult = manager.serverNamesCache[cacheKey]!;

      // Verify the cached result has correct server map size
      expect(cachedResult.serverMap.length, 2);

      // Check that the servers are properly mapped to their expected names
      for (final server in servers) {
        final name = cachedResult.serverMap[server];
        expect(name != null, isTrue);

        if (server.url == 'https://api.example.com') {
          expect(name!.startsWith('Api'), isTrue);
        } else if (server.url == 'https://staging.example.com') {
          expect(name!.startsWith('Staging'), isTrue);
        }
      }

      // Verify custom name exists
      expect(cachedResult.customName.contains('Custom'), isTrue);
    });
  });
}
