import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const spec = {
    'openapi': '3.1.1',
    'info': {'title': 'Items', 'version': '1'},
    'paths': {
      '/items/{id}': {
        'get': {
          'operationId': 'getItem',
          'tags': ['items'],
          'parameters': [
            {
              r'$ref': '#/components/parameters/Id',
              'description': 'Specific path',
            },
            {
              r'$ref': '#/components/parameters/Limit',
              'description': 'Specific query',
            },
            {
              r'$ref': '#/components/parameters/Token',
              'description': 'Specific header',
            },
          ],
          'responses': {
            '200': {'description': 'OK'},
          },
        },
      },
    },
    'components': {
      'parameters': {
        'Id': {
          'name': 'id',
          'in': 'path',
          'required': true,
          'deprecated': true,
          'description': 'Generic path',
          'schema': {'type': 'string'},
        },
        'Limit': {
          'name': 'limit',
          'in': 'query',
          'deprecated': true,
          'description': 'Generic query',
          'schema': {'type': 'integer'},
        },
        'Token': {
          'name': 'x-token',
          'in': 'header',
          'deprecated': true,
          'description': 'Generic header',
          'schema': {'type': 'string'},
        },
      },
    },
  };

  test('operation name overrides preserve descriptions and shared targets', () {
    final api = Importer().import(spec);
    const config = TonikConfig(
      nameOverrides: NameOverridesConfig(
        schemas: {},
        properties: {},
        operations: {},
        parameters: {
          'getItem.Id': 'itemId',
          'getItem.Limit': 'maximum',
          'getItem.Token': 'accessToken',
        },
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
      enums: EnumConfig(generateUnknownCase: false, unknownCaseName: 'unknown'),
      transport: TransportConfig(backend: TransportBackend.dio),
      useImmutableCollections: false,
      workerCount: 0,
    );

    final transformed = const ConfigTransformer().apply(api, config);
    final operation = transformed.operations.single;
    final path = operation.pathParameters.single.resolve();
    final query = operation.queryParameters.single.resolve();
    final header = operation.headers.single.resolve();

    expect(path.nameOverride, 'itemId');
    expect(query.nameOverride, 'maximum');
    expect(header.nameOverride, 'accessToken');
    expect(path.description, 'Specific path');
    expect(query.description, 'Specific query');
    expect(header.description, 'Specific header');
    expect(transformed.pathParameters.single.resolve().nameOverride, isNull);
    expect(transformed.queryParameters.single.resolve().nameOverride, isNull);
    expect(transformed.requestHeaders.single.resolve().nameOverride, isNull);
    expect(
      transformed.queryParameters.single.resolve().description,
      'Generic query',
    );
  });

  test('ignoring deprecation changes operation copies only', () {
    final api = Importer().import(spec);
    const config = TonikConfig(
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
        parameters: DeprecatedHandling.ignore,
        properties: DeprecatedHandling.annotate,
      ),
      enums: EnumConfig(generateUnknownCase: false, unknownCaseName: 'unknown'),
      transport: TransportConfig(backend: TransportBackend.dio),
      useImmutableCollections: false,
      workerCount: 0,
    );

    final transformed = const ConfigTransformer().apply(api, config);
    final operation = transformed.operations.single;
    final path = operation.pathParameters.single.resolve();
    final query = operation.queryParameters.single.resolve();
    final header = operation.headers.single.resolve();

    expect(path.isDeprecated, isFalse);
    expect(query.isDeprecated, isFalse);
    expect(header.isDeprecated, isFalse);
    expect(path.description, 'Specific path');
    expect(query.description, 'Specific query');
    expect(header.description, 'Specific header');
    expect(transformed.pathParameters.single.resolve().isDeprecated, isTrue);
    expect(transformed.queryParameters.single.resolve().isDeprecated, isTrue);
    expect(transformed.requestHeaders.single.resolve().isDeprecated, isTrue);
  });

  test('a parsed 3.1 query override appears in generated method docs', () {
    final api = Importer().import({
      'openapi': '3.1.1',
      'info': {'title': 'Items', 'version': '1'},
      'paths': {
        '/items': {
          'get': {
            'operationId': 'listItems',
            'summary': 'List items',
            'tags': ['items'],
            'parameters': [
              {
                r'$ref': '#/components/parameters/Limit',
                'description': 'Specific limit',
              },
            ],
            'responses': {
              '200': {'description': 'OK'},
            },
          },
        },
      },
      'components': {
        'parameters': {
          'Limit': {
            'name': 'limit',
            'in': 'query',
            'description': 'Generic limit',
            'schema': {'type': 'integer'},
          },
        },
      },
    });
    final nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final generator = ApiClientGenerator(
      nameManager: nameManager,
      package: 'items_api',
      backendGenerator: const DioBackendGenerator(),
      defaultsCache: OperationDefaultsCache(
        nameManager: nameManager,
        package: 'items_api',
      ),
    );
    final operation = api.operations.single;
    final generatedClass = generator.generateClass(
      {operation},
      operation.tags.single,
      [
        const Server(
          url: 'https://api.example.com',
          description: null,
          variables: [],
        ),
      ],
    );

    expect(api.queryParameters.single.resolve().description, 'Generic limit');
    expect(generatedClass.methods.single.docs, [
      '/// List items',
      '/// [limit] Specific limit',
    ]);
  });
}
