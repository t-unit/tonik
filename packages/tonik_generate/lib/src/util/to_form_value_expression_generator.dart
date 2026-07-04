import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

BuiltExpression buildToFormValueExpression(
  String valueExpression,
  Model model, {
  required bool useQueryComponent,
  bool explodeLiteral = true,
  bool allowEmptyLiteral = true,
  Map<Property, FieldEncoding>? encoding,
}) {
  final receiver = refer(valueExpression);
  final resolved = model.resolved;

  final unsupported = formEntriesUnsupportedReason(resolved);
  if (unsupported != null) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(unsupported),
    );
  }

  if (resolved is MapModel) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(
        'Form encoding not supported for map types.',
      ),
    );
  }

  if (isAnyModelFormValue(model)) {
    return BuiltExpression.simple(
      refer('encodeAnyToForm', 'package:tonik_util/tonik_util.dart').call(
        [receiver],
        {
          'explode': literalBool(explodeLiteral),
          'allowEmpty': literalBool(allowEmptyLiteral),
          if (useQueryComponent) 'useQueryComponent': literalBool(true),
        },
      ),
    );
  }

  final entries = buildFormEntriesValueExpression(
    receiver,
    model,
    paramName: literalString(''),
    explode: literalBool(explodeLiteral),
    allowEmpty: literalBool(allowEmptyLiteral),
    useQueryComponent: useQueryComponent ? literalBool(true) : null,
    fieldEncodings: _fieldEncodingsLiteral(encoding),
  );

  if (entries == null) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(
        'Unsupported model type for form encoding.',
      ),
    );
  }

  return BuiltExpression.simple(_entriesToBody(entries));
}

/// Builds a `<String, FormFieldEncoding>` map literal for the object `toForm`
/// call, containing only the writable properties that opt into `allowReserved`.
/// Keyed by raw spec name to match the class's own per-property lookup. Returns
/// null when no property opts in so the call omits the argument.
Expression? _fieldEncodingsLiteral(
  Map<Property, FieldEncoding>? encoding,
) {
  if (encoding == null) return null;

  final descriptor = refer(
    'FormFieldEncoding',
    'package:tonik_util/tonik_util.dart',
  );
  final reserved = <Expression, Expression>{
    for (final entry in encoding.entries)
      if (!entry.key.isReadOnly && entry.value.allowReserved)
        specLiteralString(entry.key.name): descriptor.constInstance([], {
          'allowReserved': literalBool(true),
        }),
  };

  if (reserved.isEmpty) return null;

  return literalMap(reserved, refer('String', 'dart:core'), descriptor);
}

Expression _entriesToBody(Expression entries) {
  return entries
      .property('map')
      .call([formEntryToWireString()])
      .property('join')
      .call([literalString('&')]);
}
