import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

BuiltStatements buildMultipartBodyStatements(MultipartBodyPlan plan) {
  if (plan.runtimeEncodingError case final encodingError?) {
    return BuiltStatements.simple([
      generateEncodingExceptionExpression(encodingError, raw: true).statement,
    ]);
  }
  return BuiltStatements.simple([
    declareFinal(r'_$formData')
        .assign(refer('FormData', 'package:dio/dio.dart').call([]))
        .statement,
    for (final emission in plan.emissions)
      switch (emission) {
        MultipartCode(:final code) => code,
        MultipartAppend() => _append(emission),
      },
    Block.of([
      const Code(
        r'if (_$formData.fields.isEmpty && _$formData.files.isEmpty) {',
      ),
      generateEncodingExceptionExpression(
        'Multipart request body must contain at least one part.',
        raw: true,
      ).statement,
      const Code('}'),
    ]),
    refer(r'_$formData').returned.statement,
  ]);
}

BuiltExpression buildMultipartBodyExpression(MultipartBodyPlan plan) =>
    BuiltExpression.simple(
      Method(
        (b) => b
          ..modifier = MethodModifier.async
          ..lambda = false
          ..body = Block.of(buildMultipartBodyStatements(plan).statements),
      ).closure.call([]).awaited,
    );

Code _append(MultipartAppend part) {
  if (part.source == MultipartValueSource.file) {
    return Block.of([
      const Code('switch ('),
      part.value.code,
      const Code(') { case '),
      refer('TonikFileBytes', 'package:tonik_util/tonik_util.dart').code,
      const Code('(:final bytes, :final fileName):'),
      _appendNative(
        part,
        MultipartValueSource.bytes,
        refer('bytes'),
        selectedFileName: refer('fileName'),
      ),
      const Code('case '),
      refer('TonikFilePath', 'package:tonik_util/tonik_util.dart').code,
      const Code('(:final path, :final fileName):'),
      _appendNative(
        part,
        MultipartValueSource.bytes,
        refer('path'),
        filePath: true,
        selectedFileName: refer('fileName'),
      ),
      const Code('}'),
    ]);
  }
  return _appendNative(part, part.source, part.value);
}

Code _appendNative(
  MultipartAppend part,
  MultipartValueSource source,
  Expression value, {
  bool filePath = false,
  Expression? selectedFileName,
}) {
  final arguments = <String, Expression>{
    if (part.resolvedFilename(selectedFileName: selectedFileName)
        case final filename?)
      'filename': filename.parenthesized.property('replaceAll').call([
        specLiteralString(r'\'),
        specLiteralString(r'\\'),
      ]),
    if (part.contentType case final contentType?)
      'contentType': refer(
        'DioMediaType',
        'package:dio/dio.dart',
      ).property('parse').call([specLiteralString(contentType)]),
    'headers': ?part.headers,
  };
  final constructor = refer('MultipartFile', 'package:dio/dio.dart');
  final nativeValue = switch (source) {
    MultipartValueSource.field => value,
    MultipartValueSource.text => constructor.property('fromString').call([
      value,
    ], arguments),
    MultipartValueSource.bytes =>
      filePath
          ? constructor.property('fromFile').call([value], arguments).awaited
          : constructor.property('fromBytes').call([value], arguments),
    MultipartValueSource.file => throw StateError(
      'Dio file values must be resolved by the native adapter.',
    ),
  };
  return refer(r'_$formData')
      .property(source == MultipartValueSource.field ? 'fields' : 'files')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          part.name.parenthesized.property('replaceAll').call([
            specLiteralString(r'\'),
            specLiteralString(r'\\'),
          ]),
          nativeValue,
        ]),
      ])
      .statement;
}
