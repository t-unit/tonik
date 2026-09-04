import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_file_generator.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator_factory.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';
import 'package:tonik_parse/tonik_parse.dart';

Map<String, dynamic> _spec({bool includeUntagged = true}) => {
  'openapi': '3.0.3',
  'info': {'title': 'Tags', 'version': '1.0.0'},
  'tags': [
    {
      'name': 'declared',
      'description': 'Declared operations',
      'x-dart-name': 'Management',
    },
  ],
  'paths': {
    for (final entry in {
      'first': ['Accounts', 'Zone', 'Accounts', 'declared'],
      'second': ['Accounts'],
      'hyphen': ['zone-name'],
      'underscore': ['zone_name'],
      if (includeUntagged) 'empty': <String>[],
      if (includeUntagged) 'missing': null,
    }.entries)
      '/${entry.key}': {
        'get': {
          'operationId': entry.key,
          if (entry.value != null) 'tags': entry.value,
          'responses': <String, dynamic>{},
        },
      },
  },
};

void main() {
  for (final backend in TransportBackend.values) {
    group('imported tag clients (${backend.name})', () {
      late Directory output;
      late ApiClientGenerator clientGenerator;
      late ApiClientFileGenerator fileGenerator;

      setUp(() {
        output = Directory.systemTemp.createTempSync('tonik_tags_');
        final names = NameManager(
          generator: NameGenerator(),
          stableModelSorter: StableModelSorter(),
        );
        clientGenerator = ApiClientGenerator(
          nameManager: names,
          package: 'tags_api',
          defaultsCache: OperationDefaultsCache(
            nameManager: names,
            package: 'tags_api',
          ),
          backendGenerator: transportBackendGeneratorFor(backend),
        );
        fileGenerator = ApiClientFileGenerator(
          apiClientGenerator: clientGenerator,
        );
      });

      tearDown(() => output.deleteSync(recursive: true));

      test('groups every operation, retaining multiple memberships', () {
        final api = Importer().import(_spec());
        final clients = [
          for (final entry in api.operationsByTag.entries)
            clientGenerator.generateClass(entry.value, entry.key, []),
          clientGenerator.generateClass(
            fileGenerator.getUntaggedOperations(api),
            ApiClientFileGenerator.defaultTag,
            [],
          ),
        ];

        expect(
          {
            for (final client in clients)
              client.name: client.methods.map((method) => method.name).toList(),
          },
          {
            'AccountsApi': ['first', 'second'],
            'ZoneApi': ['first'],
            'ManagementApi': ['first'],
            'ZoneNameApi': ['hyphen'],
            'ZoneNameApi2': ['underscore'],
            'DefaultApi': ['empty', 'missing'],
          },
        );
        for (final client in clients) {
          expect(client.fields, hasLength(client.methods.length));
          expect(
            client.constructors.single.initializers,
            hasLength(client.methods.length),
          );
        }
        expect(clients[2].docs, ['/// Declared operations']);

        final files = fileGenerator.writeFiles(
          apiDocument: api,
          outputDirectory: output.path,
          package: 'tags_api',
        );
        expect(
          files.map(path.basename),
          unorderedEquals([
            'accounts_api.dart',
            'zone_api.dart',
            'management_api.dart',
            'zone_name_api.dart',
            'zone_name_api2.dart',
            'default_api.dart',
          ]),
        );
      });

      test('fully tagged documents emit no default client', () {
        final api = Importer().import(_spec(includeUntagged: false));
        final files = fileGenerator.writeFiles(
          apiDocument: api,
          outputDirectory: output.path,
          package: 'tags_api',
        );
        expect(
          files.map(path.basename),
          unorderedEquals([
            'accounts_api.dart',
            'zone_api.dart',
            'management_api.dart',
            'zone_name_api.dart',
            'zone_name_api2.dart',
          ]),
        );
        expect(fileGenerator.getUntaggedOperations(api), isEmpty);
      });

      test('repeated imports generate identical names and client files', () {
        Map<String, String> generate() {
          final api = Importer().import(_spec());
          const ConfigTransformer().apply(
            api,
            const TonikConfig(
              nameOverrides: NameOverridesConfig(
                tags: {'Accounts': 'Customer'},
              ),
            ),
          );
          final names = NameManager(
            generator: NameGenerator(),
            stableModelSorter: StableModelSorter(),
          );
          final generator = ApiClientGenerator(
            nameManager: names,
            package: 'tags_api',
            defaultsCache: OperationDefaultsCache(
              nameManager: names,
              package: 'tags_api',
            ),
            backendGenerator: transportBackendGeneratorFor(backend),
          );
          return {
            for (final entry in api.operationsByTag.entries)
              generator.generate(entry.value, entry.key, []).filename: generator
                  .generate(entry.value, entry.key, [])
                  .code,
          };
        }

        final first = generate();
        expect(
          first.keys,
          unorderedEquals([
            'customer_api.dart',
            'zone_api.dart',
            'management_api.dart',
            'zone_name_api.dart',
            'zone_name_api2.dart',
          ]),
        );
        expect(generate(), first);
      });
    });
  }
}
