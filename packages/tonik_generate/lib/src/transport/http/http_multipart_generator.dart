import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Native HTTP parts stay ordered, including duplicate field names.
List<Code> buildHttpMultipartBodyStatements(MultipartBodyPlan plan) {
  if (plan.runtimeEncodingError case final encodingError?) {
    return [
      generateEncodingExceptionExpression(encodingError, raw: true).statement,
    ];
  }
  final custom = plan.usesCustomParts;
  final variable = custom ? r'_$multipartParts' : r'_$multipartFiles';
  return [
    declareFinal(variable)
        .assign(
          literalList(
            [],
            custom
                ? refer(
                    'TonikMultipartPart',
                    'package:tonik_util/tonik_util.dart',
                  )
                : refer('MultipartFile', 'package:http/http.dart'),
          ),
        )
        .statement,
    for (final emission in plan.emissions)
      switch (emission) {
        MultipartCode(:final code) => code,
        MultipartAppend() => _append(emission, variable, custom),
      },
    (custom
            ? refer(
                'TonikMultipartBody',
                'package:tonik_util/tonik_util.dart',
              ).newInstance([refer(variable)])
            : refer(variable))
        .returned
        .statement,
  ];
}

Code _append(MultipartAppend part, String variable, bool custom) {
  final bytes = switch (part.source) {
    MultipartValueSource.bytes => part.value,
    MultipartValueSource.file => part.value.property('toBytes').call([]),
    _ => throw StateError(
      'HTTP text and paths must be planned before emission.',
    ),
  };
  final contentType = part.contentType!;
  return refer(variable).property('add').call([
    if (custom)
      refer(
        'TonikMultipartPart',
        'package:tonik_util/tonik_util.dart',
      ).newInstance([], {
        'name': part.name,
        'bytes': bytes,
        'contentType': specLiteralString(contentType),
        'filename': ?part.filename,
        'headers': ?part.headers,
      })
    else
      refer('MultipartFile', 'package:http/http.dart')
          .property('fromBytes')
          .call(
            [part.name, bytes],
            {
              'filename': ?part.filename,
              'contentType': refer(
                'MediaType',
                'package:http/http.dart',
              ).property('parse').call([specLiteralString(contentType)]),
            },
          ),
  ]).statement;
}
