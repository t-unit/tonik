import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/config_transformer.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/operations', () {
    test(
      'applies operation overrides and preserves non-overridden identity',
      () {
        final ctx = Context.initial();

        final tag = Tag(name: 'pet', description: 'Pet tag');

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
          responses: const {},
          securitySchemes: const {},
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
          nameOverrides: NameOverridesConfig(
            operations: {'getPet': 'fetchPet'},
          ),
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
