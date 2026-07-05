import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

/// A writable form array property paired with the expression that reads its
/// list value (`field`) and two independent null tests the merge fold consults.
///
/// `memberGuard` is null-safe access to the composition member that owns the
/// property; when it evaluates null the member is absent from the runtime
/// `parameterProperties` merge, so its data never reaches the wire and the fold
/// falls through to an earlier duplicate-key candidate. A null `memberGuard`
/// marks a member that is always present (the class path has no member, so it
/// is always null there).
///
/// `leafGuard` is access to the array property read through a present member;
/// when it evaluates null the member is present but its array value is absent.
/// `parameterProperties` writes `''` for such a property (form bodies pass
/// `allowEmpty: true`), so that member WINS the merge with zero elements. A
/// null `leafGuard` marks an array value that is always present once its member
/// is.
typedef FormPropertyBinding = ({
  Expression field,
  Expression? memberGuard,
  Expression? leafGuard,
  Property property,
});

/// Whether [property] is a writable array with simple content and therefore
/// eligible for the explode machinery — the field encoding descriptor and the
/// `explodedValues` channel. Whether it is actually exploded is decided by its
/// encoding (explicit `explode`, or the form/absent-style default).
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

/// Whether the schema-aware field generated for [property] on the owning class
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
/// to the `Map<String, String>.toForm` call inside the generated object's
/// `toForm`, holding the individually-encoded elements of each simple-content
/// array property keyed by raw spec name.
///
/// Delivering elements as a list keeps their boundaries intact, so an element
/// containing a literal comma survives `style: form, explode: true` instead of
/// being re-split. Returns null when the object has no such array property.
///
/// When several composition members expose the same raw name, the emitted
/// elements track exactly which member wins the runtime `parameterProperties`
/// merge, so flipping `explode` cannot change which member's data is
/// transmitted. The merge is per-member `addAll` — a later member overrides an
/// earlier one — with two null cases distinguished:
///
/// - the later member is absent (its access chain is null): it never merges, so
///   the fold falls through to the earlier candidate;
/// - the later member is present but its array property is null:
///   `parameterProperties` coerces that to an empty string entry (form bodies
///   pass `allowEmpty: true`), clobbering the earlier member, so the later
///   member wins with an empty element list (zero exploded entries).
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

/// The elements of the raw-name group emitted for the member that wins the
/// `parameterProperties` merge. Built as a left fold so each later binding
/// overrides the running winner; an absent member (`memberGuard` null) falls
/// through to the earlier one, while a present member with a null array leaf
/// (`leafGuard` null) wins with an empty list.
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

  var winner = _guarded(group.first, elements(group.first), _emptyStringList());
  for (final binding in group.skip(1)) {
    winner = _guarded(binding, elements(binding), winner);
  }
  return winner;
}

Expression _emptyStringList() =>
    literalConstList([], refer('String', 'dart:core'));

/// The value [binding] contributes to the merge fold, given [fallback] for an
/// earlier candidate:
///
/// - member absent → [fallback];
/// - member present, array leaf null → an empty element list (member wins with
///   zero entries, matching the `''` `parameterProperties` writes);
/// - otherwise → [present].
Expression _guarded(
  FormPropertyBinding binding,
  Expression present,
  Expression fallback,
) {
  final leafGuard = binding.leafGuard;
  final whenMemberPresent = leafGuard == null
      ? present
      : leafGuard.equalTo(literalNull).conditional(_emptyStringList(), present);

  final memberGuard = binding.memberGuard;
  if (memberGuard == null) return whenMemberPresent;
  return memberGuard
      .equalTo(literalNull)
      .conditional(fallback, whenMemberPresent);
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
