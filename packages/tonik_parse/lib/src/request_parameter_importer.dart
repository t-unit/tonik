import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';
import 'package:tonik_parse/src/model_importer.dart';

class RequestParameterImporter {
  RequestParameterImporter({
    required this.openApiObject,
    required this.modelImporter,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final log = Logger('RequestParameterImporter');

  late Set<core.RequestHeader> headers;
  late Set<core.QueryParameter> queryParameters;
  late Set<core.PathParameter> pathParameters;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'parameters']);

  void import() {
    headers = {};
    queryParameters = {};
    pathParameters = {};
    final parameterMap = openApiObject.components?.parameters ?? {};

    for (final entry in parameterMap.entries) {
      final name = entry.key;
      final parameter = entry.value;

      final imported = _importParameter(
        name: name,
        wrapper: parameter,
        context: rootContext.push(name),
      );

      if (imported case final core.RequestHeader header) {
        headers.add(header);
      } else if (imported case final core.QueryParameter query) {
        queryParameters.add(query);
      } else if (imported case final core.PathParameter path) {
        pathParameters.add(path);
      }
    }
  }

  (
    Set<core.RequestHeader> headers,
    Set<core.QueryParameter> queryParameters,
    Set<core.PathParameter> pathParameters,
  )
  importOperationParameters(
    List<ReferenceWrapper<Parameter>> parameters,
    core.Context context,
  ) {
    final localHeaders = <core.RequestHeader>{};
    final localQueryParameters = <core.QueryParameter>{};
    final localPathParameters = <core.PathParameter>{};

    for (final wrapper in parameters) {
      final imported = _importParameter(
        name: null,
        wrapper: wrapper,
        context: context,
      );

      if (imported case final core.RequestHeader header) {
        if (header is core.RequestHeaderObject) {
          headers.add(header);
          localHeaders.add(header);
        } else if (header is core.RequestHeaderAlias) {
          localHeaders.add(header.header);
        }
      } else if (imported case final core.QueryParameter query) {
        if (query is core.QueryParameterObject) {
          queryParameters.add(query);
          localQueryParameters.add(query);
        } else if (query is core.QueryParameterAlias) {
          localQueryParameters.add(query.parameter);
        }
      } else if (imported case final core.PathParameter path) {
        if (path is core.PathParameterObject) {
          pathParameters.add(path);
          localPathParameters.add(path);
        } else if (path is core.PathParameterAlias) {
          localPathParameters.add(path.parameter);
        }
      }
    }

    return (localHeaders, localQueryParameters, localPathParameters);
  }

  dynamic _importParameter({
    required String? name,
    required ReferenceWrapper<Parameter> wrapper,
    required core.Context context,
  }) {
    switch (wrapper) {
      case Reference<Parameter>():
        if (!wrapper.ref.startsWith('#/components/parameters/')) {
          throw UnimplementedError(
            'Only local parameter references are supported, '
            'found ${wrapper.ref}',
          );
        }

        final refName = wrapper.ref.split('/').last;
        final refParameter = openApiObject.components?.parameters?[refName];

        if (refParameter == null) {
          throw ArgumentError('Parameter $refName not found');
        }

        if (refParameter is InlinedObject<Parameter>) {
          switch (refParameter.object.location) {
            case ParameterLocation.header:
              // Check if we already imported this header.
              final existing = headers.firstWhere(
                (h) =>
                    (h is core.RequestHeaderAlias && h.name == refName) ||
                    (h is core.RequestHeaderObject && h.name == refName),
                orElse:
                    () =>
                        _importParameter(
                              name: refName,
                              wrapper: refParameter,
                              context: context,
                            )
                            as core.RequestHeader,
              );

              return core.RequestHeaderAlias(
                name: name ?? refName,
                header: existing,
                context: context,
              );

            case ParameterLocation.query:
              // Check if we already imported this query parameter.
              final existing = queryParameters.firstWhere(
                (q) =>
                    (q is core.QueryParameterAlias && q.name == refName) ||
                    (q is core.QueryParameterObject && q.name == refName),
                orElse:
                    () =>
                        _importParameter(
                              name: refName,
                              wrapper: refParameter,
                              context: context,
                            )
                            as core.QueryParameter,
              );

              return core.QueryParameterAlias(
                name: name ?? refName,
                parameter: existing,
                context: context,
              );

            case ParameterLocation.path:
              // Check if we already imported this path parameter.
              final existing = pathParameters.firstWhere(
                (p) =>
                    (p is core.PathParameterAlias && p.name == refName) ||
                    (p is core.PathParameterObject && p.name == refName),
                orElse:
                    () =>
                        _importParameter(
                              name: refName,
                              wrapper: refParameter,
                              context: context,
                            )
                            as core.PathParameter,
              );

              return core.PathParameterAlias(
                name: name ?? refName,
                parameter: existing,
                context: context,
              );

            case ParameterLocation.cookie:
              log.warning(
                'Cookie parameters are not supported: $name. '
                'Ignoring this parameter!',
              );
              return null;
          }
        }

      case InlinedObject<Parameter>():
        final parameter = wrapper.object;

        if (parameter.schema == null) {
          throw ArgumentError(
            'Parameter ${name ?? context.path} must have a schema. '
            'Complex parameters via content are not supported.',
          );
        }

        final model = modelImporter.importSchema(parameter.schema!, context);

        switch (parameter.location) {
          case ParameterLocation.header:
            return core.RequestHeaderObject(
              name: name,
              rawName: parameter.name,
              description: parameter.description,
              encoding: _headerEncoding(parameter.style),
              explode: parameter.explode ?? false,
              model: model,
              isRequired: parameter.isRequired ?? false,
              isDeprecated: parameter.isDeprecated ?? false,
              allowEmptyValue: parameter.allowEmptyValue ?? false,
              context: context,
            );

          case ParameterLocation.query:
            return core.QueryParameterObject(
              name: name,
              rawName: parameter.name,
              description: parameter.description,
              encoding: _queryEncoding(parameter.style),
              explode: parameter.explode ??
                  _defaultExplodeForQueryParameter(parameter.style),
              model: model,
              isRequired: parameter.isRequired ?? false,
              isDeprecated: parameter.isDeprecated ?? false,
              allowEmptyValue: parameter.allowEmptyValue ?? false,
              allowReserved: parameter.allowReserved ?? false,
              context: context,
            );

          case ParameterLocation.path:
            return core.PathParameterObject(
              name: name,
              rawName: parameter.name,
              description: parameter.description,
              encoding: _pathEncoding(parameter.style),
              explode: parameter.explode ?? false,
              model: model,
              isRequired: parameter.isRequired ?? false,
              isDeprecated: parameter.isDeprecated ?? false,
              allowEmptyValue: parameter.allowEmptyValue ?? false,
              context: context,
            );

          case ParameterLocation.cookie:
            log.warning(
              'Cookie parameters are not supported: $name. '
              'Ignoring this parameter',
            );
            return null;
        }
    }
  }

  core.HeaderParameterEncoding _headerEncoding(SerializationStyle? style) {
    if (style != null && style != SerializationStyle.simple) {
      throw ArgumentError(
        'Invalid encoding style for header parameter: $style. '
        'Header parameters only support "simple" style.',
      );
    }
    return core.HeaderParameterEncoding.simple;
  }

  core.QueryParameterEncoding _queryEncoding(SerializationStyle? style) {
    switch (style) {
      case SerializationStyle.form || null:
        return core.QueryParameterEncoding.form;
      case SerializationStyle.spaceDelimited:
        return core.QueryParameterEncoding.spaceDelimited;
      case SerializationStyle.pipeDelimited:
        return core.QueryParameterEncoding.pipeDelimited;
      case SerializationStyle.deepObject:
        return core.QueryParameterEncoding.deepObject;
      case SerializationStyle.simple:
      case SerializationStyle.label:
      case SerializationStyle.matrix:
        throw ArgumentError(
          'Invalid encoding style for query parameter: $style. '
          'Supported styles are: form, spaceDelimited, '
          'pipeDelimited, deepObject.',
        );
    }
  }

  bool _defaultExplodeForQueryParameter(SerializationStyle? style) {
    return style == SerializationStyle.form || style == null;
  }

  core.PathParameterEncoding _pathEncoding(SerializationStyle? style) {
    switch (style) {
      case SerializationStyle.simple || null:
        return core.PathParameterEncoding.simple;
      case SerializationStyle.label:
        return core.PathParameterEncoding.label;
      case SerializationStyle.matrix:
        return core.PathParameterEncoding.matrix;
      case SerializationStyle.form:
      case SerializationStyle.spaceDelimited:
      case SerializationStyle.pipeDelimited:
      case SerializationStyle.deepObject:
        throw ArgumentError(
          'Invalid encoding style for path parameter: $style. '
          'Supported styles are: simple, label, matrix.',
        );
    }
  }
}
