import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/models', () {
    test(
      'applies schema name overrides and preserves non-overridden identity',
      () {
        final ctx = Context.initial();

        final petModel = ClassModel(
          name: 'Pet',
          properties: const [],
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
        final userModel = ClassModel(
          name: 'User',
          properties: const [],
          context: ctx.push('User'),
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
          nameOverrides: NameOverridesConfig(
            schemas: {'Pet': 'Animal'},
            properties: {},
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

        expect(
          transformed.models.whereType<ClassModel>().map((m) => m.name).toSet(),
          {'Pet', 'User'},
        );

        final transformedPet = transformed.models
            .whereType<ClassModel>()
            .firstWhere((m) => m.name == 'Pet');
        expect(transformedPet.nameOverride, 'Animal');
        expect(identical(transformedPet, petModel), isTrue);

        final transformedUser = transformed.models
            .whereType<ClassModel>()
            .firstWhere((m) => m.name == 'User');
        expect(transformedUser.nameOverride, isNull);
        expect(identical(transformedUser, userModel), isTrue);
      },
    );
  });
}
