import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/transport/dio/dio_multipart_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

void main() {
  const generator = DioBackendGenerator();
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  test('constructs a multipart form with a native text part', () {
    final plan = MultipartBodyPlan(
      value: refer('body'),
      rawContentType: 'multipart/form-data',
      isRequired: true,
      emissions: [
        MultipartAppend(
          name: specLiteralString('value'),
          value: refer('body').property('value'),
          source: MultipartValueSource.text,
          contentType: 'text/plain',
        ),
      ],
    );
    final method = Method(
      (builder) => builder
        ..name = 'test'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of(buildMultipartBodyStatements(plan).statements),
    );
    const expected = r'''
Object? test() {
  final _$formData = FormData();
  _$formData.files.add(
    MapEntry(
      r'value',
      MultipartFile.fromString(
        body.value,
        contentType: DioMediaType.parse(r'text/plain'),
      ),
    ),
  );
  return _$formData;
}
''';
    expect(
      collapseWhitespace(format(method.accept(emitter).toString())),
      collapseWhitespace(format(expected)),
    );
  });

  test('exposes portable cancellation while keeping Dio bridging private', () {
    final parameter = generator.cancellationParameter;

    expect(parameter.name, 'cancellation');
    expect(
      parameter.type?.accept(emitter).toString(),
      'TonikCancellation?',
    );
    expect(parameter.named, isTrue);
    expect(parameter.required, isFalse);
  });

  group('Dio client adapter', () {
    late Class adapter;

    setUp(() {
      adapter = generator.generateClientAdapter();
    });

    test('tracks cached ownership and one stable closed error', () {
      expect(
        adapter.fields.map((field) => field.name),
        [
          'baseUrl',
          'serverConfig',
          r'_$dio',
          r'_$ownsDio',
          r'_$isClosed',
          r'_$closedError',
        ],
      );

      final closedError = adapter.fields.singleWhere(
        (field) => field.name == r'_$closedError',
      );
      expect(
        closedError.type?.accept(emitter).toString(),
        'StateError',
      );
      expect(closedError.modifier, FieldModifier.final$);
    });

    test(
      'resolves once, records ownership, and rejects access after close',
      () {
        final getter = adapter.methods.singleWhere(
          (method) => method.name == 'dio',
        );

        const expectedMethod = r'''
Dio dio() {
  if (_$isClosed) {
    throw _$closedError;
  }

  final cachedDio = _$dio;
  if (cachedDio != null) {
    return cachedDio;
  }

  final client = serverConfig.client;
  final clientFactory = serverConfig.clientFactory;
  final resolvedDio = client ?? clientFactory?.call() ?? Dio();
  _$ownsDio = client == null;
  resolvedDio.options.baseUrl = baseUrl;
  return _$dio = resolvedDio;
}
''';

        expect(
          collapseWhitespace(format(_asMethod(getter, emitter))),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test('closes an owned resolved Dio once without resolving on close', () {
      final close = adapter.methods.singleWhere(
        (method) => method.name == 'close',
      );

      expect(
        close.returns?.accept(emitter).toString(),
        'void',
      );

      const expectedMethod = r'''
void close() {
  if (_$isClosed) {
    return;
  }

  _$isClosed = true;
  if (_$ownsDio) {
    _$dio?.close();
  }
}
''';

      expect(
        collapseWhitespace(format(_asMethod(close, emitter))),
        collapseWhitespace(format(expectedMethod)),
      );
    });
  });
}

String _asMethod(Method method, DartEmitter emitter) {
  final wrapped = method.rebuild(
    (builder) => builder
      ..type = null
      ..name = method.name,
  );
  return '${wrapped.accept(emitter)}';
}
