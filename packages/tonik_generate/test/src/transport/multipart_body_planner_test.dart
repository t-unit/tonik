import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';

import 'multipart_test_support.dart';

void main() {
  final context = Context.initial();
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  String emit(MultipartRequestContent content) {
    final method = Method(
      (builder) => builder
        ..name = 'test'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(
          buildHttpMultipartBodyStatements(
            const MultipartBodyPlanner(backend: TransportBackend.http)
                .plan(content, bodyAccessor: 'body', isRequired: true),
          ),
        ),
    );
    return format('${method.accept(emitter)}');
  }

  void expectPropertyCode(
    Model model,
    String expectedPartCode, {
    PartEncoding? encoding,
  }) {
    final content = multipartContentFixture(context, [
      multipartPartFixture(name: 'value', model: model, encoding: encoding),
    ]);
    final expected = [
      'Object? test() {',
      r'  final _$multipartFiles = <MultipartFile>[];',
      expectedPartCode,
      r'  return _$multipartFiles;',
      '}',
    ].join('\n');

    expect(
      collapseWhitespace(emit(content)),
      collapseWhitespace(format(expected)),
    );
  }

  test('emits an empty multipart body when there are no parts', () {
    const expected = r'''
Object? test() {
  final _$multipartFiles = <MultipartFile>[];
  return _$multipartFiles;
}
''';
    expect(
      collapseWhitespace(emit(multipartContentFixture(context, const []))),
      collapseWhitespace(format(expected)),
    );
  });

  group('single-value parts', () {
    test('retains file bytes and the existing filename fallback', () {
      for (final model in [
        BinaryModel(context: context),
        Base64Model(context: context),
      ]) {
        expectPropertyCode(model, r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      body.value.toBytes(),
      filename: body.value.fileName ?? r'value',
      contentType: MediaType.parse(r'application/octet-stream'),
    ),
  );''');
      }
    });

    test('converts date URI decimal and boolean scalar values once', () {
      for (final model in [
        DateModel(context: context),
        UriModel(context: context),
        DecimalModel(context: context),
        BooleanModel(context: context),
      ]) {
        expectPropertyCode(model, r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value.toString()),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );''');
      }
    });

    test('omits read-only parts and guards optional normalized access', () {
      final content = multipartContentFixture(context, [
        multipartPartFixture(
          name: 'serverId',
          model: StringModel(context: context),
          isReadOnly: true,
        ),
        multipartPartFixture(
          name: 'display-name',
          model: StringModel(context: context),
          isRequired: false,
          isNullable: true,
        ),
      ]);
      const expected = r'''
Object? test() {
  final _$multipartFiles = <MultipartFile>[];
  if (body.displayName != null) {
    _$multipartFiles.add(
      MultipartFile.fromBytes(
        r'display-name',
        utf8.encode(body.displayName!),
        contentType: MediaType.parse(r'text/plain'),
      ),
    );
  }
  return _$multipartFiles;
}
''';
      expect(
        collapseWhitespace(emit(content)),
        collapseWhitespace(format(expected)),
      );
    });

    test('encodes optional part headers and their scalar values', () {
      final content = multipartContentFixture(context, [
        multipartPartFixture(
          name: 'value',
          model: StringModel(context: context),
          encoding: PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            style: null,
            explode: null,
            allowReserved: null,
            headers: {
              'X-Label': ResponseHeaderObject(
                name: 'X-Label',
                context: context,
                description: null,
                explode: false,
                model: IntegerModel(context: context),
                isRequired: false,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                examples: const [],
              ),
            },
          ),
        ),
      ]);
      const expected = r'''
Object? test() {
  final _$multipartParts = <TonikMultipartPart>[];
  final _$valueHeaders = <String, String>{};
  if (valueLabel != null) {
    _$valueHeaders[r'X-Label'] = valueLabel.toSimple(explode: false, allowEmpty: true);
  }
  _$multipartParts.add(
    TonikMultipartPart(
      name: r'value',
      bytes: utf8.encode(body.value),
      contentType: r'text/plain',
      headers: _$valueHeaders,
    ),
  );
  return TonikMultipartBody(_$multipartParts);
}
''';
      expect(
        collapseWhitespace(emit(content)),
        collapseWhitespace(format(expected)),
      );
    });

    test('rejects a cyclic alias', () {
      final model = AliasModel(
        name: 'CyclicValue',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      model.model = model;

      expectPropertyCode(
        model,
        '  throw EncodingException(r"Cannot encode cyclic AliasModel '
        'property \'value\'.");',
      );
    });

    test('emits an encoding failure for Never', () {
      expectPropertyCode(
        NeverModel(context: context, isNullable: false),
        '  throw EncodingException(r"Cannot encode NeverModel property '
        '\'value\' - this type does not permit any value.");',
      );
    });

    test('JSON encodes unconstrained values', () {
      expectPropertyCode(AnyModel(context: context), r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(encodeAnyToJson(body.value))),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''');
    });

    test('JSON encodes maps', () {
      expectPropertyCode(
        MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(body.value)),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''',
      );
    });

    for (final entry in <({String name, Model model})>[
      (name: 'class', model: _classModel(context, 'Nested')),
      (
        name: 'allOf',
        model: AllOfModel(
          name: 'Combined',
          models: [_classModel(context, 'AllOfMember')],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      ),
      (
        name: 'oneOf',
        model: OneOfModel(
          name: 'Either',
          models: [
            (
              discriminatorValue: null,
              model: _classModel(context, 'OneOfMember'),
            ),
          ],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      ),
      (
        name: 'anyOf',
        model: AnyOfModel(
          name: 'Any',
          models: [
            (
              discriminatorValue: null,
              model: _classModel(context, 'AnyOfMember'),
            ),
          ],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      ),
    ]) {
      test('JSON encodes ${entry.name} objects', () {
        expectPropertyCode(entry.model, r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(body.value.toJson())),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''');
      });
    }

    test('emits deepObject entries as bracket-named parts', () {
      expectPropertyCode(
        _classModel(context, 'Nested'),
        r'''
  for (final entry in body.value.toDeepObject(
    r'value',
    explode: true,
    allowEmpty: true,
  )) {
    _$multipartFiles.add(
      MultipartFile.fromBytes(
        entry.name,
        utf8.encode(entry.value),
        contentType: MediaType.parse(r'application/x-www-form-urlencoded'),
      ),
    );
  }''',
        encoding: _encoding(
          style: EncodingStyle.deepObject,
          explode: true,
          allowReserved: false,
        ),
      );
    });

    test('form-encodes an object in content-based mode', () {
      expectPropertyCode(
        _classModel(context, 'Nested'),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(
        body.value
            .toForm(
              r'value',
              explode: true,
              allowEmpty: true,
              useQueryComponent: true,
              textEncoding: utf8,
            )
            .map((entry) => '${entry.name}=${entry.value}')
            .join('&'),
      ),
      contentType: MediaType.parse(
        r'application/x-www-form-urlencoded',
      ),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.form,
          rawContentType: 'application/x-www-form-urlencoded',
        ),
      );
    });

    test('uses plain and JSON encodings for string enums', () {
      final model = _stringEnum(context);
      expectPropertyCode(model, r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value.toJson()),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );''');
      expectPropertyCode(
        model,
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(body.value.toJson())),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      );
    });

    test('uses a plain string for integer enums', () {
      expectPropertyCode(_integerEnum(context), r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value.toJson().toString()),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );''');
    });

    test('uses plain and JSON encodings for DateTime', () {
      final model = DateTimeModel(context: context);
      expectPropertyCode(model, r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value.toTimeZonedIso8601String()),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );''');
      expectPropertyCode(
        model,
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(body.value)),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      );
    });

    test('uses plain and JSON encodings for numeric primitives', () {
      final model = IntegerModel(context: context);
      expectPropertyCode(model, r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value.toString()),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );''');
      expectPropertyCode(
        model,
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(body.value)),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      );
    });

    test('semantic encoding selects HTTP multipart text bytes', () {
      expectPropertyCode(
        StringModel(context: context),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      ascii.encode(body.value),
      contentType: MediaType.parse(r'text/plain; charset=iso-8859-1'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=iso-8859-1',
          textEncoding: TextEncoding.ascii,
        ),
      );
    });

    test('semantic encoding reaches every HTTP multipart text path', () {
      expectPropertyCode(
        StringModel(context: context),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      latin1.encode(body.value),
      contentType: MediaType.parse(
        r'application/vnd.example.text; charset=iso-8859-1',
      ),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.bytes,
          rawContentType: 'application/vnd.example.text; charset=iso-8859-1',
          textEncoding: TextEncoding.latin1,
        ),
      );
      expectPropertyCode(
        IntegerModel(context: context),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      latin1.encode(body.value.toString()),
      contentType: MediaType.parse(r'text/plain; charset=us-ascii'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
        ),
      );
      expectPropertyCode(
        _stringEnum(context),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      latin1.encode(body.value.toJson()),
      contentType: MediaType.parse(r'text/plain; charset=us-ascii'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
        ),
      );
      expectPropertyCode(
        AnyModel(context: context),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      latin1.encode(jsonEncode(encodeAnyToJson(body.value))),
      contentType: MediaType.parse(r'application/json; charset=us-ascii'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.json,
          rawContentType: 'application/json; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
        ),
      );
      expectPropertyCode(
        _classModel(context, 'Nested'),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      latin1.encode(jsonEncode(body.value.toJson())),
      contentType: MediaType.parse(r'application/json; charset=us-ascii'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.json,
          rawContentType: 'application/json; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
        ),
      );
      expectPropertyCode(
        _classModel(context, 'Styled'),
        r'''
  for (final entry in body.value
      .parameterProperties(allowEmpty: true)
      .toRawStyleParts(r'value', explode: true)) {
    _$multipartFiles.add(
      MultipartFile.fromBytes(
        entry.name,
        latin1.encode(entry.value),
        contentType: MediaType.parse(r'text/plain'),
      ),
    );
  }''',
        encoding: _encoding(
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
        ),
      );
      expectPropertyCode(
        _list(context, StringModel(context: context)),
        r'''
  for (final item in body.value) {
    _$multipartFiles.add(
      MultipartFile.fromBytes(
        r'value',
        latin1.encode(item),
        contentType: MediaType.parse(r'text/plain; charset=us-ascii'),
      ),
    );
  }''',
        encoding: _encoding(
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
        ),
      );
    });
  });

  group('content-based arrays', () {
    test('rejects arrays of arrays', () {
      expectPropertyCode(
        ListModel(
          content: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        "  throw EncodingException(r'Arrays of arrays are not supported for "
        "multipart encoding (property: value).');",
      );
    });

    test('rejects unsupported content types', () {
      expectPropertyCode(
        _list(context, StringModel(context: context)),
        '''  throw EncodingException(r'Unsupported contentType '''
        '''"application/x-www-form-urlencoded" for array multipart property '''
        '''"value". Only application/json is supported for content-based array '''
        '''serialization.');''',
        encoding: _encoding(
          contentType: ContentType.form,
          rawContentType: 'application/x-www-form-urlencoded',
        ),
      );
    });

    test('accepts application/octet-stream content encoding', () {
      expectPropertyCode(
        _list(context, IntegerModel(context: context)),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(body.value)),
      contentType: MediaType.parse(r'application/octet-stream'),
    ),
  );''',
        encoding: _encoding(
          contentType: ContentType.bytes,
          rawContentType: 'application/octet-stream',
        ),
      );
    });

    for (final entry in <({String name, Model model, String encodedValue})>[
      (
        name: 'objects',
        model: _classModel(context, 'ListItem'),
        encodedValue: 'body.value.map((item) => item.toJson()).toList()',
      ),
      (
        name: 'enums',
        model: _stringEnum(context),
        encodedValue: 'body.value.map((item) => item.toJson()).toList()',
      ),
      (
        name: 'dates',
        model: DateTimeModel(context: context),
        encodedValue:
            'body.value.map((item) => '
            'item.toTimeZonedIso8601String()).toList()',
      ),
      (
        name: 'unconstrained values',
        model: AnyModel(context: context),
        encodedValue:
            'body.value.map((item) => encodeAnyToJson(item)).toList()',
      ),
      (
        name: 'integers',
        model: IntegerModel(context: context),
        encodedValue: 'body.value',
      ),
    ]) {
      test('JSON encodes ${entry.name}', () {
        expectPropertyCode(
          _list(context, entry.model),
          '''
  _\$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(jsonEncode(${entry.encodedValue})),
      contentType: MediaType.parse(r'application/json'),
    ),
  );''',
          encoding: _encoding(
            contentType: ContentType.json,
            rawContentType: 'application/json',
          ),
        );
      });
    }
  });

  group('repeated and style-based arrays', () {
    test('rejects a cyclic item alias', () {
      final item = AliasModel(
        name: 'CyclicItem',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      item.model = item;

      expectPropertyCode(
        _list(context, item),
        '  throw EncodingException(r"Cannot encode cyclic AliasModel list '
        'items for multipart property \'value\'.");',
      );
    });

    for (final entry in <({String name, Model model, String encodedItem})>[
      (
        name: 'objects',
        model: _classModel(context, 'RepeatedItem'),
        encodedItem: 'jsonEncode(item.toJson())',
      ),
      (
        name: 'maps',
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        encodedItem: 'jsonEncode(item)',
      ),
      (
        name: 'unconstrained values',
        model: AnyModel(context: context),
        encodedItem: 'jsonEncode(encodeAnyToJson(item))',
      ),
    ]) {
      test('emits one JSON part for each ${entry.name} item', () {
        expectPropertyCode(_list(context, entry.model), '''
  for (final item in body.value) {
    _\$multipartFiles.add(
      MultipartFile.fromBytes(
        r'value',
        utf8.encode(${entry.encodedItem}),
        contentType: MediaType.parse(r'application/json'),
      ),
    );
  }''', encoding: _encoding(style: EncodingStyle.form, explode: true));
      });
    }

    test('joins a non-exploded string array into one part', () {
      expectPropertyCode(
        _list(context, StringModel(context: context)),
        r'''
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value.toSimple(explode: false, allowEmpty: true)),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );''',
        encoding: _encoding(
          style: EncodingStyle.form,
          explode: false,
          allowReserved: false,
        ),
      );
    });

    for (final entry in <({EncodingStyle style, String method})>[
      (style: EncodingStyle.pipeDelimited, method: 'toPipeDelimited'),
      (style: EncodingStyle.spaceDelimited, method: 'toSpaceDelimited'),
    ]) {
      test('honors ${entry.style.name} for a non-exploded string array', () {
        final delimiterArgument = entry.style == EncodingStyle.spaceDelimited
            ? '\n    percentEncodeDelimiter: false,'
            : '';
        expectPropertyCode(
          _list(context, StringModel(context: context)),
          '''
  for (final item in body.value.${entry.method}(
    explode: false,
    allowEmpty: true,
    alreadyEncoded: true,$delimiterArgument
  )) {
    _\$multipartFiles.add(
      MultipartFile.fromBytes(
        r'value',
        utf8.encode(item),
        contentType: MediaType.parse(r'text/plain'),
      ),
    );
  }''',
          encoding: _encoding(
            style: entry.style,
            explode: false,
            allowReserved: false,
          ),
        );
      });
    }

    for (final entry in <({String name, Model model, String encodedItem})>[
      (
        name: 'string enums',
        model: _stringEnum(context),
        encodedItem: 'item.toJson()',
      ),
      (
        name: 'integer enums',
        model: _integerEnum(context),
        encodedItem: 'item.toJson().toString()',
      ),
      (
        name: 'dates',
        model: DateTimeModel(context: context),
        encodedItem: 'item.toTimeZonedIso8601String()',
      ),
      (
        name: 'integers',
        model: IntegerModel(context: context),
        encodedItem: 'item.toString()',
      ),
    ]) {
      test('emits one text part for each ${entry.name} item', () {
        expectPropertyCode(_list(context, entry.model), '''
  for (final item in body.value) {
    _\$multipartFiles.add(
      MultipartFile.fromBytes(
        r'value',
        utf8.encode(${entry.encodedItem}),
        contentType: MediaType.parse(r'text/plain'),
      ),
    );
  }''');
      });
    }
  });

  group('regular multipart root models', () {
    test('discovers class, alias, and nested allOf member access in order', () {
      final files = _classWithProperties(context, 'UploadFiles', [
        _property(
          context,
          'files',
          _list(context, BinaryModel(context: context)),
        ),
      ]);
      final metadataBase = _classWithProperties(context, 'MetadataBase', [
        _property(context, 'metadata', _classModel(context, 'Base')),
      ]);
      final annotations = _classWithProperties(context, 'Annotations', [
        _property(context, 'metadata', _classModel(context, 'Details')),
      ]);
      final nested = _allOf(context, 'Nested', [metadataBase, annotations]);
      final root = AliasModel(
        name: 'UploadAlias',
        context: context,
        model: _allOf(context, 'Upload', [files, nested]),
        defaultValue: null,
        examples: const [],
      );

      final properties = normalizeMultipartProperties(_content(root));
      expect(properties.map((property) => property.rawName), [
        'files',
        'metadata',
      ]);
      expect(
        properties.first.accessPaths.single.map((segment) => segment.name),
        ['uploadFiles', 'files'],
      );
      expect(
        properties.last.accessPaths.map(
          (path) => path.map((segment) => segment.name).toList(),
        ),
        [
          ['nested', 'metadataBase', 'metadata'],
          ['nested', 'annotations', 'metadata'],
        ],
      );
    });

    test('rejects unsupported map roots clearly', () {
      final content = _content(
        MapModel(
          valueModel: BinaryModel(context: context),
          context: context,
          examples: const [],
        ),
      );
      expect(
        () => emit(content),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Unsupported multipart body root/member MapModel'),
          ),
        ),
      );
    });

    test('rejects Cloudflare-style dynamic parts before emitting parts', () {
      final model = _classWithProperties(
        context,
        'Snippet',
        [_property(context, 'metadata', _classModel(context, 'Metadata'))],
        additionalProperties: AllowedAdditionalProperties(
          valueModel: BinaryModel(context: context),
        ),
      );
      expect(
        () => emit(_content(model)),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Dynamic multipart part names are not supported'),
          ),
        ),
      );
    });

    test('allows the implicit object additional-properties default', () {
      final model = _classWithProperties(context, 'Upload', [
        _property(context, 'label', StringModel(context: context)),
      ]);
      expect(emit(_content(model)), contains('body.label'));
    });

    test('rejects cycles and unmatched raw encoding keys', () {
      final alias = AliasModel(
        name: 'Cycle',
        context: context,
        model: StringModel(context: context),
        defaultValue: null,
        examples: const [],
      );
      alias.model = alias;
      expect(
        () => normalizeMultipartProperties(_content(alias)),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('cycle'),
          ),
        ),
      );

      final model = _classWithProperties(context, 'Upload', [
        _property(context, 'raw-name', StringModel(context: context)),
      ]);
      expect(
        () => normalizeMultipartProperties(
          _content(model, encoding: {'normalizedName': _encoding()}),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('normalizedName'),
          ),
        ),
      );
    });

    test('uses effective model and root nullability in generated access', () {
      final nullableValue = AliasModel(
        name: 'NullableValue',
        context: context,
        model: StringModel(context: context),
        isNullable: true,
        defaultValue: null,
        examples: const [],
      );
      final nullableClass = _classWithProperties(context, 'Upload', [
        _property(context, 'value', nullableValue),
      ], isNullable: true);
      final property = normalizeMultipartProperties(_content(nullableClass))
          .single;
      expect(property.isNullable, isTrue);
      expect(emit(_content(nullableClass)), contains('body?.value'));

      final member = _classWithProperties(context, 'Member', [
        _property(context, 'value', StringModel(context: context)),
      ]);
      final nullableAllOf = _allOf(context, 'NullableAllOf', [
        member,
      ], isNullable: true);
      expect(emit(_content(nullableAllOf)), contains('body?.member?.value'));
    });

    test(
      'keeps required write-only parts required but guards their access',
      () {
        final model = _classWithProperties(context, 'Credentials', [
          _property(
            context,
            'secret',
            StringModel(context: context),
            isWriteOnly: true,
          ),
        ]);

        final property = normalizeMultipartProperties(_content(model)).single;
        expect(property.isRequired, isTrue);
        expect(property.isNullable, isTrue);
        final code = emit(_content(model));
        expect(code, contains('if (body.secret == null)'));
        expect(code, contains('Required multipart property "secret" is null.'));
        expect(code, contains('utf8.encode(body.secret!)'));
      },
    );

    test('rejects read-only roots and excludes read-only members', () {
      final readOnly = _classWithProperties(context, 'ReadOnly', [
        _property(context, 'server', StringModel(context: context)),
      ], isReadOnly: true);
      expect(
        () => emit(_content(readOnly)),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('read-only'),
          ),
        ),
      );

      final writable = _classWithProperties(context, 'Writable', [
        _property(context, 'client', StringModel(context: context)),
      ]);
      final properties = normalizeMultipartProperties(
        _content(_allOf(context, 'Combined', [readOnly, writable])),
      );
      expect(properties.map((property) => property.rawName), ['client']);
    });

    test('rejects incompatible nested duplicate definitions structurally', () {
      final leftMetadata = _classWithProperties(context, 'LeftMetadata', [
        _property(context, 'id', StringModel(context: context)),
      ]);
      final rightMetadata = _classWithProperties(context, 'RightMetadata', [
        _property(context, 'id', IntegerModel(context: context)),
      ]);
      final root = _allOf(context, 'Upload', [
        _classWithProperties(context, 'Left', [
          _property(context, 'metadata', leftMetadata, isRequired: false),
        ]),
        _classWithProperties(context, 'Right', [
          _property(context, 'metadata', rightMetadata, isRequired: false),
        ]),
      ]);
      expect(
        () => emit(_content(root)),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('incompatible definitions'),
          ),
        ),
      );
    });

    test('compares nested explicit additional-properties policies', () {
      ClassModel metadata(AdditionalPropertiesPolicy policy) =>
          _classWithProperties(context, 'Metadata', [
            _property(context, 'id', StringModel(context: context)),
          ], additionalProperties: policy);

      AllOfModel root(Model left, Model right) => _allOf(context, 'Upload', [
        _classWithProperties(context, 'Left', [
          _property(context, 'metadata', left),
        ]),
        _classWithProperties(context, 'Right', [
          _property(context, 'metadata', right),
        ]),
      ]);

      final allowedString = AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
      );
      final anotherAllowedString = AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
      );
      final allowedInteger = AllowedAdditionalProperties(
        valueModel: IntegerModel(context: context),
      );

      expect(
        emit(
          _content(
            root(metadata(allowedString), metadata(anotherAllowedString)),
          ),
        ),
        contains('mergeMultipartValues'),
      );
      for (final incompatible in [
        root(metadata(allowedString), metadata(allowedInteger)),
        root(
          metadata(allowedString),
          metadata(const ForbiddenAdditionalProperties()),
        ),
      ]) {
        expect(
          () => emit(_content(incompatible)),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('incompatible definitions'),
            ),
          ),
        );
      }

      expect(
        emit(
          _content(
            root(
              _classWithProperties(context, 'ImplicitMetadata', [
                _property(context, 'id', StringModel(context: context)),
              ]),
              metadata(const ForbiddenAdditionalProperties()),
            ),
          ),
        ),
        contains('mergeMultipartValues'),
      );
    });

    test('only merges duplicate enum values from the same generated type', () {
      final shared = _stringEnum(context);
      AllOfModel root(Model left, Model right) => _allOf(context, 'Upload', [
        _classWithProperties(context, 'Left', [
          _property(context, 'status', left),
        ]),
        _classWithProperties(context, 'Right', [
          _property(context, 'status', right),
        ]),
      ]);

      expect(
        emit(_content(root(shared, shared))),
        contains('body.left.status'),
      );
      expect(
        () => emit(_content(root(_stringEnum(context), _stringEnum(context)))),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('incompatible definitions'),
          ),
        ),
      );
    });

    test('merges compatible duplicate objects without losing object style', () {
      final root = _duplicateMetadataRoot(context);
      final jsonCode = emit(_content(root));
      expect(jsonCode, contains('body.left.metadata.toJson()'));
      expect(jsonCode, contains('body.right.metadata.toJson()'));
      expect(jsonCode, contains('mergeObjects: true'));
      expect(jsonCode, contains(r'jsonEncode(_$metadataMultipartValue)'));

      final styleCode = emit(
        _content(
          root,
          encoding: {
            'metadata': _encoding(style: EncodingStyle.form, explode: true),
          },
        ),
      );
      expect(styleCode, contains('body.left.metadata.parameterProperties'));
      expect(styleCode, contains('body.right.metadata.parameterProperties'));
      expect(styleCode, contains('mergeMultipartPropertyValues'));
      expect(styleCode, contains('toRawStyleParts'));
      expect(styleCode, isNot(contains('jsonEncode')));

      final deepObjectCode = emit(
        _content(
          root,
          encoding: {
            'metadata': _encoding(
              style: EncodingStyle.deepObject,
              explode: true,
            ),
          },
        ),
      );
      expect(deepObjectCode, contains('mergeMultipartPropertyValues'));
      expect(deepObjectCode, contains('toDeepObject'));

      final formCode = emit(
        _content(
          root,
          encoding: {
            'metadata': _encoding(
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
            ),
          },
        ),
      );
      expect(formCode, contains('mergeMultipartPropertyValues'));
      expect(formCode, contains('toForm'));
    });

    test('merges repeated mutable and immutable lists and maps in order', () {
      final list = _list(context, StringModel(context: context));
      final map = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );
      final root = _allOf(context, 'Collections', [
        _classWithProperties(context, 'First', [
          _property(context, 'items', list),
          _property(context, 'metadata', map),
        ]),
        _classWithProperties(context, 'Second', [
          _property(context, 'items', list),
          _property(context, 'metadata', map),
        ]),
      ]);
      final mutable = emit(_content(root));
      expect(mutable, contains('body.first.items'));
      expect(mutable, contains('body.second.items'));
      expect(mutable, contains("propertyName: r'items'"));
      expect(mutable, contains("propertyName: r'metadata'"));
      expect(mutable, contains('mergeObjects: true'));

      final nonExploded = emit(
        _content(
          root,
          encoding: {
            'items': _encoding(style: EncodingStyle.form, explode: false),
          },
        ),
      );
      expect(nonExploded, contains('mergeMultipartLists'));
      expect(nonExploded, contains("propertyName: r'items')!"));
      expect(nonExploded, contains(r'_$itemsMultipartValue.toSimple'));

      const immutablePlanner = MultipartBodyPlanner(
        backend: TransportBackend.http,
        useImmutableCollections: true,
      );
      final immutablePlan = immutablePlanner.plan(
        _content(root),
        bodyAccessor: 'body',
        isRequired: true,
      );
      final method = Method(
        (builder) => builder
          ..name = 'test'
          ..body = Block.of(buildHttpMultipartBodyStatements(immutablePlan)),
      );
      final immutableCode = format('${method.accept(emitter)}');
      expect(immutableCode, contains('body.first.items.unlock'));
      expect(immutableCode, contains('body.second.metadata.unlock'));
    });
  });
}

ClassModel _classModel(Context context, String name) => ClassModel(
  name: name,
  properties: const [],
  context: context,
  isDeprecated: false,
  examples: const [],
);

ClassModel _classWithProperties(
  Context context,
  String name,
  List<Property> properties, {
  AdditionalPropertiesPolicy? additionalProperties,
  bool isNullable = false,
  bool isReadOnly = false,
}) => ClassModel(
  name: name,
  properties: properties,
  context: context,
  additionalPropertiesPolicy: additionalProperties,
  isNullable: isNullable,
  isReadOnly: isReadOnly,
  isDeprecated: false,
  examples: const [],
);

Property _property(
  Context context,
  String name,
  Model model, {
  bool isRequired = true,
  bool isNullable = false,
  bool isWriteOnly = false,
}) => Property(
  name: name,
  model: model,
  isRequired: isRequired,
  isNullable: isNullable,
  isWriteOnly: isWriteOnly,
  isDeprecated: false,
  examples: const [],
  defaultValue: null,
);

AllOfModel _allOf(
  Context context,
  String name,
  List<Model> models, {
  bool isNullable = false,
}) => AllOfModel(
  name: name,
  models: models,
  context: context,
  isNullable: isNullable,
  isDeprecated: false,
  examples: const [],
);

MultipartRequestContent _content(
  Model model, {
  Map<String, PartEncoding> encoding = const {},
}) => MultipartRequestContent(
  model: model,
  encoding: encoding,
  rawContentType: 'multipart/form-data',
  examples: const [],
);

AllOfModel _duplicateMetadataRoot(Context context) =>
    _allOf(context, 'Upload', [
      _classWithProperties(context, 'Left', [
        _property(
          context,
          'metadata',
          _classWithProperties(context, 'MetadataBase', [
            _property(context, 'id', StringModel(context: context)),
          ]),
        ),
      ]),
      _classWithProperties(context, 'Right', [
        _property(
          context,
          'metadata',
          _classWithProperties(context, 'MetadataDetails', [
            _property(context, 'label', StringModel(context: context)),
          ]),
        ),
      ]),
    ]);

ListModel _list(Context context, Model content) =>
    ListModel(content: content, context: context, examples: const []);

EnumModel<String> _stringEnum(Context context) => EnumModel(
  name: 'StringValue',
  values: {const EnumEntry(value: 'value')},
  isNullable: false,
  context: context,
  isDeprecated: false,
  examples: const [],
);

EnumModel<int> _integerEnum(Context context) => EnumModel(
  name: 'IntegerValue',
  values: {const EnumEntry(value: 1)},
  isNullable: false,
  context: context,
  isDeprecated: false,
  examples: const [],
);

PartEncoding _encoding({
  ContentType? contentType,
  String? rawContentType,
  String? wireContentType,
  TextEncoding textEncoding = TextEncoding.utf8,
  EncodingStyle? style,
  bool? explode,
  bool? allowReserved,
}) => PartEncoding(
  contentType: contentType,
  rawContentType: rawContentType,
  wireContentType: wireContentType ?? rawContentType,
  textEncoding: textEncoding,
  headers: null,
  style: style,
  explode: explode,
  allowReserved: allowReserved,
);
