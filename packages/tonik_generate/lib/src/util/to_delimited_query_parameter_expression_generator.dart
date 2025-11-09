import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// Creates code blocks that serialize a query parameter to its delimited
/// representation (space or pipe delimited).
List<Code> buildToDelimitedQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  required QueryParameterEncoding encoding,
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;
  final encodingName =
      encoding == QueryParameterEncoding.spaceDelimited
          ? 'spaceDelimited'
          : 'pipeDelimited';

  if (model is! ListModel) {
    return [
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding only '
        'supports list types',
        raw: true,
      ).statement,
    ];
  }

  return _buildDelimitedCode(
    parameterName,
    model.content,
    parameter.rawName,
    encoding: encoding,
    explode: explode,
    allowEmpty: allowEmpty,
    encodingName: encodingName,
  );
}

List<Code> _buildDelimitedCode(
  String parameterName,
  Model contentModel,
  String rawName, {
  required QueryParameterEncoding encoding,
  required bool explode,
  required bool allowEmpty,
  required String encodingName,
}) {
  final methodName =
      encoding == QueryParameterEncoding.spaceDelimited
          ? 'toSpaceDelimited'
          : 'toPipeDelimited';

  return switch (contentModel) {
    StringModel() => _buildForLoop(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      needsMapping: false,
    ),

    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    EnumModel() => _buildForLoop(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      needsMapping: true,
      mapExpression:
          'e.uriEncode(allowEmpty: $allowEmpty, useQueryComponent: true)',
    ),

    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildForLoopWithRuntimeCheck(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      encodingName,
    ),

    AliasModel() => _buildDelimitedCode(
      parameterName,
      contentModel.model,
      rawName,
      encoding: encoding,
      explode: explode,
      allowEmpty: allowEmpty,
      encodingName: encodingName,
    ),

    _ => [
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding does not '
        'support list content type',
        raw: true,
      ).statement,
    ],
  };
}

List<Code> _buildForLoop(
  String parameterName,
  String rawName,
  String methodName,
  bool explode,
  bool allowEmpty, {
  required bool needsMapping,
  String? mapExpression,
}) {
  final baseExpression =
      needsMapping
          ? '$parameterName.map((e) => $mapExpression).toList().$methodName('
              ' explode: $explode, allowEmpty: $allowEmpty,'
              ' alreadyEncoded: true)'
          : '$parameterName.$methodName('
              ' explode: $explode, allowEmpty: $allowEmpty)';

  return [
    Code('for (final value in $baseExpression) {'),
    Code("result.add((name: r'$rawName', value: value));"),
    const Code('}'),
  ];
}

List<Code> _buildForLoopWithRuntimeCheck(
  String parameterName,
  String rawName,
  String methodName,
  bool explode,
  bool allowEmpty,
  String encodingName,
) {
  if (explode) {
    return [
      Code('for (final item in $parameterName) { '),
      const Code('if (item.currentEncodingShape != '),
      refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      ).property('simple').code,
      const Code(') {'),
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding requires simple '
        'encoding shape',
        raw: true,
      ).statement,
      const Code('}'),
      Code(
        "result.add((name: r'$rawName', value: "
        'item.uriEncode(allowEmpty: $allowEmpty)));',
      ),
      const Code('}'),
    ];
  } else {
    return [
      Code('for (final item in $parameterName) { '),
      const Code('if (item.currentEncodingShape != '),
      refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      ).property('simple').code,
      const Code(') {'),
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding requires simple '
        'encoding shape',
        raw: true,
      ).statement,
      const Code('}'),
      const Code('}'),
      Code(
        'for (final value in $parameterName.map((item) => item'
        ' .uriEncode(allowEmpty: $allowEmpty)).toList()'
        ' .$methodName(explode: $explode, allowEmpty: $allowEmpty, '
        ' alreadyEncoded: true)) {',
      ),
      Code("result.add((name: r'$rawName', value: value));"),
      const Code('}'),
    ];
  }
}
