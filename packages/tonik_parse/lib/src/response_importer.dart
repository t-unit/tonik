import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';

class ResponseImporter {
  ResponseImporter({
    required this.openApiObject,
    required this.modelImporter,
    required this.headerImporter,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final ResponseHeaderImporter headerImporter;
  final log = Logger('ResponseImporter');

  late Set<core.Response> responses;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'responses']);

  void import() {
    responses = {};
    final responseMap = openApiObject.components?.responses ?? {};

    for (final entry in responseMap.entries) {
      final name = entry.key;
      final response = entry.value;

      final imported = importResponse(
        name: name,
        wrapper: response,
        context: rootContext.push(name),
      );
      responses.add(imported);
    }
  }

  core.Response importResponse({
    required String? name,
    required ReferenceWrapper<Response> wrapper,
    required core.Context context,
  }) {
    switch (wrapper) {
      case Reference<Response>():
        if (!wrapper.ref.startsWith('#/components/responses/')) {
          throw UnimplementedError(
            'Only local response references are supported, '
            'found ${wrapper.ref}',
          );
        }

        final refName = wrapper.ref.split('/').last;
        final refResponse = openApiObject.components?.responses?[refName];

        if (refResponse == null) {
          throw ArgumentError('Response $refName not found');
        }

        return importResponse(
          name: refName,
          wrapper: refResponse,
          context: context,
        );

      case InlinedObject<Response>():
        final response = wrapper.object;
        final headers = <String, core.ResponseHeader>{};

        if (response.headers != null) {
          for (final entry in response.headers!.entries) {
            headers[entry.key] = headerImporter.importInlineHeader(
              wrapper: entry.value,
              context: context.push('header').push(entry.key),
            );
          }
        }

        core.ResponseBody? body;
        if (response.content != null) {
          final mediaTypes = response.content!;

          // Try to find application/json first
          var mediaType = mediaTypes.entries.firstWhereOrNull(
            (entry) => entry.key == 'application/json',
          );

          // If not found, look for any JSON-like content type
          mediaType ??= mediaTypes.entries.firstWhereOrNull(
            (entry) => entry.key.toLowerCase().contains('json'),
          );

          // If no json media type is found, use the first one
          if (mediaType == null) {
            log.warning('No JSON media type found for response $name');
            mediaType = mediaTypes.entries.firstOrNull;
          }

          if (mediaType?.value.schema != null) {
            final model = modelImporter.importSchema(
              mediaType!.value.schema!,
              context.push('content'),
            );
            body = core.ResponseBody(
              model: model,
              rawContentType: mediaType.key,
              contentType: core.ContentType.json,
            );
          } else if (mediaType != null) {
            log.warning(
              'No schema found for response $name. '
              'Ignoring response body for ${mediaType.key}',
            );
          }
        }

        return core.Response(
          name: name,
          description: response.description,
          headers: headers,
          body: body,
          context: context,
        );
    }
  }
}
