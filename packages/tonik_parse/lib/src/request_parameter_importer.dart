import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';
import 'package:tonik_parse/src/model_importer.dart';

class RequestParameterImporter({
  required final OpenApiObject openApiObject,
  required final ModelImporter modelImporter,
  required final ExampleImporter exampleImporter,
}) {
  final log = Logger('RequestParameterImporter');

  late Set<core.RequestHeader> headers;
  late Set<core.QueryParameter> queryParameters;
  late Set<core.PathParameter> pathParameters;
  late Set<core.CookieParameter> cookieParameters;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'parameters']);

  void import() {
    headers = {};
    queryParameters = {};
    pathParameters = {};
    cookieParameters = {};
    final parameterMap = openApiObject.components?.parameters ?? {};

    for (final entry in parameterMap.entries) {
      final name = entry.key;
      final parameter = entry.value;

      // Resolve chained aliases when used so unused cycles stay inert.
      if (parameter is Reference<Parameter> &&
          parameter.ref.startsWith('#/components/parameters/') &&
          parameterMap[parameter.ref.split('/').last] is Reference<Parameter>) {
        continue;
      }

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
      } else if (imported case final core.CookieParameter cookie) {
        cookieParameters.add(cookie);
      }
    }
  }

  (
    Set<core.RequestHeader> headers,
    Set<core.QueryParameter> queryParameters,
    Set<core.PathParameter> pathParameters,
    Set<core.CookieParameter> cookieParameters,
  )
  importOperationParameters(
    List<ReferenceWrapper<Parameter>> parameters,
    core.Context context,
  ) {
    final localHeaders = <core.RequestHeader>{};
    final localQueryParameters = <core.QueryParameter>{};
    final localPathParameters = <core.PathParameter>{};
    final localCookieParameters = <core.CookieParameter>{};

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
          localHeaders.add(header);
        }
      } else if (imported case final core.QueryParameter query) {
        if (query is core.QueryParameterObject) {
          queryParameters.add(query);
          localQueryParameters.add(query);
        } else if (query is core.QueryParameterAlias) {
          localQueryParameters.add(query);
        }
      } else if (imported case final core.PathParameter path) {
        if (path is core.PathParameterObject) {
          pathParameters.add(path);
          localPathParameters.add(path);
        } else if (path is core.PathParameterAlias) {
          localPathParameters.add(path);
        }
      } else if (imported case final core.CookieParameter cookie) {
        if (cookie is core.CookieParameterObject) {
          cookieParameters.add(cookie);
          localCookieParameters.add(cookie);
        } else if (cookie is core.CookieParameterAlias) {
          localCookieParameters.add(cookie);
        }
      }
    }

    return (
      localHeaders,
      localQueryParameters,
      localPathParameters,
      localCookieParameters,
    );
  }

  dynamic _importParameter({
    required String? name,
    required ReferenceWrapper<Parameter> wrapper,
    required core.Context context,
    Set<String>? visitedRefs,
  }) {
    switch (wrapper) {
      case Reference<Parameter>():
        if (!wrapper.ref.startsWith('#/components/parameters/')) {
          throw UnimplementedError(
            'Only local parameter references are supported, '
            'found ${wrapper.ref}',
          );
        }

        final seen = visitedRefs ?? <String>{};
        if (!seen.add(wrapper.ref)) {
          throw ArgumentError('Cyclic parameter reference: ${wrapper.ref}');
        }

        final refName = wrapper.ref.split('/').last;
        final refParameter = openApiObject.components?.parameters?[refName];

        if (refParameter == null) {
          throw ArgumentError('Parameter $refName not found');
        }

        final existing =
            _importedComponent(refName) ??
            _importParameter(
              name: refName,
              wrapper: refParameter,
              context: rootContext.push(refName),
              visitedRefs: seen,
            );
        return switch (existing) {
          final core.RequestHeader header => core.RequestHeaderAlias(
            name: name ?? refName,
            header: header,
            context: context,
            description: _referenceDescription(wrapper),
          ),
          final core.QueryParameter query => core.QueryParameterAlias(
            name: name ?? refName,
            parameter: query,
            context: context,
            description: _referenceDescription(wrapper),
          ),
          final core.PathParameter path => core.PathParameterAlias(
            name: name ?? refName,
            parameter: path,
            context: context,
            description: _referenceDescription(wrapper),
          ),
          final core.CookieParameter cookie => core.CookieParameterAlias(
            name: name ?? refName,
            parameter: cookie,
            context: context,
            description: _referenceDescription(wrapper),
          ),
          null => null,
          _ => throw StateError('Unexpected parameter reference target'),
        };

      case InlinedObject<Parameter>():
        final parameter = wrapper.object;

        if (_isReservedHeaderParameter(parameter)) {
          return null;
        }

        if (parameter.schema == null) {
          throw ArgumentError(
            'Parameter ${name ?? context.path} must have a schema. '
            'Complex parameters via content are not supported.',
          );
        }

        final model = modelImporter.importSchema(parameter.schema!, context);

        final rawDefault = parameter.schema!.rawDefault;

        switch (parameter.location) {
          case ParameterLocation.header:
            final header = core.RequestHeaderObject(
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
              examples: exampleImporter.fromParameter(parameter),
              defaultValue: rawDefault,
              nameOverride: null,
            );
            if (parameter.xDartName != null) {
              header.nameOverride = parameter.xDartName;
            }
            return header;

          case ParameterLocation.query:
            final queryParam = core.QueryParameterObject(
              name: name,
              rawName: parameter.name,
              description: parameter.description,
              encoding: _queryEncoding(parameter.style),
              explode:
                  parameter.explode ??
                  _defaultExplodeForQueryParameter(parameter.style),
              model: model,
              isRequired: parameter.isRequired ?? false,
              isDeprecated: parameter.isDeprecated ?? false,
              allowEmptyValue: parameter.allowEmptyValue ?? false,
              allowReserved: parameter.allowReserved ?? false,
              context: context,
              examples: exampleImporter.fromParameter(parameter),
              defaultValue: rawDefault,
              nameOverride: null,
            );
            if (parameter.xDartName != null) {
              queryParam.nameOverride = parameter.xDartName;
            }
            return queryParam;

          case ParameterLocation.path:
            final pathParam = core.PathParameterObject(
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
              examples: exampleImporter.fromParameter(parameter),
              defaultValue: rawDefault,
              nameOverride: null,
            );
            if (parameter.xDartName != null) {
              pathParam.nameOverride = parameter.xDartName;
            }
            return pathParam;

          case ParameterLocation.cookie:
            final cookieParam = core.CookieParameterObject(
              name: name,
              rawName: parameter.name,
              description: parameter.description,
              encoding: _cookieEncoding(parameter.style),
              explode: parameter.explode ?? true,
              model: model,
              isRequired: parameter.isRequired ?? false,
              isDeprecated: parameter.isDeprecated ?? false,
              context: context,
              examples: exampleImporter.fromParameter(parameter),
              defaultValue: rawDefault,
              nameOverride: null,
            );
            if (parameter.xDartName != null) {
              cookieParam.nameOverride = parameter.xDartName;
            }
            return cookieParam;
        }
    }
  }

  String? _referenceDescription(Reference<Parameter> reference) =>
      openApiObject.openapi.startsWith('3.0.') ? null : reference.description;

  Object? _importedComponent(String name) {
    for (final header in headers) {
      if (header case core.RequestHeaderAlias(name: final aliasName)) {
        if (aliasName == name) return header;
      } else if (header case core.RequestHeaderObject(name: final objectName)) {
        if (objectName == name) return header;
      }
    }
    for (final query in queryParameters) {
      if (query case core.QueryParameterAlias(name: final aliasName)) {
        if (aliasName == name) return query;
      } else if (query case core.QueryParameterObject(name: final objectName)) {
        if (objectName == name) return query;
      }
    }
    for (final path in pathParameters) {
      if (path case core.PathParameterAlias(name: final aliasName)) {
        if (aliasName == name) return path;
      } else if (path case core.PathParameterObject(name: final objectName)) {
        if (objectName == name) return path;
      }
    }
    for (final cookie in cookieParameters) {
      if (cookie case core.CookieParameterAlias(name: final aliasName)) {
        if (aliasName == name) return cookie;
      } else if (cookie case core.CookieParameterObject(
        name: final objectName,
      )) {
        if (objectName == name) return cookie;
      }
    }
    return null;
  }

  // OpenAPI reserves these headers for media types and security schemes.
  bool _isReservedHeaderParameter(Parameter parameter) =>
      parameter.location == ParameterLocation.header &&
      const {
        'accept',
        'content-type',
        'authorization',
      }.contains(parameter.name.toLowerCase());

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

  core.CookieParameterEncoding _cookieEncoding(SerializationStyle? style) {
    if (style != null && style != SerializationStyle.form) {
      throw ArgumentError(
        'Invalid encoding style for cookie parameter: $style. '
        'Cookie parameters only support "form" style.',
      );
    }
    return core.CookieParameterEncoding.form;
  }
}
