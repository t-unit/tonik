import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/tags', () {
    test('applies tag overrides without duplicating tag instances', () {
      final ctx = Context.initial();

      final sharedTag = Tag(name: 'pet', description: 'Pet tag');

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
        responses: const {},
        securitySchemes: const {},
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
        responses: const {},
        securitySchemes: const {},
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
        requestBodies: const {},
      );

      const config = TonikConfig(
        nameOverrides: NameOverridesConfig(tags: {'pet': 'animal'}),
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
