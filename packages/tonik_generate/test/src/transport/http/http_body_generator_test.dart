import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_body_generator.dart';

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

  test('JSON encodes an object exactly once before UTF-8 encoding', () {
    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: ClassModel(
            name: 'Payload',
            properties: const [],
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
Object? _data({required Payload body}) {
  return utf8.encode(jsonEncode(body.toJson()));
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('JSON encodes a nested recursive map exactly once', () {
    final tree = MapModel(
      name: 'Tree',
      valueModel: AnyModel(context: context),
      context: context,
      examples: const [],
    );
    tree.valueModel = tree;

    final method = generator.generateBodyMethod(
      _operation(
        context,
        requestBody: _body(
          context,
          model: tree,
          contentType: ContentType.json,
          rawContentType: 'application/json',
        ),
      ),
    );

    const expected = r'''
Object? _data({required Tree body}) {
  late final Object? Function(Object?) _$encodeTree;
  _$encodeTree = (Object? raw) {
    if (raw is! Tree) {
      throw EncodingException(
        'Cannot encode value as Tree (at \'sendPayload.body\'); got: '
        '${raw.runtimeType}',
      );
    }
    final v = raw;
    return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
  };
  return utf8.encode(jsonEncode(_$encodeTree(body)));
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

  test('UTF-8 encodes ordered form entries without a map conversion', () {
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
    ),
  },
);
