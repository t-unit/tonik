import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_body_generator.dart';
import 'package:tonik_util/tonik_util.dart';

import '../multipart_test_support.dart';

void main() {
  late HttpBodyGenerator generator;
  late Context context;
  late DartEmitter emitter;
  late String Function(String, {Object? uri}) format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    format = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
        .format;
    generator = HttpBodyGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
      package: 'test_package',
    );
  });

  test('emits no synthetic payload when the request body is absent', () {
    final method = generator.generateBodyMethod(_operation(context));

    const expected = '''
Object? _data() {
  return null;
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('JSON encodes a scalar exactly once before UTF-8 encoding', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: StringModel(context: context),
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      ),
    );

    const expected = '''
Object? _data({required String body}) {
  return utf8.encode(jsonEncode(body));
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('JSON encodes a nested order object exactly once', () {
    final customer = _customerModel(context);
    final lineItem = _lineItemModel(context);
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: ClassModel(
            name: 'CreateOrderRequest',
            properties: [
              Property(
                name: 'customer',
                model: customer,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'lineItems',
                model: ListModel(
                  content: lineItem,
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
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      ),
    );

    const expected = '''
Object? _data({required CreateOrderRequest body}) {
  return utf8.encode(jsonEncode(body.toJson()));
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('JSON encodes grouped line items through a map and lists once', () {
    final lineItem = _lineItemModel(context);

    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: MapModel(
            valueModel: ListModel(
              content: lineItem,
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      ),
    );

    const expected = '''
Object? _data({required Map<String, List<LineItem>> body}) {
  return utf8.encode(
    jsonEncode(
      body.map(
        (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
      ),
    ),
  );
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('semantic encoding selects HTTP text bytes for required bodies', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: StringModel(context: context),
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=us-ascii',
          textEncoding: TextEncoding.latin1,
        ),
      ),
    );

    const expected = '''
Object? _data({required String body}) {
  return latin1.encode(body);
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('preserves binary body bytes unchanged', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: BinaryModel(context: context),
          contentType: ContentType.bytes,
          rawContentType: 'application/octet-stream',
        ),
      ),
    );

    const expected = '''
Object? _data({required TonikFile body}) {
  return body.toBytes();
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('omits an optional body without encoding JSON null', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: StringModel(context: context),
          contentType: ContentType.json,
          rawContentType: 'application/json',
          isRequired: false,
        ),
      ),
    );

    const expected = '''
Object? _data({String? body}) {
  if (body == null) return null;
  return utf8.encode(jsonEncode(body));
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('uses a promoted optional nullable JSON model directly', () {
    final model = ClassModel(
      name: 'NullablePayload',
      properties: const [],
      context: context,
      isDeprecated: false,
      isNullable: true,
      examples: const [],
    );
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: model,
          contentType: ContentType.json,
          rawContentType: 'application/json',
          isRequired: false,
        ),
      ),
    );

    const expected = '''
Object? _data({NullablePayload? body}) {
  if (body == null) return null;
  return utf8.encode(jsonEncode(body.toJson()));
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  group('form-urlencoded bodies', () {
    test('UTF-8 encodes a scalar without inventing a field name', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _body(
            context,
            model: StringModel(context: context),
            contentType: ContentType.form,
            rawContentType: 'application/x-www-form-urlencoded',
          ),
        ),
      );

      const expected = r'''
Object? _data({required String body}) {
  return utf8.encode(
    body
        .toForm(
          '',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: utf8,
        )
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
        .join('&'),
  );
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test('Latin-1 percent-encodes a scalar from raw text in one pass', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _body(
            context,
            model: StringModel(context: context),
            contentType: ContentType.form,
            rawContentType:
                'application/x-www-form-urlencoded; charset=iso-8859-1',
            textEncoding: TextEncoding.latin1,
          ),
        ),
      );

      const expected = r'''
Object? _data({required String body}) {
  return utf8.encode(
    body
        .toForm(
          '',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: latin1,
        )
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
        .join('&'),
  );
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test('UTF-8 encodes a top-level array without collapsing entries', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _body(
            context,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            contentType: ContentType.form,
            rawContentType: 'application/x-www-form-urlencoded',
          ),
        ),
      );

      const expected = r'''
Object? _data({required List<String> body}) {
  return utf8.encode(
    body
        .toForm(
          '',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: utf8,
        )
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
        .join('&'),
  );
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'UTF-8 encodes an object with reserved and repeated field metadata',
      () {
        final form = _profileFormModel(context);
        final method = generator.generateBodyMethod(
          _operation(
            context,
            requestBody: _body(
              context,
              model: form.model,
              contentType: ContentType.form,
              rawContentType: 'application/x-www-form-urlencoded',
              formEncoding: {
                form.callback: const FieldEncoding(
                  allowReserved: true,
                  style: EncodingStyle.form,
                  explode: true,
                ),
                form.tags: const FieldEncoding(
                  allowReserved: false,
                  style: EncodingStyle.form,
                  explode: true,
                ),
              },
            ),
          ),
        );

        const expected = r'''
Object? _data({required ProfileSubmission body}) {
  return utf8.encode(
    body
        .toForm(
          '',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: utf8,
          fieldEncodings: <String, FormFieldEncoding>{
            r'callback': const FormFieldEncoding(allowReserved: true),
            r'tags': const FormFieldEncoding(explode: true),
          },
        )
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
        .join('&'),
  );
}
''';

        expect(
          collapseWhitespace(format('${method.accept(emitter)}')),
          collapseWhitespace(format(expected)),
        );
      },
    );

    test('omits an optional object before applying field encodings', () {
      final form = _profileFormModel(context);
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _body(
            context,
            model: form.model,
            contentType: ContentType.form,
            rawContentType: 'application/x-www-form-urlencoded',
            isRequired: false,
            formEncoding: {
              form.callback: const FieldEncoding(
                allowReserved: true,
                style: EncodingStyle.form,
                explode: true,
              ),
            },
          ),
        ),
      );

      const expected = r'''
Object? _data({ProfileSubmission? body}) {
  if (body == null) return null;
  return utf8.encode(
    body
        .toForm(
          '',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: utf8,
          fieldEncodings: <String, FormFieldEncoding>{
            r'callback': const FormFieldEncoding(allowReserved: true),
            r'tags': const FormFieldEncoding(explode: true),
          },
        )
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
        .join('&'),
  );
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'produces exact bytes for Unicode reserved empty and repeated values',
      () {
        final entries =
            <String, PropertyValue>{
              'display name': const PropertyValue.scalar('Zoë & Co'),
              'callback': const PropertyValue.scalar(
                'https://example.test/a/b?x=1&next=%2F',
              ),
              'tags': const PropertyValue.array(['red & blue', '', '雪']),
              'note': const PropertyValue.scalar(''),
            }.toForm(
              '',
              explode: true,
              allowEmpty: true,
              useQueryComponent: true,
              fieldEncodings: const {
                'callback': FormFieldEncoding(allowReserved: true),
                'tags': FormFieldEncoding(explode: true),
              },
              textEncoding: utf8,
            );

        final wireBody = entries
            .map(
              (entry) => entry.name.isEmpty
                  ? entry.value
                  : '${entry.name}=${entry.value}',
            )
            .join('&');
        const expected =
            'display+name=Zo%C3%AB+%26+Co'
            '&callback=https://example.test/a/b?x%3D1%26next%3D%252F'
            '&tags=red+%26+blue'
            '&tags='
            '&tags=%E9%9B%AA'
            '&note=';

        expect(wireBody, expected);
        expect(utf8.encode(wireBody), utf8.encode(expected));
      },
    );
  });

  test('semantic encoding selects HTTP text bytes for optional bodies', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: StringModel(context: context),
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=utf-16',
          textEncoding: TextEncoding.ascii,
          isRequired: false,
        ),
      ),
    );

    const expected = '''
Object? _data({String? body}) {
  if (body == null) return null;
  return ascii.encode(body);
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('lowers each selected non-multipart content type to bytes', () {
    final requestBody = RequestBodyObject(
      name: 'payload',
      context: context,
      description: null,
      isRequired: true,
      content: {
        ModelRequestContent(
          model: StringModel(context: context),
          contentType: ContentType.json,
          rawContentType: 'application/json',
          examples: const [],
        ),
        ModelRequestContent(
          model: StringModel(context: context),
          contentType: ContentType.text,
          rawContentType: 'text/plain',
          wireContentType: 'text/plain',
          textEncoding: TextEncoding.latin1,
          examples: const [],
        ),
      },
    );
    final method = generator.generateBodyMethod(
      _operation(context, requestBody: requestBody),
    );

    const expected = '''
Object? _data({required Payload body}) {
  return switch (body) {
    final PayloadJson value => utf8.encode(jsonEncode(value.value)),
    final PayloadPlain value => latin1.encode(value.value),
  };
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('does not bind the value of an empty multipart variant', () {
    final requestBody = RequestBodyObject(
      name: 'payload',
      context: context,
      description: null,
      isRequired: true,
      content: {
        ModelRequestContent(
          model: StringModel(context: context),
          contentType: ContentType.json,
          rawContentType: 'application/json',
          examples: const [],
        ),
        multipartContentFixture(context, const []),
      },
    );
    final method = generator.generateBodyMethod(
      _operation(context, requestBody: requestBody),
    );
    const expected = r'''
Future<Object?> _data({required Payload body}) async {
  return switch (body) {
    final PayloadJson value => utf8.encode(jsonEncode(value.value)),
    final PayloadFormData _ => await () async {
      final _$multipartFiles = <MultipartFile>[];
      return _$multipartFiles;
    }(),
  };
}
''';
    expect(
      collapseWhitespace(format(method.accept(emitter).toString())),
      collapseWhitespace(format(expected)),
    );
  });

  test('lowers a runtime-selected JSON or multipart body', () {
    final requestBody = RequestBodyObject(
      name: 'payload',
      context: context,
      description: null,
      isRequired: true,
      content: {
        ModelRequestContent(
          model: StringModel(context: context),
          contentType: ContentType.json,
          rawContentType: 'application/json',
          examples: const [],
        ),
        multipartContentFixture(context, [
          multipartPartFixture(
            name: 'value',
            model: StringModel(context: context),
          ),
        ], name: 'Upload'),
      },
    );
    final method = generator.generateBodyMethod(
      _operation(context, requestBody: requestBody),
    );

    const expected = r'''
Future<Object?> _data({required Payload body}) async {
  return switch (body) {
    final PayloadJson value => utf8.encode(jsonEncode(value.value)),
    final PayloadFormData value => await () async {
      final _$multipartFiles = <MultipartFile>[];
      _$multipartFiles.add(
        MultipartFile.fromBytes(
          r'value',
          utf8.encode(value.value.value),
          contentType: MediaType.parse(r'text/plain'),
        ),
      );
      return _$multipartFiles;
    }(),
  };
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  group('multipart bodies', () {
    test('rejects incompatible duplicate multipart definitions', () {
      final operation = _operation(
        context,
        requestBody: _multipartBody(context, [
          multipartPartFixture(
            name: 'item',
            model: StringModel(context: context),
          ),
          multipartPartFixture(
            name: 'item',
            model: BinaryModel(context: context),
          ),
        ], name: 'Upload'),
      );

      expect(
        () => generator.generateBodyMethod(operation),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Multipart property "item" has incompatible definitions'),
          ),
        ),
      );
    });

    test('emits repeated scalar and file parts in collection order', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _multipartBody(context, [
            multipartPartFixture(
              name: 'tag',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
            ),
            multipartPartFixture(
              name: 'file',
              model: ListModel(
                content: BinaryModel(context: context),
                context: context,
                examples: const [],
              ),
            ),
          ], name: 'BatchUpload'),
        ),
      );

      const expected = r'''
Future<Object?> _data({required BatchUpload body}) async {
  final _$multipartFiles = <MultipartFile>[];
  for (final item in body.tag) {
    _$multipartFiles.add(
      MultipartFile.fromBytes(
        r'tag',
        utf8.encode(item),
        contentType: MediaType.parse(r'text/plain'),
      ),
    );
  }
  for (final item in body.file) {
    _$multipartFiles.add(
      MultipartFile.fromBytes(
        r'file',
        item.toBytes(),
        filename: item.fileName ?? r'file',
        contentType: MediaType.parse(r'application/octet-stream'),
      ),
    );
  }
  return _$multipartFiles;
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test('omits an optional multipart body without emitting an empty part', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _multipartBody(
            context,
            [
              multipartPartFixture(
                name: 'value',
                model: StringModel(context: context),
              ),
            ],
            name: 'OptionalUpload',
            isRequired: false,
          ),
        ),
      );

      const expected = r'''
Future<Object?> _data({OptionalUpload? body}) async {
  if (body == null) return null;
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );
  return _$multipartFiles;
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test('uses normalized semantic fallback for HTTP multipart text', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _multipartBody(context, [
            multipartPartFixture(
              name: 'value',
              model: StringModel(context: context),
              encoding: const PartEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain; charset=utf-16',
                wireContentType: 'text/plain; charset=utf-8',
                headers: null,
                style: null,
                explode: null,
                allowReserved: null,
              ),
            ),
          ], name: 'UnsupportedTextUpload'),
        ),
      );

      const expected = r'''
Future<Object?> _data({required UnsupportedTextUpload body}) async {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(
    MultipartFile.fromBytes(
      r'value',
      utf8.encode(body.value),
      contentType: MediaType.parse(r'text/plain; charset=utf-8'),
    ),
  );
  return _$multipartFiles;
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });

    test('attaches required per-part headers to the encoded body', () {
      final method = generator.generateBodyMethod(
        _operation(
          context,
          requestBody: _multipartBody(context, [
            multipartPartFixture(
              name: 'value',
              model: StringModel(context: context),
              encoding: PartEncoding(
                contentType: null,
                rawContentType: null,
                headers: {
                  'X-Trace': ResponseHeaderObject(
                    name: 'X-Trace',
                    description: null,
                    isRequired: true,
                    isDeprecated: false,
                    explode: false,
                    model: IntegerModel(context: context),
                    context: context,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
                style: null,
                explode: null,
                allowReserved: null,
              ),
            ),
          ], name: 'HeaderUpload'),
        ),
      );

      const expected = r'''
Future<Object?> _data({
  required HeaderUpload body,
  required int valueTrace,
}) async {
  final _$multipartParts = <TonikMultipartPart>[];
  final _$valueHeaders = <String, String>{};
  _$valueHeaders[r'X-Trace'] = valueTrace.toSimple(
    explode: false,
    allowEmpty: true,
  );
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
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    });
  });
}

Operation _operation(Context context, {RequestBody? requestBody}) => Operation(
  operationId: 'sendPayload',
  path: '/payload',
  method: HttpMethod.post,
  requestBody: requestBody,
  responses: const {},
  pathParameters: const {},
  queryParameters: const {},
  headers: const {},
  cookieParameters: const {},
  securitySchemes: const {},
  context: context,
  tags: const {},
  isDeprecated: false,
);

RequestBodyObject _body(
  Context context, {
  required Model model,
  required ContentType contentType,
  required String rawContentType,
  String? wireContentType,
  TextEncoding textEncoding = TextEncoding.utf8,
  bool isRequired = true,
  Map<Property, FieldEncoding>? formEncoding,
}) => RequestBodyObject(
  name: 'payload',
  context: context,
  description: null,
  isRequired: isRequired,
  content: {
    ModelRequestContent(
      model: model,
      contentType: contentType,
      rawContentType: rawContentType,
      wireContentType: wireContentType ?? rawContentType,
      textEncoding: textEncoding,
      examples: const [],
      formEncoding: formEncoding,
    ),
  },
);

RequestBodyObject _multipartBody(
  Context context,
  List<MultipartPartFixture> parts, {
  required String name,
  bool isRequired = true,
}) => RequestBodyObject(
  name: 'payload',
  context: context,
  description: null,
  isRequired: isRequired,
  content: {multipartContentFixture(context, parts, name: name)},
);

typedef _ProfileForm = ({ClassModel model, Property callback, Property tags});

_ProfileForm _profileFormModel(Context context) {
  final displayName = _formProperty(
    context,
    name: 'display name',
    model: StringModel(context: context),
  );
  final callback = _formProperty(
    context,
    name: 'callback',
    model: StringModel(context: context),
  );
  final tags = _formProperty(
    context,
    name: 'tags',
    model: ListModel(
      content: StringModel(context: context),
      context: context,
      examples: const [],
    ),
  );
  final note = _formProperty(
    context,
    name: 'note',
    model: StringModel(context: context),
    isRequired: false,
    isNullable: true,
  );

  return (
    model: ClassModel(
      name: 'ProfileSubmission',
      properties: [displayName, callback, tags, note],
      context: context,
      isDeprecated: false,
      examples: const [],
    ),
    callback: callback,
    tags: tags,
  );
}

Property _formProperty(
  Context context, {
  required String name,
  required Model model,
  bool isRequired = true,
  bool isNullable = false,
}) => Property(
  name: name,
  model: model,
  isRequired: isRequired,
  isNullable: isNullable,
  isDeprecated: false,
  examples: const [],
  defaultValue: null,
);

ClassModel _customerModel(Context context) => ClassModel(
  name: 'Customer',
  properties: [
    Property(
      name: 'id',
      model: StringModel(context: context),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
    ),
  ],
  context: context,
  isDeprecated: false,
  examples: const [],
);

ClassModel _lineItemModel(Context context) => ClassModel(
  name: 'LineItem',
  properties: [
    Property(
      name: 'sku',
      model: StringModel(context: context),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
    ),
    Property(
      name: 'quantity',
      model: IntegerModel(context: context),
      isRequired: true,
      isNullable: false,
      isDeprecated: false,
      examples: const [],
      defaultValue: null,
    ),
  ],
  context: context,
  isDeprecated: false,
  examples: const [],
);
