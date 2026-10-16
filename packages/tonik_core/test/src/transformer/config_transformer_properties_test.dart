import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/properties', () {
    test('applies property overrides and does not duplicate properties', () {
      final ctx = Context.initial();

      final idProperty = Property(
        name: 'petId',
        model: IntegerModel(context: ctx.push('Pet').push('petId')),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
        isReadOnly: false,
        isWriteOnly: false,
        nameOverride: null,
        description: null,
      );

      final nameProperty = Property(
        name: 'name',
        model: StringModel(context: ctx.push('Pet').push('name')),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
        isReadOnly: false,
        isWriteOnly: false,
        nameOverride: null,
        description: null,
      );

      final petModel = ClassModel(
        name: 'Pet',
        properties: [idProperty, nameProperty],
        context: ctx.push('Pet'),
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {petModel},
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
        nameOverrides: NameOverridesConfig(
          properties: {'Pet.petId': 'id'},
          schemas: {},
          operations: {},
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

      final transformedPet = transformed.models
          .whereType<ClassModel>()
          .firstWhere((m) => m.name == 'Pet');

      expect(transformedPet.properties, hasLength(2));

      final transformedId = transformedPet.properties.firstWhere(
        (p) => p.name == 'petId',
      );
      expect(transformedId.nameOverride, 'id');
      expect(identical(transformedId, idProperty), isTrue);

      final transformedName = transformedPet.properties.firstWhere(
        (p) => p.name == 'name',
      );
      expect(transformedName.nameOverride, isNull);
      expect(identical(transformedName, nameProperty), isTrue);
    });
  });
}
