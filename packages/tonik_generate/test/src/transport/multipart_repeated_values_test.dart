import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';

void main() {
  test(
    'required repeated metadata merges fields and rejects conflicts',
    () {
      final context = Context.initial();

      final text = StringModel(context: context);
      final base = ClassModel(
        name: 'BaseMetadata',
        context: context.push('BaseMetadata'),
        properties: [
          Property(
            name: 'name',
            model: text,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'settings',
            model: ClassModel(
              name: 'BaseSettings',
              context: context.push('BaseSettings'),
              properties: [
                Property(
                  name: 'enabled',
                  model: BooleanModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              isDeprecated: false,
              examples: const [],
              additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final extra = ClassModel(
        name: 'ExtraMetadata',
        context: context.push('ExtraMetadata'),
        properties: [
          Property(
            name: 'name',
            model: text,
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'settings',
            model: ClassModel(
              name: 'ExtraSettings',
              context: context.push('ExtraSettings'),
              properties: [
                Property(
                  name: 'region',
                  model: text,
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              isDeprecated: false,
              examples: const [],
              additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'annotations',
            model: MapModel(
              valueModel: text,
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );

      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'metadata',
                model: base,
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'metadata',
                model: extra,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );

      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final method = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final actual = method
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];

Object? _$mergeMultipartValues(Object? first, Object? second) {
  if (first == null) return second;
  if (second == null) return first;
  if (first is Map<String, Object?> && second is Map<String, Object?>) {
    final result = <String, Object?>{...first};
    for (final entry in second.entries) {
      result[entry.key] = result.containsKey(entry.key)
          ? _$mergeMultipartValues(result[entry.key], entry.value)
          : entry.value;
    }
    return result;
  }
  if (const DeepCollectionEquality().equals(first, second)) return first;
  throw 'conflict';
}

  final _$metadata = _$mergeMultipartValues(
    body.first.metadata?.toJson(), body.second.metadata.toJson(),
  );

  _$multipartFiles.add(MultipartFile.fromBytes(
    r'metadata', utf8.encode(jsonEncode(_$metadata)),
    contentType: MediaType.parse(r'application/json'),
  ));

  return _$multipartFiles;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      expect(
        collapseWhitespace(
          formatter.format(
            actual.replaceAll(RegExp('throw [^;]+;'), "throw 'conflict';"),
          ),
        ),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );

  test(
    'optional repeated metadata merges fields and rejects conflicts',
    () {
      final context = Context.initial();

      final text = StringModel(context: context);
      final base = ClassModel(
        name: 'BaseMetadata',
        context: context.push('BaseMetadata'),
        properties: [
          Property(
            name: 'name',
            model: text,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'settings',
            model: ClassModel(
              name: 'BaseSettings',
              context: context.push('BaseSettings'),
              properties: [
                Property(
                  name: 'enabled',
                  model: BooleanModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              isDeprecated: false,
              examples: const [],
              additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final extra = ClassModel(
        name: 'ExtraMetadata',
        context: context.push('ExtraMetadata'),
        properties: [
          Property(
            name: 'name',
            model: text,
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'settings',
            model: ClassModel(
              name: 'ExtraSettings',
              context: context.push('ExtraSettings'),
              properties: [
                Property(
                  name: 'region',
                  model: text,
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              isDeprecated: false,
              examples: const [],
              additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'annotations',
            model: MapModel(
              valueModel: text,
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );

      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'metadata',
                model: base,
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'metadata',
                model: extra,
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );

      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final method = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final actual = method
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];

Object? _$mergeMultipartValues(Object? first, Object? second) {
  if (first == null) return second;
  if (second == null) return first;
  if (first is Map<String, Object?> && second is Map<String, Object?>) {
    final result = <String, Object?>{...first};
    for (final entry in second.entries) {
      result[entry.key] = result.containsKey(entry.key)
          ? _$mergeMultipartValues(result[entry.key], entry.value)
          : entry.value;
    }
    return result;
  }
  if (const DeepCollectionEquality().equals(first, second)) return first;
  throw 'conflict';
}

  final _$metadata = _$mergeMultipartValues(
    body.first.metadata?.toJson(), body.second.metadata?.toJson(),
  );
  if (_$metadata != null) {
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'metadata', utf8.encode(jsonEncode(_$metadata)),
    contentType: MediaType.parse(r'application/json'),
  ));
  }
  return _$multipartFiles;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      expect(
        collapseWhitespace(
          formatter.format(
            actual.replaceAll(RegExp('throw [^;]+;'), "throw 'conflict';"),
          ),
        ),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );

  test('repeated scalar values retain equal values and reject conflicts', () {
    final context = Context.initial();

    final text = StringModel(context: context);
    final root = AllOfModel(
      name: 'Upload',
      context: context.push('Upload'),
      models: [
        ClassModel(
          name: 'First',
          context: context.push('First'),
          properties: [
            Property(
              name: 'label',
              model: text,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          isDeprecated: false,
          examples: const [],
          additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
        ),
        ClassModel(
          name: 'Second',
          context: context.push('Second'),
          properties: [
            Property(
              name: 'label',
              model: text,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          isDeprecated: false,
          examples: const [],
          additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
        ),
      ],
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );

    final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
        .plan(
          MultipartRequestContent(
            model: root,
            rawContentType: 'multipart/form-data',
            examples: const [],
          ),
          bodyAccessor: 'body',
          isRequired: true,
        );
    final method = Method(
      (b) => b
        ..name = 'encode'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
    );
    final actual = method
        .accept(DartEmitter(useNullSafetySyntax: true))
        .toString();
    const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];

Object? _$mergeMultipartValues(Object? first, Object? second) {
  if (first == null) return second;
  if (second == null) return first;
  if (first is Map<String, Object?> && second is Map<String, Object?>) {
    final result = <String, Object?>{...first};
    for (final entry in second.entries) {
      result[entry.key] = result.containsKey(entry.key)
          ? _$mergeMultipartValues(result[entry.key], entry.value)
          : entry.value;
    }
    return result;
  }
  if (const DeepCollectionEquality().equals(first, second)) return first;
  throw 'conflict';
}

  final _$label = _$mergeMultipartValues(body.first.label, body.second.label);
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'label', utf8.encode((_$label as String)),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(
      collapseWhitespace(
        formatter.format(
          actual.replaceAll(RegExp('throw [^;]+;'), "throw 'conflict';"),
        ),
      ),
      collapseWhitespace(formatter.format(expected)),
    );
  });

  test(
    'repeated enum then Any values normalize separately before merging',
    () async {
      final context = Context.initial();
      final status = EnumModel<String>(
        name: 'Status',
        context: context.push('Status'),
        values: {const EnumEntry(value: 'active')},
        isNullable: false,
        isDeprecated: false,
        examples: const [],
      );
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'status',
                model: status,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'status',
                model: AnyModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generated = EnumGenerator(nameManager: manager).generate(status);
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              encoding: const {
                'status': PartEncoding(
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  headers: null,
                  style: null,
                  explode: null,
                  allowReserved: null,
                ),
              },
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer(
                  '({({Status status}) first, ({Object? status}) second})',
                  'dart:core',
                ),
            ),
          )
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_enum_any_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:core';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${generated.code}
${encoder.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final parts = encode((first: (status: Status.active,), second: (status: 'active',)));
  if (parts.length != 1 || parts.single.field != 'status' ||
      jsonDecode(utf8.decode(await parts.single.finalize().toBytes())) != 'active') {
    throw StateError('Equal enum and Any values did not produce one JSON value.');
  }
}
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated Any then enum values normalize separately before merging',
    () async {
      final context = Context.initial();
      final status = EnumModel<String>(
        name: 'Status',
        context: context.push('Status'),
        values: {const EnumEntry(value: 'active')},
        isNullable: false,
        isDeprecated: false,
        examples: const [],
      );
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'status',
                model: AnyModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'status',
                model: status,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generated = EnumGenerator(nameManager: manager).generate(status);
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              encoding: const {
                'status': PartEncoding(
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  headers: null,
                  style: null,
                  explode: null,
                  allowReserved: null,
                ),
              },
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer(
                  '({({Object? status}) first, ({Status status}) second})',
                  'dart:core',
                ),
            ),
          )
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_enum_any_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:core';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${generated.code}
${encoder.accept(DartEmitter(useNullSafetySyntax: true))}
Future<void> main() async {
  final parts = encode((first: (status: 'active',), second: (status: Status.active,)));
  if (parts.length != 1 || parts.single.field != 'status' ||
      jsonDecode(utf8.decode(await parts.single.finalize().toBytes())) != 'active') {
    throw StateError('Equal enum and Any values did not produce one JSON value.');
  }
}
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated typed map and class metadata merge complementary nested fields',
    () async {
      final context = Context.initial();
      final baseSettings = ClassModel(
        name: 'BaseSettings',
        context: context.push('BaseSettings'),
        properties: [
          Property(
            name: 'enabled',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final extraSettings = ClassModel(
        name: 'ExtraSettings',
        context: context.push('ExtraSettings'),
        properties: [
          Property(
            name: 'region',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final metadata = ClassModel(
        name: 'Metadata',
        context: context.push('Metadata'),
        properties: [
          Property(
            name: 'settings',
            model: extraSettings,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'metadata',
                model: MapModel(
                  valueModel: baseSettings,
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'metadata',
                model: metadata,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generator = ClassGenerator(
        nameManager: manager,
        package: 'example',
      );
      final library = Library(
        (b) => b.body.addAll([
          ...generator.generateClasses(baseSettings),
          ...generator.generateClasses(extraSettings),
          ...generator.generateClasses(metadata),
        ]),
      );
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer(
                  '({({Map<String, BaseSettings> metadata}) first, '
                      '({Metadata metadata}) second})',
                  'dart:core',
                ),
            ),
          )
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_typed_map_',
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
  final parts = encode((
    first: (metadata: <String, BaseSettings>{'settings': const BaseSettings(enabled: true)},),
    second: (metadata: const Metadata(settings: ExtraSettings(region: 'eu')),),
  ));
  if (parts.length != 1 || parts.single.field != 'metadata') {
    throw StateError('Expected exactly one metadata part.');
  }
  final value = jsonDecode(utf8.decode(await parts.single.finalize().toBytes()));
  if (!const DeepCollectionEquality().equals(value, {
    'settings': {'enabled': true, 'region': 'eu'},
  })) throw StateError('Complementary nested fields were lost.');
}
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated typed lists merge equal JSON values from distinct item classes',
    () async {
      final context = Context.initial();
      final firstItem = ClassModel(
        name: 'FirstItem',
        context: context.push('FirstItem'),
        properties: [
          Property(
            name: 'value',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final secondItem = ClassModel(
        name: 'SecondItem',
        context: context.push('SecondItem'),
        properties: [
          Property(
            name: 'value',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: firstItem,
                  context: context,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: secondItem,
                  context: context,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generator = ClassGenerator(
        nameManager: manager,
        package: 'example',
      );
      final library = Library(
        (b) => b.body.addAll([
          ...generator.generateClasses(firstItem),
          ...generator.generateClasses(secondItem),
        ]),
      );
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer(
                  '({({List<FirstItem>? items}) first, '
                      '({List<SecondItem>? items}) second})',
                  'dart:core',
                ),
            ),
          )
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_typed_lists_',
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
  final parts = encode((
    first: (items: const <FirstItem>[FirstItem(value: 'x')],),
    second: (items: const <SecondItem>[SecondItem(value: 'x')],),
  ));
  if (parts.length != 1 || parts.single.field != 'items') {
    throw StateError('Expected exactly one items part.');
  }
  final value = jsonDecode(utf8.decode(await parts.single.finalize().toBytes()));
  if (!const DeepCollectionEquality().equals(value, [{'value': 'x'}])) {
    throw StateError('The typed list did not retain its JSON value.');
  }
}
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated typed lists retain the later contribution '
    'when the first is absent',
    () async {
      final context = Context.initial();
      final firstItem = ClassModel(
        name: 'FirstItem',
        context: context.push('FirstItem'),
        properties: [
          Property(
            name: 'value',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final secondItem = ClassModel(
        name: 'SecondItem',
        context: context.push('SecondItem'),
        properties: [
          Property(
            name: 'value',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: firstItem,
                  context: context,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: secondItem,
                  context: context,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final manager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final generator = ClassGenerator(
        nameManager: manager,
        package: 'example',
      );
      final library = Library(
        (b) => b.body.addAll([
          ...generator.generateClasses(firstItem),
          ...generator.generateClasses(secondItem),
        ]),
      );
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            MultipartRequestContent(
              model: root,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
            bodyAccessor: 'body',
            isRequired: true,
          );
      final encoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = refer(
                  '({({List<FirstItem>? items}) first, '
                      '({List<SecondItem>? items}) second})',
                  'dart:core',
                ),
            ),
          )
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_typed_lists_',
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
  final parts = encode((
    first: (items: null,),
    second: (items: const <SecondItem>[SecondItem(value: 'x')],),
  ));
  if (parts.length != 1 || parts.single.field != 'items') {
    throw StateError('Expected exactly one items part.');
  }
  final value = jsonDecode(utf8.decode(await parts.single.finalize().toBytes()));
  if (!const DeepCollectionEquality().equals(value, [{'value': 'x'}])) {
    throw StateError('The typed list did not retain its JSON value.');
  }
}
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated String then Any lists support form without explode',
    () async {
      final context = Context.initial();
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: AnyModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final content = MultipartRequestContent(
        model: root,
        encoding: const {
          'items': PartEncoding(
            contentType: null,
            rawContentType: null,
            headers: null,
            style: EncodingStyle.form,
            explode: false,
            allowReserved: null,
          ),
        },
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final httpPlan = const MultipartBodyPlanner(
        backend: TransportBackend.http,
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final parameter = Parameter(
        (p) => p
          ..name = 'body'
          ..type = refer(
            '({({List<String> items}) first, '
                '({List<Object?> items}) second})',
            'dart:core',
          ),
      );
      final httpEncoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(parameter)
          ..body = Block.of(buildHttpMultipartBodyStatements(httpPlan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_string_any_lists_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/http_encoder.dart').writeAsStringSync('''
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${httpEncoder.accept(DartEmitter(useNullSafetySyntax: true))}
''');
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'http_encoder.dart' as http;
Future<void> main() async {
  const body = (
    first: (items: <String>['alpha', 'beta'],),
    second: (items: <Object?>['alpha', 'beta'],),
  );
  final httpParts = http.encode(body);
  if (httpParts.length != 1 || httpParts.single.field != 'items') {
    throw StateError('Expected exactly one items part.');
  }
  if (utf8.decode(await httpParts.single.finalize().toBytes()) !=
      'alpha,beta') {
    throw StateError('Expected the complete delimited string values.');
  }
  const conflictingBody = (
    first: (items: <String>['alpha', 'beta'],),
    second: (items: <Object?>['different'],),
  );
  var rejectedConflict = false;
  try {
    http.encode(conflictingBody);
  } on Object {
    rejectedConflict = true;
  }
  if (!rejectedConflict) {
    throw StateError('Conflicting repeated values must be rejected.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated String then Any lists support spaceDelimited without explode',
    () async {
      final context = Context.initial();
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: AnyModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final content = MultipartRequestContent(
        model: root,
        encoding: const {
          'items': PartEncoding(
            contentType: null,
            rawContentType: null,
            headers: null,
            style: EncodingStyle.spaceDelimited,
            explode: false,
            allowReserved: null,
          ),
        },
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final httpPlan = const MultipartBodyPlanner(
        backend: TransportBackend.http,
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final parameter = Parameter(
        (p) => p
          ..name = 'body'
          ..type = refer(
            '({({List<String> items}) first, '
                '({List<Object?> items}) second})',
            'dart:core',
          ),
      );
      final httpEncoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(parameter)
          ..body = Block.of(buildHttpMultipartBodyStatements(httpPlan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_string_any_lists_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/http_encoder.dart').writeAsStringSync('''
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${httpEncoder.accept(DartEmitter(useNullSafetySyntax: true))}
''');
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'http_encoder.dart' as http;
Future<void> main() async {
  const body = (
    first: (items: <String>['alpha', 'beta'],),
    second: (items: <Object?>['alpha', 'beta'],),
  );
  final httpParts = http.encode(body);
  if (httpParts.length != 1 || httpParts.single.field != 'items') {
    throw StateError('Expected exactly one items part.');
  }
  if (utf8.decode(await httpParts.single.finalize().toBytes()) !=
      'alpha beta') {
    throw StateError('Expected the complete delimited string values.');
  }
  const conflictingBody = (
    first: (items: <String>['alpha', 'beta'],),
    second: (items: <Object?>['different'],),
  );
  var rejectedConflict = false;
  try {
    http.encode(conflictingBody);
  } on Object {
    rejectedConflict = true;
  }
  if (!rejectedConflict) {
    throw StateError('Conflicting repeated values must be rejected.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated String then Any lists support pipeDelimited without explode',
    () async {
      final context = Context.initial();
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: AnyModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final content = MultipartRequestContent(
        model: root,
        encoding: const {
          'items': PartEncoding(
            contentType: null,
            rawContentType: null,
            headers: null,
            style: EncodingStyle.pipeDelimited,
            explode: false,
            allowReserved: null,
          ),
        },
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final httpPlan = const MultipartBodyPlanner(
        backend: TransportBackend.http,
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final parameter = Parameter(
        (p) => p
          ..name = 'body'
          ..type = refer(
            '({({List<String> items}) first, '
                '({List<Object?> items}) second})',
            'dart:core',
          ),
      );
      final httpEncoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(parameter)
          ..body = Block.of(buildHttpMultipartBodyStatements(httpPlan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_string_any_lists_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/http_encoder.dart').writeAsStringSync('''
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${httpEncoder.accept(DartEmitter(useNullSafetySyntax: true))}
''');
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'http_encoder.dart' as http;
Future<void> main() async {
  const body = (
    first: (items: <String>['alpha', 'beta'],),
    second: (items: <Object?>['alpha', 'beta'],),
  );
  final httpParts = http.encode(body);
  if (httpParts.length != 1 || httpParts.single.field != 'items') {
    throw StateError('Expected exactly one items part.');
  }
  if (utf8.decode(await httpParts.single.finalize().toBytes()) !=
      'alpha|beta') {
    throw StateError('Expected the complete delimited string values.');
  }
  const conflictingBody = (
    first: (items: <String>['alpha', 'beta'],),
    second: (items: <Object?>['different'],),
  );
  var rejectedConflict = false;
  try {
    http.encode(conflictingBody);
  } on Object {
    rejectedConflict = true;
  }
  if (!rejectedConflict) {
    throw StateError('Conflicting repeated values must be rejected.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated Any then String lists support form without explode',
    () async {
      final context = Context.initial();
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: AnyModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final content = MultipartRequestContent(
        model: root,
        encoding: const {
          'items': PartEncoding(
            contentType: null,
            rawContentType: null,
            headers: null,
            style: EncodingStyle.form,
            explode: false,
            allowReserved: null,
          ),
        },
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final httpPlan = const MultipartBodyPlanner(
        backend: TransportBackend.http,
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final parameter = Parameter(
        (p) => p
          ..name = 'body'
          ..type = refer(
            '({({List<Object?> items}) first, '
                '({List<String> items}) second})',
            'dart:core',
          ),
      );
      final httpEncoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(parameter)
          ..body = Block.of(buildHttpMultipartBodyStatements(httpPlan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_string_any_lists_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/http_encoder.dart').writeAsStringSync('''
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${httpEncoder.accept(DartEmitter(useNullSafetySyntax: true))}
''');
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'http_encoder.dart' as http;
Future<void> main() async {
  const body = (
    first: (items: <Object?>['alpha', 'beta'],),
    second: (items: <String>['alpha', 'beta'],),
  );
  final httpParts = http.encode(body);
  if (httpParts.length != 2 ||
      httpParts.first.field != 'items' || httpParts.last.field != 'items') {
    throw StateError('Expected two items parts in declaration order.');
  }
  if (jsonDecode(utf8.decode(await httpParts.first.finalize().toBytes())) !=
      'alpha') {
    throw StateError('Expected the first JSON string value.');
  }
  if (jsonDecode(utf8.decode(await httpParts.last.finalize().toBytes())) !=
      'beta') {
    throw StateError('Expected the last JSON string value.');
  }
  const conflictingBody = (
    first: (items: <Object?>['alpha', 'beta'],),
    second: (items: <String>['different'],),
  );
  var rejectedConflict = false;
  try {
    http.encode(conflictingBody);
  } on Object {
    rejectedConflict = true;
  }
  if (!rejectedConflict) {
    throw StateError('Conflicting repeated values must be rejected.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated Any then String lists support spaceDelimited without explode',
    () async {
      final context = Context.initial();
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: AnyModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final content = MultipartRequestContent(
        model: root,
        encoding: const {
          'items': PartEncoding(
            contentType: null,
            rawContentType: null,
            headers: null,
            style: EncodingStyle.spaceDelimited,
            explode: false,
            allowReserved: null,
          ),
        },
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final httpPlan = const MultipartBodyPlanner(
        backend: TransportBackend.http,
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final parameter = Parameter(
        (p) => p
          ..name = 'body'
          ..type = refer(
            '({({List<Object?> items}) first, '
                '({List<String> items}) second})',
            'dart:core',
          ),
      );
      final httpEncoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(parameter)
          ..body = Block.of(buildHttpMultipartBodyStatements(httpPlan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_string_any_lists_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/http_encoder.dart').writeAsStringSync('''
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${httpEncoder.accept(DartEmitter(useNullSafetySyntax: true))}
''');
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'http_encoder.dart' as http;
Future<void> main() async {
  const body = (
    first: (items: <Object?>['alpha', 'beta'],),
    second: (items: <String>['alpha', 'beta'],),
  );
  final httpParts = http.encode(body);
  if (httpParts.length != 2 ||
      httpParts.first.field != 'items' || httpParts.last.field != 'items') {
    throw StateError('Expected two items parts in declaration order.');
  }
  if (jsonDecode(utf8.decode(await httpParts.first.finalize().toBytes())) !=
      'alpha') {
    throw StateError('Expected the first JSON string value.');
  }
  if (jsonDecode(utf8.decode(await httpParts.last.finalize().toBytes())) !=
      'beta') {
    throw StateError('Expected the last JSON string value.');
  }
  const conflictingBody = (
    first: (items: <Object?>['alpha', 'beta'],),
    second: (items: <String>['different'],),
  );
  var rejectedConflict = false;
  try {
    http.encode(conflictingBody);
  } on Object {
    rejectedConflict = true;
  }
  if (!rejectedConflict) {
    throw StateError('Conflicting repeated values must be rejected.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test(
    'repeated Any then String lists support pipeDelimited without explode',
    () async {
      final context = Context.initial();
      final root = AllOfModel(
        name: 'Upload',
        context: context.push('Upload'),
        models: [
          ClassModel(
            name: 'First',
            context: context.push('First'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: AnyModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
          ClassModel(
            name: 'Second',
            context: context.push('Second'),
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            isDeprecated: false,
            examples: const [],
            additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
          ),
        ],
        isDeprecated: false,
        examples: const [],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );
      final content = MultipartRequestContent(
        model: root,
        encoding: const {
          'items': PartEncoding(
            contentType: null,
            rawContentType: null,
            headers: null,
            style: EncodingStyle.pipeDelimited,
            explode: false,
            allowReserved: null,
          ),
        },
        rawContentType: 'multipart/form-data',
        examples: const [],
      );
      final httpPlan = const MultipartBodyPlanner(
        backend: TransportBackend.http,
      ).plan(content, bodyAccessor: 'body', isRequired: true);
      final parameter = Parameter(
        (p) => p
          ..name = 'body'
          ..type = refer(
            '({({List<Object?> items}) first, '
                '({List<String> items}) second})',
            'dart:core',
          ),
      );
      final httpEncoder = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('List<MultipartFile>', 'package:http/http.dart')
          ..requiredParameters.add(parameter)
          ..body = Block.of(buildHttpMultipartBodyStatements(httpPlan)),
      );
      final directory = Directory.systemTemp.createTempSync(
        'multipart_string_any_lists_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/http_encoder.dart').writeAsStringSync('''
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:tonik_util/tonik_util.dart';
${httpEncoder.accept(DartEmitter(useNullSafetySyntax: true))}
''');
      final script = File('${directory.path}/main.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'http_encoder.dart' as http;
Future<void> main() async {
  const body = (
    first: (items: <Object?>['alpha', 'beta'],),
    second: (items: <String>['alpha', 'beta'],),
  );
  final httpParts = http.encode(body);
  if (httpParts.length != 2 ||
      httpParts.first.field != 'items' || httpParts.last.field != 'items') {
    throw StateError('Expected two items parts in declaration order.');
  }
  if (jsonDecode(utf8.decode(await httpParts.first.finalize().toBytes())) !=
      'alpha') {
    throw StateError('Expected the first JSON string value.');
  }
  if (jsonDecode(utf8.decode(await httpParts.last.finalize().toBytes())) !=
      'beta') {
    throw StateError('Expected the last JSON string value.');
  }
  const conflictingBody = (
    first: (items: <Object?>['alpha', 'beta'],),
    second: (items: <String>['different'],),
  );
  var rejectedConflict = false;
  try {
    http.encode(conflictingBody);
  } on Object {
    rejectedConflict = true;
  }
  if (!rejectedConflict) {
    throw StateError('Conflicting repeated values must be rejected.');
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${Platform.packageConfig}',
        script.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );
}
