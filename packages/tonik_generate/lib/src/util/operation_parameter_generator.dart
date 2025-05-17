import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
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
    final parameterType =
        requestBody.contentCount == 1
            ? typeReference(
              requestBody.resolvedContent.first.model,
              nameManager,
              package,
              isNullableOverride: !requestBody.isRequired,
            )
            : TypeReference(
              (b) =>
                  b
                    ..symbol = nameManager.requestBodyNames(requestBody).$1
                    ..url = package
                    ..isNullable = !requestBody.isRequired,
            );

    parameters.add(
      Parameter(
        (b) =>
            b
              ..name = 'body'
              ..type = parameterType
              ..named = true
              ..required = requestBody.isRequired,
      ),
    );
  }

  // Normalize all parameter names
  final normalizedParams = normalizeRequestParameters(
    pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
    queryParameters: operation.queryParameters.map((p) => p.resolve()).toSet(),
    headers: operation.headers.map((p) => p.resolve()).toSet(),
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
        (b) =>
            b
              ..name = pathParam.normalizedName
              ..type = parameterType
              ..named = true
              ..required = pathParam.parameter.isRequired,
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
        (b) =>
            b
              ..name = queryParam.normalizedName
              ..type = parameterType
              ..named = true
              ..required = queryParam.parameter.isRequired,
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
        (b) =>
            b
              ..name = headerParam.normalizedName
              ..type = parameterType
              ..named = true
              ..required = headerParam.parameter.isRequired,
      ),
    );
  }

  return parameters;
}
