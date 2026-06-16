import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  late Directory tempDir;
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tonik_oas_parity_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<String> generateAndRead({
    required Map<String, dynamic> spec,
    required String subdir,
    required String filename,
  }) async {
    final api = Importer().import(spec);
    final outputDirectory = path.join(tempDir.path, subdir);
    Directory(outputDirectory).createSync(recursive: true);
    await const Generator().generate(
      apiDocument: api,
      outputDirectory: outputDirectory,
      package: 'parity_api',
    );
    final modelPath = path.join(
      outputDirectory,
      'parity_api',
      'lib',
      'src',
      'model',
      filename,
    );
    final raw = File(modelPath).readAsStringSync();
    return formatter.format(raw);
  }

  Map<String, dynamic> wrapSpec({
    required String openapiVersion,
    required String name,
    required Map<String, dynamic> schema,
  }) => <String, dynamic>{
    'openapi': openapiVersion,
    'info': <String, dynamic>{
      'title': 'Parity $openapiVersion',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'components': <String, dynamic>{
      'schemas': <String, dynamic>{name: schema},
    },
  };

  group(
    'OAS 3.0 / 3.1 parity — default keyword and nullability syntax',
    () {
      const className = 'ParityModel';
      const filename = 'parity_model.dart';

      final schema30 = <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'name': <String, dynamic>{'type': 'string', 'default': 'anon'},
          'count': <String, dynamic>{'type': 'integer', 'default': 0},
          'rate': <String, dynamic>{
            'type': 'number',
            'format': 'double',
            'default': 1.5,
          },
          'active': <String, dynamic>{'type': 'boolean', 'default': true},
          'nickname': <String, dynamic>{
            'type': 'string',
            'nullable': true,
            'default': null,
          },
          'title': <String, dynamic>{
            'type': 'string',
            'nullable': true,
            'default': 'Mx.',
          },
          'tags': <String, dynamic>{
            'type': 'array',
            'items': <String, dynamic>{'type': 'string'},
            'default': <String>['new', 'featured'],
          },
        },
      };

      final schema31 = <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'name': <String, dynamic>{'type': 'string', 'default': 'anon'},
          'count': <String, dynamic>{'type': 'integer', 'default': 0},
          'rate': <String, dynamic>{
            'type': 'number',
            'format': 'double',
            'default': 1.5,
          },
          'active': <String, dynamic>{'type': 'boolean', 'default': true},
          'nickname': <String, dynamic>{
            'type': <String>['string', 'null'],
            'default': null,
          },
          'title': <String, dynamic>{
            'type': <String>['string', 'null'],
            'default': 'Mx.',
          },
          'tags': <String, dynamic>{
            'type': 'array',
            'items': <String, dynamic>{'type': 'string'},
            'default': <String>['new', 'featured'],
          },
        },
      };

      late String out30;
      late String out31;

      setUp(() async {
        out30 = await generateAndRead(
          spec: wrapSpec(
            openapiVersion: '3.0.4',
            name: className,
            schema: schema30,
          ),
          subdir: 'oas30',
          filename: filename,
        );
        out31 = await generateAndRead(
          spec: wrapSpec(
            openapiVersion: '3.1.0',
            name: className,
            schema: schema31,
          ),
          subdir: 'oas31',
          filename: filename,
        );
      });

      test(
        '3.0 (nullable: true) and 3.1 (type: [.., null]) emit identical Dart '
        'for the same conceptual schema with defaults',
        () {
          expect(
            out30,
            contains("static const _i3.String nameDefault = r'anon';"),
          );
          expect(
            out30,
            contains('static const _i3.int countDefault = 0;'),
          );
          expect(
            out30,
            contains('static const _i3.double rateDefault = 1.5;'),
          );
          expect(
            out30,
            contains('static const _i3.bool activeDefault = true;'),
          );
          expect(
            out30,
            contains("static const _i3.String? titleDefault = r'Mx.';"),
          );
          expect(
            out30,
            contains('static const _i3.List<_i3.String> tagsDefault'),
          );
          expect(out30, contains(r"_$map.containsKey(r'name')"));
          expect(out30, contains(r"_$map.containsKey(r'tags')"));
          expect(out30, isNot(contains('nicknameDefault')));
          expect(out30, isNot(contains(r"_$map.containsKey(r'nickname')")));
          expect(out31, contains('nameDefault'));
          expect(out31, contains('tagsDefault'));
          expect(out31, isNot(contains('nicknameDefault')));
          expect(out31, isNot(contains(r"_$map.containsKey(r'nickname')")));
          expect(out31, out30);
        },
      );
    },
  );
}
