import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
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

  // BinaryModel (format: binary) cannot be form-encoded.
  if (model is BinaryModel) {
    return [
      generateEncodingExceptionExpression(
        'Binary data cannot be form-encoded.',
      ).statement,
    ];
  }

  if (model is AnyModel) {
    return [
      const Code(r'_$entries.add(('),
      Code('name: ${specLiteralStringCode(parameter.rawName)}, '),
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
    final contentModel = model.content.resolved;
    final contentShape = contentModel.encodingShape;

    // BinaryModel content cannot be form-encoded.
    if (contentModel is BinaryModel) {
      return [
        generateEncodingExceptionExpression(
          'Binary data cannot be form-encoded.',
        ).statement,
      ];
    }

    // NeverModel content cannot be form-encoded.
    if (contentModel is NeverModel) {
      return [
        generateEncodingExceptionExpression(
          'Cannot encode List<NeverModel> - '
          'this type does not permit any value.',
        ).statement,
      ];
    }

    if (explode) {
      return _buildExplodedListCode(
        parameterName,
        parameter,
        contentModel,
        contentShape,
        allowEmpty: allowEmpty,
        isContentNullable: model.content.isEffectivelyNullable,
      );
    }

    if (contentModel is AnyModel ||
        contentModel is AllOfModel ||
        contentModel is OneOfModel ||
        contentModel is AnyOfModel) {
      return [
        const Code(r'_$entries.add(('),
        Code('name: ${specLiteralStringCode(parameter.rawName)}, '),
        const Code('value: '),
        refer(parameterName).code,
        const Code('.map((e) => '),
        refer('encodeAnyToUri', 'package:tonik_util/tonik_util.dart')
            .call(
              [refer('e')],
              {
                'allowEmpty': literalBool(allowEmpty),
              },
            )
            .code,
        const Code(').toList().toForm('),
        Code('explode: $explode, allowEmpty: $allowEmpty),),);'),
      ];
    }

    // MapModel and Base64Model content can be form-encoded despite having
    // complex/simple encoding shapes, because we convert them to strings first.
    if (contentModel is MapModel || contentModel is Base64Model) {
      final suffix = _getFormSerializationSuffix(
        model,
        explode: explode,
        allowEmpty: allowEmpty,
      );

      if (suffix == null) {
        return [
          generateEncodingExceptionExpression(
            'Unsupported list content type for form query encoding.',
          ).statement,
        ];
      }

      final valueExpression = '$parameterName$suffix';

      return [
        Code(
          r'_$entries'
          '.add(('
          'name: ${specLiteralStringCode(parameter.rawName)}, '
          'value: $valueExpression, '
          '),);',
        ),
      ];
    }

    if (contentShape == EncodingShape.complex) {
      return [
        Code('if ($parameterName.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Form encoding only supports lists of simple types',
        ).statement,
        const Code('}'),
        Code(
          r'_$entries'
          '.add((name: ${specLiteralStringCode(parameter.rawName)}, value: <',
        ),
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

      if (suffix == null) {
        return [
          generateEncodingExceptionExpression(
            'Unsupported list content type for form query encoding.',
          ).statement,
        ];
      }

      final valueExpression = '$parameterName$suffix';

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
          r'_$entries'
          '.add(('
          'name: ${specLiteralStringCode(parameter.rawName)}, '
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

  if (suffix == null) {
    return [
      generateEncodingExceptionExpression(
        'Unsupported model type for form query encoding.',
      ).statement,
    ];
  }

  final valueExpression = '$parameterName$suffix';

  return [
    Code(
      r'_$entries'
      '.add(('
      'name: ${specLiteralStringCode(parameter.rawName)}, '
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
      isContentNullable: model.content.isEffectivelyNullable,
    ),

    AliasModel() => _getFormSerializationSuffix(
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    // MapModel: convert to Map<String, String> via toParameterMap(), then
    // call toForm() on the resulting map.
    MapModel() => '.toParameterMap().toForm($paramString)',

    // Base64Model: convert to base64 string via toBase64String(), then
    // call toForm() on the resulting string.
    Base64Model() => '.toBase64String().toForm($paramString)',

    AnyModel() => '?.toString() ?? ""',
    NeverModel() => null,
    BinaryModel() => null,

    _ => null,
  };
}

String? _handleListExpression(
  Model contentModel, {
  required bool explode,
  required bool allowEmpty,
  bool isContentNullable = false,
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
      final nullAware = isContentNullable ? '?' : '';
      final elementMapBody = '(e) => e$nullAware$suffix';
      return '.map($elementMapBody).toList().toForm($paramString)';
    }(),

    AnyModel() => () {
      final suffix = _getFormSerializationSuffix(
        contentModel,
        explode: explode,
        allowEmpty: allowEmpty,
      );
      final elementMapBody = '(e) => e$suffix';
      return '.map($elementMapBody).toList().toForm($paramString)';
    }(),

    // List<Map<String, V>>: map each item through
    // toParameterMap().toForm()
    MapModel() => () {
      final suffix = _getFormSerializationSuffix(
        contentModel,
        explode: explode,
        allowEmpty: allowEmpty,
      );
      final elementMapBody = '(e) => e$suffix';
      return '.map($elementMapBody).toList().toForm($paramString)';
    }(),

    // List<TonikFile> (base64): map each item through
    // toBase64String().toForm()
    Base64Model() => () {
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
      isContentNullable: isContentNullable || contentModel.isNullable,
    ),

    BinaryModel() => null,

    _ => null,
  };
}

/// Generates code for exploded list parameters (explode=true).
List<Code> _buildExplodedListCode(
  String parameterName,
  QueryParameterObject parameter,
  Model contentModel,
  EncodingShape contentShape, {
  required bool allowEmpty,
  bool isContentNullable = false,
}) {
  final nameCode = specLiteralStringCode(parameter.rawName);
  final toFormCall = isContentNullable
      ? "e?.toForm(explode: true, allowEmpty: $allowEmpty) ?? ''"
      : 'e.toForm(explode: true, allowEmpty: $allowEmpty)';

  // MapModel and Base64Model can be exploded — convert each item first.
  if (contentModel is MapModel) {
    final mapToFormCall =
        'e.toParameterMap().toForm(explode: true, allowEmpty: $allowEmpty)';
    return [
      Code(
        r'_$entries'
        '.addAll($parameterName.map((e) => (',
      ),
      Code('name: $nameCode, '),
      Code('value: $mapToFormCall,),),);'),
    ];
  }

  if (contentModel is Base64Model) {
    final base64ToFormCall =
        'e.toBase64String().toForm(explode: true, allowEmpty: $allowEmpty)';
    return [
      Code(
        r'_$entries'
        '.addAll($parameterName.map((e) => (',
      ),
      Code('name: $nameCode, '),
      Code('value: $base64ToFormCall,),),);'),
    ];
  }

  if (contentShape == EncodingShape.complex) {
    return [
      Code('if ($parameterName.isNotEmpty) {'),
      generateEncodingExceptionExpression(
        'Form encoding only supports lists of simple types',
      ).statement,
      const Code('}'),
    ];
  }

  if (contentModel is AnyModel ||
      contentModel is AllOfModel ||
      contentModel is OneOfModel ||
      contentModel is AnyOfModel) {
    return [
      Code(
        r'_$entries'
        '.addAll($parameterName.map((e) => (',
      ),
      Code('name: $nameCode, '),
      const Code('value: '),
      refer(
        'encodeAnyToUri',
        'package:tonik_util/tonik_util.dart',
      ).call([refer('e')], {'allowEmpty': literalBool(allowEmpty)}).code,
      const Code(',),),);'),
    ];
  }

  if (contentShape == EncodingShape.mixed) {
    final itemAccessor = isContentNullable
        ? 'item?.currentEncodingShape'
        : 'item.currentEncodingShape';
    return [
      Code('for (final item in $parameterName) {'),
      Code('if ($itemAccessor != '),
      refer('EncodingShape', 'package:tonik_util/tonik_util.dart').code,
      const Code('.simple) {'),
      generateEncodingExceptionExpression(
        'Form encoding only supports lists of simple types',
      ).statement,
      const Code('}'),
      const Code('}'),
      Code(
        r'_$entries'
        '.addAll($parameterName.map((e) => (',
      ),
      Code('name: $nameCode, '),
      Code('value: $toFormCall,),),);'),
    ];
  }

  return [
    Code(
      r'_$entries'
      '.addAll($parameterName.map((e) => (',
    ),
    Code('name: $nameCode, '),
    Code('value: $toFormCall,),),);'),
  ];
}
