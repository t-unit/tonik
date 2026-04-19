import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generates parameters for an operation
List<Parameter> generateParameters({
  required Operation operation,
  required NameManager nameManager,
  required String package,
}) {
  final hasRequestBody =
      operation.requestBody?.resolvedContent.isNotEmpty ?? false;
  final parameters = <Parameter>[];

  // Add request body parameter if present
  if (hasRequestBody) {
    final requestBody = operation.requestBody!;
    final parameterType = requestBody.contentCount == 1
        ? typeReference(
            requestBody.resolvedContent.first.model,
            nameManager,
            package,
            isNullableOverride: !requestBody.isRequired,
          )
        : TypeReference(
            (b) => b
              ..symbol = nameManager.requestBodyNames(requestBody).$1
              ..url = sourceFileUrl(
                package,
                'request_body',
                nameManager.requestBodyNames(requestBody).$1,
              )
              ..isNullable = !requestBody.isRequired,
          );

    parameters.add(
      Parameter(
        (b) => b
          ..name = 'body'
          ..type = parameterType
          ..named = true
          ..required = requestBody.isRequired,
      ),
    );
  }

  // Normalize all parameter names, reserving 'body' when a request body
  // exists so that any parameter named 'body' gets a type suffix.
  final normalizedParams = normalizeRequestParameters(
    pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
    queryParameters: operation.queryParameters.map((p) => p.resolve()).toSet(),
    headers: operation.headers.map((p) => p.resolve()).toSet(),
    cookieParameters: operation.cookieParameters
        .map((p) => p.resolve())
        .toSet(),
    reservedNames: hasRequestBody ? {'body'} : {},
  );

  // Add path parameters
  for (final pathParam in normalizedParams.pathParameters) {
    final parameterType = typeReference(
      pathParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !pathParam.parameter.isRequired,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = pathParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = pathParam.parameter.isRequired;

          if (pathParam.parameter.isDeprecated) {
            b.annotations.add(
              refer('Deprecated', 'dart:core').call([
                literalString('This parameter is deprecated.'),
              ]),
            );
          }
        },
      ),
    );
  }

  // Add query parameters
  for (final queryParam in normalizedParams.queryParameters) {
    final parameterType = typeReference(
      queryParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !queryParam.parameter.isRequired,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = queryParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = queryParam.parameter.isRequired;

          if (queryParam.parameter.isDeprecated) {
            b.annotations.add(
              refer('Deprecated', 'dart:core').call([
                literalString('This parameter is deprecated.'),
              ]),
            );
          }
        },
      ),
    );
  }

  // Add header parameters
  for (final headerParam in normalizedParams.headers) {
    final parameterType = typeReference(
      headerParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !headerParam.parameter.isRequired,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = headerParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = headerParam.parameter.isRequired;

          if (headerParam.parameter.isDeprecated) {
            b.annotations.add(
              refer('Deprecated', 'dart:core').call([
                literalString('This parameter is deprecated.'),
              ]),
            );
          }
        },
      ),
    );
  }

  // Add cookie parameters
  for (final cookieParam in normalizedParams.cookieParameters) {
    final parameterType = typeReference(
      cookieParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !cookieParam.parameter.isRequired,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = cookieParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = cookieParam.parameter.isRequired;

          if (cookieParam.parameter.isDeprecated) {
            b.annotations.add(
              refer('Deprecated', 'dart:core').call([
                literalString('This parameter is deprecated.'),
              ]),
            );
          }
        },
      ),
    );
  }
  // Add multipart header parameters last so names can be
  // deduplicated against all already-added parameters.
  if (hasRequestBody) {
    _addMultipartHeaderParameters(
      parameters: parameters,
      requestBody: operation.requestBody!,
      nameManager: nameManager,
      package: package,
    );
  }
  return parameters;
}

/// Adds per-part header parameters for multipart request bodies.
///
/// Per OAS spec, `encoding.headers` defines per-part MIME headers. Each header
/// becomes a method parameter so callers can provide header values at runtime.
///
/// Names are deduplicated against already-added parameters by appending
/// a `PartHeader` suffix when a collision is detected.
void _addMultipartHeaderParameters({
  required List<Parameter> parameters,
  required RequestBody requestBody,
  required NameManager nameManager,
  required String package,
}) {
  // Collect existing parameter names for deduplication.
  final usedNames = <String>{
    for (final p in parameters) p.name.toLowerCase(),
  };

  for (final content in requestBody.resolvedContent) {
    if (content.contentType != ContentType.multipart) continue;

    final encoding = content.encoding;
    if (encoding == null) continue;

    // Resolve the model to get properties.
    final model = content.model.resolved;
    if (model is! ClassModel) continue;

    final writeProperties = model.properties
        .where((p) => !p.isReadOnly)
        .toList();
    final normalizedProps = normalizeProperties(writeProperties);

    for (final (:normalizedName, :property) in normalizedProps) {
      final propertyEncoding = encoding[property.name];
      final headers = propertyEncoding?.headers;
      if (headers == null || headers.isEmpty) continue;

      final isPropertyOptional = !property.isRequired || property.isNullable;

      for (final entry in headers.entries) {
        final rawHeaderName = entry.key;
        final header = entry.value;

        final resolved = header.resolve(name: rawHeaderName);

        // Parameter is required only if both property and header are required.
        final isRequired = !isPropertyOptional && resolved.isRequired;

        final parameterType = typeReference(
          resolved.model,
          nameManager,
          package,
          isNullableOverride: !isRequired,
        );

        final paramName = normalizeMultipartHeaderName(
          normalizedName,
          rawHeaderName,
        );

        // Deduplicate against existing parameter names.
        final uniqueName = usedNames.contains(paramName.toLowerCase())
            ? '${paramName}PartHeader'
            : paramName;
        usedNames.add(uniqueName.toLowerCase());

        parameters.add(
          Parameter(
            (b) {
              b
                ..name = uniqueName
                ..type = parameterType
                ..named = true
                ..required = isRequired;

              if (resolved.isDeprecated) {
                b.annotations.add(
                  refer('Deprecated', 'dart:core').call([
                    literalString('This parameter is deprecated.'),
                  ]),
                );
              }
            },
          ),
        );
      }
    }
  }
}
