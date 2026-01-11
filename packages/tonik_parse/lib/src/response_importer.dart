import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
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
    this.contentTypes = const {},
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final ResponseHeaderImporter headerImporter;
  final log = Logger('ResponseImporter');

  final Map<String, core.ContentType> contentTypes;

  late Set<core.Response> responses;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'responses']);

  void import() {
    responses = {};
    final responseMap = openApiObject.components?.responses ?? {};

    for (final entry in responseMap.entries) {
      final name = entry.key;
      final response = entry.value;

      importResponse(
        name: name,
        wrapper: response,
        context: rootContext.push(name),
      );
    }
  }

  core.Response importResponse({
    required String? name,
    required ReferenceWrapper<Response> wrapper,
    required core.Context context,
  }) {
    // Check if we already have a response with this name
    if (name != null) {
      final existing = responses
          .where((response) => response.name == name)
          .firstOrNull;
      if (existing != null) {
        return existing;
      }
    }

    core.Response response;
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

        response = core.ResponseAlias(
          name: name,
          response: referencedResponse,
          context: context,
          description: wrapper.description,
        );

      case InlinedObject<Response>():
        final responseObj = wrapper.object;
        final headers = <String, core.ResponseHeader>{};

        if (responseObj.headers != null) {
          for (final entry in responseObj.headers!.entries) {
            headers[entry.key] = headerImporter.importInlineHeader(
              wrapper: entry.value,
              context: context.push('header').push(entry.key),
            );
          }
        }

        if (responseObj.content != null) {
          final mediaTypes = responseObj.content!;
          final bodies = <core.ResponseBody>[];

          // Process content types based on configuration
          for (final entry in mediaTypes.entries) {
            final rawContentType = entry.key;
            final contentType = resolveContentType(
              rawContentType,
              contentTypes: contentTypes,
              log: log,
            );

            if (entry.value.schema != null) {
              final model = modelImporter.importSchema(
                entry.value.schema!,
                context.push('body'),
              );
              bodies.add(
                core.ResponseBody(
                  model: model,
                  rawContentType: rawContentType,
                  contentType: contentType,
                ),
              );
            } else {
              final model = switch (contentType) {
                core.ContentType.bytes => core.BinaryModel(
                  context: context.push('body'),
                ),
                core.ContentType.json => core.AnyModel(
                  context: context.push('body'),
                ),
                core.ContentType.text => core.StringModel(
                  context: context.push('body'),
                ),
                core.ContentType.form => () {
                  log.warning(
                    'No schema found for form content type $rawContentType. '
                    'Treating as binary data.',
                  );
                  return core.BinaryModel(
                    context: context.push('body'),
                  );
                }(),
              };

              bodies.add(
                core.ResponseBody(
                  model: model,
                  rawContentType: rawContentType,
                  contentType: contentType,
                ),
              );
            }
          }

          response = core.ResponseObject(
            name: name,
            description: responseObj.description,
            headers: headers,
            bodies: bodies.toSet(),
            context: context,
          );
        } else {
          response = core.ResponseObject(
            name: name,
            description: responseObj.description,
            headers: headers,
            bodies: const {},
            context: context,
          );
        }
    }

    responses.add(response);
    return response;
  }
}
