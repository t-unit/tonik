import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/form_exploded_values_generator.dart';
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
    fieldEncodings: _fieldEncodingsLiteral(model, encoding),
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
/// call, keyed by raw spec name to match the class's own per-property lookup.
///
/// Carries per-property `explode` for every writable simple-content array
/// property — defaulting to true only when the property's encoding omits
/// explode and its style is form or absent — so the runtime emits repeated
/// keys, plus `allowReserved` for any property that opts in. Returns null when
/// no property needs either.
Expression? _fieldEncodingsLiteral(
  Model model,
  Map<Property, FieldEncoding>? encoding,
) {
  final byName = <String, FieldEncoding>{
    if (encoding != null)
      for (final entry in encoding.entries) entry.key.name: entry.value,
  };

  final properties = <String, Property>{};
  for (final property in _collectFormProperties(model)) {
    properties[property.name] = property;
  }
  if (encoding != null) {
    for (final property in encoding.keys) {
      properties.putIfAbsent(property.name, () => property);
    }
  }

  final descriptor = refer(
    'FormFieldEncoding',
    'package:tonik_util/tonik_util.dart',
  );
  final map = <Expression, Expression>{};
  for (final property in properties.values) {
    if (property.isReadOnly) continue;

    final fieldEncoding = byName[property.name];
    final allowReserved = fieldEncoding?.allowReserved ?? false;
    final explode = isExplodedFormArrayProperty(property)
        ? _explodeDefault(fieldEncoding)
        : null;

    if (!allowReserved && explode == null) continue;

    map[specLiteralString(property.name)] = descriptor.constInstance([], {
      if (allowReserved) 'allowReserved': literalBool(true),
      if (explode != null) 'explode': literalBool(explode),
    });
  }

  if (map.isEmpty) return null;

  return literalMap(map, refer('String', 'dart:core'), descriptor);
}

/// The effective explode for a form array property: the explicit value, or
/// per OAS the default of true only for form or absent style.
bool _explodeDefault(FieldEncoding? fieldEncoding) {
  final style = fieldEncoding?.style;
  return fieldEncoding?.explode ??
      (style == null || style == EncodingStyle.form);
}

List<Property> _collectFormProperties(Model model) {
  final sorter = StableModelSorter();
  List<Property> collect(Model model) {
    switch (model.resolved) {
      case final ClassModel m:
        return m.properties.toList();
      case final AllOfModel m:
        return [
          for (final member in sorter.sortModels(m.models)) ...collect(member),
        ];
      default:
        return const [];
    }
  }

  return collect(model);
}

Expression _entriesToBody(Expression entries) {
  return entries
      .property('map')
      .call([formEntryToWireString()])
      .property('join')
      .call([literalString('&')]);
}
