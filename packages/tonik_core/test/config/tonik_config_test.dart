import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('TonikConfig', () {
    test('accepts existing typed serialization maps', () {
      const types = <String, ContentType>{
        'application/example': ContentType.json,
      };
      const config = TonikConfig(
        contentTypes: types,
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
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

      expect(config.contentTypes, {'application/example': ContentType.json});
    });

    test('streaming mappings participate in value semantics', () {
      const config = TonikConfig(
        contentTypes: {
          'application/example': StreamingContentType.jsonSequence,
        },
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
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
      const sameConfig = TonikConfig(
        contentTypes: {
          'application/example': StreamingContentType.jsonSequence,
        },
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
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
      const otherFormat = TonikConfig(
        contentTypes: {'application/example': ContentType.json},
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
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

      expect(config, sameConfig);
      expect(config.hashCode, sameConfig.hashCode);
      expect(config == otherFormat, isFalse);
      expect(
        config.toString(),
        contains(
          'contentTypes: {application/example: StreamingContentType.jsonSequence}',
        ),
      );
    });

    test('default configuration preserves generation settings', () {
      const config = TonikConfig.defaults;

      expect(
        config.nameOverrides,
        const NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
      );
      expect(config.contentTypes, isEmpty);
      expect(config.contentMediaTypes, isEmpty);
      expect(
        config.filter,
        const FilterConfig(
          includeTags: [],
          excludeTags: [],
          excludeOperations: [],
          excludeSchemas: [],
        ),
      );
      expect(
        config.deprecated,
        const DeprecatedConfig(
          operations: DeprecatedHandling.annotate,
          schemas: DeprecatedHandling.annotate,
          parameters: DeprecatedHandling.annotate,
          properties: DeprecatedHandling.annotate,
        ),
      );
      expect(
        config.enums,
        const EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
      );
      expect(
        config.transport,
        const TransportConfig(backend: TransportBackend.dio),
      );
      expect(config.transport.backend, TransportBackend.dio);
      expect(config.useImmutableCollections, isFalse);
      expect(config.workerCount, 0);
    });

    test('stores transport configuration', () {
      const config = TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        useImmutableCollections: false,
        workerCount: 0,
      );

      expect(config.transport.backend, TransportBackend.http);
    });

    test('equality and hashCode include transport configuration', () {
      const httpConfig = TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        useImmutableCollections: false,
        workerCount: 0,
      );
      const sameHttpConfig = TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        useImmutableCollections: false,
        workerCount: 0,
      );
      const dioConfig = TonikConfig.defaults;

      expect(httpConfig, sameHttpConfig);
      expect(httpConfig.hashCode, sameHttpConfig.hashCode);
      expect(httpConfig == dioConfig, isFalse);
      expect(httpConfig.hashCode, isNot(dioConfig.hashCode));
    });

    test('toString includes transport configuration', () {
      const config = TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        useImmutableCollections: false,
        workerCount: 0,
      );

      expect(
        config.toString(),
        contains('transport: TransportConfig{backend: TransportBackend.http}'),
      );
    });

    test('stores contentMediaTypes configuration', () {
      const config = TonikConfig(
        contentMediaTypes: {
          'image/png': SchemaContentType.binary,
          'text/csv': SchemaContentType.text,
        },
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
        contentTypes: {},
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

      expect(config.contentMediaTypes, hasLength(2));
      expect(config.contentMediaTypes['image/png'], SchemaContentType.binary);
      expect(config.contentMediaTypes['text/csv'], SchemaContentType.text);
    });

    test('equality includes contentMediaTypes', () {
      const config1 = TonikConfig(
        contentMediaTypes: {'image/png': SchemaContentType.binary},
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
        contentTypes: {},
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
      const config2 = TonikConfig(
        contentMediaTypes: {'image/png': SchemaContentType.binary},
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
        contentTypes: {},
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
      const config3 = TonikConfig(
        contentMediaTypes: {'image/png': SchemaContentType.text},
        nameOverrides: NameOverridesConfig(
          schemas: {},
          properties: {},
          operations: {},
          parameters: {},
          enums: {},
          tags: {},
        ),
        contentTypes: {},
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

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('stores useImmutableCollections configuration', () {
      const config = TonikConfig(
        useImmutableCollections: true,
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        transport: TransportConfig(backend: TransportBackend.dio),
        workerCount: 0,
      );

      expect(config.useImmutableCollections, isTrue);
    });

    test('equality includes useImmutableCollections', () {
      const config1 = TonikConfig(
        useImmutableCollections: true,
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        transport: TransportConfig(backend: TransportBackend.dio),
        workerCount: 0,
      );
      const config2 = TonikConfig(
        useImmutableCollections: true,
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        transport: TransportConfig(backend: TransportBackend.dio),
        workerCount: 0,
      );
      const config3 = TonikConfig.defaults;

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('hashCode includes useImmutableCollections', () {
      const a = TonikConfig(
        useImmutableCollections: true,
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        transport: TransportConfig(backend: TransportBackend.dio),
        workerCount: 0,
      );
      const b = TonikConfig.defaults;
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('toString includes useImmutableCollections', () {
      const config = TonikConfig(
        useImmutableCollections: true,
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
        enums: EnumConfig(
          generateUnknownCase: false,
          unknownCaseName: 'unknown',
        ),
        transport: TransportConfig(backend: TransportBackend.dio),
        workerCount: 0,
      );
      expect(config.toString(), contains('useImmutableCollections: true'));
    });
  });

  group('SchemaContentType', () {
    test('has binary and text values', () {
      expect(SchemaContentType.values, contains(SchemaContentType.binary));
      expect(SchemaContentType.values, contains(SchemaContentType.text));
    });
  });
}
