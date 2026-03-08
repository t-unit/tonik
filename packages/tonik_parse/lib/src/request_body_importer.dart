import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/schema.dart';
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
          final explicitEncoding =
              contentType == core.ContentType.multipart &&
                  mediaType.encoding != null &&
                  mediaType.encoding!.isNotEmpty
              ? _importEncoding(mediaType.encoding!, context)
              : null;

          if (mediaType.schema != null) {
            final model = modelImporter.importSchema(
              mediaType.schema!,
              context.push('body'),
            );

            final propertyFormats = contentType == core.ContentType.multipart
                ? _extractPropertyFormats(mediaType.schema)
                : null;
            final encoding = contentType == core.ContentType.multipart
                ? _populateMultipartDefaults(
                    name: name,
                    model: model,
                    explicitEncoding: explicitEncoding,
                    propertyFormats: propertyFormats,
                  )
                : null;

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

  Map<String, String?> _extractPropertyFormats(Schema? schema) {
    if (schema == null) return {};
    Schema? resolved = schema;
    if (schema.ref != null) {
      final refName = schema.ref!.split('/').last;
      resolved = openApiObject.components?.schemas?[refName];
    }
    final properties = resolved?.properties;
    if (properties == null) return {};
    return {
      for (final e in properties.entries)
        e.key: e.value.format ??
            (e.value.ref != null
                ? (openApiObject.components?.schemas?[e.value.ref!.split('/').last])?.format
                : null),
    };
  }

  Map<String, core.MultipartPropertyEncoding>? _populateMultipartDefaults({
    required String? name,
    required core.Model model,
    required Map<String, core.MultipartPropertyEncoding>? explicitEncoding,
    required Map<String, String?>? propertyFormats,
  }) {
    // Resolve through aliases to find the underlying model
    final resolved = model is core.AliasModel ? model.resolved : model;

    // Only populate per-property defaults for ClassModel
    if (resolved is! core.ClassModel) {
      final label = name != null ? 'Multipart body "$name"' : 'Multipart body';
      log.warning(
        '$label has a non-object schema (${resolved.runtimeType}). '
        'Only object schemas with properties are supported. '
        'The generated method will throw at runtime.',
      );
      return null;
    }

    final propertyNames = resolved.properties.map((p) => p.name).toSet();

    // Warn about encoding keys that don't match any property
    if (explicitEncoding != null) {
      for (final key in explicitEncoding.keys) {
        if (!propertyNames.contains(key)) {
          log.warning(
            'Encoding key "$key" does not match any property '
            'on the multipart schema. Ignoring.',
          );
        }
      }
    }

    final result = <String, core.MultipartPropertyEncoding>{};

    for (final property in resolved.properties) {
      final existing = explicitEncoding?[property.name];
      final format = propertyFormats?[property.name];
      final isByteFormat = format == 'byte' || format == 'binary';
      final defaultContentType = isByteFormat
          ? core.ContentType.bytes
          : _resolveDefaultContentType(property.model);
      final defaultRawContentType = isByteFormat
          ? 'application/octet-stream'
          : _resolveDefaultRawContentType(property.model);

      result[property.name] = core.MultipartPropertyEncoding(
        contentType: existing?.contentType ?? defaultContentType,
        rawContentType: existing?.rawContentType ?? defaultRawContentType,
        headers: existing?.headers,
        style: existing?.style,
        explode: existing?.explode,
        allowReserved: existing?.allowReserved,
      );
    }

    return result;
  }

  static core.ContentType _resolveDefaultContentType(core.Model model) {
    return switch (model) {
      core.AliasModel() => _resolveDefaultContentType(model.resolved),
      core.ListModel() => _resolveDefaultContentType(model.content),
      core.ClassModel() => core.ContentType.json,
      core.AllOfModel() => core.ContentType.json,
      core.OneOfModel() => core.ContentType.json,
      core.AnyOfModel() => core.ContentType.json,
      core.BinaryModel() => core.ContentType.bytes,
      core.AnyModel() => core.ContentType.bytes,
      _ => core.ContentType.text,
    };
  }

  static String _resolveDefaultRawContentType(core.Model model) {
    return switch (model) {
      core.AliasModel() => _resolveDefaultRawContentType(model.resolved),
      core.ListModel() => _resolveDefaultRawContentType(model.content),
      core.ClassModel() => 'application/json',
      core.AllOfModel() => 'application/json',
      core.OneOfModel() => 'application/json',
      core.AnyOfModel() => 'application/json',
      core.BinaryModel() => 'application/octet-stream',
      core.AnyModel() => 'application/octet-stream',
      _ => 'text/plain',
    };
  }

  Map<String, core.MultipartPropertyEncoding> _importEncoding(
    Map<String, Encoding> encodingMap,
    core.Context context,
  ) {
    final result = <String, core.MultipartPropertyEncoding>{};
    final isOas30 = openApiObject.openapi.startsWith('3.0');
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

      final resolvedContentType = encoding.contentType != null
          ? resolveContentType(
              encoding.contentType!,
              contentTypes: contentTypes,
              log: log,
            )
          : null;

      final hasExplicitStyleFields =
          encoding.style != null ||
          encoding.explode != null ||
          encoding.allowReserved != null;
      // OAS 3.0: always content-based; OAS 3.1: style-based only if explicit
      final useStyleMode = !isOas30 && hasExplicitStyleFields;

      final resolvedStyle = useStyleMode
          ? (_mapSerializationStyle(encoding.style) ??
                core.MultipartEncodingStyle.form)
          : null;

      result[propertyName] = core.MultipartPropertyEncoding(
        contentType: resolvedContentType,
        rawContentType: encoding.contentType,
        headers: headers,
        style: resolvedStyle,
        explode: useStyleMode
            ? (encoding.explode ??
                  (resolvedStyle == core.MultipartEncodingStyle.form))
            : null,
        allowReserved: useStyleMode ? (encoding.allowReserved ?? false) : null,
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
