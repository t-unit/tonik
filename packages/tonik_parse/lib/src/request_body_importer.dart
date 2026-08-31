import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/media_type.dart';
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
          final textEncoding = _resolveTextEncoding(
            rawContentType,
            applicable:
                contentType == core.ContentType.text ||
                contentType == core.ContentType.form,
          );

          final hasEncoding =
              mediaType.encoding != null && mediaType.encoding!.isNotEmpty;

          if (contentType == core.ContentType.multipart) {
            content.add(
              _importMultipartContent(mediaType, rawContentType, context),
            );
            continue;
          }

          if (mediaType.schema != null) {
            final model = modelImporter.importSchema(
              mediaType.schema!,
              context.push('body'),
            );
            final formEncoding =
                contentType == core.ContentType.form && hasEncoding
                ? _importFormEncoding(mediaType.encoding!, model)
                : null;
            content.add(
              core.ModelRequestContent(
                model: model,
                rawContentType: rawContentType,
                wireContentType: textEncoding.wireContentType,
                textEncoding: textEncoding.encoding,
                contentType: contentType,
                formEncoding: formEncoding,
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
              core.ContentType.form => () {
                log.warning(
                  'No schema found for ${contentType.name} content type '
                  '$rawContentType. Treating as binary data.',
                );
                return core.BinaryModel(context: context.push('body'));
              }(),
              core.ContentType.multipart => throw StateError(
                'Multipart content is parsed separately.',
              ),
            };

            content.add(
              core.ModelRequestContent(
                model: model,
                rawContentType: rawContentType,
                wireContentType: textEncoding.wireContentType,
                textEncoding: textEncoding.encoding,
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

  core.MultipartRequestContent _importMultipartContent(
    MediaType mediaType,
    String rawContentType,
    core.Context context,
  ) {
    final rootSchema = mediaType.schema;
    if (rootSchema == null) {
      return _emptyMultipartContent(mediaType, rawContentType, context);
    }
    var schema = rootSchema;
    final bodyContext = context.push('body');
    final hasAnnotations = modelImporter.hasAnnotationSiblings(schema);
    var sourceContext = bodyContext;
    String? sourceName;
    final referenceContext = schema.ref?.contains(r'/$defs/') == true
        ? core.Context.initial().pushAll(schema.ref!.substring(2).split('/'))
        : ModelImporter.rootContext;
    final alias = schema.ref != null && hasAnnotations
        ? core.MultipartContentAlias(
            targetName: schema.ref!.split('/').last,
            targetContext: referenceContext,
            targetNameOverride: modelImporter
                .resolveSchemaReference(schema)
                ?.xDartName,
            isNullable: schema.isNullable ?? schema.hasNullType,
            description: schema.description,
            isDeprecated: schema.isDeprecated ?? false,
            examples: exampleImporter.fromSchema(schema),
          )
        : null;
    final exposedContext = schema.ref != null && !hasAnnotations
        ? referenceContext
        : bodyContext;
    final exposedName = schema.ref != null && !hasAnnotations
        ? schema.ref!.split('/').last
        : null;
    var exposedNameOverride = schema.xDartName;
    final seen = <Schema>{};
    while (true) {
      if (!seen.add(schema)) {
        throw ArgumentError(
          'Multipart body at $context has a cyclic schema reference.',
        );
      }
      if (schema.allOf != null ||
          schema.oneOf != null ||
          schema.anyOf != null ||
          (schema.ref != null && schema.properties != null)) {
        return _emptyMultipartContent(mediaType, rawContentType, context);
      }
      final ref = schema.ref;
      if (ref == null) break;
      sourceName = ref.split('/').last;
      sourceContext = ref.contains(r'/$defs/')
          ? core.Context.initial().pushAll(ref.substring(2).split('/'))
          : ModelImporter.rootContext;
      schema =
          modelImporter.resolveSchemaReference(schema) ??
          (throw ArgumentError('Schema $ref not found'));
      if (sourceName == exposedName) exposedNameOverride = schema.xDartName;
    }
    final types = schema.nonNullTypes;
    if (schema.isBooleanSchema != null ||
        types.length > 1 ||
        (types.isNotEmpty && types.single != 'object') ||
        (schema.hasNullType && types.isEmpty) ||
        modelImporter.isOpenMapSchema(schema, types)) {
      return _emptyMultipartContent(mediaType, rawContentType, context);
    }
    final parts = <core.MultipartPart>[];
    if (schema.not != null && sourceName == null) {
      modelImporter.log.warning(
        'Found not schema for null. The not keyword is not '
        'supported and will be ignored.',
      );
    }
    for (final entry in (schema.properties ?? <String, Schema>{}).entries) {
      final property = entry.value;
      final model = modelImporter.importPropertySchema(
        property,
        sourceContext.pushAll([
          ?sourceName,
          if (entry.key.trim().isEmpty) 'property' else entry.key,
        ]),
      );
      parts.add(
        core.MultipartPart(
          name: entry.key,
          model: model,
          encoding: _importPartEncoding(
            property.isReadOnly == true ? null : mediaType.encoding?[entry.key],
            model,
            entry.key,
            context,
            warnOnCycle: property.isReadOnly != true,
          ),
          isRequired: schema.required?.contains(entry.key) ?? false,
          isNullable: property.isNullable ?? property.hasNullType,
          isDeprecated: property.isDeprecated ?? false,
          isReadOnly: property.isReadOnly ?? false,
          isWriteOnly: property.isWriteOnly ?? false,
          nameOverride: property.xDartName,
          description: property.description,
          defaultValue: property.rawDefault,
          examples: exampleImporter.fromSchema(property),
        ),
      );
    }
    for (final key in mediaType.encoding?.keys ?? <String>[]) {
      if (!parts.any((part) => part.name == key)) {
        log.warning(
          'Encoding key "$key" does not match any property '
          'on the multipart schema. Ignoring.',
        );
      }
    }
    return core.MultipartRequestContent(
      name: exposedName,
      context: exposedContext,
      nameOverride: exposedNameOverride,
      sourceName: sourceName,
      sourceContext: sourceContext,
      sourceNameOverride: schema.xDartName,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isNullable:
          schema.isNullable ?? (types.contains('object') && schema.hasNullType),
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      schemaExamples: exampleImporter.fromSchema(schema),
      alias: alias,
      additionalPropertiesPolicy: modelImporter.importAdditionalProperties(
        schema,
        sourceContext,
      ),
      parts: parts,
      rawContentType: rawContentType,
      examples: exampleImporter.fromMediaType(mediaType),
    );
  }

  core.MultipartRequestContent _emptyMultipartContent(
    MediaType mediaType,
    String rawContentType,
    core.Context context,
  ) {
    log.warning(
      'Multipart body at $context has an unsupported or missing root schema. '
      'Generating an empty multipart body.',
    );
    return core.MultipartRequestContent(
      parts: const [],
      context: context.push('body'),
      rawContentType: rawContentType,
      examples: exampleImporter.fromMediaType(mediaType),
      additionalPropertiesPolicy: const core.ForbiddenAdditionalProperties(),
    );
  }

  /// A recursive model has no leaf to inspect; only complex structures can
  /// recurse, so a cycle defaults to JSON.
  core.ContentType _resolveDefaultContentType(
    core.Model model,
    Set<core.Model> visited,
    String propertyName, {
    bool warnOnCycle = true,
  }) {
    if (!visited.add(model)) {
      if (warnOnCycle) {
        log.warning(
          'Multipart property "$propertyName" has a recursive schema with no '
          'terminal type. Defaulting part content type to application/json.',
        );
      }
      return core.ContentType.json;
    }
    return switch (model) {
      core.AliasModel() => _resolveDefaultContentType(
        model.model,
        visited,
        propertyName,
        warnOnCycle: warnOnCycle,
      ),
      core.ListModel() => _resolveDefaultContentType(
        model.content,
        visited,
        propertyName,
        warnOnCycle: warnOnCycle,
      ),
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

  /// Unmatched keys and read-only properties are dropped: the former have no
  /// field to describe, the latter are never sent. No per-property content-type
  /// default is applied, unlike the multipart path.
  Map<core.Property, core.FieldEncoding>? _importFormEncoding(
    Map<String, Encoding> encodingMap,
    core.Model model,
  ) {
    final propertiesByName = _collectFormProperties(model);

    if (propertiesByName == null && encodingMap.isNotEmpty) {
      log.warning(
        'Form-urlencoded body has a non-object schema '
        '(${model.resolved.runtimeType}). Its encoding block '
        '(${encodingMap.keys.join(', ')}) has no fields to describe and '
        'is ignored.',
      );
    }

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

  /// Maps raw spec property names to their [core.Property] for a form body's
  /// schema. Resolves through alias chains and unions the properties of an
  /// `allOf`'s members so composite bodies expose the same names the shared
  /// object path emits. Returns null when the schema exposes no named fields.
  Map<String, core.Property>? _collectFormProperties(core.Model model) {
    switch (model.resolved) {
      case final core.ClassModel resolved:
        return {for (final p in resolved.properties) p.name: p};
      case final core.AllOfModel resolved:
        final byName = <String, core.Property>{};
        for (final member in resolved.models) {
          final memberProperties = _collectFormProperties(member);
          if (memberProperties != null) byName.addAll(memberProperties);
        }
        return byName.isEmpty ? null : byName;
      default:
        return null;
    }
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

  core.PartEncoding _importPartEncoding(
    Encoding? encoding,
    core.Model model,
    String propertyName,
    core.Context context, {
    bool warnOnCycle = true,
  }) {
    final isOas30 = openApiObject.openapi.startsWith('3.0');
    final headers = encoding == null
        ? null
        : _importEncodingHeaders(encoding, propertyName, context);
    final defaultContentType = _resolveDefaultContentType(
      model,
      <core.Model>{},
      propertyName,
      warnOnCycle: warnOnCycle,
    );
    final resolvedContentType = encoding?.contentType != null
        ? resolveContentType(
            encoding!.contentType!,
            contentTypes: contentTypes,
            log: log,
          )
        : defaultContentType;

    final hasExplicitStyleFields =
        encoding?.style != null ||
        encoding?.explode != null ||
        encoding?.allowReserved != null;
    // OAS 3.0: always content-based; OAS 3.1: style-based only if explicit
    final useStyleMode = !isOas30 && hasExplicitStyleFields;

    final resolvedStyle = useStyleMode
        ? (_mapSerializationStyle(encoding?.style) ?? core.EncodingStyle.form)
        : null;
    final rawContentType =
        encoding?.contentType ??
        switch (defaultContentType) {
          core.ContentType.json => 'application/json',
          core.ContentType.bytes => 'application/octet-stream',
          _ => 'text/plain',
        };
    final textEncoding = _resolveTextEncoding(
      rawContentType,
      applicable:
          !useStyleMode && _serializesMultipartAsText(model, <core.Model>{}),
    );

    return core.PartEncoding(
      contentType: useStyleMode ? null : resolvedContentType,
      rawContentType: useStyleMode ? null : rawContentType,
      wireContentType: useStyleMode ? null : textEncoding.wireContentType,
      textEncoding: textEncoding.encoding,
      headers: headers,
      style: resolvedStyle,
      explode: useStyleMode
          ? (encoding?.explode ?? (resolvedStyle == core.EncodingStyle.form))
          : null,
      allowReserved: useStyleMode ? (encoding?.allowReserved ?? false) : null,
    );
  }

  static bool _serializesMultipartAsText(
    core.Model model,
    Set<core.Model> visited,
  ) {
    if (!visited.add(model)) return false;
    return switch (model) {
      core.AliasModel() => _serializesMultipartAsText(model.model, visited),
      core.ListModel() => switch (model.content.resolved) {
        core.ListModel() => false,
        _ => _serializesMultipartAsText(model.content, visited),
      },
      core.BinaryModel() || core.Base64Model() || core.NeverModel() => false,
      _ => true,
    };
  }

  ({core.TextEncoding encoding, String wireContentType}) _resolveTextEncoding(
    String rawContentType, {
    required bool applicable,
  }) {
    if (!applicable) {
      return (
        encoding: core.TextEncoding.utf8,
        wireContentType: rawContentType,
      );
    }

    final match = _charsetPattern.firstMatch(rawContentType);
    final charset = match?.group(3)?.toLowerCase();
    final encoding = switch (charset) {
      null || 'utf-8' || 'utf8' => core.TextEncoding.utf8,
      'iso-8859-1' || 'latin1' => core.TextEncoding.latin1,
      'us-ascii' || 'ascii' => core.TextEncoding.ascii,
      _ => null,
    };
    if (encoding != null) {
      return (encoding: encoding, wireContentType: rawContentType);
    }

    final quote = match!.group(2) == '"' ? '"' : '';
    final wireContentType = rawContentType.replaceRange(
      match.start,
      match.end,
      '${match.group(1)}${quote}utf-8$quote',
    );
    return (
      encoding: core.TextEncoding.utf8,
      wireContentType: wireContentType,
    );
  }

  static final _charsetPattern = RegExp(
    r'((?:^|;)\s*charset\s*=\s*)("?)([^";\s]+)("?)',
    caseSensitive: false,
  );

  static core.EncodingStyle? _mapSerializationStyle(
    SerializationStyle? style,
  ) {
    if (style == null) return null;
    return switch (style) {
      SerializationStyle.form => core.EncodingStyle.form,
      SerializationStyle.spaceDelimited => core.EncodingStyle.spaceDelimited,
      SerializationStyle.pipeDelimited => core.EncodingStyle.pipeDelimited,
      SerializationStyle.deepObject => core.EncodingStyle.deepObject,
      _ => null,
    };
  }
}
