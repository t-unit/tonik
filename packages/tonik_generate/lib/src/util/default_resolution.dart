import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/default_value_materialiser.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

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

/// Composite-target defaults drop silently — they cannot carry a const
/// default anyway, so emitting a warning would be noise.
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
  );

  if (materialised == null) {
    if (onDroppedDefault != null) {
      final resolved = model.resolved;
      if (resolved is PrimitiveModel) {
        final reason = _isMaterialiserSupportedPrimitive(model)
            ? 'value does not match the expected type'
            : 'default value cannot be expressed as a const Dart expression '
                  'for this type';
        onDroppedDefault(
          'Dropping default for $containerName.$specName '
          '($location, expected ${_specTypeName(resolved)}, '
          'value: ${_describeDefault(rawDefault)}): $reason.',
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

// Mirrors the supported-types switch in default_value_materialiser.dart;
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

// Spec authors edit YAML in OpenAPI keywords, not the generator's Dart class
// names — surface the keyword so the warning is directly actionable.
String _specTypeName(PrimitiveModel resolved) => switch (resolved) {
  StringModel() => 'string',
  IntegerModel() => 'integer',
  DoubleModel() => 'number (double)',
  NumberModel() => 'number',
  BooleanModel() => 'boolean',
  DateTimeModel() => 'string (date-time)',
  DateModel() => 'string (date)',
  UriModel() => 'string (uri)',
  DecimalModel() => 'string (decimal)',
  BinaryModel() => 'string (binary)',
  Base64Model() => 'string (byte)',
};
