import 'package:code_builder/code_builder.dart';

Method buildDataMethod({
  required List<Code> statements,
  Reference? bodyType,
  bool isRequired = false,
  bool isAsync = false,
  Iterable<Parameter> headerParameters = const [],
}) => Method(
  (builder) => builder
    ..name = '_data'
    ..returns = isAsync
        ? TypeReference(
            (type) => type
              ..symbol = 'Future'
              ..url = 'dart:async'
              ..types.add(refer('Object?', 'dart:core')),
          )
        : refer('Object?', 'dart:core')
    ..modifier = isAsync ? MethodModifier.async : null
    ..optionalParameters.addAll([
      if (bodyType != null)
        Parameter(
          (parameter) => parameter
            ..name = 'body'
            ..type = bodyType
            ..named = true
            ..required = isRequired,
        ),
      ...headerParameters,
    ])
    ..lambda = false
    ..body = Block.of(statements),
);
