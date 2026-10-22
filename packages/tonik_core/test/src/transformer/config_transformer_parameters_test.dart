import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/parameters', () {
    test('keeps operation parameter overrides separate from '
        'shared component instances', () {
      final ctx = Context.initial();

      final petIdParam = QueryParameterObject(
        name: null,
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
        examples: const [],
        defaultValue: null,
        nameOverride: null,
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
        examples: const [],
        defaultValue: null,
        nameOverride: null,
      );

      final sessionParam = CookieParameterObject(
        name: null,
        rawName: 'session_id',
        description: null,
        isRequired: false,
        isDeprecated: false,
        explode: true,
        model: StringModel(context: ctx.push('session_id')),
        encoding: CookieParameterEncoding.form,
        context: ctx.push('paths').push('/pet/{petId}').push('get'),
        examples: const [],
        defaultValue: null,
        nameOverride: null,
      );

      final tag = Tag(name: 'pet', description: 'Pet tag', nameOverride: null);

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
        cookieParameters: {sessionParam},
        responses: const {},
        securitySchemes: const {},
        nameOverride: null,
        summary: null,
        description: null,
        requestBody: null,
      );

      final listPets = Operation(
        operationId: 'listPets',
        context: ctx.push('paths').push('/pets').push('get'),
        tags: {tag},
        isDeprecated: false,
        path: '/pets',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {petIdParam},
        pathParameters: const {},
        cookieParameters: {sessionParam},
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
        queryParameters: {petIdParam, limitParam},
        pathParameters: const {},
        cookieParameters: {sessionParam},
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
          parameters: {'getPet.petId': 'id', 'getPet.session_id': 'session'},
          schemas: {},
          properties: {},
          operations: {'getPet': 'fetchPet'},
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

      final transformedOp = transformed.operations.firstWhere(
        (op) => op.operationId == 'getPet',
      );

      final opPetId = transformedOp.queryParameters
          .whereType<QueryParameterObject>()
          .firstWhere((p) => p.rawName == 'petId');
      final docPetId = transformed.queryParameters
          .whereType<QueryParameterObject>()
          .firstWhere((p) => p.rawName == 'petId');

      expect(opPetId.nameOverride, 'id');
      expect(opPetId.rawName, 'petId');
      expect(transformedOp.nameOverride, 'fetchPet');
      expect(docPetId.nameOverride, isNull);
      expect(listPets.queryParameters.single.resolve().nameOverride, isNull);
      expect(identical(opPetId, docPetId), isFalse);
      expect(identical(opPetId, petIdParam), isFalse);
      expect(identical(listPets.queryParameters.single, petIdParam), isTrue);
      final opLimit = transformedOp.queryParameters
          .whereType<QueryParameterObject>()
          .firstWhere((p) => p.name == 'limit');
      final docLimit = transformed.queryParameters
          .whereType<QueryParameterObject>()
          .firstWhere((p) => p.name == 'limit');

      expect(opLimit.nameOverride, isNull);
      expect(identical(opLimit, docLimit), isTrue);
      expect(identical(opLimit, limitParam), isTrue);
      expect(
        transformedOp.cookieParameters.single.resolve().nameOverride,
        'session',
      );
      expect(transformedOp.cookieParameters.single, isNot(same(sessionParam)));
      expect(listPets.cookieParameters.single, same(sessionParam));
      expect(listPets.cookieParameters.single.resolve().nameOverride, isNull);
      expect(
        transformed.cookieParameters.single.resolve().nameOverride,
        isNull,
      );
    });
  });
}
