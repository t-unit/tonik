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

/// Whether [property] is a writable array with simple content that form
/// encoding emits as an exploded (`style: form, explode: true`) repeated-key
/// property.
///
/// Uses the unresolved model so it matches the class-dispatch predicate: an
/// alias-wrapped array is not treated as an exploded form array (that routes
/// the whole class to the "contains complex types" path instead). The field
/// encoding descriptor, the `explodedValues` channel, and the member-binding
/// collector must all agree on this set or the wire data diverges.
bool isExplodedFormArrayProperty(Property property) {
  if (property.isReadOnly) return false;
  final model = property.model;
  return model is ListModel && model.hasSimpleContent;
}

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
/// When several composition members expose the same raw name, the emitted
/// elements come from whichever member's value wins the `parameterProperties`
/// merge at runtime — last non-null wins. A later nullable member that is null
/// falls back through a runtime-conditional chain to the earlier member's
/// elements, so the wire never drops the merge winner's data.
Expression? buildFormExplodedValuesLiteral(
  List<FormPropertyBinding> bindings, {
  required bool useImmutableCollections,
}) {
  final byName = <String, List<FormPropertyBinding>>{};
  for (final binding in bindings) {
    if (!isExplodedFormArrayProperty(binding.property)) continue;
    byName.putIfAbsent(binding.property.name, () => []).add(binding);
  }

  if (byName.isEmpty) return null;

  return literalMap(
    {
      for (final entry in byName.entries)
        specLiteralString(entry.key): _mergeWinnerElements(
          entry.value,
          useImmutableCollections: useImmutableCollections,
        ),
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

/// The elements of the raw-name group that wins the `parameterProperties`
/// merge — last non-null member. Built as a left fold so each later present
/// binding overrides the running winner, and a later null binding falls
/// through to the earlier one, mirroring last-non-null-wins.
Expression _mergeWinnerElements(
  List<FormPropertyBinding> group, {
  required bool useImmutableCollections,
}) {
  Expression elements(FormPropertyBinding binding) =>
      _encodedElementsExpression(
        binding.field,
        binding.property.model as ListModel,
        binding.property.name,
        useImmutableCollections: useImmutableCollections,
      );

  final emptyList = literalConstList([], refer('String', 'dart:core'));

  var winner = _guarded(group.first, elements(group.first), emptyList);
  for (final binding in group.skip(1)) {
    winner = _guarded(binding, elements(binding), winner);
  }
  return winner;
}

/// [present] when [binding] is non-null at runtime, otherwise [fallback]. A
/// non-nullable binding is always present and returns [present] directly.
Expression _guarded(
  FormPropertyBinding binding,
  Expression present,
  Expression fallback,
) {
  final guard = binding.nullGuard;
  if (guard == null) return present;
  return guard.equalTo(literalNull).conditional(fallback, present);
}

Expression _encodedElementsExpression(
  Expression field,
  ListModel model,
  String rawName, {
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

  final listExpr = useImmutableCollections
      ? field.property('unlock')
      : field;
  return listExpr.property('map').call([closure]).property('toList').call([]);
}
