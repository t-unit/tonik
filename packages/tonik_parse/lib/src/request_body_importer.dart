import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
import 'package:tonik_parse/src/example_importer.dart';
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
    required this.exampleImporter,
  });

  final OpenApiObject openApiObject;
  final ModelImporter modelImporter;
  final ResponseHeaderImporter responseHeaderImporter;
  final ExampleImporter exampleImporter;
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

          final hasEncoding =
              mediaType.encoding != null && mediaType.encoding!.isNotEmpty;
          final explicitEncoding =
              hasEncoding && contentType == core.ContentType.multipart
              ? _importEncoding(mediaType.encoding!, context)
              : null;

          if (mediaType.schema != null) {
            final model = modelImporter.importSchema(
              mediaType.schema!,
              context.push('body'),
            );

            final formEncoding =
                contentType == core.ContentType.form && hasEncoding
                ? _importFormEncoding(mediaType.encoding!, model)
                : null;
            final multipartEncoding =
                contentType == core.ContentType.multipart
                ? _populateMultipartDefaults(
                    name: name,
                    model: model,
                    explicitEncoding: explicitEncoding,
                  )
                : null;

            content.add(
              core.RequestContent(
                model: model,
                rawContentType: rawContentType,
                contentType: contentType,
                formEncoding: formEncoding,
                multipartEncoding: multipartEncoding,
                examples: exampleImporter.fromMediaType(mediaType),
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
                examples: exampleImporter.fromMediaType(mediaType),
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

  Map<core.Property, core.PartEncoding>? _populateMultipartDefaults({
    required String? name,
    required core.Model model,
    required Map<String, core.PartEncoding>? explicitEncoding,
  }) {
    // Resolve through aliases to find the underlying model
    final resolved = model.resolved;

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

    final result = <core.Property, core.PartEncoding>{};

    for (final property in resolved.properties) {
      // Encoding on a read-only property is meaningless; it is not sent.
      if (property.isReadOnly) continue;

      final existing = explicitEncoding?[property.name];
      final defaultContentType = _resolveDefaultContentType(property.model);
      final defaultRawContentType = _resolveDefaultRawContentType(
        property.model,
      );

      final isStyleBased = existing?.isStyleBased ?? false;
      result[property] = core.PartEncoding(
        contentType: isStyleBased
            ? null
            : (existing?.contentType ?? defaultContentType),
        rawContentType: isStyleBased
            ? null
            : (existing?.rawContentType ?? defaultRawContentType),
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
      core.Base64Model() => core.ContentType.bytes,
      core.AnyModel() => core.ContentType.json,
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
      core.Base64Model() => 'application/octet-stream',
      core.AnyModel() => 'application/json',
      _ => 'text/plain',
    };
  }

  /// Unlike the multipart path, no per-property content-type default is
  /// applied, and allowReserved is captured regardless of OpenAPI version.
  ///
  /// Keys that match no property, and read-only properties, are dropped: the
  /// former have no field to describe, the latter are never sent.
  Map<core.Property, core.FieldEncoding>? _importFormEncoding(
    Map<String, Encoding> encodingMap,
    core.Model model,
  ) {
    final resolved = model.resolved;
    final propertiesByName = resolved is core.ClassModel
        ? {for (final p in resolved.properties) p.name: p}
        : null;

    final result = <core.Property, core.FieldEncoding>{};
    for (final entry in encodingMap.entries) {
      final encoding = entry.value;
      final property = propertiesByName?[entry.key];

      if (propertiesByName != null && property == null) {
        log.warning(
          'Encoding key "${entry.key}" does not match any property '
          'on the form-urlencoded schema. Ignoring.',
        );
        continue;
      }

      if (property == null || property.isReadOnly) continue;

      result[property] = core.FieldEncoding(
        style: _mapSerializationStyle(encoding.style),
        explode: encoding.explode,
        allowReserved: encoding.allowReserved ?? false,
      );
    }
    return result;
  }

  Map<String, core.ResponseHeader>? _importEncodingHeaders(
    Encoding encoding,
    String propertyName,
    core.Context context,
  ) {
    if (encoding.headers == null || encoding.headers!.isEmpty) {
      return null;
    }

    final headers = <String, core.ResponseHeader>{};
    for (final headerEntry in encoding.headers!.entries) {
      headers[headerEntry.key] = responseHeaderImporter.importInlineHeader(
        wrapper: headerEntry.value,
        context: context.pushAll(['encoding', propertyName, headerEntry.key]),
      );
    }
    return headers;
  }

  Map<String, core.PartEncoding> _importEncoding(
    Map<String, Encoding> encodingMap,
    core.Context context,
  ) {
    final result = <String, core.PartEncoding>{};
    final isOas30 = openApiObject.openapi.startsWith('3.0');
    for (final entry in encodingMap.entries) {
      final propertyName = entry.key;
      final encoding = entry.value;

      final headers = _importEncodingHeaders(encoding, propertyName, context);

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
                core.EncodingStyle.form)
          : null;

      result[propertyName] = core.PartEncoding(
        contentType: useStyleMode ? null : resolvedContentType,
        rawContentType: useStyleMode ? null : encoding.contentType,
        headers: headers,
        style: resolvedStyle,
        explode: useStyleMode
            ? (encoding.explode ??
                  (resolvedStyle == core.EncodingStyle.form))
            : null,
        allowReserved: useStyleMode ? (encoding.allowReserved ?? false) : null,
      );
    }
    return result;
  }

  static core.EncodingStyle? _mapSerializationStyle(
    SerializationStyle? style,
  ) {
    if (style == null) return null;
    return switch (style) {
      SerializationStyle.form => core.EncodingStyle.form,
      SerializationStyle.spaceDelimited =>
        core.EncodingStyle.spaceDelimited,
      SerializationStyle.pipeDelimited =>
        core.EncodingStyle.pipeDelimited,
      SerializationStyle.deepObject => core.EncodingStyle.deepObject,
      _ => null,
    };
  }
}
