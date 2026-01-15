import 'dart:io';

import 'package:test/test.dart';
import 'package:tonik/src/config/config_loader.dart';
import 'package:tonik/src/config/log_level.dart';
import 'package:tonik/src/config/tonik_config.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tonik_config_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('load', () {
      test('returns default config when path is null', () {
        final config = ConfigLoader.load(null);

        expect(config, const CliConfig());
      });

      test('returns default config when file does not exist', () {
        final config = ConfigLoader.load('${tempDir.path}/nonexistent.yaml');

        expect(config, const CliConfig());
      });

      test('loads valid full YAML config', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
spec: ./openapi.yaml
outputDir: ./generated
packageName: my_api_client
logLevel: verbose

nameOverrides:
  schemas:
    UserDTO: User
  properties:
    "User.unique_identifier": id
  operations:
    GetAllUsers: listUsers
  parameters:
    "listUsers.max_results": limit
  enums:
    "Status.STATUS_ACTIVE": active
  tags:
    "User Management": UserApi

contentTypes:
  "application/problem+json": json
  "application/vnd.api+json": json

filter:
  includeTags:
    - Users
    - Orders
  excludeTags:
    - Internal
  excludeOperations:
    - legacyEndpoint
  excludeSchemas:
    - DeprecatedModel

deprecated:
  operations: exclude
  schemas: ignore
  parameters: exclude
  properties: annotate

enums:
  generateUnknownCase: true
  unknownCaseName: unrecognized
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.spec, './openapi.yaml');
        expect(config.outputDir, './generated');
        expect(config.packageName, 'my_api_client');
        expect(config.logLevel, LogLevel.verbose);

        expect(config.nameOverrides.schemas, {'UserDTO': 'User'});
        expect(
          config.nameOverrides.properties,
          {'User.unique_identifier': 'id'},
        );
        expect(
          config.nameOverrides.operations,
          {'GetAllUsers': 'listUsers'},
        );
        expect(
          config.nameOverrides.parameters,
          {'listUsers.max_results': 'limit'},
        );
        expect(config.nameOverrides.enums, {'Status.STATUS_ACTIVE': 'active'});
        expect(config.nameOverrides.tags, {'User Management': 'UserApi'});

        expect(config.contentTypes, {
          'application/problem+json': ContentType.json,
          'application/vnd.api+json': ContentType.json,
        });

        expect(config.filter.includeTags, ['Users', 'Orders']);
        expect(config.filter.excludeTags, ['Internal']);
        expect(config.filter.excludeOperations, ['legacyEndpoint']);
        expect(config.filter.excludeSchemas, ['DeprecatedModel']);

        expect(config.deprecated.operations, DeprecatedHandling.exclude);
        expect(config.deprecated.schemas, DeprecatedHandling.ignore);
        expect(config.deprecated.parameters, DeprecatedHandling.exclude);
        expect(config.deprecated.properties, DeprecatedHandling.annotate);

        expect(config.enums.generateUnknownCase, isTrue);
        expect(config.enums.unknownCaseName, 'unrecognized');
      });

      test('loads partial config with missing fields using defaults', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
spec: ./api.yaml
packageName: partial_api
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.spec, './api.yaml');
        expect(config.outputDir, isNull);
        expect(config.packageName, 'partial_api');
        expect(config.logLevel, isNull);

        expect(config.nameOverrides, const NameOverridesConfig());
        expect(config.contentTypes, isEmpty);
        expect(config.filter, const FilterConfig());
        expect(config.deprecated, const DeprecatedConfig());
        expect(config.enums, const EnumConfig());
      });

      test('loads config with only nameOverrides', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
nameOverrides:
  schemas:
    OldName: NewName
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.nameOverrides.schemas, {'OldName': 'NewName'});
        expect(config.nameOverrides.properties, isEmpty);
      });

      test('loads config with only filter', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
filter:
  includeTags:
    - Api
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.filter.includeTags, ['Api']);
        expect(config.filter.excludeTags, isEmpty);
      });

      test('loads config with only deprecated', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
deprecated:
  operations: annotate
  schemas: exclude
  parameters: ignore
  properties: exclude
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.deprecated.operations, DeprecatedHandling.annotate);
        expect(config.deprecated.schemas, DeprecatedHandling.exclude);
        expect(config.deprecated.parameters, DeprecatedHandling.ignore);
        expect(config.deprecated.properties, DeprecatedHandling.exclude);
      });

      test('loads config with partial deprecated fields uses defaults', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
deprecated:
  operations: exclude
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.deprecated.operations, DeprecatedHandling.exclude);
        expect(config.deprecated.schemas, DeprecatedHandling.annotate);
        expect(config.deprecated.parameters, DeprecatedHandling.annotate);
        expect(config.deprecated.properties, DeprecatedHandling.annotate);
      });

      test('loads config with only enums', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
enums:
  generateUnknownCase: true
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.enums.generateUnknownCase, isTrue);
        expect(config.enums.unknownCaseName, 'unknown');
      });

      test('throws meaningful error for invalid YAML', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
spec: [invalid yaml
  this is not valid
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse'),
            ),
          ),
        );
      });

      test('throws meaningful error for non-map root YAML', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
- item1
- item2
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error for invalid deprecated value', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
deprecated:
  operations: invalid_value
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('Invalid deprecated handling'),
            ),
          ),
        );
      });

      test('throws meaningful error when nameOverrides is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
nameOverrides: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"nameOverrides" must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error when filter is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
filter: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"filter" must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error when filter.includeTags is not a list', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
filter:
  includeTags: not_a_list
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"filter.includeTags" must be a list'),
            ),
          ),
        );
      });

      test('throws meaningful error when deprecated is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
deprecated: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"deprecated" must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error for invalid log level value', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
logLevel: invalid_level
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('Invalid log level'),
            ),
          ),
        );
      });

      test('throws meaningful error when enums is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
enums: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"enums" must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error when contentTypes is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
contentTypes: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"contentTypes" must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error for invalid content type value', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
contentTypes:
  "application/xml": xml
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('Invalid content type'),
            ),
          ),
        );
      });

      test('parses all ContentType enum values correctly', () {
        // Test all enum values to ensure none are missed when updating
        for (final contentType in ContentType.values) {
          final typeString = contentType.name;
          File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
contentTypes:
  "application/test": $typeString
''');

          final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

          expect(
            config.contentTypes['application/test'],
            contentType,
            reason:
                'ContentType.$typeString should be parsable from "$typeString"',
          );
        }
      });

      test('loads contentMediaTypes configuration', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
contentMediaTypes:
  "image/png": binary
  "image/jpeg": binary
  "text/csv": text
  "application/octet-stream": binary
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.contentMediaTypes, hasLength(4));
        expect(
          config.contentMediaTypes['image/png'],
          SchemaContentType.binary,
        );
        expect(
          config.contentMediaTypes['image/jpeg'],
          SchemaContentType.binary,
        );
        expect(
          config.contentMediaTypes['text/csv'],
          SchemaContentType.text,
        );
        expect(
          config.contentMediaTypes['application/octet-stream'],
          SchemaContentType.binary,
        );
      });

      test('throws meaningful error when contentMediaTypes is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
contentMediaTypes: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"contentMediaTypes" must be a map'),
            ),
          ),
        );
      });

      test('throws meaningful error for invalid contentMediaTypes value', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
contentMediaTypes:
  "image/png": invalid
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('Invalid schema content type'),
            ),
          ),
        );
      });

      test('throws meaningful error when schemas override is not a map', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
nameOverrides:
  schemas: not_a_map
''');

        expect(
          () => ConfigLoader.load('${tempDir.path}/tonik.yaml'),
          throwsA(
            isA<ConfigLoaderException>().having(
              (e) => e.message,
              'message',
              contains('"nameOverrides.schemas" must be a map'),
            ),
          ),
        );
      });

      test('loads empty config file as default config', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config, const CliConfig());
      });

      test('handles config with null values gracefully', () {
        File('${tempDir.path}/tonik.yaml').writeAsStringSync('''
spec: null
outputDir: null
nameOverrides:
  schemas:
''');

        final config = ConfigLoader.load('${tempDir.path}/tonik.yaml');

        expect(config.spec, isNull);
        expect(config.outputDir, isNull);
        expect(config.nameOverrides.schemas, isEmpty);
      });
    });

    group('merge', () {
      test('CLI arguments override config values', () {
        const config = CliConfig(
          spec: './config-spec.yaml',
          outputDir: './config-output',
          packageName: 'config_package',
          logLevel: LogLevel.info,
        );

        final merged = config.merge(
          spec: './cli-spec.yaml',
          outputDir: './cli-output',
          packageName: 'cli_package',
          logLevel: LogLevel.verbose,
        );

        expect(merged.spec, './cli-spec.yaml');
        expect(merged.outputDir, './cli-output');
        expect(merged.packageName, 'cli_package');
        expect(merged.logLevel, LogLevel.verbose);
      });

      test('null CLI arguments preserve config values', () {
        const config = CliConfig(
          spec: './config-spec.yaml',
          outputDir: './config-output',
          packageName: 'config_package',
          logLevel: LogLevel.info,
        );

        final merged = config.merge();

        expect(merged.spec, './config-spec.yaml');
        expect(merged.outputDir, './config-output');
        expect(merged.packageName, 'config_package');
        expect(merged.logLevel, LogLevel.info);
      });

      test('partial CLI arguments override only specified values', () {
        const config = CliConfig(
          spec: './config-spec.yaml',
          outputDir: './config-output',
          packageName: 'config_package',
          logLevel: LogLevel.info,
        );

        final merged = config.merge(
          spec: './cli-spec.yaml',
          logLevel: LogLevel.verbose,
        );

        expect(merged.spec, './cli-spec.yaml');
        expect(merged.outputDir, './config-output');
        expect(merged.packageName, 'config_package');
        expect(merged.logLevel, LogLevel.verbose);
      });

      test('merge preserves non-CLI config properties', () {
        const config = CliConfig(
          spec: './config-spec.yaml',
          nameOverrides: NameOverridesConfig(
            schemas: {'OldName': 'NewName'},
          ),
          contentTypes: {'application/problem+json': ContentType.json},
          filter: FilterConfig(includeTags: ['Api']),
          deprecated: DeprecatedConfig(
            operations: DeprecatedHandling.exclude,
          ),
          enums: EnumConfig(generateUnknownCase: true),
        );

        final merged = config.merge(spec: './cli-spec.yaml');

        expect(merged.spec, './cli-spec.yaml');
        expect(merged.nameOverrides.schemas, {'OldName': 'NewName'});
        expect(merged.contentTypes, {
          'application/problem+json': ContentType.json,
        });
        expect(merged.filter.includeTags, ['Api']);
        expect(merged.deprecated.operations, DeprecatedHandling.exclude);
        expect(merged.enums.generateUnknownCase, isTrue);
      });
    });
  });
}
