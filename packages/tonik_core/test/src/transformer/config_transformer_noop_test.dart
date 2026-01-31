import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/no-op', () {
    test('preserves identities when config is empty', () {
      final ctx = Context.initial();

      const active = EnumEntry<String>(value: 'active');
      final statusModel = EnumModel<String>(
        name: 'Status',
        values: {active},
        isNullable: false,
        context: ctx.push('Status'),
        isDeprecated: false,
      );

      final idProperty = Property(
        name: 'petId',
        model: IntegerModel(context: ctx.push('Pet').push('petId')),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      final petModel = ClassModel(
        name: 'Pet',
        properties: [idProperty],
        context: ctx.push('Pet'),
        isDeprecated: false,
      );

      final petTag = Tag(name: 'pet', description: 'Pet tag');

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

      final getPet = Operation(
        operationId: 'getPet',
        context: ctx.push('paths').push('/pet/{petId}').push('get'),
        tags: {petTag},
        isDeprecated: false,
        path: '/pet/{petId}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {petIdParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {petModel, statusModel},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {getPet},
        responses: const {},
        queryParameters: {petIdParam},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const transformer = ConfigTransformer();
      final transformed = transformer.apply(apiDocument, const TonikConfig());

      final transformedPet = transformed.models
          .whereType<ClassModel>()
          .firstWhere((m) => m.name == 'Pet');
      expect(identical(transformedPet, petModel), isTrue);
      expect(identical(transformedPet.properties.single, idProperty), isTrue);

      final transformedStatus = transformed.models
          .whereType<EnumModel<String>>()
          .firstWhere((m) => m.name == 'Status');
      expect(identical(transformedStatus, statusModel), isTrue);
      expect(identical(transformedStatus.values.single, active), isTrue);

      final transformedOp = transformed.operations.single;
      expect(identical(transformedOp, getPet), isTrue);
      expect(identical(transformedOp.tags.single, petTag), isTrue);

      final transformedParam = transformedOp.queryParameters
          .whereType<QueryParameterObject>()
          .single;
      expect(identical(transformedParam, petIdParam), isTrue);
      expect(
        identical(
          transformed.queryParameters.whereType<QueryParameterObject>().single,
          petIdParam,
        ),
        isTrue,
      );
    });
  });
}
