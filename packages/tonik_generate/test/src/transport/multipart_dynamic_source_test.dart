import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';
import 'package:tonik_generate/src/transport/dio/dio_multipart_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';

import 'multipart_test_support.dart';

void main() {
  final context = Context.initial();

  test('uses an immutable inline body in API and operation methods', () {
    final nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final defaultsCache = OperationDefaultsCache(
      nameManager: nameManager,
      package: 'api',
    );
    final operation = Operation(
      operationId: 'upload',
      context: context,
      tags: const {},
      isDeprecated: false,
      path: '/upload',
      method: HttpMethod.post,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      responses: const {},
      securitySchemes: const {},
      requestBody: RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          _content(
            MapModel(
              context: context,
              valueModel: StringModel(context: context),
              examples: const [],
            ),
          ),
        },
      ),
    );
    final api = ApiClientGenerator(
      nameManager: nameManager,
      package: 'api',
      backendGenerator: const DioBackendGenerator(),
      defaultsCache: defaultsCache,
      useImmutableCollections: true,
    ).generateClass({operation}, Tag(name: 'uploads'), const []);
    final call =
        OperationGenerator(
          nameManager: nameManager,
          package: 'api',
          backendGenerator: const DioBackendGenerator(),
          defaultsCache: defaultsCache,
          operationBaseFilename: 'dio_operation.dart',
          useImmutableCollections: true,
        ).generateCallMethod(
          operation,
          const NormalizedRequestParameters(
            pathParameters: [],
            queryParameters: [],
            headers: [],
            cookieParameters: [],
          ),
        );
    final emitter = DartEmitter(useNullSafetySyntax: true);
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    expect(
      format('${api.methods.single.accept(emitter)};'),
      format('''
Future<TonikResult<void, Response<Object?>>> upload({
        required IMap<String, String> body,
        TonikCancellation? cancellation,
      }) async => _upload(body: body, cancellation: cancellation);
      '''),
    );
    expect(
      format(call.accept(emitter).toString()),
      format('''
Future<TonikResult<void, Response<Object?>>> call({
        required IMap<String, String> body,
        TonikCancellation? cancellation,
      }) {
        return this.executeVoidAsync(
          cancellation: cancellation,
          prepare: () async => DioOperationRequest(
            path: _path(),
            query: null,
            data: await _data(body: body),
            options: _options(),
          ),
          decode: (_) {},
        );
      }
      '''),
    );
  });

  test('emits one part per dynamic primitive-union array item', () {
    final union = OneOfModel(
      name: 'PrimitiveUnion',
      models: [
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: IntegerModel(context: context)),
      ],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final content = _content(
      MapModel(
        context: context,
        examples: const [],
        valueModel: ListModel(
          context: context,
          examples: const [],
          content: union,
        ),
      ),
    );
    _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  final _$multipartMap = body;
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    for (final item in _$multipartValue) {
      _$multipartFiles.add(MultipartFile.fromBytes(
        (_$multipartEntry.key).replaceAll(r'\', r'\\'),
        utf8.encode(jsonEncode(item.toJson())),
        contentType: MediaType.parse(r'application/json'),
      ));
    }
  }
  if (_$multipartFiles.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$multipartFiles;
}
''');
  });

  test('emits the complete nullable map method with guarded iteration', () {
    final content = _content(
      MapModel(
        context: context,
        examples: const [],
        isNullable: true,
        isValueNullable: true,
        valueModel: StringModel(context: context),
      ),
    );
    _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  final _$multipartMap = body;
  if (_$multipartMap == null) {
    throw EncodingException(r'Required multipart body is null.');
  }
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    if (_$multipartValue == null) continue;
    _$multipartFiles.add(MultipartFile.fromBytes(
      (_$multipartEntry.key).replaceAll(r'\', r'\\'),
      utf8.encode(_$multipartValue),
      contentType: MediaType.parse(r'text/plain'),
    ));
  }
  if (_$multipartFiles.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$multipartFiles;
}
''');
  });

  test('emits Dio dynamic arrays through the ordered file channel', () {
    final content = _content(
      MapModel(
        context: context,
        examples: const [],
        valueModel: ListModel(
          context: context,
          examples: const [],
          content: IntegerModel(context: context),
        ),
      ),
    );
    _expectMethod(content, TransportBackend.dio, r'''
Object? encode() {
  final _$formData = FormData();
  final _$multipartMap = body;
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    for (final item in _$multipartValue) {
      _$formData.files.add(MapEntry(
        (_$multipartEntry.key).replaceAll(r'\', r'\\'),
        MultipartFile.fromString(item.toString(),
          contentType: DioMediaType.parse(r'text/plain')),
      ));
    }
  }
  if (_$formData.fields.isEmpty && _$formData.files.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$formData;
}
''');
  });

  test('selects custom HTTP parts for base64 headers inside map loops', () {
    final content = _content(
      MapModel(
        context: context,
        examples: const [],
        valueModel: ListModel(
          context: context,
          examples: const [],
          content: Base64Model(context: context),
        ),
      ),
    );
    _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartParts = <TonikMultipartPart>[];
  final _$multipartMap = body;
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    final _$dynamicHeaders = <String, String>{
      r'Content-Transfer-Encoding': r'base64',
    };
    for (final item in _$multipartValue) {
      _$multipartParts.add(TonikMultipartPart(
        name: _$multipartEntry.key,
        bytes: ascii.encode(item.toBase64String()),
        contentType: r'application/octet-stream',
        filename: item.fileName ?? _$multipartEntry.key,
        headers: _$dynamicHeaders,
      ));
    }
  }
  if (_$multipartParts.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return TonikMultipartBody(_$multipartParts);
}
''');
  });

  test(
    'serializes nested immutable maps using the shared typed JSON codec',
    () {
      final content = _content(
        MapModel(
          context: context,
          examples: const [],
          valueModel: MapModel(
            context: context,
            examples: const [],
            valueModel: ListModel(
              context: context,
              examples: const [],
              content: IntegerModel(context: context),
            ),
          ),
        ),
      );
      _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  final _$multipartMap = body;
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    _$multipartFiles.add(MultipartFile.fromBytes(
      (_$multipartEntry.key).replaceAll(r'\', r'\\'),
      utf8.encode(jsonEncode(_$multipartValue.unlock.map((k, v) => MapEntry(k, v.unlock)))),
      contentType: MediaType.parse(r'application/json'),
    ));
  }
  if (_$multipartFiles.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$multipartFiles;
}
''', immutable: true);
    },
  );

  test('does not unlock an already merged immutable named map twice', () {
    final map = MapModel(
      context: context,
      examples: const [],
      valueModel: StringModel(context: context),
    );
    final first = multipartContentFixture(context, [
      multipartPartFixture(name: 'metadata', model: map),
    ], name: 'First').model;
    final second = multipartContentFixture(context, [
      multipartPartFixture(name: 'metadata', model: map),
    ], name: 'Second').model;
    final content = _content(
      AllOfModel(
        name: 'Merged',
        context: context,
        examples: const [],
        isDeprecated: false,
        models: [first, second],
      ),
    );
    _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  final _$metadataMultipartValue = _mergeMultipartValues([
    body.first.metadata.unlock, body.second.metadata.unlock,
  ], propertyName: r'metadata', mergeObjects: true);
  _$multipartFiles.add(MultipartFile.fromBytes(
    (r'metadata').replaceAll(r'\', r'\\'),
    utf8.encode(jsonEncode(_$metadataMultipartValue)),
    contentType: MediaType.parse(r'application/json'),
  ));
  if (_$multipartFiles.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$multipartFiles;
}
''', immutable: true);
  });

  test('omits nullable dynamic primitive items before UTF-8 encoding', () {
    final content = _content(
      MapModel(
        context: context,
        examples: const [],
        valueModel: ListModel(
          context: context,
          examples: const [],
          isContentNullable: true,
          content: StringModel(context: context),
        ),
      ),
    );
    _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  final _$multipartMap = body;
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    for (final item in _$multipartValue) {
      if (item == null) continue;
      _$multipartFiles.add(MultipartFile.fromBytes(
        (_$multipartEntry.key).replaceAll(r'\', r'\\'),
        utf8.encode(item),
        contentType: MediaType.parse(r'text/plain'),
      ));
    }
  }
  if (_$multipartFiles.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$multipartFiles;
}
''');
  });

  test('promotes nullable aliased file items before Dio file switching', () {
    final nullableFile = AliasModel(
      context: context,
      name: 'NullableFile',
      examples: const [],
      model: BinaryModel(context: context),
      isNullable: true,
      defaultValue: null,
    );
    final content = _content(
      MapModel(
        context: context,
        examples: const [],
        valueModel: ListModel(
          context: context,
          examples: const [],
          content: nullableFile,
        ),
      ),
    );
    _expectMethod(content, TransportBackend.dio, r'''
Future<Object?> encode() async {
  final _$formData = FormData();
  final _$multipartMap = body;
  for (final _$multipartEntry in _$multipartMap.entries) {
    final _$multipartValue = _$multipartEntry.value;
    for (final item in _$multipartValue) {
      if (item == null) continue;
      switch (item) {
        case TonikFileBytes(:final bytes, :final fileName):
          _$formData.files.add(MapEntry(
            (_$multipartEntry.key).replaceAll(r'\', r'\\'),
            MultipartFile.fromBytes(bytes,
              filename: (fileName ?? _$multipartEntry.key).replaceAll(r'\', r'\\'),
              contentType: DioMediaType.parse(r'application/octet-stream')),
          ));
        case TonikFilePath(:final path, :final fileName):
          _$formData.files.add(MapEntry(
            (_$multipartEntry.key).replaceAll(r'\', r'\\'),
            await MultipartFile.fromFile(path,
              filename: (fileName ?? _$multipartEntry.key).replaceAll(r'\', r'\\'),
              contentType: DioMediaType.parse(r'application/octet-stream')),
          ));
      }
    }
  }
  if (_$formData.fields.isEmpty && _$formData.files.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$formData;
}
''', asynchronous: true);
  });

  test('keeps merged immutable named lists mutable for packed JSON output', () {
    final list = ListModel(
      context: context,
      examples: const [],
      content: IntegerModel(context: context),
    );
    final first = multipartContentFixture(context, [
      multipartPartFixture(name: 'items', model: list),
    ], name: 'First').model;
    final second = multipartContentFixture(context, [
      multipartPartFixture(name: 'items', model: list),
    ], name: 'Second').model;
    final content = MultipartRequestContent(
      model: AllOfModel(
        context: context,
        name: 'Merged',
        examples: const [],
        isDeprecated: false,
        models: [first, second],
      ),
      encoding: const {
        'items': PartEncoding(
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
    );
    _expectMethod(content, TransportBackend.http, r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  final _$itemsMultipartValue = _mergeMultipartLists([
    body.first.items.unlock, body.second.items.unlock,
  ], propertyName: r'items')!;
  _$multipartFiles.add(MultipartFile.fromBytes(
    (r'items').replaceAll(r'\', r'\\'),
    utf8.encode(jsonEncode(_$itemsMultipartValue.toList())),
    contentType: MediaType.parse(r'application/json'),
  ));
  if (_$multipartFiles.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$multipartFiles;
}
''', immutable: true);
  });

  test('preserves null positions in named delimiter-packed Dio arrays', () {
    final content = multipartContentFixture(context, [
      multipartPartFixture(
        name: 'values',
        model: ListModel(
          context: context,
          examples: const [],
          isContentNullable: true,
          content: StringModel(context: context),
        ),
        encoding: const PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: EncodingStyle.form,
          explode: false,
          allowReserved: null,
        ),
      ),
    ]);
    _expectMethod(content, TransportBackend.dio, r'''
Object? encode() {
  final _$formData = FormData();
  _$formData.fields.add(MapEntry(
    (r'values').replaceAll(r'\', r'\\'),
    body.values.map((item) => item ?? '').toList().uriEncode(
      allowEmpty: true, textEncoding: utf8, alreadyEncoded: true,
    ),
  ));
  if (_$formData.fields.isEmpty && _$formData.files.isEmpty) {
    throw EncodingException(r'Multipart request body must contain at least one part.');
  }
  return _$formData;
}
''');
  });

  test('retains nullable aliases and nullable map values', () {
    final nullableValue = AliasModel(
      context: context,
      name: 'NullableText',
      examples: const [],
      model: StringModel(context: context),
      isNullable: true,
      defaultValue: null,
    );
    final root = AliasModel(
      context: context,
      name: 'NullableMap',
      examples: const [],
      model: MapModel(
        context: context,
        examples: const [],
        valueModel: nullableValue,
      ),
      isNullable: true,
      defaultValue: null,
    );
    final result = normalizeMultipartProperties(_content(root));
    expect(result.runtimeEncodingError, isNull);
    expect(result.dynamicSource!.valueModel, same(nullableValue));
    expect(result.dynamicSource!.isValueNullable, isTrue);
    expect(result.dynamicSource!.receiverNullable, isTrue);
    expect(result.dynamicSource!.accessPath, isEmpty);
  });

  test('uses the model naming policy including overridden property names', () {
    final named = multipartPartFixture(
      name: 'raw-name',
      model: StringModel(context: context),
    ).property..nameOverride = 'additionalProperties';
    final readOnly = multipartPartFixture(
      name: 'read-only',
      model: StringModel(context: context),
      isReadOnly: true,
    ).property;
    final model = ClassModel(
      context: context,
      name: 'Mixed',
      isDeprecated: false,
      examples: const [],
      properties: [named, readOnly],
      additionalPropertiesPolicy: AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
      ),
    );
    final result = normalizeMultipartProperties(
      _content(model),
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
    );
    expect(result.properties.single.rawName, 'raw-name');
    expect(
      result.properties.single.accessPaths.single.single.name,
      'additionalProperties',
    );
    expect(
      result.dynamicSource!.accessPath.single.name,
      'additionalProperties2',
    );
    expect(result.dynamicSource!.declaredWireNames, {'raw-name', 'read-only'});
  });

  test('rejects untyped map values', () {
    final result = normalizeMultipartProperties(
      _content(
        MapModel(
          context: context,
          examples: const [],
          valueModel: AnyModel(context: context),
        ),
      ),
    );
    expect(
      result.runtimeEncodingError,
      'Untyped dynamic multipart values are not supported ($context).',
    );
  });

  test('rejects untyped array elements in dynamic values', () {
    final result = normalizeMultipartProperties(
      _content(
        MapModel(
          context: context,
          examples: const [],
          valueModel: ListModel(
            context: context,
            examples: const [],
            content: AnyModel(context: context),
          ),
        ),
      ),
    );
    expect(
      result.runtimeEncodingError,
      'Untyped dynamic multipart values are not supported ($context).',
    );
  });

  test('rejects a dynamic map reached through allOf', () {
    final model = AllOfModel(
      name: 'Composed',
      context: context,
      examples: const [],
      isDeprecated: false,
      models: [
        MapModel(
          name: 'Values',
          context: context,
          examples: const [],
          valueModel: StringModel(context: context),
        ),
      ],
    );
    expect(
      normalizeMultipartProperties(_content(model)).runtimeEncodingError,
      'Dynamic multipart sources inside allOf are not supported '
      '(MapModel at $context).',
    );
  });

  test('rejects an allOf own additional-property field', () {
    final model = AllOfModel(
      name: 'Composed',
      context: context,
      examples: const [],
      isDeprecated: false,
      models: [],
      additionalPropertiesPolicy: AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
      ),
    );
    expect(
      normalizeMultipartProperties(_content(model)).runtimeEncodingError,
      'Dynamic multipart sources inside allOf are not supported '
      '(AllOfModel at $context).',
    );
  });

  test('does not interpret an unmatched encoding key as a wildcard', () {
    final model = MapModel(
      context: context,
      examples: const [],
      valueModel: StringModel(context: context),
    );
    final content = MultipartRequestContent(
      model: model,
      examples: const [],
      rawContentType: 'multipart/form-data',
      encoding: const {
        '*': PartEncoding(
          contentType: ContentType.text,
          rawContentType: '*/*',
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
        ),
      },
    );
    expect(
      normalizeMultipartProperties(content).runtimeEncodingError,
      'Multipart encoding references properties that are not writable or '
      'do not exist in the body model: *.',
    );
  });

  test('rejects a recursive map-array root before generating part loops', () {
    final root = MapModel(
      name: 'RecursiveMap',
      context: context,
      valueModel: StringModel(context: context),
      examples: const [],
    );
    root.valueModel = ListModel(
      context: context,
      content: root,
      examples: const [],
    );
    _expectMethod(_content(root), TransportBackend.dio, '''
Object? encode() {
  throw EncodingException(
    r'Recursive collection types are not supported for dynamic multipart values.',
  );
}
''');
  });

  test('rejects recursive list aliases behind unnamed map wrappers', () {
    final recursive = ListModel(
      name: 'RecursiveList',
      context: context,
      content: StringModel(context: context),
      examples: const [],
    );
    recursive.content = recursive;
    final alias = AliasModel(
      name: 'RecursiveAlias',
      context: context,
      model: recursive,
      defaultValue: null,
      examples: const [],
    );
    final root = MapModel(
      context: context,
      examples: const [],
      valueModel: MapModel(
        context: context,
        examples: const [],
        valueModel: alias,
      ),
    );
    final result = normalizeMultipartProperties(_content(root));
    expect(result.dynamicSource, isNull);
    expect(
      result.runtimeEncodingError,
      'Recursive collection types are not supported for dynamic '
      'multipart values.',
    );
  });

  test('preserves recursive class values serialized by toJson', () {
    final node = ClassModel(
      name: 'Node',
      context: context,
      properties: [],
      isDeprecated: false,
      examples: const [],
    );
    node.properties = [
      multipartPartFixture(
        name: 'child',
        model: node,
        isRequired: false,
        isNullable: true,
      ).property,
    ];
    final root = MapModel(
      context: context,
      examples: const [],
      valueModel: node,
    );
    final result = normalizeMultipartProperties(_content(root));
    expect(result.runtimeEncodingError, isNull);
    expect(result.dynamicSource!.valueModel, same(node));
  });

  test('forbidden additional properties create no dynamic source', () {
    final model = ClassModel(
      context: context,
      name: 'Closed',
      isDeprecated: false,
      examples: const [],
      properties: [],
      additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
    );
    expect(normalizeMultipartProperties(_content(model)).dynamicSource, isNull);
  });
}

MultipartRequestContent _content(Model model) => MultipartRequestContent(
  model: model,
  encoding: const {},
  rawContentType: 'multipart/form-data',
  examples: const [],
);

void _expectMethod(
  MultipartRequestContent content,
  TransportBackend backend,
  String expected, {
  bool immutable = false,
  bool asynchronous = false,
}) {
  final plan = MultipartBodyPlanner(
    backend: backend,
    useImmutableCollections: immutable,
  ).plan(content, bodyAccessor: 'body', isRequired: true);
  final method = Method(
    (b) => b
      ..name = 'encode'
      ..modifier = asynchronous ? MethodModifier.async : null
      ..returns = asynchronous
          ? TypeReference(
              (b) => b
                ..symbol = 'Future'
                ..url = 'dart:async'
                ..types.add(refer('Object?', 'dart:core')),
            )
          : refer('Object?', 'dart:core')
      ..body = Block.of(
        backend == TransportBackend.dio
            ? buildMultipartBodyStatements(plan).statements
            : buildHttpMultipartBodyStatements(plan),
      ),
  );
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;
  final actual = '${method.accept(DartEmitter(useNullSafetySyntax: true))}';
  expect(
    collapseWhitespace(format(actual)),
    collapseWhitespace(format(expected)),
  );
}
