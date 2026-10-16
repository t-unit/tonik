import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/tags', () {
    test('applies tag overrides without duplicating tag instances', () {
      final ctx = Context.initial();

      final sharedTag = Tag(
        name: 'pet',
        description: 'Pet tag',
        nameOverride: null,
      );

      final getPet = Operation(
        operationId: 'getPet',
        context: ctx.push('paths').push('/pet/{petId}').push('get'),
        tags: {sharedTag},
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
        tags: {sharedTag},
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
          tags: {'pet': 'animal'},
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
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

      final transformedGetPet = transformed.operations.firstWhere(
        (o) => o.operationId == 'getPet',
      );
      final transformedListPets = transformed.operations.firstWhere(
        (o) => o.operationId == 'listPets',
      );

      final getPetTag = transformedGetPet.tags.firstWhere(
        (t) => t.name == 'pet',
      );
      final listPetsTag = transformedListPets.tags.firstWhere(
        (t) => t.name == 'pet',
      );

      expect(getPetTag.nameOverride, 'animal');
      expect(listPetsTag.nameOverride, 'animal');

      expect(identical(getPetTag, sharedTag), isTrue);
      expect(identical(getPetTag, listPetsTag), isTrue);
    });
  });
}
