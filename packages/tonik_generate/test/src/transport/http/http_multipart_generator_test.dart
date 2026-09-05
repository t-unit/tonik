import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

void main() {
  final plan = MultipartBodyPlan(
    value: refer('body'),
    rawContentType: 'multipart/form-data',
    isRequired: true,
    emissions: [
      MultipartAppend(
        name: specLiteralString('value'),
        value: refer(
          'utf8',
          'dart:convert',
        ).property('encode').call([refer('body').property('value')]),
        source: MultipartValueSource.bytes,
        contentType: 'text/plain',
      ),
    ],
  );

  test('HTTP multipart body constructs a native text part', () {
    _expectBody(buildHttpMultipartBodyStatements(plan), r'''
Object? test() {
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
''');
  });

  test('HTTP multipart body emits a terminal encoding error', () {
    final errorPlan = MultipartBodyPlan(
      value: refer('body'),
      rawContentType: 'multipart/form-data',
      isRequired: true,
      emissions: const [],
      runtimeEncodingError:
          'Multipart property "item" has incompatible definitions.',
    );

    _expectBody(buildHttpMultipartBodyStatements(errorPlan), '''
Object? test() {
  throw EncodingException(
    r'Multipart property "item" has incompatible definitions.',
  );
}
''');
  });
}

void _expectBody(List<Code> statements, String expected) {
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  final method = Method(
    (builder) => builder
      ..name = 'test'
      ..returns = refer('Object?', 'dart:core')
      ..body = Block.of(statements),
  );
  expect(
    collapseWhitespace(
      formatter.format(
        method.accept(DartEmitter(useNullSafetySyntax: true)).toString(),
      ),
    ),
    collapseWhitespace(formatter.format(expected)),
  );
}
