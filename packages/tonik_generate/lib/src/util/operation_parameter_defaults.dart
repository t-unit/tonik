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
  final onDropped = emitWarnings ? _log.warning : null;

  void process({
    required String normalizedName,
    required Model model,
    required Object? rawDefault,
    required String specName,
    required String location,
  }) {
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
      onDroppedDefault: onDropped,
    );
    if (resolved == null) return;

    byName[normalizedName] = OperationParameterDefault.local(
      memberName: resolved.memberName,
    );
    fields.add(defaultField(resolved));
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
