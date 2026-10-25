import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/local_json_pointer.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';
import 'package:tonik_parse/src/model_importer.dart';

class ResponseHeaderImporter({
  required final OpenApiObject openApiObject,
  required final ModelImporter modelImporter,
  required final ExampleImporter exampleImporter,
}) {
  final log = Logger('HeaderImporter');

  late Set<core.ResponseHeader> headers;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'headers']);

  void import() {
    headers = {};
    final headerMap = openApiObject.components?.headers ?? {};

    for (final entry in headerMap.entries) {
      final name = entry.key;
      final header = entry.value;

      _importComponent(name, header);
    }
  }

  core.ResponseHeader _importComponent(
    String name,
    ReferenceWrapper<Header> wrapper, {
    Set<String>? visitedRefs,
  }) {
    for (final header in headers) {
      if (header.name == name) return header;
    }
    final imported = _importHeader(
      name: name,
      wrapper: wrapper,
      context: rootContext.push(name),
      visitedRefs: visitedRefs,
    );
    headers.add(imported);
    return imported;
  }

  core.ResponseHeader importInlineHeader({
    required ReferenceWrapper<Header> wrapper,
    required core.Context context,
  }) {
    final header = _importHeader(
      name: null,
      wrapper: wrapper,
      context: context,
    );

    if (header is core.ResponseHeaderObject) {
      headers.add(header);
    }

    return header;
  }

  core.ResponseHeader _importHeader({
    required String? name,
    required ReferenceWrapper<Header> wrapper,
    required core.Context context,
    Set<String>? visitedRefs,
  }) {
    switch (wrapper) {
      case Reference<Header>():
        final pointer = LocalJsonPointer.parse(wrapper.ref);
        final refName = pointer.componentName('headers');
        if (refName == null) {
          throw UnimplementedError(
            'Only local header references are supported, found ${wrapper.ref}',
          );
        }

        final seen = visitedRefs ?? <String>{};
        if (!seen.add(pointer.reference)) {
          throw ArgumentError('Cyclic header reference: ${wrapper.ref}');
        }

        final refHeader = openApiObject.components?.headers?[refName];

        if (refHeader == null) {
          throw ArgumentError('Header $refName not found');
        }

        final existing = _importComponent(
          refName,
          refHeader,
          visitedRefs: seen,
        );

        return core.ResponseHeaderAlias(
          name: name,
          header: existing,
          context: context,
          description: openApiObject.openapi.startsWith('3.0.')
              ? null
              : wrapper.description,
        );

      case InlinedObject<Header>():
        final header = wrapper.object;

        if (header.schema == null && header.content == null) {
          throw ArgumentError(
            'Header ${name ?? context.path} must have either schema or content',
          );
        }

        if (header.schema != null &&
            (header.style ?? SerializationStyle.simple) !=
                SerializationStyle.simple) {
          throw ArgumentError(
            'Headers must have serialization style "simple".',
          );
        }

        final model = header.schema != null
            ? modelImporter.importSchema(header.schema!, context)
            : core.StringModel(context: context);

        if (header.schema == null) {
          log.warning(
            'Header $name has no schema, using string model. '
            'Advanced features via "content" are not supported.',
          );
        }
        return core.ResponseHeaderObject(
          name: name,
          description: header.description,
          explode: header.explode ?? false,
          model: model,
          isRequired: header.isRequired ?? false,
          isDeprecated: header.isDeprecated ?? false,
          encoding: core.ResponseHeaderEncoding.simple,
          context: context,
          examples: exampleImporter.fromHeader(header),
        );
    }
  }
}
