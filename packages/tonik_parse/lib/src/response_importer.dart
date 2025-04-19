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

        final referencedResponse = importResponse(
          name: refName,
          wrapper: refResponse,
          context: context,
        );

        return core.ResponseAlias(
          name: name,
          response: referencedResponse,
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

        if (response.content != null) {
          final mediaTypes = response.content!;
          final bodies = <core.ResponseBody>[];

          // Process all JSON and JSON-like content types
          for (final entry in mediaTypes.entries) {
            final contentType = entry.key.toLowerCase();
            if (contentType.contains('json') && entry.value.schema != null) {
              final model = modelImporter.importSchema(
                entry.value.schema!,
                context.push('content'),
              );
              bodies.add(
                core.ResponseBody(
                  model: model,
                  rawContentType: entry.key,
                  contentType: core.ContentType.json,
                ),
              );
            }
          }

          if (bodies.isEmpty && mediaTypes.isNotEmpty) {
            log.warning('No schema found for response $name.');
          }

          return core.ResponseObject(
            name: name,
            description: response.description,
            headers: headers,
            bodies: bodies.toSet(),
            context: context,
          );
        }

        return core.ResponseObject(
          name: name,
          description: response.description,
          headers: headers,
          bodies: const {},
          context: context,
        );
    }
  }
}
