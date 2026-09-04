import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
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
          'responses': {
            '204': {'description': 'Success'},
          },
        },
      },
  },
};

void main() {
  for (final backend in TransportBackend.values) {
    group('operation tag generation (${backend.name})', () {
      late Directory output;
      var generation = 0;

      setUp(() {
        output = Directory.systemTemp.createTempSync('tonik_tags_');
        generation = 0;
      });

      tearDown(() => output.deleteSync(recursive: true));

      Future<Map<String, String>> generate(
        Map<String, dynamic> spec, {
        NameOverridesConfig overrides = const NameOverridesConfig(),
      }) async {
        final config = TonikConfig(
          transport: TransportConfig(backend: backend),
          nameOverrides: overrides,
        );
        final api = const ConfigTransformer().apply(
          Importer().import(spec),
          config,
        );
        final directory = path.join(output.path, '${generation++}');
        await const Generator().generate(
          apiDocument: api,
          outputDirectory: directory,
          package: 'tags_api',
          config: config,
        );
        final clients = Directory(
          path.join(directory, 'tags_api', 'lib', 'src', 'api_client'),
        );
        return {
          for (final file in clients.listSync().whereType<File>())
            path.basename(file.path): file.readAsStringSync(),
        };
      }

      test('matches declared tag clients with all memberships', () async {
        final actual = await generate(_spec());
        final declared = _spec();
        (declared['tags'] as List<Map<String, String>>).addAll([
          {'name': 'Accounts'},
          {'name': 'Zone'},
          {'name': 'zone-name'},
          {'name': 'zone_name'},
        ]);

        expect(
          actual.keys,
          unorderedEquals([
            'accounts_api.dart',
            'zone_api.dart',
            'management_api.dart',
            'zone_name_api.dart',
            'zone_name_api2.dart',
            'default_api.dart',
          ]),
        );
        // Compare complete generated files with equivalent declared tags.
        expect(actual, await generate(declared));
      });

      test(
        'fully tagged documents need no declarations or default client',
        () async {
          final spec = _spec(includeUntagged: false)..remove('tags');
          final clients = await generate(spec);

          expect(
            clients.keys,
            unorderedEquals([
              'accounts_api.dart',
              'zone_api.dart',
              'declared_api.dart',
              'zone_name_api.dart',
              'zone_name_api2.dart',
            ]),
          );
        },
      );

      test(
        'repeated imports retain overrides and deterministic collisions',
        () async {
          const overrides = NameOverridesConfig(tags: {'Accounts': 'Customer'});
          final first = await generate(_spec(), overrides: overrides);

          expect(
            first.keys,
            unorderedEquals([
              'customer_api.dart',
              'zone_api.dart',
              'management_api.dart',
              'zone_name_api.dart',
              'zone_name_api2.dart',
              'default_api.dart',
            ]),
          );
          expect(await generate(_spec(), overrides: overrides), first);
        },
      );
    });
  }
}
