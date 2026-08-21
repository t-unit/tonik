import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_property_value_expression_builder.dart';
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
  final resolved = parameter.model.resolved;
  final encodingName = encoding == QueryParameterEncoding.spaceDelimited
      ? 'spaceDelimited'
      : 'pipeDelimited';

  return switch (resolved) {
    ListModel() => _buildDelimitedCode(
      parameterName,
      resolved.content,
      parameter.rawName,
      encoding: encoding,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
      encodingName: encodingName,
      isContentNullable:
          resolved.isContentNullable || resolved.content.isEffectivelyNullable,
    ),
    MapModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() ||
    AnyModel() when explode => [
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding of objects with '
        'explode: true is not defined by the specification',
        raw: true,
      ).statement,
    ],
    MapModel() => _buildMapDelimitedCode(
      parameterName,
      parameter.rawName,
      resolved,
      encoding: encoding,
      encodingName: encodingName,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    ),
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildObjectDelimitedCode(
      parameterName,
      parameter.rawName,
      encoding: encoding,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    ),
    AnyModel() => _buildAnyDelimitedCode(
      parameterName,
      parameter.rawName,
      encoding: encoding,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    ),
    _ => [
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding supports only '
        'array and object types',
        raw: true,
      ).statement,
    ],
  };
}

List<Code> _buildMapDelimitedCode(
  String parameterName,
  String rawName,
  MapModel model, {
  required QueryParameterEncoding encoding,
  required String encodingName,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  final methodName = encoding == QueryParameterEncoding.spaceDelimited
      ? 'toSpaceDelimited'
      : 'toPipeDelimited';

  final conversion = buildMapPropertyValueConversion(
    refer(parameterName),
    model,
    isNullable: false,
    context: rawName,
  );

  return switch (conversion) {
    SupportedMapPropertyValueConversion(:final expression) => [
      refer(r'_$entries').property('addAll').call([
        expression
            .property(methodName)
            .call(
              [specLiteralString(rawName)],
              {
                'allowEmpty': literalBool(allowEmpty),
                if (allowReserved) 'allowReserved': literalBool(true),
              },
            ),
      ]).statement,
    ],
    UnsupportedMapPropertyValueConversion() => [
      generateEncodingExceptionExpression(
        'Parameter $parameterName: $encodingName encoding does not support '
        'Map types with complex values',
        raw: true,
      ).statement,
    ],
  };
}

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

List<Code> _buildAnyDelimitedCode(
  String parameterName,
  String rawName, {
  required QueryParameterEncoding encoding,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  final functionName = encoding == QueryParameterEncoding.spaceDelimited
      ? 'encodeAnyToSpaceDelimited'
      : 'encodeAnyToPipeDelimited';

  final entries = refer(functionName, 'package:tonik_util/tonik_util.dart')
      .call(
        [refer(parameterName), specLiteralString(rawName)],
        {
          'allowEmpty': literalBool(allowEmpty),
          if (allowReserved) 'allowReserved': literalBool(true),
        },
      );

  return [
    refer(r'_$entries').property('addAll').call([entries]).statement,
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
  Expression nullGuard(Expression encoded) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), encoded)
      : encoded;

  final scalarItem = nullGuard(
    refer('e').property('uriEncode').call([], {
      'allowEmpty': literalBool(allowEmpty),
      'textEncoding': refer('utf8', 'dart:convert'),
      if (allowReserved) 'allowReserved': literalTrue,
    }),
  );

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
      mapExpression: scalarItem,
    ),

    EnumModel() => _buildForLoop(
      parameterName,
      rawName,
      methodName,
      explode,
      allowEmpty,
      needsMapping: true,
      mapExpression: scalarItem,
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
  Expression? mapExpression,
}) {
  final receiver = needsMapping
      ? refer(parameterName)
            .property('map')
            .call([
              Method(
                (b) => b
                  ..requiredParameters.add(Parameter((p) => p..name = 'e'))
                  ..body = mapExpression!.code,
              ).closure,
            ])
            .property('toList')
            .call([])
      : refer(parameterName);
  final baseExpression = receiver.property(methodName).call([], {
    'explode': literalBool(explode),
    'allowEmpty': literalBool(allowEmpty),
    if (allowReserved) 'allowReserved': literalTrue,
    if (needsMapping) 'alreadyEncoded': literalTrue,
  });

  return [
    Block.of([
      const Code('for (final value in '),
      baseExpression.code,
      const Code(') {'),
    ]),
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
  final encodedItem = refer('item').property('uriEncode').call([], {
    'allowEmpty': literalBool(allowEmpty),
    'textEncoding': refer('utf8', 'dart:convert'),
    if (allowReserved) 'allowReserved': literalTrue,
  });

  Code validateItem() => Block.of([
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
  ]);

  if (explode) {
    return [
      Code('for (final item in $parameterName) { '),
      validateItem(),
      Block.of([
        const Code(r'_$entries.add((name: '),
        specLiteralString(rawName).code,
        const Code(', value: '),
        encodedItem.code,
        const Code('));'),
      ]),
      const Code('}'),
    ];
  } else {
    final encodedItems = refer(parameterName)
        .property('map')
        .call([
          Method(
            (b) => b
              ..requiredParameters.add(Parameter((p) => p..name = 'item'))
              ..body = encodedItem.code,
          ).closure,
        ])
        .property('toList')
        .call([])
        .property(methodName)
        .call([], {
          'explode': literalBool(explode),
          'allowEmpty': literalBool(allowEmpty),
          'alreadyEncoded': literalTrue,
        });
    return [
      Code('for (final item in $parameterName) { '),
      validateItem(),
      const Code('}'),
      Block.of([
        const Code('for (final value in '),
        encodedItems.code,
        const Code(') {'),
      ]),
      Code(
        r'_$entries'
        '.add((name: ${specLiteralStringCode(rawName)}, value: value));',
      ),
      const Code('}'),
    ];
  }
}
