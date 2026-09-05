import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';

void main() {
  const generator = HttpBackendGenerator();
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  group('response accessors', () {
    test('reads completed native response inputs', () {
      final response = refer('response');
      final generatedMethod = Method(
        (builder) => builder
          ..name = 'responseInputs'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'List'
              ..url = 'dart:core'
              ..types.add(refer('Object?', 'dart:core')),
          )
          ..requiredParameters.add(
            Parameter(
              (builder) => builder
                ..name = 'response'
                ..type = refer('Response', 'package:http/http.dart'),
            ),
          )
          ..lambda = false
          ..body = Block.of([
            const Code('return <Object?>['),
            generator.responseStatusCode(response).code,
            const Code(','),
            generator.responseContentType(response).code,
            const Code(','),
            generator.responseBodyBytes(response).code,
            const Code(','),
            generator.responseHeaderValues(response, 'X-Rate-Limit').code,
            const Code(',];'),
          ]),
      );

      const expectedMethod = '''
List<Object?> responseInputs(Response response) {
  return <Object?>[
    response.statusCode,
    response.headers['content-type'],
    response.bodyBytes,
    response.headersSplitValues[r'x-rate-limit'],
  ];
}
''';

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('uses the package http split-header fidelity boundary', () {
      final response = http.Response.bytes(
        const [],
        200,
        headers: {
          'x-values': 'first, second',
          'set-cookie': 'id=one; Expires=Wed, 21 Oct 2015 07:28:00 GMT,session=two; Path=/',
        },
      );

      expect(response.headersSplitValues['x-values'], ['first', 'second']);
      expect(response.headersSplitValues['set-cookie'], [
        'id=one; Expires=Wed, 21 Oct 2015 07:28:00 GMT',
        'session=two; Path=/',
      ]);
    });

    test('documents ambiguous comma-containing single header values', () {
      final response = http.Response.bytes(
        const [],
        200,
        headers: const {'x-display-name': 'last, first'},
      );

      expect(response.headers['x-display-name'], 'last, first');
      expect(response.headersSplitValues['x-display-name'], ['last', 'first']);
    });
  });

  group('http client adapter', () {
    late Class adapter;

    setUp(() {
      adapter = generator.generateClientAdapter();
    });

    test('tracks cached ownership and one stable closed error', () {
      expect(adapter.fields.map((field) => field.name), [
        'serverConfig',
        r'_$client',
        r'_$ownsClient',
        r'_$isClosed',
        r'_$closedError',
      ]);

      final serverConfig = adapter.fields.first;
      expect(
        serverConfig.type?.accept(emitter).toString(),
        'ServerConfig<Client>',
      );
      expect(serverConfig.modifier, FieldModifier.final$);

      final closedError = adapter.fields.last;
      expect(closedError.type?.accept(emitter).toString(), 'StateError');
      expect(closedError.modifier, FieldModifier.final$);
    });

    test(
      'resolves default injected and factory clients once with ownership',
      () {
        final getter = adapter.methods.singleWhere(
          (method) => method.name == 'client',
        );
        final generatedMethod = getter.rebuild(
          (builder) => builder
            ..type = null
            ..name = getter.name,
        );

        const expectedMethod = r'''
Client client() {
  if (_$isClosed) {
    throw _$closedError;
  }

  final cachedClient = _$client;
  if (cachedClient != null) {
    return cachedClient;
  }

  final configuredClient = serverConfig.client;
  final resolvedClient =
      configuredClient ?? serverConfig.clientFactory?.call() ?? Client();
  _$ownsClient = configuredClient == null;
  return _$client = resolvedClient;
}
''';

        expect(
          collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'closes only an owned resolved client once without resolving on close',
      () {
        final close = adapter.methods.singleWhere(
          (method) => method.name == 'close',
        );

        expect(close.returns?.accept(emitter).toString(), 'void');

        final generatedMethod = close.rebuild(
          (builder) => builder
            ..type = null
            ..name = close.name,
        );

        const expectedMethod = r'''
void close() {
  if (_$isClosed) {
    return;
  }

  _$isClosed = true;
  if (_$ownsClient) {
    _$client?.close();
  }
}
''';

        expect(
          collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });
}
