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
      (r'value').replaceAll(r'\', r'\\'),
      utf8.encode(body.value),
      contentType: MediaType.parse(r'text/plain'),
    ),
  );
  return _$multipartFiles;
}
''');
  });

  test('quotes dynamic names and filenames for native HTTP parts', () {
    final dynamicPlan = MultipartBodyPlan(
      value: refer('body'),
      rawContentType: 'multipart/form-data',
      isRequired: true,
      emissions: [
        MultipartAppend(
          name: refer('entry').property('name'),
          value: refer('bytes'),
          source: MultipartValueSource.bytes,
          filename: specLiteralString(r'file\name.txt'),
          contentType: 'text/plain',
        ),
      ],
    );
    _expectBody(buildHttpMultipartBodyStatements(dynamicPlan), r'''
Object? test() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    (entry.name).replaceAll(r'\', r'\\'), bytes,
    filename: (r'file\name.txt').replaceAll(r'\', r'\\'),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''');
  });

  test('passes raw names and filenames to the custom HTTP encoder', () {
    final customPlan = MultipartBodyPlan(
      value: refer('body'),
      rawContentType: 'multipart/form-data',
      isRequired: true,
      usesCustomParts: true,
      emissions: [
        MultipartAppend(
          name: specLiteralString(r'profile\name'),
          value: refer('bytes'),
          source: MultipartValueSource.bytes,
          filename: specLiteralString(r'file\name.txt'),
          contentType: 'text/plain',
          headers: refer('headers'),
        ),
      ],
    );
    _expectBody(buildHttpMultipartBodyStatements(customPlan), r'''
Object? test() {
  final _$multipartParts = <TonikMultipartPart>[];
  _$multipartParts.add(TonikMultipartPart(
    name: r'profile\name', bytes: bytes, contentType: r'text/plain',
    filename: r'file\name.txt', headers: headers,
  ));
  return TonikMultipartBody(_$multipartParts);
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
