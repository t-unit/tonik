import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model_importer.dart';

class RequestBodyImporter {
  RequestBodyImporter({
    required this.openApiObject,
    required this.modelImporter,
    required this.contentTypes,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final log = Logger('RequestBodyImporter');

  final Map<String, core.ContentType> contentTypes;

  late Set<core.RequestBody> requestBodies;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'requestBodies']);

  void import() {
    requestBodies = {};
    final requestBodyMap = openApiObject.components?.requestBodies ?? {};

    for (final entry in requestBodyMap.entries) {
      final name = entry.key;
      final requestBody = entry.value;

      importRequestBody(
        name: name,
        wrapper: requestBody,
        context: rootContext.push(name),
      );
    }
  }

  core.RequestBody importRequestBody({
    required String? name,
    required ReferenceWrapper<RequestBody> wrapper,
    required core.Context context,
  }) {
    // Check if we already have a request body with this name
    if (name != null) {
      final existing = requestBodies
          .where((body) => body.name == name)
          .firstOrNull;
      if (existing != null) {
        return existing;
      }
    }

    switch (wrapper) {
      case Reference<RequestBody>():
        if (!wrapper.ref.startsWith('#/components/requestBodies/')) {
          throw UnimplementedError(
            'Only local request body references are supported, '
            'found ${wrapper.ref}',
          );
        }

        final refName = wrapper.ref.split('/').last;
        final refRequestBody =
            openApiObject.components?.requestBodies?[refName];

        if (refRequestBody == null) {
          throw ArgumentError('Request body $refName not found');
        }

        final importedBody = importRequestBody(
          name: refName,
          wrapper: refRequestBody,
          context: context,
        );
        if (name != null) {
          final alias = core.RequestBodyAlias(
            name: name,
            requestBody: importedBody,
            context: context,
          );
          requestBodies.add(alias);
          return alias;
        } else {
          return importedBody;
        }

      case InlinedObject<RequestBody>():
        final requestBody = wrapper.object;
        final content = <core.RequestContent>{};

        for (final entry in requestBody.content.entries) {
          final rawContentType = entry.key;
          final mediaType = entry.value;
          final contentType = resolveContentType(
            rawContentType,
            contentTypes: contentTypes,
            log: log,
          );

          if (mediaType.schema != null) {
            final model = modelImporter.importSchema(
              mediaType.schema!,
              context.push('body'),
            );

            content.add(
              core.RequestContent(
                model: model,
                rawContentType: rawContentType,
                contentType: contentType,
              ),
            );
          } else {
            log.warning(
              'No schema found for request body $name. '
              'Ignoring request body content for $rawContentType',
            );
          }
        }

        final bodyObject = core.RequestBodyObject(
          name: name,
          context: context,
          description: requestBody.description,
          isRequired: requestBody.isRequired ?? false,
          content: content,
        );
        requestBodies.add(bodyObject);
        return bodyObject;
    }
  }
}
