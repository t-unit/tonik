@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik/src/config/cli_config.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  late Directory directory;
  late String packageConfig;

  setUpAll(() async {
    packageConfig = (await Isolate.packageConfig)!.toFilePath();
  });
  setUp(() {
    directory = Directory.systemTemp.createTempSync('tonik_alias_exclusion_');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    'retained generated consumers compile with primitive types and defaults',
    () async {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'LegacyId': {
              'type': 'string',
              'deprecated': true,
              'default': 'fallback',
            },
            'Holder': {
              'type': 'object',
              'properties': {
                'id': {r'$ref': '#/components/schemas/LegacyId'},
              },
            },
          },
        },
      });
      final config = const CliConfig(
        deprecated: DeprecatedConfig(
          operations: DeprecatedHandling.annotate,
          schemas: DeprecatedHandling.exclude,
          parameters: DeprecatedHandling.annotate,
          properties: DeprecatedHandling.annotate,
        ),
      ).toTonikConfig();
      final transformed = const ConfigTransformer().apply(api, config);
      await const Generator().generate(
        apiDocument: transformed,
        outputDirectory: directory.path,
        package: 'alias_api',
        config: config,
      );
      final holder = File(
        path.join(directory.path, 'alias_api/lib/src/model/holder.dart'),
      );
      final excluded = File(
        path.join(directory.path, 'alias_api/lib/src/model/legacy_id.dart'),
      );
      expect(excluded.existsSync(), isFalse);
      expect(holder.readAsStringSync(), isNot(contains('legacy_id.dart')));
      expect(holder.readAsStringSync(), contains('String? id;'));
      final checker = File(path.join(directory.path, 'verify.dart'))
        ..writeAsStringSync('''
import 'dart:convert';
import 'alias_api/lib/src/model/holder.dart';

void main() {
  final provided = Holder.fromJson(const {'id': 'kept'});
  final defaulted = Holder.fromJson(const <String, Object?>{});
  final String? id = provided.id;
  print(jsonEncode({
    'id': id,
    'default': defaulted.id,
    'provided': provided.toJson(),
  }));
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        checker.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        (result.stdout as String).trim(),
        '{"id":"kept","default":"fallback","provided":{"id":"kept"}}',
      );
    },
  );

  test(
    'retained generated consumers preserve nullable primitive aliases',
    () async {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'LegacyId': {
              'type': ['string', 'null'],
              'deprecated': true,
            },
            'Holder': {
              'type': 'object',
              'required': ['id'],
              'properties': {
                'id': {r'$ref': '#/components/schemas/LegacyId'},
              },
            },
          },
        },
      });
      final config = const CliConfig(
        deprecated: DeprecatedConfig(
          operations: DeprecatedHandling.annotate,
          schemas: DeprecatedHandling.exclude,
          parameters: DeprecatedHandling.annotate,
          properties: DeprecatedHandling.annotate,
        ),
      ).toTonikConfig();
      final transformed = const ConfigTransformer().apply(api, config);
      await const Generator().generate(
        apiDocument: transformed,
        outputDirectory: directory.path,
        package: 'alias_api',
        config: config,
      );
      final holder = File(
        path.join(directory.path, 'alias_api/lib/src/model/holder.dart'),
      );
      expect(holder.readAsStringSync(), isNot(contains('legacy_id.dart')));
      expect(holder.readAsStringSync(), contains('String? id;'));
      final checker = File(path.join(directory.path, 'verify.dart'))
        ..writeAsStringSync('''
import 'dart:convert';
import 'alias_api/lib/src/model/holder.dart';

void main() {
  final value = Holder.fromJson(const {'id': null});
  final String? id = value.id;
  print(jsonEncode({'id': id, 'json': value.toJson()}));
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        checker.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        (result.stdout as String).trim(),
        '{"id":null,"json":{"id":null}}',
      );
    },
  );
}
