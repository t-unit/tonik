import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_headers_generator.dart';

void main() {
  late Context context;
  late HttpHeadersGenerator generator;
  late DartEmitter emitter;
  late String Function(String, {Object? uri}) format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    generator = HttpHeadersGenerator(
      nameManager: NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      ),
      package: 'test_package',
    );
  });

  test('emits the default Accept header', () {
    final method = generator.generateHeadersMethod(
      _operation(context),
      const [],
      const [],
    );

    const expected = r'''
Map<String, String> _options() {
  final _$headers = <String, String>{};
  _$headers['Accept'] = r'*/*';
  return _$headers;
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('sets content type only when an optional body is present', () {
    final method = generator.generateHeadersMethod(
      _operation(
        context,
        requestBody: RequestBodyObject(
          name: 'payload',
          context: context,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
      ),
      const [],
      const [],
    );

    const expected = r'''
Map<String, String> _options({String? body}) {
  final _$contentType = body == null ? null : r'application/json';
  final _$headers = <String, String>{};
  _$headers['Accept'] = r'*/*';
  if (_$contentType != null) {
    _$headers[r'Content-Type'] = _$contentType;
  }
  return _$headers;
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test('sets content type directly for required non-multipart variants', () {
    final method = generator.generateHeadersMethod(
      _operation(
        context,
        requestBody: RequestBodyObject(
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
              contentType: ContentType.json,
              rawContentType: 'application/merge-patch+json',
              examples: const [],
            ),
          },
        ),
      ),
      const [],
      const [],
    );

    const expected = r'''
Map<String, String> _options({required Payload body}) {
  final _$contentType = switch (body) {
    PayloadJson _ => r'application/json',
    PayloadMergePatchJson _ => r'application/merge-patch+json',
  };
  final _$headers = <String, String>{};
  _$headers['Accept'] = r'*/*';
  _$headers[r'Content-Type'] = _$contentType;
  return _$headers;
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });

  test(
    'uses effective wire content type without changing declared identity',
    () {
      final requestBody = RequestBodyObject(
        name: 'payload',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.text,
            rawContentType: 'text/plain; charset=utf-16',
            wireContentType: 'text/plain; charset=utf-8',
            examples: const [],
          ),
        },
      );
      final method = generator.generateHeadersMethod(
        _operation(context, requestBody: requestBody),
        const [],
        const [],
      );

      const expected = r'''
Map<String, String> _options() {
  final _$headers = <String, String>{};
  _$headers['Accept'] = r'*/*';
  _$headers[r'Content-Type'] = r'text/plain; charset=utf-8';
  return _$headers;
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expected)),
      );
    },
  );

  test('preserves encoded headers and multiple cookies', () {
    final header = RequestHeaderObject(
      name: 'X-Trace',
      rawName: 'X-Trace',
      description: null,
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: HeaderParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: null,
    );
    final firstCookie = _cookie(context, 'session', isRequired: true);
    final secondCookie = _cookie(context, 'theme', isRequired: false);
    final method = generator.generateHeadersMethod(
      _operation(
        context,
        headers: {header},
        cookies: {firstCookie, secondCookie},
      ),
      [(normalizedName: 'xTrace', parameter: header)],
      [
        (normalizedName: 'session', parameter: firstCookie),
        (normalizedName: 'theme', parameter: secondCookie),
      ],
    );

    const expected = r'''
Map<String, String> _options({
  required String xTrace,
  required String session,
  String? theme,
}) {
  final _$headers = <String, String>{};
  _$headers['Accept'] = r'*/*';
  _$headers[r'X-Trace'] = xTrace.toSimple(
    explode: false,
    allowEmpty: false,
    literal: true,
  );
  final _$cookieParts = <String>[];
  _$cookieParts.addAll(
    session
        .toForm(
          r'session',
          explode: false,
          allowEmpty: true,
        )
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
  );
  if (theme != null) {
    _$cookieParts.addAll(
      theme
          .toForm(
            r'theme',
            explode: false,
            allowEmpty: true,
          )
          .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
    );
  }
  if (_$cookieParts.isNotEmpty) {
    _$headers[r'Cookie'] = _$cookieParts.join('; ');
  }
  return _$headers;
}
''';

    expect(
      collapseWhitespace(format('${method.accept(emitter)}')),
      collapseWhitespace(format(expected)),
    );
  });
}

Operation _operation(
  Context context, {
  RequestBody? requestBody,
  Set<RequestHeader> headers = const {},
  Set<CookieParameter> cookies = const {},
}) => Operation(
  operationId: 'sendPayload',
  path: '/payload',
  method: HttpMethod.post,
  requestBody: requestBody,
  responses: const {},
  pathParameters: const {},
  queryParameters: const {},
  headers: headers,
  cookieParameters: cookies,
  securitySchemes: const {},
  context: context,
  tags: const {},
  isDeprecated: false,
);

CookieParameterObject _cookie(
  Context context,
  String name, {
  required bool isRequired,
}) => CookieParameterObject(
  name: name,
  rawName: name,
  description: null,
  isRequired: isRequired,
  isDeprecated: false,
  explode: false,
  model: StringModel(context: context),
  encoding: CookieParameterEncoding.form,
  context: context,
  examples: const [],
  defaultValue: null,
);
