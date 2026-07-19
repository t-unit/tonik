import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

BuiltStatements buildToDelimitedQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  required QueryParameterEncoding encoding,
  bool explode = false,
  bool allowEmpty = true,
  bool allowReserved = false,
}) {
  return BuiltStatements.simple(
    _buildToDelimitedQueryParameterCode(
      parameterName,
      parameter,
      encoding: encoding,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    ),
  );
}

List<Code> _buildToDelimitedQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  required QueryParameterEncoding encoding,
  bool explode = false,
  bool allowEmpty = true,
  bool allowReserved = false,
}) {
  final model = parameter.model;
  final encodingName = encoding == QueryParameterEncoding.spaceDelimited
      ? 'spaceDelimited'
      : 'pipeDelimited';

  if (model is ListModel) {
    return _buildDelimitedCode(
      parameterName,
      model.content,
      parameter.rawName,
      encoding: encoding,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
      encodingName: encodingName,
      isContentNullable:
          model.isContentNullable || model.content.isEffectivelyNullable,
    );
  }

  if (_isObjectModel(model)) {
    // explode: true on an object is left undefined by the specification.
    if (explode) {
      return [
        generateEncodingExceptionExpression(
          'Parameter $parameterName: $encodingName encoding of objects with '
          'explode: true is not defined by the specification',
          raw: true,
        ).statement,
      ];
    }

    return _buildObjectDelimitedCode(
      parameterName,
      parameter.rawName,
      encoding: encoding,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }

  return [
    generateEncodingExceptionExpression(
      'Parameter $parameterName: $encodingName encoding supports only '
      'list and object types',
      raw: true,
    ).statement,
  ];
}

bool _isObjectModel(Model model) => switch (model.resolved) {
  ClassModel() || AllOfModel() || OneOfModel() || AnyOfModel() => true,
  _ => false,
};

List<Code> _buildObjectDelimitedCode(
  String parameterName,
  String rawName, {
  required QueryParameterEncoding encoding,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  final methodName = encoding == QueryParameterEncoding.spaceDelimited
      ? 'toSpaceDelimited'
      : 'toPipeDelimited';

  final flattened = refer(parameterName)
      .property('parameterProperties')
      .call([], {'allowEmpty': literalBool(allowEmpty)})
      .property(methodName)
      .call(
        [specLiteralString(rawName)],
        {
          'allowEmpty': literalBool(allowEmpty),
          if (allowReserved) 'allowReserved': literalBool(true),
        },
      );

  return [
    refer(r'_$entries').property('addAll').call([flattened]).statement,
  ];
}

List<Code> _buildDelimitedCode(
  String parameterName,
  Model contentModel,
  String rawName, {
  required QueryParameterEncoding encoding,
  required bool explode,
  required bool allowEmpty,
  required bool allowReserved,
  required String encodingName,
  required bool isContentNullable,
}) {
  final methodName = encoding == QueryParameterEncoding.spaceDelimited
      ? 'toSpaceDelimited'
      : 'toPipeDelimited';

  // A null array element encodes to the empty string, coercing the element
  // type back to non-null `String` for the whole-list extension.
  String nullGuard(String encoded) =>
      isContentNullable ? "e == null ? '' : $encoded" : encoded;

  final scalarItemArgs = allowReserved
      ? 'allowEmpty: $allowEmpty, allowReserved: true'
      : 'allowEmpty: $allowEmpty';

  return switch (contentModel) {
    StringModel() when !isContentNullable => _buildForLoop(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      allowReserved: allowReserved,
      needsMapping: false,
    ),

    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() => _buildForLoop(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      needsMapping: true,
      mapExpression: nullGuard('e.uriEncode($scalarItemArgs)'),
    ),

    EnumModel() => _buildForLoop(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      needsMapping: true,
      mapExpression: nullGuard('e.uriEncode($scalarItemArgs)'),
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
      allowReserved: allowReserved,
    ),

    AliasModel() => _buildDelimitedCode(
      parameterName,
      contentModel.model,
      rawName,
      encoding: encoding,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
      encodingName: encodingName,
      isContentNullable: isContentNullable,
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
  bool allowReserved = false,
  String? mapExpression,
}) {
  final delimitedArgs = allowReserved
      ? 'explode: $explode, allowEmpty: $allowEmpty, allowReserved: true'
      : 'explode: $explode, allowEmpty: $allowEmpty';

  final baseExpression = needsMapping
      ? '$parameterName.map((e) => $mapExpression).toList().$methodName('
            ' explode: $explode, allowEmpty: $allowEmpty,'
            ' alreadyEncoded: true)'
      : '$parameterName.$methodName($delimitedArgs)';

  return [
    Code('for (final value in $baseExpression) {'),
    Code(
      r'_$entries'
      '.add((name: ${specLiteralStringCode(rawName)}, value: value));',
    ),
    const Code('}'),
  ];
}

List<Code> _buildForLoopWithRuntimeCheck(
  String parameterName,
  String rawName,
  String methodName,
  bool explode,
  bool allowEmpty,
  String encodingName, {
  required bool allowReserved,
}) {
  final itemArgs = allowReserved
      ? 'allowEmpty: $allowEmpty, allowReserved: true'
      : 'allowEmpty: $allowEmpty';

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
        r'_$entries'
        '.add((name: ${specLiteralStringCode(rawName)}, value: '
        'item.uriEncode($itemArgs)));',
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
        ' .uriEncode($itemArgs)).toList()'
        ' .$methodName(explode: $explode, allowEmpty: $allowEmpty, '
        ' alreadyEncoded: true)) {',
      ),
      Code(
        r'_$entries'
        '.add((name: ${specLiteralStringCode(rawName)}, value: value));',
      ),
      const Code('}'),
    ];
  }
}
