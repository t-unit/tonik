import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_util/tonik_util.dart';

/// Creates code blocks that serialize a query parameter to its form-encoded
/// representation.
List<Code> buildToFormQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;

  if (model is NeverModel) {
    return [
      generateEncodingExceptionExpression(
        'Cannot encode NeverModel - this type does not permit any value.',
      ).statement,
    ];
  }

  if (model is AnyModel) {
    return [
      const Code('entries.add(('),
      Code("name: r'${parameter.rawName}', "),
      const Code('value: '),
      refer('encodeAnyToForm', 'package:tonik_util/tonik_util.dart')
          .call(
            [
              refer(parameterName),
            ],
            {
              'explode': literalBool(explode),
              'allowEmpty': literalBool(allowEmpty),
            },
          )
          .code,
      const Code(',),);'),
    ];
  }

  if (model is ListModel) {
    final contentShape = model.content.encodingShape;

    if (contentShape == EncodingShape.complex) {
      return [
        Code('if ($parameterName.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Form encoding only supports lists of simple types',
        ).statement,
        const Code('}'),
        Code("entries.add((name: r'${parameter.rawName}', value: <"),
        refer('String', 'dart:core').code,
        Code(
          '>[].toForm(explode: $explode, allowEmpty: $allowEmpty),),);',
        ),
      ];
    }

    if (contentShape == EncodingShape.mixed) {
      final suffix = _getFormSerializationSuffix(
        model,
        explode: explode,
        allowEmpty: allowEmpty,
      );
      final valueExpression = suffix == null
          ? parameterName
          : '$parameterName$suffix';

      return [
        Code('for (final item in $parameterName) {'),
        const Code('if (item.currentEncodingShape != '),
        refer('EncodingShape', 'package:tonik_util/tonik_util.dart').code,
        const Code('.simple) {'),
        generateEncodingExceptionExpression(
          'Form encoding only supports lists of simple types',
        ).statement,
        const Code('}'),
        const Code('}'),
        Code(
          'entries.add(('
          "name: r'${parameter.rawName}', "
          'value: $valueExpression, '
          '),);',
        ),
      ];
    }
  }

  // For all other types, generate simple expression.
  final suffix = _getFormSerializationSuffix(
    model,
    explode: explode,
    allowEmpty: allowEmpty,
  );
  final valueExpression = suffix == null
      ? parameterName
      : '$parameterName$suffix';

  return [
    Code(
      'entries.add(('
      "name: r'${parameter.rawName}', "
      'value: $valueExpression, '
      '),);',
    ),
  ];
}

String? _getFormSerializationSuffix(
  Model model, {
  required bool explode,
  required bool allowEmpty,
}) {
  final paramString = 'explode: $explode, allowEmpty: $allowEmpty';

  return switch (model) {
    StringModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => '.toForm($paramString)',

    ListModel() => _handleListExpression(
      model.content,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    AliasModel() => _getFormSerializationSuffix(
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    AnyModel() => '?.toString() ?? ""',
    NeverModel() => null,

    _ => throw UnimplementedError(
      'Unsupported model type for form encoding: $model',
    ),
  };
}

String? _handleListExpression(
  Model contentModel, {
  required bool explode,
  required bool allowEmpty,
}) {
  final paramString = 'explode: $explode, allowEmpty: $allowEmpty';

  return switch (contentModel) {
    StringModel() => '.toForm($paramString)',

    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    EnumModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => () {
      final suffix = _getFormSerializationSuffix(
        contentModel,
        explode: explode,
        allowEmpty: allowEmpty,
      );
      final elementMapBody = '(e) => e$suffix';
      return '.map($elementMapBody).toList().toForm($paramString)';
    }(),

    AliasModel() => _handleListExpression(
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    _ => throw UnimplementedError(
      'Unsupported list content type for form encoding: $contentModel',
    ),
  };
}
