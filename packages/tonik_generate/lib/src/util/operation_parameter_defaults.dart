import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/default_resolution.dart';

final Logger _log = Logger('OperationParameterDefaults');

@immutable
class OperationParameterDefault {
  const OperationParameterDefault.local({
    required this.memberName,
    this.isRuntime = false,
  }) : _owner = null;

  const OperationParameterDefault.qualified({
    required this.memberName,
    required String className,
    required String url,
    this.isRuntime = false,
  }) : _owner = (className: className, url: url);

  final String memberName;
  final ({String className, String url})? _owner;

  /// `true` when the underlying member is a non-const `static get` (runtime
  /// fallback). The call-site reference syntax is identical, but the
  /// generated `call()` parameter cannot wire `defaultTo` because a static
  /// getter is not a constant expression.
  final bool isRuntime;

  OperationParameterDefault withOwner({
    required String className,
    required String url,
  }) {
    assert(
      _owner == null,
      'withOwner called on an already-qualified OperationParameterDefault — '
      'qualifying twice would silently overwrite the existing owner.',
    );
    return OperationParameterDefault.qualified(
      memberName: memberName,
      className: className,
      url: url,
      isRuntime: isRuntime,
    );
  }

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
  List<Method> getters,
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
  final getters = <Method>[];
  final logWarning = emitWarnings ? _log.warning : null;

  void process({
    required String normalizedName,
    required Model model,
    required Object? rawDefault,
    required String specName,
    required String location,
  }) {
    if (rawDefault == null) return;

    var dropped = false;
    final resolved = resolveSingleDefault(
      normalizedName: normalizedName,
      specName: specName,
      model: model,
      rawDefault: rawDefault,
      containerName: operationClassName,
      location: location,
      reservedNames: reserved,
      nameManager: nameManager,
      package: package,
      onDroppedDefault: (message) {
        dropped = true;
        logWarning?.call(message);
      },
    );
    if (resolved != null) {
      byName[normalizedName] = OperationParameterDefault.local(
        memberName: resolved.memberName,
      );
      fields.add(defaultField(resolved));
      return;
    }
    if (dropped) return;

    // No `defaultTo` wiring on the `call()` parameter — a static getter is
    // not a constant expression.
    final runtime = resolveRuntimeDefault(
      normalizedName: normalizedName,
      specName: specName,
      model: model,
      rawDefault: rawDefault,
      containerName: operationClassName,
      location: location,
      reservedNames: reserved,
      nameManager: nameManager,
      package: package,
      // Mirror `emitWarnings` so the api-client forwarder doesn't
      // double-log the non-JSON-encodable drop.
      onDroppedDefault: emitWarnings ? defaultRuntimeDropLogger : null,
    );
    if (runtime == null) return;

    if (emitWarnings) {
      _log.warning(
        'Routing default to runtime fallback for $operationClassName.'
        '$specName ($location, ${runtimeFallbackReason(model)}).',
      );
    }
    byName[normalizedName] = OperationParameterDefault.local(
      memberName: runtime.memberName,
      isRuntime: true,
    );
    getters.add(runtime.getter);
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

  return (byName: byName, fields: fields, getters: getters);
}

// Normalised parameter names cannot start with `_` (see `normalizeSingle` in
// name_utils.dart), and the default-member candidate is `<paramName>Default`
// — so private operation members like `_dio` / `_path` / `_queryParameters`
// can never collide with a default and don't need to be reserved here.
Set<String> initialOperationDefaultReservedNames({
  required NormalizedRequestParameters normalizedParams,
  required bool hasRequestBody,
}) => <String>{
  'call',
  if (hasRequestBody) 'body',
  'cancelToken',
  for (final p in normalizedParams.pathParameters) p.normalizedName,
  for (final p in normalizedParams.queryParameters) p.normalizedName,
  for (final p in normalizedParams.headers) p.normalizedName,
  for (final p in normalizedParams.cookieParameters) p.normalizedName,
};
