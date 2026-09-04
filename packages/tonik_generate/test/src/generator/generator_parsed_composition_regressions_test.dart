import 'dart:convert';
import 'dart:io';

import 'package:code_builder/code_builder.dart';

import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_body_generator.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('parsed self allOf multipart root rejects partial generation', () async {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': {
        '/upload': {
          'post': {
            'operationId': 'upload',
            'requestBody': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/A'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'A': {
            'allOf': [
              {r'$ref': '#/components/schemas/A'},
              {
                'type': 'object',
                'properties': {
                  'x': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    });
    final output = Directory.systemTemp.createTempSync('parsed-allof-cycle-');
    addTearDown(() => output.deleteSync(recursive: true));

    final generation = const Generator().generate(
      apiDocument: api,
      outputDirectory: output.path,
      package: 'test_package',
      config: const TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
      ),
    );

    await expectLater(generation, throwsA(anything));
  });

  test('parsed nullable class HTTP multipart uses its normal API', () async {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': {
        '/required': {
          'post': {
            'operationId': 'requiredUpload',
            'requestBody': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
        '/optional': {
          'post': {
            'operationId': 'optionalUpload',
            'requestBody': {
              'required': false,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'Upload': {
            'type': 'object',
            'nullable': true,
            'additionalProperties': false,
            'required': ['name'],
            'properties': {
              'name': {'type': 'string'},
            },
          },
        },
      },
    });
    final directory = Directory.systemTemp.createTempSync('parsed-multipart-');
    addTearDown(() => directory.deleteSync(recursive: true));
    await const Generator().generate(
      apiDocument: api,
      outputDirectory: directory.path,
      package: 'test_package',
      config: const TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
      ),
    );
    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final generator = HttpBodyGenerator(
      nameManager: manager,
      package: 'test_package',
    );
    final requiredMethod = generator
        .generateBodyMethod(
          api.operations.singleWhere(
            (operation) => operation.path == '/required',
          ),
        )
        .rebuild((builder) => builder.name = 'encodeRequired');
    final optionalMethod = generator
        .generateBodyMethod(
          api.operations.singleWhere(
            (operation) => operation.path == '/optional',
          ),
        )
        .rebuild((builder) => builder.name = 'encodeOptional');
    final sourceConfig = File.fromUri(Uri.parse(Platform.packageConfig!));
    final config =
        jsonDecode(sourceConfig.readAsStringSync()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    for (final package in packages.cast<Map<String, dynamic>>()) {
      package['rootUri'] = sourceConfig.uri
          .resolve(
            package['rootUri'] as String,
          )
          .toString();
    }
    packages.add({
      'name': 'test_package',
      'rootUri': Directory('${directory.path}/test_package').uri.toString(),
      'packageUri': 'lib/',
      'languageVersion': '3.11',
    });
    final packageConfig = File('${directory.path}/package_config.json')
      ..writeAsStringSync(jsonEncode(config));
    final script = File('${directory.path}/main.dart')
      ..writeAsStringSync('''
import 'dart:convert';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test_package/test_package.dart';
import 'package:tonik_util/tonik_util.dart';
${requiredMethod.accept(DartEmitter(useNullSafetySyntax: true))}
${optionalMethod.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final Upload body = const \$RawUpload(name: 'value');
  final encoded = await encodeRequired(body: body);
  final parts = encoded as List<MultipartFile>;
  if (parts.length != 1 || parts.first.field != 'name' ||
      utf8.decode(await parts.first.finalize().toBytes()) != 'value') {
    throw StateError('Normal model fields were not encoded.');
  }
  if (await encodeOptional(body: null) != null) {
    throw StateError('An absent optional body was encoded.');
  }
}
''');
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=${packageConfig.path}',
      script.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('parsed nullable alias HTTP multipart uses its normal API', () async {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': {
        '/required': {
          'post': {
            'operationId': 'requiredUpload',
            'requestBody': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
        '/optional': {
          'post': {
            'operationId': 'optionalUpload',
            'requestBody': {
              'required': false,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'BaseParts': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['name'],
            'properties': {
              'name': {'type': 'string'},
            },
          },
          'Upload': {
            r'$ref': '#/components/schemas/BaseParts',
            'nullable': true,
          },
        },
      },
    });
    final directory = Directory.systemTemp.createTempSync('parsed-multipart-');
    addTearDown(() => directory.deleteSync(recursive: true));
    await const Generator().generate(
      apiDocument: api,
      outputDirectory: directory.path,
      package: 'test_package',
      config: const TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
      ),
    );
    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final generator = HttpBodyGenerator(
      nameManager: manager,
      package: 'test_package',
    );
    final requiredMethod = generator
        .generateBodyMethod(
          api.operations.singleWhere(
            (operation) => operation.path == '/required',
          ),
        )
        .rebuild((builder) => builder.name = 'encodeRequired');
    final optionalMethod = generator
        .generateBodyMethod(
          api.operations.singleWhere(
            (operation) => operation.path == '/optional',
          ),
        )
        .rebuild((builder) => builder.name = 'encodeOptional');
    final sourceConfig = File.fromUri(Uri.parse(Platform.packageConfig!));
    final config =
        jsonDecode(sourceConfig.readAsStringSync()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    for (final package in packages.cast<Map<String, dynamic>>()) {
      package['rootUri'] = sourceConfig.uri
          .resolve(
            package['rootUri'] as String,
          )
          .toString();
    }
    packages.add({
      'name': 'test_package',
      'rootUri': Directory('${directory.path}/test_package').uri.toString(),
      'packageUri': 'lib/',
      'languageVersion': '3.11',
    });
    final packageConfig = File('${directory.path}/package_config.json')
      ..writeAsStringSync(jsonEncode(config));
    final script = File('${directory.path}/main.dart')
      ..writeAsStringSync('''
import 'dart:convert';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test_package/test_package.dart';
import 'package:tonik_util/tonik_util.dart';
${requiredMethod.accept(DartEmitter(useNullSafetySyntax: true))}
${optionalMethod.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final Upload body = const BaseParts(name: 'value');
  final encoded = await encodeRequired(body: body);
  final parts = encoded as List<MultipartFile>;
  if (parts.length != 1 || parts.first.field != 'name' ||
      utf8.decode(await parts.first.finalize().toBytes()) != 'value') {
    throw StateError('Normal model fields were not encoded.');
  }
  if (await encodeOptional(body: null) != null) {
    throw StateError('An absent optional body was encoded.');
  }
}
''');
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=${packageConfig.path}',
      script.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('parsed nullable allOf HTTP multipart uses its normal API', () async {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': {
        '/required': {
          'post': {
            'operationId': 'requiredUpload',
            'requestBody': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
        '/optional': {
          'post': {
            'operationId': 'optionalUpload',
            'requestBody': {
              'required': false,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
            'responses': {
              '204': {'description': 'Uploaded'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'BaseParts': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['name'],
            'properties': {
              'name': {'type': 'string'},
            },
          },
          'Other': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['count'],
            'properties': {
              'count': {'type': 'integer'},
            },
          },
          'Upload': {
            'nullable': true,
            'allOf': [
              {r'$ref': '#/components/schemas/BaseParts'},
              {r'$ref': '#/components/schemas/Other'},
            ],
          },
        },
      },
    });
    final directory = Directory.systemTemp.createTempSync('parsed-multipart-');
    addTearDown(() => directory.deleteSync(recursive: true));
    await const Generator().generate(
      apiDocument: api,
      outputDirectory: directory.path,
      package: 'test_package',
      config: const TonikConfig(
        transport: TransportConfig(backend: TransportBackend.http),
      ),
    );
    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final generator = HttpBodyGenerator(
      nameManager: manager,
      package: 'test_package',
    );
    final requiredMethod = generator
        .generateBodyMethod(
          api.operations.singleWhere(
            (operation) => operation.path == '/required',
          ),
        )
        .rebuild((builder) => builder.name = 'encodeRequired');
    final optionalMethod = generator
        .generateBodyMethod(
          api.operations.singleWhere(
            (operation) => operation.path == '/optional',
          ),
        )
        .rebuild((builder) => builder.name = 'encodeOptional');
    final sourceConfig = File.fromUri(Uri.parse(Platform.packageConfig!));
    final config =
        jsonDecode(sourceConfig.readAsStringSync()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    for (final package in packages.cast<Map<String, dynamic>>()) {
      package['rootUri'] = sourceConfig.uri
          .resolve(
            package['rootUri'] as String,
          )
          .toString();
    }
    packages.add({
      'name': 'test_package',
      'rootUri': Directory('${directory.path}/test_package').uri.toString(),
      'packageUri': 'lib/',
      'languageVersion': '3.11',
    });
    final packageConfig = File('${directory.path}/package_config.json')
      ..writeAsStringSync(jsonEncode(config));
    final script = File('${directory.path}/main.dart')
      ..writeAsStringSync('''
import 'dart:convert';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test_package/test_package.dart';
import 'package:tonik_util/tonik_util.dart';
${requiredMethod.accept(DartEmitter(useNullSafetySyntax: true))}
${optionalMethod.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final Upload body = const \$RawUpload(baseParts: BaseParts(name: 'value'), other: Other(count: 7));
  final encoded = await encodeRequired(body: body);
  final parts = encoded as List<MultipartFile>;
  if (parts.length != 2 || parts.first.field != 'name' ||
      utf8.decode(await parts.first.finalize().toBytes()) != 'value') {
    throw StateError('Normal model fields were not encoded.');
  }
  if (await encodeOptional(body: null) != null) {
    throw StateError('An absent optional body was encoded.');
  }
}
''');
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=${packageConfig.path}',
      script.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test(
    'parsed annotated allOf HTTP multipart uses normal member names',
    () async {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/required': {
            'post': {
              'operationId': 'requiredUpload',
              'requestBody': {
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Upload'},
                  },
                },
              },
              'responses': {
                '204': {'description': 'Uploaded'},
              },
            },
          },
          '/optional': {
            'post': {
              'operationId': 'optionalUpload',
              'requestBody': {
                'required': false,
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Upload'},
                  },
                },
              },
              'responses': {
                '204': {'description': 'Uploaded'},
              },
            },
          },
        },
        'components': {
          'schemas': {
            'BaseParts': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['name'],
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'Other': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['count'],
              'properties': {
                'count': {'type': 'integer'},
              },
            },
            'Upload': {
              'allOf': [
                {
                  r'$ref': '#/components/schemas/BaseParts',
                  'description': 'Annotated base',
                },
                {r'$ref': '#/components/schemas/Other'},
              ],
            },
          },
        },
      });
      final directory = Directory.systemTemp.createTempSync(
        'parsed-multipart-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      await const Generator().generate(
        apiDocument: api,
        outputDirectory: directory.path,
        package: 'test_package',
        config: const TonikConfig(
          transport: TransportConfig(backend: TransportBackend.http),
        ),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generator = HttpBodyGenerator(
        nameManager: manager,
        package: 'test_package',
      );
      final requiredMethod = generator
          .generateBodyMethod(
            api.operations.singleWhere(
              (operation) => operation.path == '/required',
            ),
          )
          .rebuild((builder) => builder.name = 'encodeRequired');
      final optionalMethod = generator
          .generateBodyMethod(
            api.operations.singleWhere(
              (operation) => operation.path == '/optional',
            ),
          )
          .rebuild((builder) => builder.name = 'encodeOptional');
      final sourceConfig = File.fromUri(Uri.parse(Platform.packageConfig!));
      final config =
          jsonDecode(sourceConfig.readAsStringSync()) as Map<String, dynamic>;
      final packages = config['packages'] as List<dynamic>;
      for (final package in packages.cast<Map<String, dynamic>>()) {
        package['rootUri'] = sourceConfig.uri
            .resolve(
              package['rootUri'] as String,
            )
            .toString();
      }
      packages.add({
        'name': 'test_package',
        'rootUri': Directory('${directory.path}/test_package').uri.toString(),
        'packageUri': 'lib/',
        'languageVersion': '3.11',
      });
      final packageConfig = File('${directory.path}/package_config.json')
        ..writeAsStringSync(jsonEncode(config));
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test_package/test_package.dart';
import 'package:tonik_util/tonik_util.dart';
${requiredMethod.accept(DartEmitter(useNullSafetySyntax: true))}
${optionalMethod.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final Upload body = const Upload(baseParts: BaseParts(name: 'value'), other: Other(count: 7));
  final encoded = await encodeRequired(body: body);
  final parts = encoded as List<MultipartFile>;
  if (parts.length != 2 || parts.first.field != 'name' ||
      utf8.decode(await parts.first.finalize().toBytes()) != 'value') {
    throw StateError('Normal model fields were not encoded.');
  }
  if (await encodeOptional(body: null) != null) {
    throw StateError('An absent optional body was encoded.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${packageConfig.path}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );
}
