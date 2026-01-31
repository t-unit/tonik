import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/parameters', () {
    test(
      'applies parameter overrides without duplicating parameter instances',
      () {
        final ctx = Context.initial();

        final petIdParam = QueryParameterObject(
          name: 'petId',
          rawName: 'petId',
          description: null,
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: IntegerModel(context: ctx.push('petId')),
          encoding: QueryParameterEncoding.form,
          context: ctx.push('components').push('parameters').push('petId'),
        );

        final limitParam = QueryParameterObject(
          name: 'limit',
          rawName: 'limit',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: IntegerModel(context: ctx.push('limit')),
          encoding: QueryParameterEncoding.form,
          context: ctx.push('components').push('parameters').push('limit'),
        );

        final tag = Tag(name: 'pet', description: 'Pet tag');

        final getPet = Operation(
          operationId: 'getPet',
          context: ctx.push('paths').push('/pet/{petId}').push('get'),
          tags: {tag},
          isDeprecated: false,
          path: '/pet/{petId}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {petIdParam, limitParam},
          pathParameters: const {},
          cookieParameters: const {},
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
          operations: {getPet},
          responses: const {},
          queryParameters: {petIdParam, limitParam},
          pathParameters: const {},
          cookieParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          nameOverrides: NameOverridesConfig(
            parameters: {'getPet.petId': 'id'},
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(apiDocument, config);

        final transformedOp = transformed.operations.single;

        final opPetId = transformedOp.queryParameters
            .whereType<QueryParameterObject>()
            .firstWhere((p) => p.name == 'petId');
        final docPetId = transformed.queryParameters
            .whereType<QueryParameterObject>()
            .firstWhere((p) => p.name == 'petId');

        expect(opPetId.nameOverride, 'id');
        expect(docPetId.nameOverride, 'id');
        expect(identical(opPetId, docPetId), isTrue);
        expect(identical(opPetId, petIdParam), isTrue);
        final opLimit = transformedOp.queryParameters
            .whereType<QueryParameterObject>()
            .firstWhere((p) => p.name == 'limit');
        final docLimit = transformed.queryParameters
            .whereType<QueryParameterObject>()
            .firstWhere((p) => p.name == 'limit');

        expect(opLimit.nameOverride, isNull);
        expect(identical(opLimit, docLimit), isTrue);
        expect(identical(opLimit, limitParam), isTrue);
      },
    );
  });
}
