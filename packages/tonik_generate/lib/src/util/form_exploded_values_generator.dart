import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

/// A writable form array property paired with the expression that reads its
/// list value (`field`) and, when that read can yield null, a null-safe
/// expression the builder tests against null before mapping (`nullGuard`).
/// A null `nullGuard` marks a value that is always present.
typedef FormPropertyBinding = ({
  Expression field,
  Expression? nullGuard,
  Property property,
});

/// Whether the schema-aware field generated for [property] on a member class
/// is typed nullable. Form null-guard emission must consult the same predicate
/// the field type is built from, or a guard is dropped and the emission fails
/// to compile.
bool isSchemaAwareFieldNullable(
  Property property, {
  required bool memberIsReadOnly,
}) =>
    property.isNullable ||
    !property.isRequired ||
    property.isReadOnly ||
    property.isWriteOnly ||
    memberIsReadOnly;

/// Builds the `Map<String, List<String>>` literal passed as `explodedValues`
/// to an object's `toForm`, holding the individually-encoded elements of each
/// simple-content array property keyed by raw spec name.
///
/// Delivering elements as a list keeps their boundaries intact, so an element
/// containing a literal comma survives `style: form, explode: true` instead of
/// being re-split. Returns null when the object has no such array property.
///
/// Bindings that repeat a raw name (properties merged from several composition
/// members) collapse to the last, matching the last-wins merge of
/// `parameterProperties`.
Expression? buildFormExplodedValuesLiteral(
  List<FormPropertyBinding> bindings, {
  required bool useImmutableCollections,
}) {
  final byName = <String, Expression>{};
  for (final binding in bindings) {
    final model = binding.property.model;
    if (model is! ListModel || !model.hasSimpleContent) continue;

    byName[binding.property.name] = _encodedElementsExpression(
      binding.field,
      binding.nullGuard,
      binding.property.name,
      model,
      useImmutableCollections: useImmutableCollections,
    );
  }

  if (byName.isEmpty) return null;

  return literalMap(
    {
      for (final entry in byName.entries)
        specLiteralString(entry.key): entry.value,
    },
    refer('String', 'dart:core'),
    TypeReference(
      (t) => t
        ..symbol = 'List'
        ..url = 'dart:core'
        ..types.add(refer('String', 'dart:core')),
    ),
  );
}

Expression _encodedElementsExpression(
  Expression field,
  Expression? nullGuard,
  String rawName,
  ListModel model, {
  required bool useImmutableCollections,
}) {
  final content = model.content;
  final isContentNullable =
      model.isContentNullable || content.isEffectivelyNullable;

  final element = buildUriEncodeExpression(
    refer('e'),
    content,
    allowEmpty: literalBool(true),
    useQueryComponent: refer('useQueryComponent'),
    allowReserved: CodeExpression(
      Code(perPropertyAllowReservedValue(rawName)),
    ),
  ).expression;

  final guarded = isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), element)
      : element;

  final closure = Method(
    (b) => b
      ..lambda = true
      ..requiredParameters.add(Parameter((p) => p..name = 'e'))
      ..body = guarded.code,
  ).closure;

  Expression mapped(Expression list) {
    final listExpr = useImmutableCollections ? list.property('unlock') : list;
    return listExpr.property('map').call([closure]).property('toList').call([]);
  }

  if (nullGuard == null) return mapped(field);

  return nullGuard
      .equalTo(literalNull)
      .conditional(
        literalConstList([], refer('String', 'dart:core')),
        mapped(field),
      );
}
