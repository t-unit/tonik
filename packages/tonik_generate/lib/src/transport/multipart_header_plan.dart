import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
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
  MultipartPropertyNormalizationResult? normalization,
}) {
  normalization ??= normalizeMultipartProperties(
    content,
    nameManager: nameManager,
    package: package,
  );
  final result = <MultipartHeaderParamInfo>[];
  final usedNames = reservedNames.map((name) => name.toLowerCase()).toSet();

  for (final property in normalization.properties) {
    final headers = property.part.encoding.headers;
    if (headers == null || headers.isEmpty) continue;

    final isPropertyOptional =
        !property.part.isRequired || property.part.isNullable;

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
  Map<MultipartRequestContent, MultipartPropertyNormalizationResult>?
  normalizations,
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
      normalization: normalizations?[content],
    );
    result.addAll(parameters);
    usedNames.addAll(parameters.map((parameter) => parameter.name));
  }

  return result;
}

class const MultipartPropertyPlan({
  required final NamedMultipartPart part,
  required final String normalizedName,
  required final List<List<MultipartAccessSegment>> accessPaths,
});

typedef MultipartAccessSegment = ({String name, bool receiverNullable});

final class const MultipartDynamicSource({
  required final MultipartAdditionalFields additionalFields,
  required final List<MultipartAccessSegment> accessPath,
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
  final layout = content.layout;
  final uniqueNames = ensureUniqueness([
    for (final part in layout.fields)
      (
        normalizedName: normalizeSingle(
          part.sources.first.property.nameOverride ?? part.wireName,
          preserveNumbers: true,
        ),
        originalValue: part,
      ),
  ], defaultPrefix: defaultFieldPrefix);
  final additional = layout.additionalFields;
  MultipartDynamicSource? dynamicSource;
  if (additional != null) {
    final resolved = content.model.resolved;
    final normalizedProperties = resolved is ClassModel
        ? normalizeProperties(resolved.properties)
        : const <({String normalizedName, Property property})>[];
    final accessPath = resolved is ClassModel
        ? [
            (
              name:
                  (nameManager ??
                          NameManager(
                            generator: NameGenerator(),
                            stableModelSorter: StableModelSorter(),
                          ))
                      .additionalPropertiesFieldName(normalizedProperties),
              receiverNullable: additional.receiverNullable,
            ),
          ]
        : <MultipartAccessSegment>[];
    dynamicSource = MultipartDynamicSource(
      additionalFields: additional,
      accessPath: accessPath,
    );
  }
  return MultipartPropertyNormalizationResult(
    runtimeEncodingError: layout.runtimeEncodingError,
    dynamicSource: dynamicSource,
    properties: [
      for (final item in uniqueNames)
        MultipartPropertyPlan(
          part: item.originalValue,
          normalizedName: item.normalizedName,
          accessPaths: [
            for (final source in item.originalValue.sources)
              _accessPath(content.model, source, nameManager, package),
          ],
        ),
    ],
  );
}

List<MultipartAccessSegment> _accessPath(
  Model root,
  MultipartPartSource source,
  NameManager? nameManager,
  String? package,
) {
  final path = <MultipartAccessSegment>[];
  var current = root;
  var receiverNullable = multipartModelIsNullable(current);
  for (final member in source.members) {
    final resolved = current.resolved;
    if (resolved is! AllOfModel) {
      throw StateError('Multipart source is not aligned with its model.');
    }
    final namedMembers = ensureUniqueness([
      for (final candidate in resolved.models)
        (
          normalizedName: normalizeSingle(
            _multipartMemberTypeName(candidate, nameManager, package),
            preserveNumbers: true,
          ),
          originalValue: candidate,
        ),
    ], defaultPrefix: defaultFieldPrefix);
    final named = namedMembers[member.index];
    if (!identical(named.originalValue, member.model)) {
      throw StateError('Multipart source is not aligned with its model.');
    }
    path.add((name: named.normalizedName, receiverNullable: receiverNullable));
    current = member.model;
    receiverNullable =
        receiverNullable || multipartModelIsNullable(member.model);
  }
  final resolved = current.resolved;
  if (resolved is! ClassModel) {
    throw StateError('Multipart source property has no class model.');
  }
  final property = normalizeProperties(
    resolved.properties,
  ).firstWhere((candidate) => identical(candidate.property, source.property));
  path.add((name: property.normalizedName, receiverNullable: receiverNullable));
  return path;
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
