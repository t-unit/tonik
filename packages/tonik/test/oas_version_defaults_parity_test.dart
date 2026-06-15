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

  String generateAndRead({
    required Map<String, dynamic> spec,
    required String subdir,
    required String filename,
  }) {
    final api = Importer().import(spec);
    final outputDirectory = path.join(tempDir.path, subdir);
    Directory(outputDirectory).createSync(recursive: true);
    const Generator().generate(
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

      setUp(() {
        out30 = generateAndRead(
          spec: wrapSpec(
            openapiVersion: '3.0.4',
            name: className,
            schema: schema30,
          ),
          subdir: 'oas30',
          filename: filename,
        );
        out31 = generateAndRead(
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
          expect(out31, out30);
        },
      );
    },
  );
}
