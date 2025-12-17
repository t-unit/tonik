import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/filtering', () {
    late Context ctx;
    late Tag petTag;
    late Tag userTag;
    late Tag storeTag;
    late Tag adminTag;
    late Operation getPetOp;
    late Operation listPetsOp;
    late Operation getUserOp;
    late Operation getStoreOp;
    late Operation petUserOp;
    late Operation petStoreOp;
    late Operation tripleTagOp;
    late Operation noTagOp;
    late ClassModel petModel;
    late ClassModel userModel;
    late EnumModel<String> statusEnum;
    late AliasModel idAlias;

    setUp(() {
      ctx = Context.initial();
      petTag = Tag(name: 'pet', description: 'Pet operations');
      userTag = Tag(name: 'user', description: 'User operations');
      storeTag = Tag(name: 'store', description: 'Store operations');
      adminTag = Tag(name: 'admin', description: 'Admin operations');

      // Single tag operations
      getPetOp = Operation(
        operationId: 'getPet',
        context: ctx.push('paths').push('/pet/{petId}').push('get'),
        tags: {petTag},
        isDeprecated: false,
        path: '/pet/{petId}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      listPetsOp = Operation(
        operationId: 'listPets',
        context: ctx.push('paths').push('/pet').push('get'),
        tags: {petTag},
        isDeprecated: false,
        path: '/pet',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      getUserOp = Operation(
        operationId: 'getUser',
        context: ctx.push('paths').push('/user/{userId}').push('get'),
        tags: {userTag},
        isDeprecated: false,
        path: '/user/{userId}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      getStoreOp = Operation(
        operationId: 'getStore',
        context: ctx.push('paths').push('/store/{storeId}').push('get'),
        tags: {storeTag},
        isDeprecated: false,
        path: '/store/{storeId}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      // Two tag operations
      petUserOp = Operation(
        operationId: 'petUserOp',
        context: ctx.push('paths').push('/pet-user').push('get'),
        tags: {petTag, userTag},
        isDeprecated: false,
        path: '/pet-user',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      petStoreOp = Operation(
        operationId: 'petStoreOp',
        context: ctx.push('paths').push('/pet-store').push('get'),
        tags: {petTag, storeTag},
        isDeprecated: false,
        path: '/pet-store',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      // Three tag operation
      tripleTagOp = Operation(
        operationId: 'tripleTagOp',
        context: ctx.push('paths').push('/triple').push('get'),
        tags: {petTag, userTag, adminTag},
        isDeprecated: false,
        path: '/triple',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      // No tag operation
      noTagOp = Operation(
        operationId: 'noTagOp',
        context: ctx.push('paths').push('/noTag').push('get'),
        tags: const {},
        isDeprecated: false,
        path: '/noTag',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      // Models
      petModel = ClassModel(
        name: 'Pet',
        context: ctx.push('components').push('schemas').push('Pet'),
        isDeprecated: false,
        properties: const [],
      );

      userModel = ClassModel(
        name: 'User',
        context: ctx.push('components').push('schemas').push('User'),
        isDeprecated: false,
        properties: const [],
      );

      statusEnum = EnumModel<String>(
        name: 'Status',
        context: ctx.push('components').push('schemas').push('Status'),
        isDeprecated: false,
        isNullable: false,
        values: const {},
      );

      final stringModel = ClassModel(
        name: 'String',
        context: ctx.push('String'),
        isDeprecated: false,
        properties: const [],
      );

      idAlias = AliasModel(
        name: 'Id',
        context: ctx.push('components').push('schemas').push('Id'),
        model: stringModel,
      );
    });

    group('filterByTags', () {
      test('returns all operations when both lists are empty', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp, getStoreOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig();

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(4));
        expect(
          transformed.operations,
          containsAll([getPetOp, listPetsOp, getUserOp, getStoreOp]),
        );
      });

      test(
        'includes only operations with matching tags when includeTags is '
        'specified',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {getPetOp, listPetsOp, getUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['pet'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(2));
          expect(transformed.operations, containsAll([getPetOp, listPetsOp]));
          expect(transformed.operations, isNot(contains(getUserOp)));
          expect(transformed.operations, isNot(contains(getStoreOp)));
        },
      );

      test('includes operations with multiple matching tags', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp, getStoreOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet', 'user'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(3));
        expect(
          transformed.operations,
          containsAll([getPetOp, listPetsOp, getUserOp]),
        );
        expect(transformed.operations, isNot(contains(getStoreOp)));
      });

      test(
        'excludes operations with matching tags when excludeTags is '
        'specified',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {getPetOp, listPetsOp, getUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['store'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(3));
          expect(
            transformed.operations,
            containsAll([getPetOp, listPetsOp, getUserOp]),
          );
          expect(transformed.operations, isNot(contains(getStoreOp)));
        },
      );

      test('excludes operations with multiple excluded tags', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp, getStoreOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeTags: ['store', 'user'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(2));
        expect(transformed.operations, containsAll([getPetOp, listPetsOp]));
        expect(transformed.operations, isNot(contains(getUserOp)));
        expect(transformed.operations, isNot(contains(getStoreOp)));
      });

      test('applies includeTags first, then excludeTags', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp, getStoreOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        // Include pet and user, then exclude user
        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet', 'user'],
            excludeTags: ['user'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(2));
        expect(transformed.operations, containsAll([getPetOp, listPetsOp]));
        expect(transformed.operations, isNot(contains(getUserOp)));
        expect(transformed.operations, isNot(contains(getStoreOp)));
      });

      test(
        'handles operation with multiple tags - keeps if any tag matches '
        'include',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['pet'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(petUserOp));
        },
      );

      test(
        'handles operation with multiple tags - excludes if any tag matches '
        'exclude',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getPetOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['user'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getPetOp));
          expect(transformed.operations, isNot(contains(petUserOp)));
        },
      );

      test('returns empty set when all operations are filtered out', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['user'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, isEmpty);
      });

      test('handles empty operations set', () {
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
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, isEmpty);
      });

      test(
        'operation with two tags - both in includeTags - is included',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['pet', 'user'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(petUserOp));
        },
      );

      test(
        'operation with two tags - only one in includeTags - is included',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['user'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(petUserOp));
        },
      );

      test(
        'operation with two tags - neither in includeTags - is excluded',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['store'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getStoreOp));
          expect(transformed.operations, isNot(contains(petUserOp)));
        },
      );

      test(
        'operation with two tags - both in excludeTags - is excluded',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getStoreOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['pet', 'user'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getStoreOp));
          expect(transformed.operations, isNot(contains(petUserOp)));
        },
      );

      test(
        'operation with two tags - only one in excludeTags - is excluded',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petUserOp, getPetOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['pet'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, isEmpty);
        },
      );

      test(
        'operation with two tags - includeTags matches one, excludeTags '
        'matches the other - is excluded',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {petStoreOp, getUserOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['pet', 'user'],
              excludeTags: ['store'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getUserOp));
          expect(transformed.operations, isNot(contains(petStoreOp)));
        },
      );

      test(
        'operation with three tags - complex include/exclude scenario',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {tripleTagOp, getPetOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          // Include pet (matches both), but exclude admin
          // (only matches tripleTagOp)
          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['pet'],
              excludeTags: ['admin'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getPetOp));
          expect(transformed.operations, isNot(contains(tripleTagOp)));
        },
      );

      test(
        'operation with no tags - is excluded when includeTags is '
        'specified',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {noTagOp, getPetOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['pet'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getPetOp));
          expect(transformed.operations, isNot(contains(noTagOp)));
        },
      );

      test(
        'operation with no tags - is included when no filters specified',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {noTagOp, getPetOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig();

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(2));
          expect(transformed.operations, containsAll([noTagOp, getPetOp]));
        },
      );

      test(
        'operation with no tags - is included when only excludeTags specified',
        () {
          final document = ApiDocument(
            title: 'Test API',
            version: '1.0.0',
            models: const {},
            responseHeaders: const {},
            requestHeaders: const {},
            servers: const {},
            operations: {noTagOp, getPetOp},
            responses: const {},
            queryParameters: const {},
            pathParameters: const {},
            requestBodies: const {},
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['user'],
            ),
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(2));
          expect(transformed.operations, containsAll([noTagOp, getPetOp]));
        },
      );
    });

    group('filterByOperationId', () {
      test('returns all operations when excludeOperations is empty', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig();

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(3));
        expect(
          transformed.operations,
          containsAll([getPetOp, listPetsOp, getUserOp]),
        );
      });

      test('excludes operations by operationId', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(2));
        expect(transformed.operations, containsAll([listPetsOp, getUserOp]));
        expect(transformed.operations, isNot(contains(getPetOp)));
      });

      test('excludes multiple operations by operationId', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp, getUserOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet', 'listPets'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(getUserOp));
        expect(transformed.operations, isNot(contains(getPetOp)));
        expect(transformed.operations, isNot(contains(listPetsOp)));
      });

      test('handles operationId not in exclude list', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['nonExistentOp'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(2));
        expect(transformed.operations, containsAll([getPetOp, listPetsOp]));
      });

      test('returns empty set when all operations are excluded', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPetOp, listPetsOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet', 'listPets'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, isEmpty);
      });

      test('handles operations with null operationId', () {
        final noIdOp = Operation(
          context: ctx.push('paths').push('/noId').push('get'),
          tags: {petTag},
          isDeprecated: false,
          path: '/noId',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {noIdOp, getPetOp},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(noIdOp));
      });

      test('handles empty operations set', () {
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
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, isEmpty);
      });
    });

    group('filterSchemas', () {
      test('returns all models when excludeSchemas is empty', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {petModel, userModel, statusEnum},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig();

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, hasLength(3));
        expect(
          transformed.models,
          containsAll([petModel, userModel, statusEnum]),
        );
      });

      test('excludes model by name', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {petModel, userModel, statusEnum},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, hasLength(2));
        expect(transformed.models, containsAll([userModel, statusEnum]));
        expect(transformed.models, isNot(contains(petModel)));
      });

      test('excludes multiple models by name', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {petModel, userModel, statusEnum, idAlias},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet', 'Status'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, hasLength(2));
        expect(transformed.models, containsAll([userModel, idAlias]));
        expect(transformed.models, isNot(contains(petModel)));
        expect(transformed.models, isNot(contains(statusEnum)));
      });

      test('handles schema name not in exclude list', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {petModel, userModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['NonExistent'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, hasLength(2));
        expect(transformed.models, containsAll([petModel, userModel]));
      });

      test('returns empty set when all models are excluded', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {petModel, userModel},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet', 'User'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, isEmpty);
      });

      test('works with different model types', () {
        final document = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {petModel, statusEnum, idAlias},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Status'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, hasLength(2));
        expect(transformed.models, containsAll([petModel, idAlias]));
        expect(transformed.models, isNot(contains(statusEnum)));
      });

      test('handles empty models set', () {
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
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, isEmpty);
      });
    });
  });
}
