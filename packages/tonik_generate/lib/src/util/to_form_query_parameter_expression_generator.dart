import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/encoding_policy.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';
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

  if (model is Base64Model) {
    final valueExpression =
        '$parameterName.toBase64String().toForm(explode: $explode, '
        'allowEmpty: $allowEmpty)';
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

  if (model is BinaryModel) {
    return [
      generateEncodingExceptionExpression(
        'Binary data cannot be form-encoded.',
      ).statement,
    ];
  }

  if (model is MapModel) {
    final converted = buildMapToStringMapExpression(
      refer(parameterName),
      model,
      isNullable: false,
    );

    if (converted == null) {
      return [
        generateEncodingExceptionExpression(
          'Map with complex value types cannot be form query encoded.',
        ).statement,
      ];
    }

    // For StringModel values, converted == refer(parameterName) (identity).
    final convertedSuffix = '.toForm(explode: $explode, '
        'allowEmpty: $allowEmpty)';

    if (converted == refer(parameterName)) {
      return [
        Code(
          r'_$entries'
          '.add(('
          'name: ${specLiteralStringCode(parameter.rawName)}, '
          'value: $parameterName$convertedSuffix, '
          '),);',
        ),
      ];
    }

    // For non-string value types, we need to use code_builder for the
    // converted expression.
    return [
      const Code(r'_$entries.add(('),
      Code('name: ${specLiteralStringCode(parameter.rawName)}, '),
      const Code('value: '),
      converted
          .property('toForm')
          .call(
            [],
            {
              'explode': literalBool(explode),
              'allowEmpty': literalBool(allowEmpty),
            },
          )
          .code,
      const Code(',),);'),
    ];
  }

  if (model is AnyModel) {
    return [
      const Code(r'_$entries.add(('),
      Code('name: ${specLiteralStringCode(parameter.rawName)}, '),
      const Code('value: '),
      encodeAnyToFormExpression(
        refer(parameterName),
        explode: literalBool(explode),
        allowEmpty: literalBool(allowEmpty),
      ).code,
      const Code(',),);'),
    ];
  }

  if (model is ListModel) {
    final contentModel = model.content.resolved;
    final contentShape = contentModel.encodingShape;

    // Base64 content can be form-encoded via toBase64String.
    if (contentModel is Base64Model) {
      final toForm = 'toForm(explode: $explode, allowEmpty: $allowEmpty)';
      final suffix = '.map((e) => e.toBase64String()).toList().$toForm';
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

    // Binary content cannot be form-encoded.
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
        encodeAnyToUriExpression(
          refer('e'),
          allowEmpty: literalBool(allowEmpty),
        ).code,
        const Code(').toList().toForm('),
        Code('explode: $explode, allowEmpty: $allowEmpty),),);'),
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

    Base64Model() => '.toBase64String().toForm($paramString)',

    // AnyModel cannot be encoded via the suffix path; falls through to
    // EncodingException so callers see an explicit failure rather than a
    // silent toString.
    AnyModel() => null,
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

    // AnyModel cannot be encoded via the suffix path; the top-level
    // ListModel branch routes List<AnyModel> through encodeAnyToUri, so
    // returning null here causes any unexpected fall-through (e.g., a
    // List<List<AnyModel>>) to produce an EncodingException rather than
    // silently emitting wrong code.
    AnyModel() => null,

    AliasModel() => _handleListExpression(
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isContentNullable: isContentNullable || contentModel.isNullable,
    ),

    Base64Model() => () {
      return '.map((e) => e.toBase64String()).toList().toForm($paramString)';
    }(),

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
      encodeAnyToUriExpression(
        refer('e'),
        allowEmpty: literalBool(allowEmpty),
      ).code,
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
