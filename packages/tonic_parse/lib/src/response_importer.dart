import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart' as core;
import 'package:tonic_parse/src/header_importer.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/response.dart';
import 'package:tonic_parse/src/model_importer.dart';

class ResponseImporter {
  ResponseImporter({
    required this.openApiObject,
    required this.modelImporter,
    required this.headerImporter,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final HeaderImporter headerImporter;
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

      final imported = _importResponse(
        name: name,
        wrapper: response,
        context: rootContext.push(name),
      );
      responses.add(imported);
    }
  }

  core.Response _importResponse({
    required String name,
    required ReferenceWrapper<Response> wrapper,
    required core.Context context,
  }) {
    switch (wrapper) {
      case Reference<Response>():
        if (!wrapper.ref.startsWith('#/components/responses/')) {
          throw UnimplementedError(
            'Only local response references are supported, found ${wrapper.ref}',
          );
        }

        final refName = wrapper.ref.split('/').last;
        final refResponse = openApiObject.components?.responses?[refName];

        if (refResponse == null) {
          throw ArgumentError('Response $refName not found');
        }

        return _importResponse(
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
              context: context.push('headers').push(entry.key),
            );
          }
        }

        core.Model? body;
        if (response.content != null) {
          final mediaTypes = response.content!;

          // Try to find application/json first
          var mediaType = mediaTypes['application/json'];

          // If not found, look for any JSON-like content type
          mediaType ??= mediaTypes.entries
              .firstWhereOrNull(
                (entry) => entry.key.toLowerCase().contains('json'),
              )
              ?.value;

          // If no json media type is found, use the first one
          if (mediaType == null) {
            log.warning('No JSON media type found for response $name');
            mediaType = mediaTypes.entries.firstOrNull?.value;
          }

          if (mediaType?.schema != null) {
            body = modelImporter.importSchema(
              mediaType!.schema!,
              context.push('content'),
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
