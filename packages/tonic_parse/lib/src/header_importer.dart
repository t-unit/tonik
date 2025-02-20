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

  late Set<core.Header> headers;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'headers']);

  void import() {
    final headerMap = openApiObject.components?.headers ?? {};

    headers = headerMap.entries
        .map(
          (entry) {
            final context = rootContext.push(entry.key);

            final value = entry.value;
            final (header, isReference) = switch (value) {
              Reference<Header>() => throw UnimplementedError(),
              InlinedObject<Header>() => (value.object, false),
            };

            if ((header.style ?? SerializationStyle.simple) !=
                SerializationStyle.simple) {
              log.warning(
                'Unsupported serialization style ${header.style} for header '
                '${entry.key}! Ignoring provided style.',
              );
            }

            final core.Model model;
            if (header.schema != null) {
              model = modelImporter.importSchema(header.schema!, context);
            } else {
              log.warning(
                'No schema provided for header ${entry.key}. '
                'Complex content via content property is ignored. '
                'Using string model instead.',
              );

              model = core.StringModel(context: context);
            }

            return core.Header(
              name: entry.key,
              description: header.description,
              explode: header.explode ?? false,
              model: model,
              isRequired: header.isRequired ?? false,
              isDeprecated: header.isDeprecated ?? false,
            );
          },
        )
        .whereType<core.Header>()
        .toSet();
  }
}
