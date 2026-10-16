import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigTransformer/enums', () {
    test(
      'applies enum value overrides and preserves non-overridden identity',
      () {
        final ctx = Context.initial();

        const active = EnumEntry<String>(value: 'active', nameOverride: null);

        const inactive = EnumEntry<String>(
          value: 'inactive',
          nameOverride: null,
        );

        final statusModel = EnumModel<String>(
          name: 'Status',
          values: {active, inactive},
          isNullable: false,
          context: ctx.push('Status'),
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          defaultValue: null,
          fallbackValue: null,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final apiDocument = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {statusModel},
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
            enums: {'Status.active': 'isActive'},
            schemas: {},
            properties: {},
            operations: {},
            parameters: {},
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

        final transformedStatus = transformed.models
            .whereType<EnumModel<String>>()
            .firstWhere((m) => m.name == 'Status');

        expect(identical(transformedStatus, statusModel), isTrue);

        final transformedActive = transformedStatus.values.firstWhere(
          (e) => e.value == 'active',
        );
        final transformedInactive = transformedStatus.values.firstWhere(
          (e) => e.value == 'inactive',
        );

        expect(transformedActive.nameOverride, 'isActive');
        expect(identical(transformedActive, active), isFalse);

        expect(transformedInactive.nameOverride, isNull);
        expect(identical(transformedInactive, inactive), isTrue);
      },
    );

    test(
      'adds fallback value to String enum when generateUnknownCase is true',
      () {
        final ctx = Context.initial();

        const active = EnumEntry<String>(value: 'active', nameOverride: null);
        const inactive = EnumEntry<String>(
          value: 'inactive',
          nameOverride: null,
        );

        final statusModel = EnumModel<String>(
          name: 'Status',
          values: {active, inactive},
          isNullable: false,
          context: ctx.push('Status'),
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          defaultValue: null,
          fallbackValue: null,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final apiDocument = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {statusModel},
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
          enums: EnumConfig(
            generateUnknownCase: true,
            unknownCaseName: 'unknown',
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
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(apiDocument, config);

        final transformedStatus = transformed.models
            .whereType<EnumModel<String>>()
            .firstWhere((m) => m.name == 'Status');

        expect(identical(transformedStatus, statusModel), isTrue);
        expect(transformedStatus.fallbackValue, isNotNull);
        expect(transformedStatus.fallbackValue!.value, 'unknown');
        expect(transformedStatus.fallbackValue!.nameOverride, 'unknown');
      },
    );

    test(
      'adds fallback value to int enum when generateUnknownCase is true',
      () {
        final ctx = Context.initial();

        const zero = EnumEntry<int>(value: 0, nameOverride: null);
        const one = EnumEntry<int>(value: 1, nameOverride: null);

        final codeModel = EnumModel<int>(
          name: 'Code',
          values: {zero, one},
          isNullable: false,
          context: ctx.push('Code'),
          isDeprecated: false,
          examples: const [],
          nameOverride: null,
          description: null,
          defaultValue: null,
          fallbackValue: null,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final apiDocument = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {codeModel},
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
          enums: EnumConfig(
            generateUnknownCase: true,
            unknownCaseName: 'unknown',
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
          transport: TransportConfig(backend: TransportBackend.dio),
          useImmutableCollections: false,
          workerCount: 0,
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(apiDocument, config);

        final transformedCode = transformed.models
            .whereType<EnumModel<int>>()
            .firstWhere((m) => m.name == 'Code');

        expect(identical(transformedCode, codeModel), isTrue);
        expect(transformedCode.fallbackValue, isNotNull);
        expect(transformedCode.fallbackValue!.value, -1);
        expect(transformedCode.fallbackValue!.nameOverride, 'unknown');
      },
    );

    test('uses custom unknownCaseName for fallback', () {
      final ctx = Context.initial();

      const active = EnumEntry<String>(value: 'active', nameOverride: null);

      final statusModel = EnumModel<String>(
        name: 'Status',
        values: {active},
        isNullable: false,
        context: ctx.push('Status'),
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {statusModel},
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
        enums: EnumConfig(
          generateUnknownCase: true,
          unknownCaseName: 'fallback',
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
        transport: TransportConfig(backend: TransportBackend.dio),
        useImmutableCollections: false,
        workerCount: 0,
      );

      const transformer = ConfigTransformer();
      final transformed = transformer.apply(apiDocument, config);

      final transformedStatus = transformed.models
          .whereType<EnumModel<String>>()
          .firstWhere((m) => m.name == 'Status');

      expect(transformedStatus.fallbackValue, isNotNull);
      expect(transformedStatus.fallbackValue!.value, 'fallback');
      expect(transformedStatus.fallbackValue!.nameOverride, 'fallback');
    });

    test('does not add fallback when generateUnknownCase is false', () {
      final ctx = Context.initial();

      const active = EnumEntry<String>(value: 'active', nameOverride: null);

      final statusModel = EnumModel<String>(
        name: 'Status',
        values: {active},
        isNullable: false,
        context: ctx.push('Status'),
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {statusModel},
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
      final transformed = transformer.apply(apiDocument, config);

      final transformedStatus = transformed.models
          .whereType<EnumModel<String>>()
          .firstWhere((m) => m.name == 'Status');

      expect(transformedStatus.fallbackValue, isNull);
    });

    test('applies fallback to multiple enums', () {
      final ctx = Context.initial();

      final statusModel = EnumModel<String>(
        name: 'Status',
        values: {const EnumEntry<String>(value: 'active', nameOverride: null)},
        isNullable: false,
        context: ctx.push('Status'),
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final roleModel = EnumModel<String>(
        name: 'Role',
        values: {const EnumEntry<String>(value: 'admin', nameOverride: null)},
        isNullable: false,
        context: ctx.push('Role'),
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final apiDocument = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {statusModel, roleModel},
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
        enums: EnumConfig(
          generateUnknownCase: true,
          unknownCaseName: 'unknown',
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
        transport: TransportConfig(backend: TransportBackend.dio),
        useImmutableCollections: false,
        workerCount: 0,
      );

      const transformer = ConfigTransformer();
      final transformed = transformer.apply(apiDocument, config);

      final transformedStatus = transformed.models
          .whereType<EnumModel<String>>()
          .firstWhere((m) => m.name == 'Status');
      final transformedRole = transformed.models
          .whereType<EnumModel<String>>()
          .firstWhere((m) => m.name == 'Role');

      expect(transformedStatus.fallbackValue, isNotNull);
      expect(transformedRole.fallbackValue, isNotNull);
    });
  });
}
