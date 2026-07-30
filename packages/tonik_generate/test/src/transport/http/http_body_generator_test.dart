import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_body_generator.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late HttpBodyGenerator generator;
  late Context context;
  late DartEmitter emitter;
  late String Function(String, {Object? uri}) format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
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

  test('uses the declared supported charset for text', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: StringModel(context: context),
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=iso-8859-1',
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

  test('emits an encoding failure for an unsupported text charset', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: StringModel(context: context),
          contentType: ContentType.text,
          rawContentType: 'text/plain; charset=utf-16',
        ),
      ),
    );

    const expected = '''
Object? _data({required String body}) {
  return throw EncodingException('Unsupported text encoding: utf-16.');
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
        RequestContent(
          model: StringModel(context: context),
          contentType: ContentType.json,
          rawContentType: 'application/json',
          examples: const [],
        ),
        RequestContent(
          model: StringModel(context: context),
          contentType: ContentType.text,
          rawContentType: 'text/plain',
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
    final PayloadPlain value => utf8.encode(value.value),
  };
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
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
  bool isRequired = true,
  Map<Property, FieldEncoding>? formEncoding,
}) => RequestBodyObject(
  name: 'payload',
  context: context,
  description: null,
  isRequired: isRequired,
  content: {
    RequestContent(
      model: model,
      contentType: contentType,
      rawContentType: rawContentType,
      examples: const [],
      formEncoding: formEncoding,
    ),
  },
);

typedef _ProfileForm = ({
  ClassModel model,
  Property callback,
  Property tags,
});

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
