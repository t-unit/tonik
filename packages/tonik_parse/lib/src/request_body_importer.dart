import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/content_type_resolver.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/media_type_resolver.dart';
import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';

class RequestBodyImporter({
  required final OpenApiObject openApiObject,
  required final ModelImporter modelImporter,
  required final Map<String, core.ContentTypeMapping> contentTypes,
  required final ResponseHeaderImporter responseHeaderImporter,
  required final ExampleImporter exampleImporter,
  required final MediaTypeResolver mediaTypeResolver,
}) {
  final log = Logger('RequestBodyImporter');

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
          if (_isWildcardMediaType(rawContentType)) {
            log.warning(
              'Wildcard request content type "$rawContentType" is not '
              'supported. Ignoring this request content entry.',
            );
            continue;
          }
          final mediaType = mediaTypeResolver.resolve(entry.value);
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
                formEncoding: null,
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
    final bodyContext = context.push('body');
    final model = mediaType.schema == null
        ? core.AnyModel(context: bodyContext)
        : modelImporter.importSchema(mediaType.schema!, bodyContext);
    final properties = _collectWritableMultipartProperties(model);
    final allProperties = _collectFormProperties(model);
    final dynamicRoot = model.resolved is core.MapModel;
    final isFormData =
        rawContentType.split(';').first.trim().toLowerCase() ==
        'multipart/form-data';
    final encoding = <String, core.PartEncoding>{};
    final mediaAlternatives = <String, List<core.PartEncoding>>{};
    for (final entry
        in mediaType.encoding?.entries ??
            const <MapEntry<String, Encoding>>[]) {
      if (allProperties != null || dynamicRoot) {
        if (!(allProperties?.containsKey(entry.key) ?? false)) {
          log.warning(
            'Encoding key "${entry.key}" does not match any property '
            'on the multipart schema. Ignoring.',
          );
          continue;
        }
        if (!(properties?.containsKey(entry.key) ?? false)) continue;
      }
      final declared = entry.value.contentType;
      final styleBased =
          isFormData &&
          (entry.value.style != null ||
              entry.value.explode != null ||
              entry.value.allowReserved != null);
      final alternatives = declared == null || styleBased
          ? const <String>[]
          : _splitPartMediaTypes(declared)
                .where((mediaType) => !_isWildcardMediaType(mediaType))
                .toList();
      if (alternatives.length > 1) {
        final choices = [
          for (final alternative in alternatives)
            _importPartEncoding(
              Encoding(
                contentType: alternative,
                headers: entry.value.headers,
                style: null,
                explode: null,
                allowReserved: null,
              ),
              entry.key,
              context,
              styleApplicable: styleBased,
            ),
        ];
        mediaAlternatives[entry.key] = choices;
        encoding[entry.key] = choices.first;
      } else if (declared != null && !styleBased) {
        encoding[entry.key] = _importPartEncoding(
          Encoding(
            contentType: alternatives.singleOrNull,
            headers: entry.value.headers,
            style: null,
            explode: null,
            allowReserved: null,
          ),
          entry.key,
          context,
          styleApplicable: false,
        );
      } else {
        encoding[entry.key] = _importPartEncoding(
          entry.value,
          entry.key,
          context,
          styleApplicable: styleBased,
        );
      }
    }
    if (properties != null) {
      for (final entry in properties.entries) {
        encoding[entry.key] = core.resolveNamedMultipartEncoding(
          entry.value.model,
          encoding[entry.key],
        );
      }
    }
    final requestSources = <core.Property, core.Property>{};
    final requestModel = _projectMultipartModel(
      model,
      encoding,
      mediaAlternatives,
      requestSources,
      <core.Model, core.Model>{},
    );
    return core.MultipartRequestContent(
      model: model,
      requestModel: requestModel,
      requestSources: Map.unmodifiable(requestSources),
      encoding: encoding,
      rawContentType: rawContentType,
      examples: exampleImporter.fromMediaType(mediaType),
      wireContentType: null,
      textEncoding: core.TextEncoding.utf8,
    );
  }

  core.Model _projectMultipartModel(
    core.Model model,
    Map<String, core.PartEncoding> encoding,
    Map<String, List<core.PartEncoding>> mediaAlternatives,
    Map<core.Property, core.Property> sources,
    Map<core.Model, core.Model> cache,
  ) {
    if (cache[model] case final existing?) return existing;
    cache[model] = model;
    final projected = _buildMultipartProjection(
      model,
      encoding,
      mediaAlternatives,
      sources,
      cache,
    );
    cache[model] = projected;
    return projected;
  }

  core.Model _buildMultipartProjection(
    core.Model model,
    Map<String, core.PartEncoding> encoding,
    Map<String, List<core.PartEncoding>> mediaAlternatives,
    Map<core.Property, core.Property> sources,
    Map<core.Model, core.Model> cache,
  ) {
    switch (model) {
      case core.AliasModel():
        final projected = _projectMultipartModel(
          model.model,
          encoding,
          mediaAlternatives,
          sources,
          cache,
        );
        if (identical(projected, model.model)) return model;
        final alias = core.AliasModel(
          model: projected,
          context: model.context.push('multipart'),
          examples: model.examples,
          defaultValue: null,
          name: model.name == null ? null : '${model.name}Multipart',
          nameOverride: model.nameOverride == null
              ? null
              : '${model.nameOverride}Multipart',
          description: model.description,
          isDeprecated: model.isDeprecated,
          isNullable: model.isNullable,
          isReadOnly: model.isReadOnly,
          isWriteOnly: model.isWriteOnly,
        );
        return alias;
      case core.ClassModel():
        var changed = false;
        final additionalPropertiesPolicy =
            switch (model.additionalPropertiesPolicy) {
              core.AllowedAdditionalProperties(
                origin: core.AdditionalPropertiesOrigin.explicit,
                :final valueModel,
              )
                  when _hasUntypedMultipartValue(valueModel) =>
                core.AllowedAdditionalProperties(
                  valueModel: _binaryMultipartInput(valueModel),
                  origin: core.AdditionalPropertiesOrigin.explicit,
                ),
              _ => model.additionalPropertiesPolicy,
            };
        changed = !identical(
          additionalPropertiesPolicy,
          model.additionalPropertiesPolicy,
        );
        final projectedProperties = <core.Property>[];
        for (final property in model.properties) {
          final partEncoding = encoding[property.name];
          final projectedValue =
              !property.isReadOnly &&
                  mediaAlternatives.containsKey(property.name)
              ? _choiceMultipartInput(
                  property.model,
                  mediaAlternatives[property.name]!,
                  property.name,
                )
              : !property.isReadOnly &&
                    partEncoding?.contentType == core.ContentType.bytes &&
                    !partEncoding!.isStyleBased
              ? _binaryMultipartInput(property.model)
              : property.model;
          if (identical(projectedValue, property.model)) {
            sources[property] = property;
            projectedProperties.add(property);
            continue;
          }
          changed = true;
          final projectedProperty = core.Property(
            name: property.name,
            model: projectedValue,
            isRequired: property.isRequired,
            isNullable:
                property.isNullable || property.model.isEffectivelyNullable,
            isDeprecated: property.isDeprecated,
            examples: const [],
            defaultValue: null,
            isReadOnly: property.isReadOnly,
            isWriteOnly: property.isWriteOnly,
            nameOverride: property.nameOverride,
            description: property.description,
          );
          sources[projectedProperty] = property;
          projectedProperties.add(projectedProperty);
        }
        if (!changed) return model;
        final projected = core.ClassModel(
          properties: projectedProperties,
          context: model.context.push('multipart'),
          isDeprecated: model.isDeprecated,
          examples: const [],
          name: model.name == null ? null : '${model.name}Multipart',
          nameOverride: model.nameOverride == null
              ? null
              : '${model.nameOverride}Multipart',
          description: model.description,
          additionalPropertiesPolicy: additionalPropertiesPolicy,
          isNullable: model.isNullable,
          isReadOnly: model.isReadOnly,
          isWriteOnly: model.isWriteOnly,
        );
        return projected;
      case core.MapModel():
        if (!_hasUntypedMultipartValue(model.valueModel)) return model;
        final projected = core.MapModel(
          valueModel: _binaryMultipartInput(model.valueModel),
          context: model.context.push('multipart'),
          examples: const [],
          name: model.name == null ? null : '${model.name}Multipart',
          nameOverride: model.nameOverride == null
              ? null
              : '${model.nameOverride}Multipart',
          isNullable: model.isNullable,
          isValueNullable: model.isValueNullable,
          isReadOnly: model.isReadOnly,
          isWriteOnly: model.isWriteOnly,
        );
        return projected;
      case core.AllOfModel():
        final members = [
          for (final member in model.models)
            _projectMultipartModel(
              member,
              encoding,
              mediaAlternatives,
              sources,
              cache,
            ),
        ];
        if (members.indexed.every(
          (entry) => identical(entry.$2, model.models[entry.$1]),
        )) {
          return model;
        }
        final projected = core.AllOfModel(
          models: members,
          context: model.context.push('multipart'),
          isDeprecated: model.isDeprecated,
          examples: const [],
          name: model.name == null ? null : '${model.name}Multipart',
          nameOverride: model.nameOverride == null
              ? null
              : '${model.nameOverride}Multipart',
          description: model.description,
          additionalPropertiesPolicy: model.additionalPropertiesPolicy,
          isNullable: model.isNullable,
          isReadOnly: model.isReadOnly,
          isWriteOnly: model.isWriteOnly,
          defaultValue: null,
        );
        return projected;
      default:
        return model;
    }
  }

  core.Model _binaryMultipartInput(core.Model model) {
    if (model.resolved is core.BinaryModel ||
        model.resolved is core.Base64Model) {
      return model;
    }
    if (model case core.AliasModel()) {
      final projected = _binaryMultipartInput(model.model);
      if (identical(projected, model.model)) return model;
      if (!model.isNullable) return projected;
      return core.AliasModel(
        model: projected,
        context: model.context.push('multipart'),
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: model.description,
        isDeprecated: model.isDeprecated,
        isNullable: model.isNullable,
        isReadOnly: model.isReadOnly,
        isWriteOnly: model.isWriteOnly,
      );
    }
    if (model is core.ListModel) {
      final projectedContent = _binaryMultipartInput(model.content);
      if (identical(projectedContent, model.content)) return model;
      return core.ListModel(
        content: projectedContent,
        context: model.context.push('multipart'),
        examples: const [],
        name: null,
        nameOverride: null,
        isNullable: model.isNullable,
        isContentNullable: model.isContentNullable,
        isReadOnly: model.isReadOnly,
        isWriteOnly: model.isWriteOnly,
      );
    }
    return core.BinaryModel(context: model.context.push('multipart'));
  }

  core.Model _choiceMultipartInput(
    core.Model model,
    List<core.PartEncoding> alternatives,
    String propertyName,
  ) {
    final resolved = model.resolved;
    if (resolved is core.ListModel) {
      return core.ListModel(
        content: _choiceMultipartValue(
          resolved.content,
          alternatives,
          propertyName,
        ),
        context: model.context.push('multipartChoices'),
        examples: const [],
        name: null,
        nameOverride: null,
        isNullable: model.isEffectivelyNullable,
        isContentNullable: resolved.isContentNullable,
        isReadOnly: resolved.isReadOnly,
        isWriteOnly: resolved.isWriteOnly,
      );
    }
    return _choiceMultipartValue(model, alternatives, propertyName);
  }

  core.Model _choiceMultipartValue(
    core.Model model,
    List<core.PartEncoding> alternatives,
    String propertyName,
  ) {
    final models = <core.DiscriminatedModel>[];
    for (final (index, alternative) in alternatives.indexed) {
      final inputModel =
          alternative.contentType == core.ContentType.multipart ||
              (model.resolved is core.Base64Model &&
                  alternative.contentType != core.ContentType.bytes)
          ? core.BinaryModel(context: model.context.push('multipart'))
          : alternative.contentType == core.ContentType.bytes
          ? model.resolved is core.ListModel
                ? core.BinaryModel(context: model.context.push('multipart'))
                : _binaryMultipartInput(model)
          : model;
      final media = alternative.rawContentType ?? 'choice';
      final base = media.split(';').first.trim();
      final suffix = base.replaceAll(RegExp('[^a-zA-Z0-9]+'), ' ');
      models.add((
        discriminatorValue: '${suffix}Choice${index + 1}',
        model: inputModel,
      ));
    }
    return core.MultipartChoiceModel(
      choices: alternatives,
      models: models,
      context: model.context.pushAll(['multipartChoices', propertyName]),
      isDeprecated: false,
      examples: const [],
      name: null,
      nameOverride: null,
      description: null,
      discriminator: null,
      isNullable: model.isEffectivelyNullable,
      isReadOnly: false,
      isWriteOnly: true,
      defaultValue: null,
    );
  }

  bool _isWildcardMediaType(String mediaType) {
    final token = mediaType.split(';').first.trim();
    return token.contains('*');
  }

  List<String> _splitPartMediaTypes(String contentType) {
    final result = <String>[];
    var start = 0;
    var quoted = false;
    var escaped = false;
    for (var index = 0; index < contentType.length; index++) {
      final character = contentType[index];
      if (escaped) {
        escaped = false;
      } else if (quoted && character == r'\') {
        escaped = true;
      } else if (character == '"') {
        quoted = !quoted;
      } else if (character == ',' && !quoted) {
        final part = contentType.substring(start, index).trim();
        if (part.isNotEmpty) result.add(part);
        start = index + 1;
      }
    }
    final last = contentType.substring(start).trim();
    if (last.isNotEmpty) result.add(last);
    return result;
  }

  bool _hasUntypedMultipartValue(core.Model model) => switch (model.resolved) {
    core.AnyModel() => true,
    core.ListModel(:final content) => content.resolved is core.AnyModel,
    _ => false,
  };

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

  Map<String, core.Property>? _collectWritableMultipartProperties(
    core.Model model,
  ) {
    if (_multipartModelIsReadOnly(model, <core.Model>{})) return null;
    switch (model.resolved) {
      case final core.ClassModel resolved:
        return {
          for (final property in resolved.properties)
            if (!property.isReadOnly &&
                !_multipartModelIsReadOnly(property.model, <core.Model>{}))
              property.name: property,
        };
      case final core.AllOfModel resolved:
        final byName = <String, core.Property>{};
        for (final member in resolved.models) {
          final memberProperties = _collectWritableMultipartProperties(member);
          if (memberProperties != null) byName.addAll(memberProperties);
        }
        return byName.isEmpty ? null : byName;
      default:
        return null;
    }
  }

  bool _multipartModelIsReadOnly(core.Model model, Set<core.Model> active) {
    if (!active.add(model)) return false;
    try {
      return switch (model) {
        core.AliasModel(:final isReadOnly, :final model) =>
          isReadOnly || _multipartModelIsReadOnly(model, active),
        core.ClassModel(:final isReadOnly) ||
        core.ListModel(:final isReadOnly) ||
        core.MapModel(:final isReadOnly) ||
        core.EnumModel(:final isReadOnly) ||
        core.AllOfModel(:final isReadOnly) ||
        core.OneOfModel(:final isReadOnly) ||
        core.AnyOfModel(:final isReadOnly) => isReadOnly,
        _ => false,
      };
    } finally {
      active.remove(model);
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
      if (headerEntry.key.toLowerCase() == 'content-type') continue;
      if (headerEntry.value case Reference<Header>(:final ref)
          when isExternalReference(ref)) {
        log.warning(
          'Multipart part header "${headerEntry.key}" has an external '
          'reference. Ignoring.',
        );
        continue;
      }
      if (responseHeaderImporter.isUnsupportedHeaderDefinition(
        headerEntry.value,
      )) {
        log.warning(
          'Multipart part header "${headerEntry.key}" has no usable '
          'definition. Ignoring.',
        );
        continue;
      }
      headers[headerEntry.key] = responseHeaderImporter.importInlineHeader(
        wrapper: headerEntry.value,
        context: context.pushAll(['encoding', propertyName, headerEntry.key]),
      );
    }
    return headers;
  }

  core.PartEncoding _importPartEncoding(
    Encoding encoding,
    String propertyName,
    core.Context context, {
    required bool styleApplicable,
  }) {
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
    final useStyleMode = styleApplicable && hasExplicitStyleFields;

    final resolvedStyle = useStyleMode
        ? (_mapSerializationStyle(encoding.style) ?? core.EncodingStyle.form)
        : null;
    final rawContentType = encoding.contentType;
    final textEncoding = _resolveTextEncoding(
      rawContentType ?? '',
      applicable:
          !useStyleMode &&
          (resolvedContentType == core.ContentType.text ||
              resolvedContentType == core.ContentType.json ||
              resolvedContentType == core.ContentType.form),
    );

    return core.PartEncoding(
      contentType: useStyleMode ? null : resolvedContentType,
      rawContentType: useStyleMode ? null : rawContentType,
      wireContentType: useStyleMode || rawContentType == null
          ? null
          : textEncoding.wireContentType,
      textEncoding: textEncoding.encoding,
      headers: headers,
      style: resolvedStyle,
      explode: useStyleMode
          ? (encoding.explode ?? (resolvedStyle == core.EncodingStyle.form))
          : null,
      allowReserved: null,
    );
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

    final parameter = _charsetParameter(rawContentType);
    final charset = parameter?.charset.toLowerCase();
    final encoding = switch (charset) {
      null || 'utf-8' || 'utf8' => core.TextEncoding.utf8,
      'iso-8859-1' || 'latin1' => core.TextEncoding.latin1,
      'us-ascii' || 'ascii' => core.TextEncoding.ascii,
      _ => null,
    };
    if (encoding != null) {
      return (encoding: encoding, wireContentType: rawContentType);
    }

    final wireContentType = rawContentType.replaceRange(
      parameter!.start,
      parameter.end,
      'utf-8',
    );
    return (encoding: core.TextEncoding.utf8, wireContentType: wireContentType);
  }

  ({String charset, int start, int end})? _charsetParameter(String mediaType) {
    var segmentStart = 0;
    var quoted = false;
    var escaped = false;
    for (var index = 0; index <= mediaType.length; index++) {
      final atEnd = index == mediaType.length;
      final char = atEnd ? '' : mediaType[index];
      if (!atEnd) {
        if (escaped) {
          escaped = false;
        } else if (quoted && char == r'\') {
          escaped = true;
        } else if (char == '"') {
          quoted = !quoted;
        }
      }
      if (!atEnd && (char != ';' || quoted)) continue;
      if (segmentStart != 0) {
        final segment = mediaType.substring(segmentStart, index);
        final equals = segment.indexOf('=');
        if (equals != -1 &&
            segment.substring(0, equals).trim().toLowerCase() == 'charset') {
          var start = segmentStart + equals + 1;
          var end = index;
          while (start < end && mediaType[start].trim().isEmpty) {
            start++;
          }
          while (end > start && mediaType[end - 1].trim().isEmpty) {
            end--;
          }
          if (end > start &&
              mediaType[start] == '"' &&
              mediaType[end - 1] == '"') {
            start++;
            end--;
          }
          return (
            charset: mediaType.substring(start, end),
            start: start,
            end: end,
          );
        }
      }
      segmentStart = index + 1;
    }
    return null;
  }

  static core.EncodingStyle? _mapSerializationStyle(SerializationStyle? style) {
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
