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

      final imported = _importHeader(name, header);
      headers.add(imported);
    }
  }

  core.ResponseHeader _importHeader(
      String name, ReferenceWrapper<Header> wrapper) {
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
          orElse: () => _importHeader(refName, refHeader),
        );

        return core.ResponseHeaderAlias(name: name, header: existing);

      case InlinedObject<Header>():
        final header = wrapper.object;

        if (header.schema == null && header.content == null) {
          throw ArgumentError(
            'Header $name must have either schema or content',
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
            ? modelImporter.importSchema(header.schema!, rootContext.push(name))
            : core.StringModel(context: rootContext.push(name));

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
        );
    }
  }
}
