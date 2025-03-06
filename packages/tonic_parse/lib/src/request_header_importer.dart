import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart' as core;
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/parameter.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/serialization_style.dart';
import 'package:tonic_parse/src/model_importer.dart';

class RequestHeaderImporter {
  RequestHeaderImporter({
    required this.openApiObject,
    required this.modelImporter,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final log = Logger('HeaderImporter');

  late Set<core.RequestHeader> headers;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'parameters']);

  void import() {
    headers = {};
    final parameterMap = openApiObject.components?.parameters ?? {};

    for (final entry in parameterMap.entries) {
      final name = entry.key;
      final parameter = entry.value;

      // Skip non-header parameters
      if (parameter is InlinedObject<Parameter> &&
          parameter.object.location != ParameterLocation.header) {
        continue;
      }

      final imported = _importHeader(
        name: name,
        wrapper: parameter,
        context: rootContext.push(name),
      );
      headers.add(imported);
    }
  }

  core.RequestHeader importInlineHeader({
    required ReferenceWrapper<Parameter> wrapper,
    required core.Context context,
  }) {
    final header = _importHeader(
      name: null,
      wrapper: wrapper,
      context: context,
    );

    if (header is core.RequestHeaderObject) {
      headers.add(header);
    }

    return header is core.RequestHeaderAlias ? header.header : header;
  }

  core.RequestHeader _importHeader({
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

        // Check if we already imported this header
        final existing = headers.firstWhere(
          (h) =>
              (h is core.RequestHeaderAlias && h.name == refName) ||
              (h is core.RequestHeaderObject && h.name == refName),
          orElse: () => _importHeader(
            name: refName,
            wrapper: refParameter,
            context: context,
          ),
        );

        return core.RequestHeaderAlias(
          name: name ?? refName,
          header: existing,
          context: context,
        );

      case InlinedObject<Parameter>():
        final parameter = wrapper.object;

        if (parameter.schema == null) {
          throw ArgumentError(
            'Header ${name ?? context.path} must have a schema. '
            'Complex headers via content are not supported.',
          );
        }

        if (parameter.location != ParameterLocation.header) {
          throw ArgumentError(
            'Parameter ${name ?? context.path} must be a header parameter',
          );
        }

        final model = modelImporter.importSchema(parameter.schema!, context);

        return core.RequestHeaderObject(
          name: name,
          rawName: parameter.name,
          description: parameter.description,
          encoding: _getEncoding(parameter.style ?? SerializationStyle.simple),
          explode: parameter.explode ?? false,
          model: model,
          isRequired: parameter.isRequired ?? false,
          isDeprecated: parameter.isDeprecated ?? false,
          allowEmptyValue: parameter.allowEmptyValue ?? false,
          context: context,
        );
    }
  }

  core.ParameterEncoding _getEncoding(SerializationStyle style) {
    switch (style) {
      case SerializationStyle.matrix:
        return core.ParameterEncoding.matrix;
      case SerializationStyle.label:
        return core.ParameterEncoding.label;
      case SerializationStyle.simple:
        return core.ParameterEncoding.simple;
      case SerializationStyle.form:
        return core.ParameterEncoding.form;
      case SerializationStyle.spaceDelimited:
        return core.ParameterEncoding.spaceDelimited;
      case SerializationStyle.pipeDelimited:
        return core.ParameterEncoding.pipeDelimited;
      case SerializationStyle.deepObject:
        return core.ParameterEncoding.deepObject;
    }
  }
}
