import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/default_value_materialiser.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

final Logger _log = Logger('OperationParameterDefaults');

@immutable
class OperationParameterDefault {
  const OperationParameterDefault.local({required this.memberName})
    : _owner = null;

  const OperationParameterDefault.qualified({
    required this.memberName,
    required String className,
    required String url,
  }) : _owner = (className: className, url: url);

  final String memberName;
  final ({String className, String url})? _owner;

  OperationParameterDefault withOwner({
    required String className,
    required String url,
  }) => OperationParameterDefault.qualified(
    memberName: memberName,
    className: className,
    url: url,
  );

  Code defaultToCode() {
    final owner = _owner;
    if (owner == null) {
      return refer(memberName).code;
    }
    return refer(owner.className, owner.url).property(memberName).code;
  }
}

/// Pass [emitWarnings] `false` on secondary call sites (e.g. the
/// API-client forwarder) — the primary site already logs once per
/// dropped default.
({
  Map<String, OperationParameterDefault> byName,
  List<Field> fields,
})
resolveOperationParameterDefaults({
  required NormalizedRequestParameters normalizedParams,
  required String operationClassName,
  required NameManager nameManager,
  required String package,
  required Set<String> initialReservedNames,
  bool emitWarnings = true,
}) {
  final reserved = {...initialReservedNames};
  final byName = <String, OperationParameterDefault>{};
  final fields = <Field>[];

  void process({
    required String normalizedName,
    required Model model,
    required Object? rawDefault,
    required String specName,
    required String location,
  }) {
    if (rawDefault == null) return;

    final materialised = materialiseConstDefault(
      jsonValue: rawDefault,
      targetModel: model,
    );

    if (materialised == null) {
      if (emitWarnings) {
        final resolved = model.resolved;
        if (resolved is PrimitiveModel) {
          final reason = _isMaterialiserSupportedPrimitive(model)
              ? 'value does not match the parameter type'
              : 'default value cannot be expressed as a const Dart '
                    'expression for this type';
          _log.warning(
            'Dropping default for $operationClassName.$specName '
            '($location, expected ${resolved.runtimeType}, '
            'value: ${_describeDefault(rawDefault)}): $reason.',
          );
        }
      }
      return;
    }

    final memberName = nameManager.defaultMemberName(
      propertyName: normalizedName,
      reservedNames: reserved,
    );
    reserved.add(memberName);

    final type = typeReference(
      model,
      nameManager,
      package,
    );

    byName[normalizedName] = OperationParameterDefault.local(
      memberName: memberName,
    );

    fields.add(
      Field(
        (b) => b
          ..static = true
          ..modifier = FieldModifier.constant
          ..name = memberName
          ..type = type
          ..assignment = materialised.code,
      ),
    );
  }

  for (final p in normalizedParams.pathParameters) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
      location: 'path',
    );
  }
  for (final p in normalizedParams.queryParameters) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
      location: 'query',
    );
  }
  for (final p in normalizedParams.headers) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
      location: 'header',
    );
  }
  for (final p in normalizedParams.cookieParameters) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
      location: 'cookie',
    );
  }

  return (byName: byName, fields: fields);
}

Set<String> initialOperationDefaultReservedNames({
  required NormalizedRequestParameters normalizedParams,
  required bool hasRequestBody,
  required bool hasResponses,
  required bool hasQueryParameters,
}) => <String>{
  '_dio',
  'call',
  '_path',
  '_data',
  '_options',
  if (hasQueryParameters) '_queryParameters',
  if (hasResponses) '_parseResponse',
  if (hasRequestBody) 'body',
  'cancelToken',
  for (final p in normalizedParams.pathParameters) p.normalizedName,
  for (final p in normalizedParams.queryParameters) p.normalizedName,
  for (final p in normalizedParams.headers) p.normalizedName,
  for (final p in normalizedParams.cookieParameters) p.normalizedName,
};

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
