import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

BuiltStatements buildMultipartBodyStatements(MultipartBodyPlan plan) =>
    BuiltStatements.simple([
      declareFinal(
        r'_$formData',
      ).assign(refer('FormData', 'package:dio/dio.dart').call([])).statement,
      for (final emission in plan.emissions)
        switch (emission) {
          MultipartCode(:final code) => code,
          MultipartAppend() => _append(emission),
        },
      refer(r'_$formData').returned.statement,
    ]);

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
  final arguments = <String, Expression>{
    'filename': ?part.filename,
    if (part.contentType case final contentType?)
      'contentType': refer(
        'DioMediaType',
        'package:dio/dio.dart',
      ).property('parse').call([specLiteralString(contentType)]),
    'headers': ?part.headers,
  };
  final constructor = refer('MultipartFile', 'package:dio/dio.dart');
  final value = switch (part.source) {
    MultipartValueSource.field => part.value,
    MultipartValueSource.text => constructor.property('fromString').call([
      part.value,
    ], arguments),
    MultipartValueSource.bytes => constructor.property('fromBytes').call([
      part.value,
    ], arguments),
    MultipartValueSource.path => constructor.property('fromFile').call([
      part.value,
    ], arguments).awaited,
    MultipartValueSource.file => throw StateError(
      'Dio file paths must be planned before emission.',
    ),
  };
  return refer(r'_$formData')
      .property(part.source == MultipartValueSource.field ? 'fields' : 'files')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([part.name, value]),
      ])
      .statement;
}
