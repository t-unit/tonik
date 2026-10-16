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
      petTag = Tag(
        name: 'pet',
        description: 'Pet operations',
        nameOverride: null,
      );
      userTag = Tag(
        name: 'user',
        description: 'User operations',
        nameOverride: null,
      );
      storeTag = Tag(
        name: 'store',
        description: 'Store operations',
        nameOverride: null,
      );
      adminTag = Tag(
        name: 'admin',
        description: 'Admin operations',
        nameOverride: null,
      );

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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
      );

      // Models
      petModel = ClassModel(
        name: 'Pet',
        context: ctx.push('components').push('schemas').push('Pet'),
        isDeprecated: false,
        properties: const [],
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      userModel = ClassModel(
        name: 'User',
        context: ctx.push('components').push('schemas').push('User'),
        isDeprecated: false,
        properties: const [],
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      statusEnum = EnumModel<String>(
        name: 'Status',
        context: ctx.push('components').push('schemas').push('Status'),
        isDeprecated: false,
        isNullable: false,
        values: const {},
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final stringModel = ClassModel(
        name: 'String',
        context: ctx.push('String'),
        isDeprecated: false,
        properties: const [],
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      idAlias = AliasModel(
        name: 'Id',
        context: ctx.push('components').push('schemas').push('Id'),
        model: stringModel,
        examples: const [],
        defaultValue: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig.defaults;

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(4));
        expect(
          transformed.operations,
          containsAll([getPetOp, listPetsOp, getUserOp, getStoreOp]),
        );
      });

      test('includes only operations with matching tags when includeTags is '
          'specified', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(2));
        expect(transformed.operations, containsAll([getPetOp, listPetsOp]));
        expect(transformed.operations, isNot(contains(getUserOp)));
        expect(transformed.operations, isNot(contains(getStoreOp)));
      });

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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet', 'user'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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

      test('excludes operations with matching tags when excludeTags is '
          'specified', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeTags: ['store'],
            includeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeTags: ['store', 'user'],
            includeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        // Include pet and user, then exclude user
        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet', 'user'],
            excludeTags: ['user'],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(2));
        expect(transformed.operations, containsAll([getPetOp, listPetsOp]));
        expect(transformed.operations, isNot(contains(getUserOp)));
        expect(transformed.operations, isNot(contains(getStoreOp)));
      });

      test('handles operation with multiple tags - keeps if any tag matches '
          'include', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(petUserOp));
      });

      test('handles operation with multiple tags - excludes if any tag matches '
          'exclude', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeTags: ['user'],
            includeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(getPetOp));
        expect(transformed.operations, isNot(contains(petUserOp)));
      });

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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['user'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, isEmpty);
      });

      test('operation with two tags - both in includeTags - is included', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet', 'user'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(petUserOp));
      });

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
            cookieParameters: const {},
            requestBodies: const {},
            summary: null,
            description: null,
            contact: null,
            license: null,
            termsOfService: null,
            externalDocs: null,
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['user'],
              excludeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
            workerCount: 0,
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
            cookieParameters: const {},
            requestBodies: const {},
            summary: null,
            description: null,
            contact: null,
            license: null,
            termsOfService: null,
            externalDocs: null,
          );

          const config = TonikConfig(
            filter: FilterConfig(
              includeTags: ['store'],
              excludeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
            workerCount: 0,
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, hasLength(1));
          expect(transformed.operations, contains(getStoreOp));
          expect(transformed.operations, isNot(contains(petUserOp)));
        },
      );

      test('operation with two tags - both in excludeTags - is excluded', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeTags: ['pet', 'user'],
            includeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(getStoreOp));
        expect(transformed.operations, isNot(contains(petUserOp)));
      });

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
            cookieParameters: const {},
            requestBodies: const {},
            summary: null,
            description: null,
            contact: null,
            license: null,
            termsOfService: null,
            externalDocs: null,
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['pet'],
              includeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
            workerCount: 0,
          );

          const transformer = ConfigTransformer();
          final transformed = transformer.apply(document, config);

          expect(transformed.operations, isEmpty);
        },
      );

      test('operation with two tags - includeTags matches one, excludeTags '
          'matches the other - is excluded', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet', 'user'],
            excludeTags: ['store'],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(getUserOp));
        expect(transformed.operations, isNot(contains(petStoreOp)));
      });

      test('operation with three tags - complex include/exclude scenario', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        // Include pet (matches both), but exclude admin
        // (only matches tripleTagOp)
        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet'],
            excludeTags: ['admin'],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(getPetOp));
        expect(transformed.operations, isNot(contains(tripleTagOp)));
      });

      test('operation with no tags - is excluded when includeTags is '
          'specified', () {
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['pet'],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.operations, hasLength(1));
        expect(transformed.operations, contains(getPetOp));
        expect(transformed.operations, isNot(contains(noTagOp)));
      });

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
            cookieParameters: const {},
            requestBodies: const {},
            summary: null,
            description: null,
            contact: null,
            license: null,
            termsOfService: null,
            externalDocs: null,
          );

          const config = TonikConfig.defaults;

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
            cookieParameters: const {},
            requestBodies: const {},
            summary: null,
            description: null,
            contact: null,
            license: null,
            termsOfService: null,
            externalDocs: null,
          );

          const config = TonikConfig(
            filter: FilterConfig(
              excludeTags: ['user'],
              includeTags: [],
              excludeOperations: [],
              excludeSchemas: [],
            ),
            nameOverrides: NameOverridesConfig(
              schemas: {},
              properties: {},
              operations: {},
              parameters: {},
              enums: {},
              tags: {},
            ),
            contentTypes: {},
            contentMediaTypes: {},
            deprecated: DeprecatedConfig(
              operations: DeprecatedHandling.annotate,
              schemas: DeprecatedHandling.annotate,
              parameters: DeprecatedHandling.annotate,
              properties: DeprecatedHandling.annotate,
            ),
            enums: EnumConfig(
              generateUnknownCase: false,
              unknownCaseName: 'unknown',
            ),
            transport: TransportConfig(backend: TransportBackend.dio),
            useImmutableCollections: false,
            workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig.defaults;

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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet'],
            includeTags: [],
            excludeTags: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet', 'listPets'],
            includeTags: [],
            excludeTags: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['nonExistentOp'],
            includeTags: [],
            excludeTags: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet', 'listPets'],
            includeTags: [],
            excludeTags: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
          operationId: null,
          nameOverride: null,
          summary: null,
          description: null,
          requestBody: null,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet'],
            includeTags: [],
            excludeTags: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeOperations: ['getPet'],
            includeTags: [],
            excludeTags: [],
            excludeSchemas: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig.defaults;

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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet'],
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet', 'Status'],
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['NonExistent'],
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet', 'User'],
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Status'],
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
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
          cookieParameters: const {},
          requestBodies: const {},
          summary: null,
          description: null,
          contact: null,
          license: null,
          termsOfService: null,
          externalDocs: null,
        );

        const config = TonikConfig(
          filter: FilterConfig(
            excludeSchemas: ['Pet'],
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
          ),
          nameOverrides: NameOverridesConfig(
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.annotate,
            schemas: DeprecatedHandling.annotate,
            parameters: DeprecatedHandling.annotate,
            properties: DeprecatedHandling.annotate,
          ),
          enums: EnumConfig(
            generateUnknownCase: false,
            unknownCaseName: 'unknown',
          ),
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(document, config);

        expect(transformed.models, isEmpty);
      });
    });
  });
}
