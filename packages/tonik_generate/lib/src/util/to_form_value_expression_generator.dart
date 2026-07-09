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
/// Emits per-property `explode: true` for every writable simple-content array
/// property whose effective explode is true, so the runtime serializes it as
/// repeated keys, merged with `allowReserved` for any property that opts in.
/// Returns null when no property needs either descriptor.
Expression? _fieldEncodingsLiteral(
  Model model,
  Map<Property, FieldEncoding>? encoding,
) {
  final encodingByProperty = encoding ?? const {};
  final encodingByName = <String, FieldEncoding>{
    for (final entry in encodingByProperty.entries) entry.key.name: entry.value,
  };

  final properties = <Property>[
    ..._collectFormProperties(model),
    ...encodingByProperty.keys,
  ];

  final descriptor = refer(
    'FormFieldEncoding',
    'package:tonik_util/tonik_util.dart',
  );

  final entries = <Expression, Expression>{};
  final seen = <String>{};
  for (final property in properties) {
    if (property.isReadOnly) continue;
    if (!seen.add(property.name)) continue;

    final fieldEncoding = encodingByName[property.name];
    final allowReserved = fieldEncoding?.allowReserved ?? false;
    final explode =
        _isSimpleContentList(property.model) && _explodeDefault(fieldEncoding);

    if (!allowReserved && !explode) continue;

    entries[specLiteralString(property.name)] = descriptor.constInstance([], {
      if (allowReserved) 'allowReserved': literalBool(true),
      if (explode) 'explode': literalBool(true),
    });
  }

  if (entries.isEmpty) return null;

  return literalMap(entries, refer('String', 'dart:core'), descriptor);
}

/// The OAS default explodes only `form`/absent style; `spaceDelimited` and
/// `pipeDelimited` with explode omitted comma-join.
bool _explodeDefault(FieldEncoding? encoding) =>
    encoding?.explode ??
    (encoding?.style == null || encoding?.style == EncodingStyle.form);

List<Property> _collectFormProperties(Model model) {
  switch (model.resolved) {
    case final ClassModel m:
      return m.properties;
    case final AllOfModel m:
      return [
        for (final member in m.models) ..._collectFormProperties(member),
      ];
    default:
      return const [];
  }
}

bool _isSimpleContentList(Model model) {
  final resolved = model.resolved;
  return resolved is ListModel && resolved.hasSimpleContent;
}

Expression _entriesToBody(Expression entries) {
  return entries
      .property('map')
      .call([formEntryToWireString()])
      .property('join')
      .call([literalString('&')]);
}
