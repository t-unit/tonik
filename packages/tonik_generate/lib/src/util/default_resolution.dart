import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/default_value_materialiser.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

final Logger _log = Logger('DefaultResolution');

/// Default dropped-default callback for [resolveRuntimeDefault]. Exposed so
/// secondary call sites can opt back into the canonical logger after passing
/// `null` to suppress.
void defaultRuntimeDropLogger(String message) => _log.warning(message);

@immutable
class ResolvedDefault {
  const ResolvedDefault({
    required this.memberName,
    required this.value,
    required this.type,
  });

  final String memberName;
  final Expression value;
  final TypeReference type;
}

/// Runtime-fallback sibling of [ResolvedDefault] for defaults that cannot be
/// const-materialised (composite targets, non-const leaf scalars, or
/// collections nesting either). The static getter recomputes the value on
/// every access via the runtime decode path appropriate for the target:
/// `fromJson` for composite and object targets, scalar extension decoders
/// (`decodeJsonDateTime`, etc.) for non-const leaves.
@immutable
class RuntimeResolvedDefault {
  const RuntimeResolvedDefault({
    required this.memberName,
    required this.getter,
    required this.type,
  });

  final String memberName;
  final Method getter;
  final TypeReference type;
}

/// Sealed binding so a caller can pattern-match const vs runtime defaults
/// without ad-hoc booleans. Both carriers expose [memberName] — that is
/// all the decoder template needs.
@immutable
sealed class DefaultBinding {
  const DefaultBinding();

  String get memberName;
}

final class ConstDefaultBinding extends DefaultBinding {
  const ConstDefaultBinding(this.resolved);

  final ResolvedDefault resolved;

  @override
  String get memberName => resolved.memberName;
}

final class RuntimeDefaultBinding extends DefaultBinding {
  const RuntimeDefaultBinding(this.resolved);

  final RuntimeResolvedDefault resolved;

  @override
  String get memberName => resolved.memberName;
}

/// Returns `null` when the default cannot be expressed as a const Dart
/// expression. `onDroppedDefault` fires only for real drops (type / shape /
/// enum-value mismatches on otherwise-supported primitives, enums, and
/// collections). Silent `null` returns are intentional bubbles the caller
/// routes to [resolveRuntimeDefault].
ResolvedDefault? resolveSingleDefault({
  required String normalizedName,
  required String specName,
  required Model model,
  required Object? rawDefault,
  required String containerName,
  required String location,
  required Set<String> reservedNames,
  required NameManager nameManager,
  required String package,
  required void Function(String message)? onDroppedDefault,
  bool isNullableOverride = false,
  bool useImmutableCollections = false,
}) {
  if (rawDefault == null) return null;

  final materialised = materialiseConstDefault(
    jsonValue: rawDefault,
    targetModel: model,
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  );

  if (materialised == null) {
    if (onDroppedDefault != null) {
      final resolved = model.resolved;
      if (resolved is PrimitiveModel) {
        // Type mismatch on a const-supported primitive is a real drop —
        // a runtime decoder would throw, so warn rather than route to the
        // runtime fallback. Non-const-materialisable primitives (DateTime /
        // Uri / Decimal / Binary / Base64) are intentional bubbles — the
        // caller routes them to the runtime fallback.
        if (_isMaterialiserSupportedPrimitive(model)) {
          onDroppedDefault(
            'Dropping default for $containerName.$specName '
            '($location, expected ${resolved.runtimeType}, '
            'value: ${_describeDefault(rawDefault)}): '
            'value does not match the expected type.',
          );
        }
      } else if (resolved is EnumModel) {
        // Enum value mismatch is a real drop. A nullable enum that holds a
        // valid value just lacks a const variant ref — bubble to the runtime
        // fallback.
        if (!_enumValueIsMember(resolved, rawDefault)) {
          onDroppedDefault(
            'Dropping default for $containerName.$specName '
            '($location, expected ${resolved.runtimeType}, '
            'value: ${_describeDefault(rawDefault)}): '
            'value is not one of the enum values.',
          );
        }
      } else if (resolved is ListModel ||
          resolved is MapModel ||
          resolved is AnyModel) {
        // Outer-shape mismatch is a real drop; nested-leaf failures bubble
        // to the runtime fallback (the runtime decoder handles them via
        // fromJson).
        if (_isCollectionShapeMismatch(resolved, rawDefault)) {
          onDroppedDefault(
            'Dropping default for $containerName.$specName '
            '($location, expected ${resolved.runtimeType}, '
            'value: ${_describeDefault(rawDefault)}): '
            'value does not match the expected list / map / free-form '
            'shape.',
          );
        }
      }
      // ClassModel and CompositeModel return null silently — both are
      // intentional bubbles to the runtime fallback.
    }
    return null;
  }

  final memberName = nameManager.defaultMemberName(
    propertyName: normalizedName,
    reservedNames: reservedNames,
  );
  reservedNames.add(memberName);

  return ResolvedDefault(
    memberName: memberName,
    value: materialised,
    type: typeReference(
      model,
      nameManager,
      package,
      isNullableOverride: isNullableOverride,
      useImmutableCollections: useImmutableCollections,
    ),
  );
}

Field defaultField(ResolvedDefault resolved) => Field(
  (b) => b
    ..static = true
    ..modifier = FieldModifier.constant
    ..name = resolved.memberName
    ..type = resolved.type
    ..assignment = resolved.value.code,
);

/// Runtime-fallback entry point. Sibling of [resolveSingleDefault] for
/// defaults that cannot be expressed as a const Dart expression (composite
/// targets, non-const leaves, or collections nesting either). Emits a
/// computed `static get <name>Default` getter whose body decodes the
/// raw-JSON default literal via the runtime decode path appropriate for
/// the target: `fromJson` for composite and object targets, scalar
/// extension decoders (`decodeJsonDateTime`, etc.) for non-const leaves.
///
/// The runtime decoder is the validator — no codegen-time dry-run. A bad
/// default surfaces as a `DecodingException` on first access.
RuntimeResolvedDefault? resolveRuntimeDefault({
  required String normalizedName,
  required String specName,
  required Model model,
  required Object? rawDefault,
  required String containerName,
  required Set<String> reservedNames,
  required NameManager nameManager,
  required String package,
  void Function(String message)? onDroppedDefault = defaultRuntimeDropLogger,
  bool isNullableOverride = false,
  bool useImmutableCollections = false,
}) {
  if (rawDefault == null) return null;

  // A non-JSON-encodable raw default (e.g. a YAML-parsed DateTime that
  // wasn't quoted in the spec) cannot be embedded as a Dart literal. Without
  // a warning here the spec's `default:` would silently vanish from the
  // generated code: the const path may have bubbled without warning (for
  // non-const-materialisable primitives like DateTime/Uri/Decimal/Binary/
  // Base64) and this guard would also drop it. Logging makes the drop
  // visible to the spec author.
  if (!_isJsonEncodable(rawDefault)) {
    onDroppedDefault?.call(
      'Dropping default for $containerName.$specName: '
      'value of type ${rawDefault.runtimeType} is not JSON-encodable '
      'and cannot be embedded as a runtime literal.',
    );
    return null;
  }

  final memberName = nameManager.defaultMemberName(
    propertyName: normalizedName,
    reservedNames: reservedNames,
  );
  reservedNames.add(memberName);

  final returnType = typeReference(
    model,
    nameManager,
    package,
    isNullableOverride: isNullableOverride,
    useImmutableCollections: useImmutableCollections,
  );

  final rawLiteral = _jsonAsConstExpression(rawDefault);
  final decoded = buildFromJsonValueExpression(
    // The receiver override below replaces this name at every top-level use,
    // so the identifier never appears in the emitted code. It still names the
    // few inline helpers we could not eliminate via the override.
    r'_$raw',
    model: model,
    nameManager: nameManager,
    package: package,
    contextClass: containerName,
    contextProperty: specName,
    isNullable: isNullableOverride,
    useImmutableCollections: useImmutableCollections,
    receiverOverride: rawLiteral,
  );

  final getter = Method(
    (b) {
      b
        ..static = true
        ..name = memberName
        ..type = MethodType.getter
        ..returns = returnType;

      if (decoded.inlineFunctions.isEmpty) {
        b
          ..lambda = true
          ..body = decoded.unsafeRawBody.code;
      } else {
        // Self-referential `MapModel`/`ListModel` typedefs surface as inline
        // helper functions that must be declared as statements before the
        // returned expression. A lambda body can only carry a single
        // expression, so we fall back to a block body for this case.
        b.body = Block.of([
          ...spliceInlineHelpers(decoded.inlineFunctions),
          decoded.unsafeRawBody.returned.statement,
        ]);
      }
    },
  );

  return RuntimeResolvedDefault(
    memberName: memberName,
    getter: getter,
    type: returnType,
  );
}

/// Discriminator returned to log/diagnostic call sites that route a default
/// to the runtime fallback. Distinguishes object targets ([ClassModel]),
/// true composites ([AllOfModel] / [OneOfModel] / [AnyOfModel]), and
/// non-const leaf scalars / collections.
String runtimeFallbackReason(Model model) => switch (model.resolved) {
  ClassModel() => 'object target',
  AllOfModel() || OneOfModel() || AnyOfModel() => 'composite target',
  _ => 'non-const leaf',
};

// Recursive JSON → const Dart expression. Callers must gate on
// `_isJsonEncodable` first; otherwise this may throw on non-JSON inputs:
// non-String map keys and non-JSON scalars (e.g. YAML-parsed DateTime) are
// rejected with a StateError — the runtime fallback requires a const-able
// literal.
Expression _jsonAsConstExpression(Object? json) {
  switch (json) {
    case null:
      return literalNull;
    case final bool value:
      return literalBool(value);
    case final num value:
      return literalNum(value);
    case final String value:
      return specLiteralString(value);
    case final List<Object?> value:
      return literalConstList(
        value.map(_jsonAsConstExpression).toList(),
        refer('Object?', 'dart:core'),
      );
    case final Map<Object?, Object?> value:
      final entries = <Object?, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw StateError(
            'Non-String map key in runtime default literal: '
            '${entry.key}',
          );
        }
        entries[specLiteralString(key)] = _jsonAsConstExpression(entry.value);
      }
      return literalConstMap(
        entries,
        refer('String', 'dart:core'),
        refer('Object?', 'dart:core'),
      );
  }
  throw StateError('Non-JSON value in runtime default literal: $json');
}

// YAML's timestamp inference can hand us a `DateTime` (or any non-JSON
// scalar) — fall back to `toString` so a logging path never throws.
String _describeDefault(Object? raw) =>
    _isJsonEncodable(raw) ? jsonEncode(raw) : raw.toString();

bool _isJsonEncodable(Object? value) => switch (value) {
  null || bool() || num() || String() => true,
  final List<Object?> list => list.every(_isJsonEncodable),
  final Map<Object?, Object?> map =>
    map.keys.every((k) => k is String) && map.values.every(_isJsonEncodable),
  _ => false,
};

// Mirrors the supported-primitives switch in default_value_materialiser.dart;
// kept duplicated so a primitive added there without a parallel update here
// shows up immediately as a wrong-reason warning.
bool _isMaterialiserSupportedPrimitive(Model model) => switch (model.resolved) {
  StringModel() ||
  IntegerModel() ||
  DoubleModel() ||
  NumberModel() ||
  BooleanModel() => true,
  _ => false,
};

bool _enumValueIsMember(EnumModel<dynamic> model, Object? rawDefault) =>
    model.values.any((entry) => entry.value == rawDefault);

// Outer-shape gate: true when the raw default cannot be the JSON shape this
// model expects at the top level. Non-String map keys and inner-leaf failures
// are classified as nested-value failures, not shape mismatches.
bool _isCollectionShapeMismatch(Model resolved, Object? rawDefault) =>
    switch (resolved) {
      ListModel() => rawDefault is! List,
      MapModel() => rawDefault is! Map,
      AnyModel() =>
        rawDefault is! bool &&
            rawDefault is! num &&
            rawDefault is! String &&
            rawDefault is! List<Object?> &&
            rawDefault is! Map<Object?, Object?>,
      _ => false,
    };
