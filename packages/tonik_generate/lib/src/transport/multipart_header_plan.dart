import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';

typedef MultipartHeaderParamInfo = ({
  RequestContent content,
  String name,
  String normalizedPropertyName,
  String rawHeaderName,
  Model model,
  bool isRequired,
  bool isDeprecated,
});

List<MultipartHeaderParamInfo> extractMultipartHeaderParamInfo(
  RequestContent content, {
  Set<String> reservedNames = const {},
}) {
  final encoding = content.multipartEncoding;
  if (encoding == null) return const [];

  final model = content.model.resolved;
  if (model is! ClassModel) return const [];

  final writeProperties = model.properties.where((p) => !p.isReadOnly).toList();
  final normalizedProps = normalizeProperties(writeProperties);

  final result = <MultipartHeaderParamInfo>[];
  final usedNames = reservedNames.map((name) => name.toLowerCase()).toSet();

  for (final (:normalizedName, :property) in normalizedProps) {
    final propertyEncoding = encoding[property];
    final headers = propertyEncoding?.headers;
    if (headers == null || headers.isEmpty) continue;

    final isPropertyOptional = !property.isRequired || property.isNullable;

    for (final entry in headers.entries) {
      final rawHeaderName = entry.key;
      final header = entry.value.resolve(name: rawHeaderName);
      final isRequired = !isPropertyOptional && header.isRequired;

      final baseName = normalizeMultipartHeaderName(
        normalizedName,
        rawHeaderName,
      );
      final paramName = _uniqueMultipartHeaderParameterName(
        baseName,
        usedNames,
      );

      result.add((
        content: content,
        name: paramName,
        normalizedPropertyName: normalizedName,
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
  Operation operation,
) {
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
    if (content.contentType != ContentType.multipart) continue;
    final parameters = extractMultipartHeaderParamInfo(
      content,
      reservedNames: usedNames,
    );
    result.addAll(parameters);
    usedNames.addAll(parameters.map((parameter) => parameter.name));
  }

  return result;
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
