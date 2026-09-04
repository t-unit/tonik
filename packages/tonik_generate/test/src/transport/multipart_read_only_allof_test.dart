import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/dio/dio_multipart_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'HTTP readOnly allOf root rejects multipart generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'ReadOnly', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Server': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['shared'],
              'properties': {
                'shared': {'type': 'string'},
              },
            },
            'Revision': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['revision'],
              'properties': {
                'revision': {'type': 'integer'},
              },
            },
            'ReadOnlyGroup': {
              'readOnly': true,
              'additionalProperties': false,
              'allOf': [
                {r'$ref': '#/components/schemas/Server'},
                {r'$ref': '#/components/schemas/Revision'},
              ],
            },
          },
          'requestBodies': {
            'Multipart': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/ReadOnlyGroup'},
                },
              },
            },
          },
        },
      });
      final content =
          api.requestBodies.whereType<RequestBodyObject>().single.content.single
              as MultipartRequestContent;
      expect(content.model, isA<AllOfModel>());
      final readOnly = api.models.whereType<AllOfModel>().singleWhere(
        (model) => model.name == 'ReadOnlyGroup',
      );
      expect(readOnly.isReadOnly, isTrue);
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final allOf = AllOfGenerator(
        nameManager: manager,
        package: 'example',
        stableModelSorter: StableModelSorter(),
      );
      final generatedReadOnly = allOf.generateClass(readOnly);
      expect(generatedReadOnly.fields.map((field) => field.name), [
        'server',
        'revision',
      ]);
      expect(
        generatedReadOnly.fields.map(
          (field) => field.type!
              .accept(DartEmitter(useNullSafetySyntax: true))
              .toString(),
        ),
        ['Server?', 'Revision?'],
      );
      expect(
        () => MultipartBodyPlanner(
          backend: TransportBackend.http,
          nameManager: manager,
          package: 'example',
        ).plan(content, bodyAccessor: 'body', isRequired: true),
        throwsA(anything),
      );
    },
  );

  test('HTTP nested readOnly allOf excludes fields and requiredness', () async {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'ReadOnly', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Server': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['shared'],
            'properties': {
              'shared': {'type': 'string'},
            },
          },
          'Revision': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['revision'],
            'properties': {
              'revision': {'type': 'integer'},
            },
          },
          'ReadOnlyGroup': {
            'readOnly': true,
            'additionalProperties': false,
            'allOf': [
              {r'$ref': '#/components/schemas/Server'},
              {r'$ref': '#/components/schemas/Revision'},
            ],
          },
          'Writable': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['name'],
            'properties': {
              'shared': {'type': 'string'},
              'name': {'type': 'string'},
            },
          },
          'Upload': {
            'additionalProperties': false,
            'allOf': [
              {r'$ref': '#/components/schemas/ReadOnlyGroup'},
              {r'$ref': '#/components/schemas/Writable'},
            ],
          },
        },
        'requestBodies': {
          'Multipart': {
            'required': true,
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/Upload'},
              },
            },
          },
        },
      },
    });
    final content =
        api.requestBodies.whereType<RequestBodyObject>().single.content.single
            as MultipartRequestContent;
    expect(content.model, isA<AllOfModel>());
    final readOnly = api.models.whereType<AllOfModel>().singleWhere(
      (model) => model.name == 'ReadOnlyGroup',
    );
    expect(readOnly.isReadOnly, isTrue);
    final manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final classes = ClassGenerator(nameManager: manager, package: 'example');
    final allOf = AllOfGenerator(
      nameManager: manager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    final generatedReadOnly = allOf.generateClass(readOnly);
    expect(generatedReadOnly.fields.map((field) => field.name), [
      'server',
      'revision',
    ]);
    expect(
      generatedReadOnly.fields.map(
        (field) => field.type!
            .accept(DartEmitter(useNullSafetySyntax: true))
            .toString(),
      ),
      ['Server?', 'Revision?'],
    );
    final library = Library(
      (b) => b.body.addAll([
        for (final model in api.models.whereType<ClassModel>())
          ...classes.generateClasses(model),
        for (final model in api.models.whereType<AllOfModel>())
          ...allOf.generateClasses(model),
      ]),
    );
    final plan = MultipartBodyPlanner(
      backend: TransportBackend.http,
      nameManager: manager,
      package: 'example',
    ).plan(content, bodyAccessor: 'body', isRequired: true);
    final encoder = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'body'
              ..type = refer('Upload', 'package:example/example.dart'),
          ),
        )
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final directory = Directory.systemTemp.createTempSync(
      'multipart_read_only_',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final script = File('${directory.path}/main.dart')
      ..writeAsStringSync('''
import 'dart:core';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:tonik_util/tonik_util.dart';
${library.accept(DartEmitter(useNullSafetySyntax: true))}
${encoder.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final omitted = encode(const Upload(
    readOnlyGroup: ReadOnlyGroup(),
    writable: Writable(name: 'request'),
  ));
  if (!const IterableEquality<String>().equals(omitted.map((part) => part.field), ['name'])) {
    throw StateError('Empty readOnly group must emit only the writable name.');
  }
  final populated = encode(const Upload(
    readOnlyGroup: ReadOnlyGroup(
      server: Server(shared: 'server-only'),
      revision: Revision(revision: 7),
    ),
    writable: Writable(shared: 'client', name: 'request'),
  ));
  if (!const IterableEquality<String>().equals(populated.map((part) => part.field), ['shared', 'name'])) {
    throw StateError('Populated readOnly group must emit only writable fields.');
  }
  if (!const IterableEquality<String>().equals([for (final part in populated) utf8.decode(await part.finalize().toBytes())], ['client', 'request'])) {
    throw StateError('Multipart values must come from the writable member.');
  }
  final absentWritable = encode(const Upload(
    readOnlyGroup: ReadOnlyGroup(
      server: Server(shared: 'server-only'),
      revision: Revision(revision: 7),
    ),
    writable: Writable(name: 'request'),
  ));
  if (!const IterableEquality<String>().equals(absentWritable.map((part) => part.field), ['name'])) {
    throw StateError('ReadOnly shared value must be omitted when writable shared is absent.');
  }
}
''');
    final run = await Process.run(Platform.resolvedExecutable, [
      '--packages=${Platform.packageConfig}',
      script.path,
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
  });

  test(
    'DIO readOnly allOf root rejects multipart generation',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'ReadOnly', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Server': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['shared'],
              'properties': {
                'shared': {'type': 'string'},
              },
            },
            'Revision': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['revision'],
              'properties': {
                'revision': {'type': 'integer'},
              },
            },
            'ReadOnlyGroup': {
              'readOnly': true,
              'additionalProperties': false,
              'allOf': [
                {r'$ref': '#/components/schemas/Server'},
                {r'$ref': '#/components/schemas/Revision'},
              ],
            },
          },
          'requestBodies': {
            'Multipart': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/ReadOnlyGroup'},
                },
              },
            },
          },
        },
      });
      final content =
          api.requestBodies.whereType<RequestBodyObject>().single.content.single
              as MultipartRequestContent;
      expect(content.model, isA<AllOfModel>());
      final readOnly = api.models.whereType<AllOfModel>().singleWhere(
        (model) => model.name == 'ReadOnlyGroup',
      );
      expect(readOnly.isReadOnly, isTrue);
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final allOf = AllOfGenerator(
        nameManager: manager,
        package: 'example',
        stableModelSorter: StableModelSorter(),
      );
      final generatedReadOnly = allOf.generateClass(readOnly);
      expect(generatedReadOnly.fields.map((field) => field.name), [
        'server',
        'revision',
      ]);
      expect(
        generatedReadOnly.fields.map(
          (field) => field.type!
              .accept(DartEmitter(useNullSafetySyntax: true))
              .toString(),
        ),
        ['Server?', 'Revision?'],
      );
      expect(
        () => MultipartBodyPlanner(
          backend: TransportBackend.dio,
          nameManager: manager,
          package: 'example',
        ).plan(content, bodyAccessor: 'body', isRequired: true),
        throwsA(anything),
      );
    },
  );

  test(
    'DIO nested readOnly allOf emits only writable fields and requiredness',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'ReadOnly', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Server': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['shared'],
              'properties': {
                'shared': {'type': 'string'},
              },
            },
            'Revision': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['revision'],
              'properties': {
                'revision': {'type': 'integer'},
              },
            },
            'ReadOnlyGroup': {
              'readOnly': true,
              'additionalProperties': false,
              'allOf': [
                {r'$ref': '#/components/schemas/Server'},
                {r'$ref': '#/components/schemas/Revision'},
              ],
            },
            'Writable': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['name'],
              'properties': {
                'shared': {'type': 'string'},
                'name': {'type': 'string'},
              },
            },
            'Upload': {
              'additionalProperties': false,
              'allOf': [
                {r'$ref': '#/components/schemas/ReadOnlyGroup'},
                {r'$ref': '#/components/schemas/Writable'},
              ],
            },
          },
          'requestBodies': {
            'Multipart': {
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {r'$ref': '#/components/schemas/Upload'},
                },
              },
            },
          },
        },
      });
      final content =
          api.requestBodies.whereType<RequestBodyObject>().single.content.single
              as MultipartRequestContent;
      expect(content.model, isA<AllOfModel>());
      final readOnly = api.models.whereType<AllOfModel>().singleWhere(
        (model) => model.name == 'ReadOnlyGroup',
      );
      expect(readOnly.isReadOnly, isTrue);
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final allOf = AllOfGenerator(
        nameManager: manager,
        package: 'example',
        stableModelSorter: StableModelSorter(),
      );
      final generatedReadOnly = allOf.generateClass(readOnly);
      expect(generatedReadOnly.fields.map((field) => field.name), [
        'server',
        'revision',
      ]);
      expect(
        generatedReadOnly.fields.map(
          (field) => field.type!
              .accept(DartEmitter(useNullSafetySyntax: true))
              .toString(),
        ),
        ['Server?', 'Revision?'],
      );
      final plan = MultipartBodyPlanner(
        backend: TransportBackend.dio,
        nameManager: manager,
        package: 'example',
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('FormData', 'package:dio/dio.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer('Upload', 'package:example/example.dart'),
            ),
          )
          ..body = Block.of(buildMultipartBodyStatements(plan).statements),
      );
      const expected = r'''
FormData encode(Upload body) {
  final _$formData = FormData();
  if (body.writable.shared != null) {
    _$formData.files.add(MapEntry(r'shared', MultipartFile.fromString(
      body.writable.shared!, contentType: DioMediaType.parse(r'text/plain'),
    )));
  }
  _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(
    body.writable.name, contentType: DioMediaType.parse(r'text/plain'),
  )));
  return _$formData;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      final actual = encoder
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      expect(
        collapseWhitespace(formatter.format(actual)),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );
}
