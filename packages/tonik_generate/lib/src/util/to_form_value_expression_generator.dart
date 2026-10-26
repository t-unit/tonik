import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/text_encoding_expression.dart';

BuiltExpression buildToFormValueExpression(
  String valueExpression,
  Model model, {
  required bool useQueryComponent,
  required TextEncoding textEncoding,
  bool explodeLiteral = true,
  bool allowEmptyLiteral = true,
  bool receiverIsPromotedNonNull = false,
  Map<Property, FieldEncoding>? encoding,
}) {
  final receiver = refer(valueExpression);
  final resolved = model.resolved;
  final codec = textEncodingExpression(textEncoding);

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
          'textEncoding': codec,
        },
      ),
    );
  }

  final guardNull = model.isEffectivelyNullable && !receiverIsPromotedNonNull;
  final entries = buildFormEntriesValueExpression(
    guardNull ? refer('formValue') : receiver,
    model,
    paramName: literalString(''),
    explode: literalBool(explodeLiteral),
    allowEmpty: literalBool(allowEmptyLiteral),
    useQueryComponent: useQueryComponent ? literalBool(true) : null,
    textEncoding: codec,
    fieldEncodings: _fieldEncodingsLiteral(model, encoding),
  );

  if (entries == null) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(
        'Unsupported model type for form encoding.',
      ),
    );
  }

  final body = _entriesToBody(entries);
  return BuiltExpression.simple(
    guardNull
        ? Method(
            (b) => b
              ..lambda = false
              ..body = Block.of([
                const Code('final formValue = '),
                receiver.code,
                const Code("; if (formValue == null) return ''; return "),
                body.code,
                const Code(';'),
              ]),
          ).closure.call([])
        : body,
  );
}

/// Builds a `<String, FormFieldEncoding>` map literal for the object `toForm`
/// call, keyed by raw spec name to match the class's own per-property lookup.
///
/// Returns null when no property needs a descriptor, so the call omits the
/// argument entirely.
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
        _canEncodeArray(property.model) && _explodeDefault(fieldEncoding);

    if (!allowReserved && !explode) continue;

    entries[specLiteralString(property.name)] = descriptor.constInstance([], {
      if (allowReserved) 'allowReserved': literalBool(true),
      if (explode) 'explode': literalBool(true),
    });
  }

  if (entries.isEmpty) return null;

  return literalMap(entries, refer('String', 'dart:core'), descriptor);
}

/// With `explode` omitted, only `form`/absent style defaults to exploding;
/// every other style comma-joins.
bool _explodeDefault(FieldEncoding? encoding) =>
    encoding?.explode ??
    (encoding?.style == null || encoding?.style == EncodingStyle.form);

List<Property> _collectFormProperties(Model model) {
  switch (model.resolved) {
    case final ClassModel m:
      return m.properties;
    case final AllOfModel m:
      return [for (final member in m.models) ..._collectFormProperties(member)];
    default:
      return const [];
  }
}

bool _canEncodeArray(Model model, [Set<Model>? visited]) {
  final resolved = model.resolved;
  final seen = visited ?? <Model>{};
  if (!seen.add(resolved)) return false;
  return switch (resolved) {
    // Composed values use runtime flat-value checks instead of list codecs.
    ListModel() => visited != null || resolved.hasSimpleContent,
    CompositeModel() => resolved.containedModels.any(
      (member) => member.resolved is AnyModel || _canEncodeArray(member, seen),
    ),
    _ => false,
  };
}

Expression _entriesToBody(Expression entries) {
  return entries
      .property('map')
      .call([formEntryToWireString()])
      .property('join')
      .call([literalString('&')]);
}
