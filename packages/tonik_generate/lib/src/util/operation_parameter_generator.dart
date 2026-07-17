import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/to_multipart_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generates the `call()` parameters for an operation.
///
/// When [defaultsByName] is supplied, named parameters become optional and
/// receive `defaultTo` references — qualified for call sites outside the
/// owning class so the import allocator resolves them.
List<Parameter> generateParameters({
  required Operation operation,
  required NameManager nameManager,
  required String package,
  Map<String, OperationParameterDefault> defaultsByName = const {},
}) {
  final hasRequestBody =
      operation.requestBody?.resolvedContent.isNotEmpty ?? false;
  final parameters = <Parameter>[];

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
                nameManager,
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

  final normalizedParams = normalizeRequestParameters(
    pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
    queryParameters: operation.queryParameters.map((p) => p.resolve()).toSet(),
    headers: operation.headers.map((p) => p.resolve()).toSet(),
    cookieParameters: operation.cookieParameters
        .map((p) => p.resolve())
        .toSet(),
    reservedNames: operationReservedParameterNames(
      hasRequestBody: hasRequestBody,
    ),
  );

  for (final pathParam in normalizedParams.pathParameters) {
    final defaulted = defaultsByName[pathParam.normalizedName];
    final wiresDefaultTo = defaulted != null && !defaulted.isRuntime;
    final parameterType = typeReference(
      pathParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !pathParam.parameter.isRequired && !wiresDefaultTo,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = pathParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = !wiresDefaultTo && pathParam.parameter.isRequired
            ..defaultTo = wiresDefaultTo ? defaulted.defaultToCode() : null;

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

  for (final queryParam in normalizedParams.queryParameters) {
    final defaulted = defaultsByName[queryParam.normalizedName];
    final wiresDefaultTo = defaulted != null && !defaulted.isRuntime;
    final parameterType = typeReference(
      queryParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !queryParam.parameter.isRequired && !wiresDefaultTo,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = queryParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = !wiresDefaultTo && queryParam.parameter.isRequired
            ..defaultTo = wiresDefaultTo ? defaulted.defaultToCode() : null;

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

  for (final headerParam in normalizedParams.headers) {
    final defaulted = defaultsByName[headerParam.normalizedName];
    final wiresDefaultTo = defaulted != null && !defaulted.isRuntime;
    final parameterType = typeReference(
      headerParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !headerParam.parameter.isRequired && !wiresDefaultTo,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = headerParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = !wiresDefaultTo && headerParam.parameter.isRequired
            ..defaultTo = wiresDefaultTo ? defaulted.defaultToCode() : null;

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

  for (final cookieParam in normalizedParams.cookieParameters) {
    final defaulted = defaultsByName[cookieParam.normalizedName];
    final wiresDefaultTo = defaulted != null && !defaulted.isRuntime;
    final parameterType = typeReference(
      cookieParam.parameter.model,
      nameManager,
      package,
      isNullableOverride: !cookieParam.parameter.isRequired && !wiresDefaultTo,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = cookieParam.normalizedName
            ..type = parameterType
            ..named = true
            ..required = !wiresDefaultTo && cookieParam.parameter.isRequired
            ..defaultTo = wiresDefaultTo ? defaulted.defaultToCode() : null;

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
  // Multipart header parameters come last so names can be deduplicated.
  if (hasRequestBody) {
    _addMultipartHeaderParameters(
      parameters: parameters,
      operation: operation,
      nameManager: nameManager,
      package: package,
    );
  }
  return parameters;
}

void _addMultipartHeaderParameters({
  required List<Parameter> parameters,
  required Operation operation,
  required NameManager nameManager,
  required String package,
}) {
  for (final info in extractOperationMultipartHeaderParamInfo(operation)) {
    final parameterType = typeReference(
      info.model,
      nameManager,
      package,
      isNullableOverride: !info.isRequired,
    );

    parameters.add(
      Parameter(
        (b) {
          b
            ..name = info.name
            ..type = parameterType
            ..named = true
            ..required = info.isRequired;

          if (info.isDeprecated) {
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
