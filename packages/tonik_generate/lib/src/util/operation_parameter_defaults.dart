import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/default_value_materialiser.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

final Logger _log = Logger('OperationParameterDefaults');

/// Qualified with [ownerClassName] when emitted outside the owning operation
/// class (API-client wrapper); otherwise a bare reference suffices.
@immutable
class OperationParameterDefault {
  const OperationParameterDefault({
    required this.memberName,
    required this.value,
    required this.type,
    this.ownerClassName,
    this.ownerUrl,
  });

  final String memberName;
  final Expression value;
  final TypeReference type;
  final String? ownerClassName;
  final String? ownerUrl;

  Code defaultToCode() {
    final owner = ownerClassName;
    if (owner == null) {
      return refer(memberName).code;
    }
    return refer(owner, ownerUrl).property(memberName).code;
  }
}

/// Primary emission site for warnings; API-client forwarding suppresses to
/// avoid duplicates.
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
  }) {
    if (rawDefault == null) return;

    final materialised = materialiseConstDefault(
      jsonValue: rawDefault,
      targetModel: model,
    );

    if (materialised == null) {
      if (emitWarnings && _isMaterialiserSupportedPrimitive(model)) {
        _log.warning(
          'Dropping default for $operationClassName.$specName: '
          'value does not match the parameter type.',
        );
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

    byName[normalizedName] = OperationParameterDefault(
      memberName: memberName,
      value: materialised,
      type: type,
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
    );
  }
  for (final p in normalizedParams.queryParameters) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
    );
  }
  for (final p in normalizedParams.headers) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
    );
  }
  for (final p in normalizedParams.cookieParameters) {
    process(
      normalizedName: p.normalizedName,
      model: p.parameter.model,
      rawDefault: p.parameter.effectiveDefaultValue,
      specName: p.parameter.rawName,
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

// Must duplicate (not introspect) the set in default_value_materialiser.dart —
// the coupling is intentional: a `PrimitiveModel` outside this set (DateTime,
// Date, Decimal, Uri, Binary, Base64) is parseable but not const-materialisable
// in Dart, so its default is silently dropped without warning.
bool _isMaterialiserSupportedPrimitive(Model model) => switch (model.resolved) {
  StringModel() ||
  IntegerModel() ||
  DoubleModel() ||
  NumberModel() ||
  BooleanModel() => true,
  _ => false,
};
