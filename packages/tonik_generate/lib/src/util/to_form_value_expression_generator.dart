import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// Creates a Dart expression that correctly serializes a property
/// to its form-encoded representation.
///
/// The [useQueryComponent] parameter controls whether to use query component
/// encoding with spaces as + (for form-urlencoded bodies).
Expression buildToFormPropertyExpression(
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

  // For required but nullable properties, provide empty string fallback
  if (property.isRequired && property.isNullable) {
    return expr.ifNullThen(literalString(''));
  }

  return expr;
}

/// Creates a Dart expression that correctly serializes any model
/// to its form-encoded representation, including complex types.
///
/// The [useQueryComponent] parameter controls whether to use query component
/// encoding with spaces as + (for form-urlencoded bodies).
///
/// The [explodeLiteral] and [allowEmptyLiteral] parameters allow specifying
/// literal boolean values for these arguments instead of using variable
/// references. When null, the expression will reference 'explode' and
/// 'allowEmpty' variables expected to be in scope.
Expression buildToFormValueExpression(
  String valueExpression,
  Model model, {
  required bool useQueryComponent,
  bool? explodeLiteral,
  bool? allowEmptyLiteral,
}) {
  return _buildFormSerializationExpression(
    refer(valueExpression),
    model,
    isNullable: false,
    useQueryComponent: useQueryComponent,
    explodeLiteral: explodeLiteral,
    allowEmptyLiteral: allowEmptyLiteral,
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

    AliasModel() => _buildFormSerializationExpression(
      receiver,
      model.model,
      isNullable: isNullable,
      useQueryComponent: useQueryComponent,
      explodeLiteral: explodeLiteral,
      allowEmptyLiteral: allowEmptyLiteral,
    ),

    BinaryModel() => throw UnsupportedError(
      'Form encoding not supported for binary types',
    ),

    AnyModel() => receiver, // Pass through as-is

    _ => throw UnimplementedError(
      'Unsupported model type for form encoding: $model',
    ),
  };
}
