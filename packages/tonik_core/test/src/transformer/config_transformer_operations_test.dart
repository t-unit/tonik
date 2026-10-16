import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/operations', () {
    test(
      'applies operation overrides and preserves non-overridden identity',
      () {
        final ctx = Context.initial();

        final tag = Tag(
          name: 'pet',
          description: 'Pet tag',
          nameOverride: null,
        );

        final getPet = Operation(
          operationId: 'getPet',
          context: ctx.push('paths').push('/pet/{petId}').push('get'),
          tags: {tag},
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

        final listPets = Operation(
          operationId: 'listPets',
          context: ctx.push('paths').push('/pet').push('get'),
          tags: {tag},
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

        final apiDocument = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          operations: {getPet, listPets},
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
          nameOverrides: NameOverridesConfig(
            operations: {'getPet': 'fetchPet'},
            schemas: {},
            properties: {},
            parameters: {},
            enums: {},
            tags: {},
          ),
          contentTypes: {},
          contentMediaTypes: {},
          filter: FilterConfig(
            includeTags: [],
            excludeTags: [],
            excludeOperations: [],
            excludeSchemas: [],
          ),
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
        final transformed = transformer.apply(apiDocument, config);

        expect(transformed.operations, hasLength(2));

        final transformedGetPet = transformed.operations.firstWhere(
          (o) => o.operationId == 'getPet',
        );
        expect(transformedGetPet.nameOverride, 'fetchPet');
        expect(identical(transformedGetPet, getPet), isTrue);

        final transformedListPets = transformed.operations.firstWhere(
          (o) => o.operationId == 'listPets',
        );
        expect(transformedListPets.nameOverride, isNull);
        expect(identical(transformedListPets, listPets), isTrue);
      },
    );
  });
}
