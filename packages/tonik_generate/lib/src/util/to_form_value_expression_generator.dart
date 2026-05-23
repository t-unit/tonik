import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// [useQueryComponent] uses `+` for spaces (for form-urlencoded bodies).
BuiltExpression buildToFormPropertyExpression(
  String fieldName,
  Property property, {
  bool useQueryComponent = false,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;

  final expr = _buildFormSerializationExpression(
    refer(fieldName),
    model,
    isNullable: isNullable,
    useQueryComponent: useQueryComponent,
  );

  // Skip the empty-string fallback when the underlying model is AnyModel:
  // encodeAnyToForm returns a non-nullable String, so `?? ''` would be dead
  // code and trigger a `dead_null_aware_expression` lint in the generated
  // output.
  if (property.isRequired &&
      property.isNullable &&
      property.model.resolved is! AnyModel) {
    return BuiltExpression.simple(expr.ifNullThen(literalString('')));
  }

  return BuiltExpression.simple(expr);
}

/// When [explodeLiteral] / [allowEmptyLiteral] are null the expression
/// references `explode` / `allowEmpty` variables expected to be in scope.
BuiltExpression buildToFormValueExpression(
  String valueExpression,
  Model model, {
  required bool useQueryComponent,
  bool? explodeLiteral,
  bool? allowEmptyLiteral,
  bool isNullable = false,
}) {
  return BuiltExpression.simple(
    _buildFormSerializationExpression(
      refer(valueExpression),
      model,
      isNullable: isNullable,
      useQueryComponent: useQueryComponent,
      explodeLiteral: explodeLiteral,
      allowEmptyLiteral: allowEmptyLiteral,
    ),
  );
}

Expression _buildFormSerializationExpression(
  Expression receiver,
  Model model, {
  required bool isNullable,
  required bool useQueryComponent,
  bool? explodeLiteral,
  bool? allowEmptyLiteral,
}) {
  Expression callToForm(Expression target, {required bool nullAware}) {
    const methodName = 'toForm';
    final args = <String, Expression>{
      'explode': explodeLiteral != null
          ? literalBool(explodeLiteral)
          : refer('explode'),
      'allowEmpty': allowEmptyLiteral != null
          ? literalBool(allowEmptyLiteral)
          : refer('allowEmpty'),
    };
    if (useQueryComponent) {
      args['useQueryComponent'] = literalBool(true);
    }
    if (nullAware) {
      return target.nullSafeProperty(methodName).call([], args);
    } else {
      return target.property(methodName).call([], args);
    }
  }

  return switch (model) {
    NeverModel() => generateEncodingExceptionExpression(
      'Cannot encode NeverModel - this type does not permit any value.',
    ),

    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() ||
    ListModel() => callToForm(receiver, nullAware: isNullable),

    MapModel() => generateEncodingExceptionExpression(
      'Form encoding not supported for map types.',
    ),

    AliasModel() => _buildFormSerializationExpression(
      receiver,
      model.model,
      isNullable: isNullable,
      useQueryComponent: useQueryComponent,
      explodeLiteral: explodeLiteral,
      allowEmptyLiteral: allowEmptyLiteral,
    ),

    BinaryModel() || Base64Model() => generateEncodingExceptionExpression(
      'Form encoding not supported for binary types.',
    ),

    AnyModel() =>
      refer(
        'encodeAnyToForm',
        'package:tonik_util/tonik_util.dart',
      ).call(
        [receiver],
        {
          'explode': explodeLiteral != null
              ? literalBool(explodeLiteral)
              : refer('explode'),
          'allowEmpty': allowEmptyLiteral != null
              ? literalBool(allowEmptyLiteral)
              : refer('allowEmpty'),
          if (useQueryComponent) 'useQueryComponent': literalBool(true),
        },
      ),

    _ => generateEncodingExceptionExpression(
      'Unsupported model type for form encoding.',
    ),
  };
}
