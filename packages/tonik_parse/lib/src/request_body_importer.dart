import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';

class RequestBodyImporter {
  RequestBodyImporter({
    required this.openApiObject,
    required this.modelImporter,
    required this.contentTypes,
    required this.responseHeaderImporter,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final ResponseHeaderImporter responseHeaderImporter;
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
            description: wrapper.description,
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

          // Extract multipart encoding if present
          final encoding = contentType == core.ContentType.multipart &&
                  mediaType.encoding != null &&
                  mediaType.encoding!.isNotEmpty
              ? _importEncoding(mediaType.encoding!, context)
              : null;

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
                encoding: encoding,
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
              core.ContentType.form || core.ContentType.multipart => () {
                log.warning(
                  'No schema found for ${contentType.name} content type '
                  '$rawContentType. Treating as binary data.',
                );
                return core.BinaryModel(context: context.push('body'));
              }(),
            };

            content.add(
              core.RequestContent(
                model: model,
                rawContentType: rawContentType,
                contentType: contentType,
                encoding: encoding,
              ),
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

  Map<String, core.MultipartPropertyEncoding> _importEncoding(
    Map<String, Encoding> encodingMap,
    core.Context context,
  ) {
    final result = <String, core.MultipartPropertyEncoding>{};
    for (final entry in encodingMap.entries) {
      final propertyName = entry.key;
      final encoding = entry.value;

      Map<String, core.ResponseHeader>? headers;
      if (encoding.headers != null && encoding.headers!.isNotEmpty) {
        headers = {};
        for (final headerEntry in encoding.headers!.entries) {
          final headerName = headerEntry.key;
          final headerWrapper = headerEntry.value;
          headers[headerName] = responseHeaderImporter.importInlineHeader(
            wrapper: headerWrapper,
            context: context.pushAll(['encoding', propertyName, headerName]),
          );
        }
      }

      result[propertyName] = core.MultipartPropertyEncoding(
        contentType: encoding.contentType,
        headers: headers,
        style: _mapSerializationStyle(encoding.style),
        explode: encoding.explode,
        allowReserved: encoding.allowReserved,
      );
    }
    return result;
  }

  static core.MultipartEncodingStyle? _mapSerializationStyle(
    SerializationStyle? style,
  ) {
    if (style == null) return null;
    return switch (style) {
      SerializationStyle.form => core.MultipartEncodingStyle.form,
      SerializationStyle.spaceDelimited =>
        core.MultipartEncodingStyle.spaceDelimited,
      SerializationStyle.pipeDelimited =>
        core.MultipartEncodingStyle.pipeDelimited,
      SerializationStyle.deepObject => core.MultipartEncodingStyle.deepObject,
      _ => null,
    };
  }
}
