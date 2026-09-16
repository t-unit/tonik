import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/recursion_detector.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

typedef MultipartHeaderParamInfo = ({
  MultipartRequestContent content,
  String name,
  String normalizedPropertyName,
  String rawHeaderName,
  Model model,
  bool isRequired,
  bool isDeprecated,
});

// Inline part headers follow the mutable operation-parameter API.
List<Parameter> buildMultipartHeaderParameters(
  List<MultipartHeaderParamInfo> headers,
  NameManager nameManager,
  String package,
) => [
  for (final header in headers)
    Parameter(
      (parameter) => parameter
        ..name = header.name
        ..type = typeReference(
          header.model,
          nameManager,
          package,
          isNullableOverride: !header.isRequired,
        )
        ..named = true
        ..required = header.isRequired,
    ),
];

List<MultipartHeaderParamInfo> extractMultipartHeaderParamInfo(
  MultipartRequestContent content, {
  Set<String> reservedNames = const {},
  NameManager? nameManager,
  String? package,
}) {
  final normalization = normalizeMultipartProperties(
    content,
    nameManager: nameManager,
    package: package,
  );
  if (normalization.runtimeEncodingError != null) return const [];

  final result = <MultipartHeaderParamInfo>[];
  final usedNames = reservedNames.map((name) => name.toLowerCase()).toSet();

  for (final property in normalization.properties) {
    final headers = content.encoding[property.rawName]?.headers;
    if (headers == null || headers.isEmpty) continue;

    final isPropertyOptional = !property.isRequired || property.isNullable;

    for (final entry in headers.entries) {
      final rawHeaderName = entry.key;
      final header = entry.value.resolve(name: rawHeaderName);
      final isRequired = !isPropertyOptional && header.isRequired;

      final baseName = normalizeMultipartHeaderName(
        property.normalizedName,
        rawHeaderName,
      );
      final paramName = _uniqueMultipartHeaderParameterName(
        baseName,
        usedNames,
      );

      result.add((
        content: content,
        name: paramName,
        normalizedPropertyName: property.normalizedName,
        rawHeaderName: rawHeaderName,
        model: header.model,
        isRequired: isRequired,
        isDeprecated: header.isDeprecated,
      ));
    }
  }

  return result;
}

/// Extracts all per-part header parameters using names scoped to one operation.
List<MultipartHeaderParamInfo> extractOperationMultipartHeaderParamInfo(
  Operation operation, {
  NameManager? nameManager,
  String? package,
}) {
  final hasRequestBody =
      operation.requestBody?.resolvedContent.isNotEmpty ?? false;
  if (!hasRequestBody) return const [];

  final normalized = normalizeRequestParameters(
    pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
    queryParameters: operation.queryParameters.map((p) => p.resolve()).toSet(),
    headers: operation.headers.map((p) => p.resolve()).toSet(),
    cookieParameters: operation.cookieParameters
        .map((p) => p.resolve())
        .toSet(),
    reservedNames: operationReservedParameterNames(hasRequestBody: true),
  );
  final usedNames = <String>{
    ...operationReservedParameterNames(hasRequestBody: true),
    ...normalized.pathParameters.map((p) => p.normalizedName),
    ...normalized.queryParameters.map((p) => p.normalizedName),
    ...normalized.headers.map((p) => p.normalizedName),
    ...normalized.cookieParameters.map((p) => p.normalizedName),
  };
  final result = <MultipartHeaderParamInfo>[];

  for (final content in operation.requestBody!.resolvedContent) {
    if (content is! MultipartRequestContent) continue;
    final parameters = extractMultipartHeaderParamInfo(
      content,
      reservedNames: usedNames,
      nameManager: nameManager,
      package: package,
    );
    result.addAll(parameters);
    usedNames.addAll(parameters.map((parameter) => parameter.name));
  }

  return result;
}

class const MultipartPropertyPlan({
  required final String rawName,
  required final String normalizedName,
  required final List<Property> properties,
  required final List<List<MultipartAccessSegment>> accessPaths,
  required final bool isRequired,
  required final bool isNullable,
}) {
  Property get property => properties.first;
}

typedef MultipartAccessSegment = ({String name, bool receiverNullable});

final class const MultipartDynamicSource({
  required final List<MultipartAccessSegment> accessPath,
  required final Model valueModel,
  required final bool isValueNullable,
  required final bool receiverNullable,
  required final Set<String> declaredWireNames,
});

final class const MultipartPropertyNormalizationResult({
  required final List<MultipartPropertyPlan> properties,
  final String? runtimeEncodingError,
  final MultipartDynamicSource? dynamicSource,
});

MultipartPropertyNormalizationResult normalizeMultipartProperties(
  MultipartRequestContent content, {
  NameManager? nameManager,
  String? package,
}) {
  final occurrences =
      <({Property property, List<MultipartAccessSegment> path})>[];
  final collection = _collectMultipartProperties(
    content.model,
    const [],
    multipartModelIsNullable(content.model),
    <Model>{},
    occurrences,
    nameManager,
    package,
  );
  if (collection.error case final collectionError?) {
    return MultipartPropertyNormalizationResult(
      properties: const [],
      runtimeEncodingError: collectionError,
    );
  }

  final grouped =
      <
        String,
        List<({Property property, List<MultipartAccessSegment> path})>
      >{};
  for (final occurrence in occurrences) {
    if (occurrence.property.isReadOnly ||
        _modelIsReadOnly(occurrence.property.model, <Model>{})) {
      continue;
    }
    (grouped[occurrence.property.name] ??= []).add(occurrence);
  }
  final unmatchedEncodingKeys = content.encoding.keys
      .where((key) => !grouped.containsKey(key))
      .toList();
  if (unmatchedEncodingKeys.isNotEmpty) {
    return MultipartPropertyNormalizationResult(
      properties: const [],
      runtimeEncodingError:
          'Multipart encoding references properties that are not writable or '
          'do not exist in the body model: '
          '${unmatchedEncodingKeys.join(', ')}.',
    );
  }
  final uniqueNames = ensureUniqueness([
    for (final entry in grouped.entries)
      (
        normalizedName: normalizeSingle(
          entry.value.first.property.nameOverride ?? entry.key,
          preserveNumbers: true,
        ),
        originalValue: entry,
      ),
  ], defaultPrefix: defaultFieldPrefix);
  return MultipartPropertyNormalizationResult(
    dynamicSource: collection.dynamicSource,
    properties: [
      for (final item in uniqueNames)
        MultipartPropertyPlan(
          rawName: item.originalValue.key,
          normalizedName: item.normalizedName,
          properties: [
            for (final occurrence in item.originalValue.value)
              occurrence.property,
          ],
          accessPaths: [
            for (final occurrence in item.originalValue.value) occurrence.path,
          ],
          isRequired: item.originalValue.value.any(
            (occurrence) => occurrence.property.isRequired,
          ),
          isNullable: item.originalValue.value.every(
            (occurrence) =>
                occurrence.property.isNullable ||
                multipartModelIsNullable(occurrence.property.model) ||
                !occurrence.property.isRequired ||
                occurrence.property.isWriteOnly ||
                occurrence.path.any((segment) => segment.receiverNullable),
          ),
        ),
    ],
  );
}

({String? error, MultipartDynamicSource? dynamicSource})
_collectMultipartProperties(
  Model model,
  List<MultipartAccessSegment> path,
  bool receiverNullable,
  Set<Model> active,
  List<({Property property, List<MultipartAccessSegment> path})> result,
  NameManager? nameManager,
  String? package,
) {
  if (_modelIsReadOnly(model, <Model>{})) {
    if (path.isEmpty) {
      return (
        error:
            'Multipart body root ${model.runtimeType} at ${model.context} is '
            'read-only and cannot be used as a request body.',
        dynamicSource: null,
      );
    }
    return (error: null, dynamicSource: null);
  }
  if (!active.add(model)) {
    return (
      error:
          'Multipart body model contains a cycle while resolving '
          '${model.context}.',
      dynamicSource: null,
    );
  }
  try {
    switch (model) {
      case AliasModel():
        return _collectMultipartProperties(
          model.model,
          path,
          receiverNullable || model.isNullable,
          active,
          result,
          nameManager,
          package,
        );
      case MapModel():
        if (path.isNotEmpty) {
          return (error: _dynamicAllOfError(model), dynamicSource: null);
        }
        final valueError = _dynamicValueError(model.valueModel);
        if (valueError != null) return (error: valueError, dynamicSource: null);
        return (
          error: null,
          dynamicSource: MultipartDynamicSource(
            accessPath: path,
            valueModel: model.valueModel,
            isValueNullable:
                model.isValueNullable ||
                multipartModelIsNullable(model.valueModel),
            receiverNullable: receiverNullable,
            declaredWireNames: const {},
          ),
        );
      case ClassModel():
        final normalizedProperties = normalizeProperties(model.properties);
        MultipartDynamicSource? dynamicSource;
        if (model.additionalPropertiesPolicy case AllowedAdditionalProperties(
          origin: AdditionalPropertiesOrigin.explicit,
          :final valueModel,
        )) {
          if (path.isNotEmpty) {
            return (error: _dynamicAllOfError(model), dynamicSource: null);
          }
          final valueError = _dynamicValueError(valueModel);
          if (valueError != null) {
            return (error: valueError, dynamicSource: null);
          }
          final fieldName =
              (nameManager ??
                      NameManager(
                        generator: NameGenerator(),
                        stableModelSorter: StableModelSorter(),
                      ))
                  .additionalPropertiesFieldName(normalizedProperties);
          dynamicSource = MultipartDynamicSource(
            accessPath: [
              ...path,
              (name: fieldName, receiverNullable: receiverNullable),
            ],
            valueModel: valueModel,
            isValueNullable: multipartModelIsNullable(valueModel),
            receiverNullable: receiverNullable,
            declaredWireNames: model.properties.map((p) => p.name).toSet(),
          );
        }
        for (final (:normalizedName, :property) in normalizedProperties) {
          result.add((
            property: property,
            path: [
              ...path,
              (name: normalizedName, receiverNullable: receiverNullable),
            ],
          ));
        }
        return (error: null, dynamicSource: dynamicSource);
      case AllOfModel():
        final additionalPropertiesError = _additionalPropertiesError(model);
        if (additionalPropertiesError != null) {
          return (error: additionalPropertiesError, dynamicSource: null);
        }
        final namedMembers = ensureUniqueness([
          for (final member in model.models)
            (
              normalizedName: normalizeSingle(
                _multipartMemberTypeName(member, nameManager, package),
                preserveNumbers: true,
              ),
              originalValue: member,
            ),
        ], defaultPrefix: defaultFieldPrefix);
        for (final member in namedMembers) {
          final memberNullable =
              receiverNullable ||
              multipartModelIsNullable(member.originalValue);
          final memberResult = _collectMultipartProperties(
            member.originalValue,
            [
              ...path,
              (name: member.normalizedName, receiverNullable: receiverNullable),
            ],
            memberNullable,
            active,
            result,
            nameManager,
            package,
          );
          if (memberResult.error != null) return memberResult;
        }
        return (error: null, dynamicSource: null);
      default:
        return (
          error:
              'Unsupported multipart body root/member ${model.runtimeType} at '
              '${model.context}. Multipart bodies require a class, an alias to '
              'a supported model, or an allOf containing supported members.',
          dynamicSource: null,
        );
    }
  } finally {
    active.remove(model);
  }
}

bool multipartModelIsNullable(Model model, [Set<Model>? active]) {
  final visited = active ?? <Model>{};
  if (!visited.add(model)) return false;
  try {
    return switch (model) {
      AliasModel(:final isNullable, :final model) =>
        isNullable || multipartModelIsNullable(model, visited),
      _ => model.isEffectivelyNullable,
    };
  } finally {
    visited.remove(model);
  }
}

String? _additionalPropertiesError(AllOfModel model) {
  if (model.additionalPropertiesPolicy case AllowedAdditionalProperties(
    origin: AdditionalPropertiesOrigin.explicit,
  )) {
    return _dynamicAllOfError(model);
  }
  return null;
}

String _dynamicAllOfError(Model model) =>
    'Dynamic multipart sources inside allOf are not supported '
    '(${model.runtimeType} at ${model.context}).';

bool _containsRecursiveCollection(Model model) {
  final visited = <Model>{};

  bool walk(Model current) {
    if (!visited.add(current)) return false;
    return switch (current) {
      AliasModel(:final model) => walk(model),
      MapModel(:final valueModel) => isRecursive(current) || walk(valueModel),
      ListModel(:final content) => isRecursive(current) || walk(content),
      _ => false,
    };
  }

  return walk(model);
}

String? _dynamicValueError(Model model) {
  if (_containsRecursiveCollection(model)) {
    return 'Recursive collection types are not supported for dynamic '
        'multipart values.';
  }
  var valueModel = model;
  var resolved = model.resolved;
  if (resolved is ListModel) {
    valueModel = resolved.content;
    resolved = valueModel.resolved;
    if (resolved is ListModel) {
      return 'Arrays of arrays are not supported for dynamic multipart values '
          '(${model.context}).';
    }
  }
  if (resolved is AnyModel) {
    return 'Untyped dynamic multipart values are not supported '
        '(${valueModel.context}).';
  }
  if (resolved is AliasModel || resolved is NeverModel) {
    return 'Unsupported dynamic multipart value ${resolved.runtimeType} '
        '(${valueModel.context}).';
  }
  return null;
}

bool _modelIsReadOnly(Model model, Set<Model> active) {
  if (!active.add(model)) return false;
  try {
    return switch (model) {
      AliasModel(:final isReadOnly, :final model) =>
        isReadOnly || _modelIsReadOnly(model, active),
      ClassModel(:final isReadOnly) ||
      ListModel(:final isReadOnly) ||
      MapModel(:final isReadOnly) ||
      EnumModel(:final isReadOnly) ||
      AllOfModel(:final isReadOnly) ||
      OneOfModel(:final isReadOnly) ||
      AnyOfModel(:final isReadOnly) => isReadOnly,
      _ => false,
    };
  } finally {
    active.remove(model);
  }
}

String _multipartMemberTypeName(
  Model model,
  NameManager? nameManager,
  String? package,
) {
  if (nameManager != null && package != null) {
    return typeReference(model, nameManager, package).symbol;
  }
  if (model case NamedModel(name: final name?)) return name;
  return model.context.path.isEmpty
      ? model.runtimeType.toString()
      : model.context.path.last;
}

String _uniqueMultipartHeaderParameterName(
  String baseName,
  Set<String> usedNames,
) {
  if (usedNames.add(baseName.toLowerCase())) return baseName;

  final suffixedBase = '${baseName}PartHeader';
  var candidate = suffixedBase;
  var counter = 2;
  while (!usedNames.add(candidate.toLowerCase())) {
    candidate = '$suffixedBase$counter';
    counter++;
  }
  return candidate;
}
