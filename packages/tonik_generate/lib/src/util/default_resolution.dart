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

/// Runtime-fallback sibling of [ResolvedDefault]. See [resolveRuntimeDefault].
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
    // Real drops warn (a runtime decoder would throw); intentional bubbles
    // are silent so the caller can route them to the runtime fallback.
    if (onDroppedDefault != null) {
      final resolved = model.resolved;
      if (resolved is PrimitiveModel &&
          _isMaterialiserSupportedPrimitive(model)) {
        onDroppedDefault(
          'Dropping default for $containerName.$specName '
          '($location, expected ${resolved.runtimeType}, '
          'value: ${_describeDefault(rawDefault)}): '
          'value does not match the expected type.',
        );
      } else if (resolved is EnumModel &&
          !_enumValueIsMember(resolved, rawDefault)) {
        onDroppedDefault(
          'Dropping default for $containerName.$specName '
          '($location, expected ${resolved.runtimeType}, '
          'value: ${_describeDefault(rawDefault)}): '
          'value is not one of the enum values.',
        );
      } else if ((resolved is ListModel ||
              resolved is MapModel ||
              resolved is AnyModel) &&
          _isCollectionShapeMismatch(resolved, rawDefault)) {
        onDroppedDefault(
          'Dropping default for $containerName.$specName '
          '($location, expected ${resolved.runtimeType}, '
          'value: ${_describeDefault(rawDefault)}): '
          'value does not match the expected list / map / free-form '
          'shape.',
        );
      }
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

/// Runtime-fallback sibling of [resolveSingleDefault]. Emits a
/// `static get <name>Default` getter that decodes the raw default on every
/// access — the runtime decoder is the validator, so a bad default surfaces
/// as a `DecodingException` rather than a codegen-time drop.
RuntimeResolvedDefault? resolveRuntimeDefault({
  required String normalizedName,
  required String specName,
  required Model model,
  required Object? rawDefault,
  required String containerName,
  required String location,
  required Set<String> reservedNames,
  required NameManager nameManager,
  required String package,
  bool isNullableOverride = false,
  bool useImmutableCollections = false,
}) {
  if (rawDefault == null) return null;

  // Without this warning a non-JSON-encodable raw default (e.g. an unquoted
  // YAML timestamp on a `format: date-time` field) would silently vanish:
  // the const path bubbled without warning and this guard drops it too.
  if (!_isJsonEncodable(rawDefault)) {
    _log.warning(
      'Dropping default for $containerName.$specName '
      '($location, expected ${model.resolved.runtimeType}, '
      'value: ${_describeDefault(rawDefault)}): '
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
    r'_$raw',
    model: model,
    nameManager: nameManager,
    package: package,
    contextClass: containerName,
    contextProperty: specName,
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
        // Self-referential typedef helpers need to be declared as statements
        // before the returned expression, which a lambda body cannot carry.
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

/// Short label embedded in routing-warning log lines.
String runtimeFallbackReason(Model model) {
  final resolved = model.resolved;
  return switch (resolved) {
    ClassModel() => 'object target',
    AllOfModel() || OneOfModel() || AnyOfModel() => 'composite target',
    EnumModel() => 'enum target',
    ListModel() => 'list with non-const content',
    MapModel() => 'map with non-const content',
    AliasModel() => 'alias target',
    DateTimeModel() ||
    DateModel() ||
    UriModel() ||
    DecimalModel() ||
    BinaryModel() ||
    Base64Model() ||
    AnyModel() => 'non-const leaf',
    _ => 'unrecognized model (${resolved.runtimeType})',
  };
}

// Callers must gate on `_isJsonEncodable` first; otherwise this throws.
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

// YAML can hand us non-JSON scalars (e.g. an inferred DateTime); fall back
// to toString so logging never throws.
String _describeDefault(Object? raw) =>
    _isJsonEncodable(raw) ? jsonEncode(raw) : raw.toString();

bool _isJsonEncodable(Object? value) => switch (value) {
  null || bool() || num() || String() => true,
  final List<Object?> list => list.every(_isJsonEncodable),
  final Map<Object?, Object?> map =>
    map.keys.every((k) => k is String) && map.values.every(_isJsonEncodable),
  _ => false,
};

// Duplicated from default_value_materialiser.dart so a primitive added there
// without a parallel update here surfaces as a wrong-reason warning.
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

// True only when the outer shape is wrong; nested-leaf failures bubble to
// the runtime fallback instead.
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
