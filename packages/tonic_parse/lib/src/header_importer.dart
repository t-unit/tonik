import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart' as core;
import 'package:tonic_parse/src/model/header.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/serialization_style.dart';
import 'package:tonic_parse/src/model_importer.dart';

class HeaderImporter {
  HeaderImporter({required this.openApiObject, required this.modelImporter});

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
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

      final imported = _importHeader(
        name: name,
        wrapper: header,
        context: rootContext.push(name),
      );
      headers.add(imported);
    }
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

    return header is core.ResponseHeaderAlias ? header.header : header;
  }

  core.ResponseHeader _importHeader({
    required String? name,
    required ReferenceWrapper<Header> wrapper,
    required core.Context context,
  }) {
    switch (wrapper) {
      case Reference<Header>():
        if (!wrapper.ref.startsWith('#/components/headers/')) {
          throw UnimplementedError(
            'Only local header references are supported, found ${wrapper.ref}',
          );
        }

        final refName = wrapper.ref.split('/').last;
        final refHeader = openApiObject.components?.headers?[refName];

        if (refHeader == null) {
          throw ArgumentError('Header $refName not found');
        }

        // Check if we already imported this header
        final existing = headers.firstWhere(
          (h) => h.name == refName,
          orElse: () => _importHeader(
            name: refName,
            wrapper: refHeader,
            context: context,
          ),
        );

        return core.ResponseHeaderAlias(
          name: name,
          header: existing,
          context: context,
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
          context: context,
        );
    }
  }
}
