import 'dart:io';

import 'package:test/test.dart';
import 'package:tonik/src/config/config_loader.dart';
import 'package:tonik/src/config/log_level.dart';
import 'package:tonik/src/config/tonik_config.dart';
import 'package:tonik_core/tonik_core.dart';

/// Helper to create a minimal ApiDocument for testing.
ApiDocument _createTestDocument() {
  final ctx = Context.initial();
  return ApiDocument(
    title: 'Test API',
    version: '1.0.0',
    models: {
      ClassModel(
        name: 'UserDTO',
        context: ctx.push('components').push('schemas').push('UserDTO'),
        properties: const [],
        isDeprecated: false,
      ),
    },
    operations: {
      Operation(
        operationId: 'getUser',
        context: ctx.push('paths').push('/user').push('get'),
        path: '/user',
        method: HttpMethod.get,
        tags: const {},
        isDeprecated: false,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        securitySchemes: const {},
      ),
    },
    responseHeaders: const {},
    requestHeaders: const {},
    servers: const {},
    responses: const {},
    queryParameters: const {},
    pathParameters: const {},
    requestBodies: const {},
  );
}

void main() {
  group('CLI Integration with Config File', () {
    late Directory tempDir;
    late String originalDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tonik_cli_test_');
      originalDir = Directory.current.path;
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('automatic config discovery', () {
      test('loads tonik.yaml from current directory when present', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./my-spec.yaml
outputDir: ./my-output
packageName: test_package
logLevel: verbose
''');

        final config = ConfigLoader.load('tonik.yaml');

        expect(config.spec, './my-spec.yaml');
        expect(config.outputDir, './my-output');
        expect(config.packageName, 'test_package');
        expect(config.logLevel, LogLevel.verbose);
      });

      test('uses default config when tonik.yaml not found', () {
        final config = ConfigLoader.load('tonik.yaml');

        expect(config, const CliConfig());
      });

      test('fails with error when tonik.yaml is invalid YAML', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./my-spec.yaml
  invalid: indentation
outputDir: test
''');

        expect(
          () => ConfigLoader.load('tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse config file'),
            ),
          ),
        );
      });

      test('fails with error when tonik.yaml is not a map', () {
        File('tonik.yaml').writeAsStringSync('''
- item1
- item2
''');

        expect(
          () => ConfigLoader.load('tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              'Config file must be a map',
            ),
          ),
        );
      });
    });

    group('CLI argument precedence', () {
      test('CLI --spec overrides config spec', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./config-spec.yaml
outputDir: ./output
packageName: test_package
''');

        final config = ConfigLoader.load('tonik.yaml');
        final merged = config.merge(spec: './cli-spec.yaml');

        expect(merged.spec, './cli-spec.yaml');
        expect(merged.outputDir, './output');
        expect(merged.packageName, 'test_package');
      });

      test('CLI --output-dir overrides config outputDir', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./spec.yaml
outputDir: ./config-output
packageName: test_package
''');

        final config = ConfigLoader.load('tonik.yaml');
        final merged = config.merge(outputDir: './cli-output');

        expect(merged.spec, './spec.yaml');
        expect(merged.outputDir, './cli-output');
        expect(merged.packageName, 'test_package');
      });

      test('CLI --package-name overrides config packageName', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./spec.yaml
outputDir: ./output
packageName: config_package
''');

        final config = ConfigLoader.load('tonik.yaml');
        final merged = config.merge(packageName: 'cli_package');

        expect(merged.spec, './spec.yaml');
        expect(merged.outputDir, './output');
        expect(merged.packageName, 'cli_package');
      });

      test('CLI --log-level overrides config logLevel', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./spec.yaml
outputDir: ./output
packageName: test_package
logLevel: verbose
''');

        final config = ConfigLoader.load('tonik.yaml');
        final merged = config.merge(logLevel: LogLevel.silent);

        expect(merged.spec, './spec.yaml');
        expect(merged.logLevel, LogLevel.silent);
      });

      test('merges all CLI args when provided', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./config-spec.yaml
outputDir: ./config-output
packageName: config_package
logLevel: info
''');

        final config = ConfigLoader.load('tonik.yaml');
        final merged = config.merge(
          spec: './cli-spec.yaml',
          outputDir: './cli-output',
          packageName: 'cli_package',
          logLevel: LogLevel.warn,
        );

        expect(merged.spec, './cli-spec.yaml');
        expect(merged.outputDir, './cli-output');
        expect(merged.packageName, 'cli_package');
        expect(merged.logLevel, LogLevel.warn);
      });

      test('preserves config values when CLI args not provided', () {
        File('tonik.yaml').writeAsStringSync('''
spec: ./config-spec.yaml
outputDir: ./config-output
packageName: config_package
logLevel: info
nameOverrides:
  schemas:
    User: Person
''');

        final config = ConfigLoader.load('tonik.yaml');
        final merged = config.merge();

        expect(merged.spec, './config-spec.yaml');
        expect(merged.outputDir, './config-output');
        expect(merged.packageName, 'config_package');
        expect(merged.logLevel, LogLevel.info);
        expect(merged.nameOverrides.schemas, {'User': 'Person'});
      });
    });

    group('ConfigTransformer integration', () {
      test('applies name overrides from config to ApiDocument', () {
        final doc = _createTestDocument();

        const config = TonikConfig(
          nameOverrides: NameOverridesConfig(
            schemas: {'UserDTO': 'User'},
            operations: {'getUser': 'fetchUser'},
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(doc, config);

        final model = transformed.models.first as ClassModel;
        expect(model.nameOverride, 'User');

        final operation = transformed.operations.first;
        expect(operation.nameOverride, 'fetchUser');
      });

      test('applies filters from config to ApiDocument', () {
        final ctx = Context.initial();
        final doc = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {
            ClassModel(
              name: 'User',
              context: ctx.push('components').push('schemas').push('User'),
              properties: const [],
              isDeprecated: false,
            ),
            ClassModel(
              name: 'Deprecated',
              context: ctx
                  .push('components')
                  .push('schemas')
                  .push('Deprecated'),
              properties: const [],
              isDeprecated: false,
            ),
          },
          operations: {
            Operation(
              operationId: 'getUser',
              context: ctx.push('paths').push('/user').push('get'),
              path: '/user',
              method: HttpMethod.get,
              tags: {Tag(name: 'Users')},
              isDeprecated: false,
              headers: const {},
              queryParameters: const {},
              pathParameters: const {},
              responses: const {},
              securitySchemes: const {},
            ),
            Operation(
              operationId: 'getInternal',
              context: ctx.push('paths').push('/internal').push('get'),
              path: '/internal',
              method: HttpMethod.get,
              tags: {Tag(name: 'Internal')},
              isDeprecated: false,
              headers: const {},
              queryParameters: const {},
              pathParameters: const {},
              responses: const {},
              securitySchemes: const {},
            ),
          },
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          filter: FilterConfig(
            includeTags: ['Users'],
            excludeSchemas: ['Deprecated'],
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(doc, config);

        expect(transformed.models.length, 1);
        expect((transformed.models.first as ClassModel).name, 'User');

        expect(transformed.operations.length, 1);
        expect(transformed.operations.first.operationId, 'getUser');
      });

      test('applies deprecation handling from config to ApiDocument', () {
        final ctx = Context.initial();
        final doc = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {
            ClassModel(
              name: 'User',
              context: ctx.push('components').push('schemas').push('User'),
              properties: const [],
              isDeprecated: true,
            ),
            ClassModel(
              name: 'Active',
              context: ctx.push('components').push('schemas').push('Active'),
              properties: const [],
              isDeprecated: false,
            ),
          },
          operations: {
            Operation(
              operationId: 'getUser',
              context: ctx.push('paths').push('/user').push('get'),
              path: '/user',
              method: HttpMethod.get,
              tags: const {},
              isDeprecated: true,
              headers: const {},
              queryParameters: const {},
              pathParameters: const {},
              responses: const {},
              securitySchemes: const {},
            ),
            Operation(
              operationId: 'getActive',
              context: ctx.push('paths').push('/active').push('get'),
              path: '/active',
              method: HttpMethod.get,
              tags: const {},
              isDeprecated: false,
              headers: const {},
              queryParameters: const {},
              pathParameters: const {},
              responses: const {},
              securitySchemes: const {},
            ),
          },
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.exclude,
            schemas: DeprecatedHandling.exclude,
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(doc, config);

        expect(transformed.models.length, 1);
        expect((transformed.models.first as ClassModel).name, 'Active');

        expect(transformed.operations.length, 1);
        expect(transformed.operations.first.operationId, 'getActive');
      });

      test('applies enum fallback from config to ApiDocument', () {
        final ctx = Context.initial();
        final doc = ApiDocument(
          title: 'Test API',
          version: '1.0.0',
          models: {
            EnumModel<String>(
              name: 'Status',
              context: ctx.push('components').push('schemas').push('Status'),
              isNullable: false,
              isDeprecated: false,
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
              },
            ),
          },
          operations: const {},
          responseHeaders: const {},
          requestHeaders: const {},
          servers: const {},
          responses: const {},
          queryParameters: const {},
          pathParameters: const {},
          requestBodies: const {},
        );

        const config = TonikConfig(
          enums: EnumConfig(
            generateUnknownCase: true,
            unknownCaseName: 'unrecognized',
          ),
        );

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(doc, config);

        final enumModel = transformed.models.first as EnumModel<String>;
        expect(enumModel.fallbackValue, isNotNull);
        expect(enumModel.fallbackValue?.value, 'unrecognized');
        expect(enumModel.fallbackValue?.nameOverride, 'unrecognized');
      });

      test('skips transformation when config has no overrides/filters', () {
        final doc = _createTestDocument();
        const config = TonikConfig();

        const transformer = ConfigTransformer();
        final transformed = transformer.apply(doc, config);

        expect(identical(transformed, doc), true);
        expect(transformed.models.length, 1);
        expect(transformed.operations.length, 1);
      });
    });
  });
}
