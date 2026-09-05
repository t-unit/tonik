import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/text_encoding_expression.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Resolves serialization before native multipart containers are constructed.
class MultipartBodyPlanner {
  const MultipartBodyPlanner({
    required this.backend,
    this.nameManager,
    this.package,
    this.useImmutableCollections = false,
  });

  final TransportBackend backend;
  final NameManager? nameManager;
  final String? package;
  final bool useImmutableCollections;
  bool get _dio => backend == TransportBackend.dio;

  MultipartBodyPlan plan(
    MultipartRequestContent content, {
    required String bodyAccessor,
    required bool isRequired,
    List<MultipartHeaderParamInfo>? headerParameters,
  }) {
    final parameters =
        (headerParameters ??
                extractMultipartHeaderParamInfo(
                  content,
                  nameManager: nameManager,
                  package: package,
                ))
            .where((parameter) => identical(parameter.content, content))
            .toList();
    final emissions = <MultipartEmission>[];
    final properties = normalizeMultipartProperties(
      content,
      nameManager: nameManager,
      package: package,
    );
    for (final property in properties) {
      _validateCompatibleDefinitions(property);
      final resolvedEncoding = _resolveEncoding(
        content.encoding[property.rawName],
        property.property.model,
      );
      final accesses = [
        for (final path in property.accessPaths)
          _access(refer(bodyAccessor), path),
      ];
      final mergedObjects =
          accesses.length > 1 &&
          property.properties.every(
            (candidate) =>
                candidate.model.resolved is ClassModel ||
                candidate.model.resolved is AllOfModel,
          );
      final mergedMaps =
          accesses.length > 1 &&
          property.properties.every(
            (candidate) => candidate.model.resolved is MapModel,
          );
      final mergedLists =
          accesses.length > 1 &&
          property.properties.every(
            (candidate) => candidate.model.resolved is ListModel,
          );
      final mergedObjectProperties =
          mergedObjects &&
          (resolvedEncoding.isStyleBased ||
              resolvedEncoding.contentType == ContentType.form);
      final nullable = property.isNullable || !property.isRequired;
      final Expression accessor;
      if (accesses.length == 1) {
        accessor = accesses.single;
      } else {
        final variable = '_\$${property.normalizedName}MultipartValue';
        final mergeFunction = mergedObjectProperties
            ? 'mergeMultipartPropertyValues'
            : mergedLists
            ? 'mergeMultipartLists'
            : 'mergeMultipartValues';
        var mergeExpression =
            refer(mergeFunction, 'package:tonik_util/tonik_util.dart').call(
              [
                literalList([
                  for (var i = 0; i < accesses.length; i++)
                    mergedObjects
                        ? _objectMergeValue(
                            accesses[i],
                            nullable: _occurrenceIsNullable(
                              property.accessPaths[i],
                              property.properties[i],
                            ),
                            asProperties: mergedObjectProperties,
                          )
                        : useImmutableCollections &&
                              (property.properties[i].model.resolved
                                      is ListModel ||
                                  property.properties[i].model.resolved
                                      is MapModel)
                        ? _immutableMergeValue(
                            accesses[i],
                            nullable: _occurrenceIsNullable(
                              property.accessPaths[i],
                              property.properties[i],
                            ),
                          )
                        : accesses[i],
                ]),
              ],
              {
                'propertyName': specLiteralString(property.rawName),
                if ((mergedObjects && !mergedObjectProperties) || mergedMaps)
                  'mergeObjects': literalTrue,
              },
            );
        if (!nullable && (mergedObjectProperties || mergedLists)) {
          mergeExpression = mergeExpression.nullChecked;
        }
        emissions.add(
          MultipartCode(
            declareFinal(variable).assign(mergeExpression).statement,
          ),
        );
        accessor = refer(variable);
      }
      if (property.isRequired && property.isNullable) {
        emissions.add(
          MultipartCode(
            Block.of([
              const Code('if ('),
              accessor.code,
              const Code(' == null) { '),
              generateEncodingExceptionExpression(
                'Required multipart property "${property.rawName}" is null.',
                raw: true,
              ).code,
              const Code('; }'),
            ]),
          ),
        );
      }
      if (nullable) {
        emissions.add(
          MultipartCode(
            Block.of([
              const Code('if ('),
              accessor.code,
              const Code(' != null) {'),
            ]),
          ),
        );
      }
      final headers = _headers(
        content.encoding[property.rawName],
        property.normalizedName,
        parameters,
        nullable,
        emissions,
      );
      final input = (
        name: property.rawName,
        normalizedName: property.normalizedName,
        value: nullable ? accessor.nullChecked : accessor,
        encoding: resolvedEncoding,
        headers: headers,
        isMergedObject: mergedObjects,
        isMergedObjectProperties: mergedObjectProperties,
      );
      emissions.addAll(_part(input, property.property.model.resolved));
      if (nullable) emissions.add(const MultipartCode(Code('}')));
    }
    return MultipartBodyPlan(
      value: refer(bodyAccessor),
      rawContentType: content.rawContentType,
      isRequired: isRequired,
      emissions: emissions,
      usesCustomParts: !_dio && parameters.isNotEmpty,
    );
  }

  List<MultipartEmission> _part(_Part part, Model model) => switch (model) {
    BinaryModel() || Base64Model() => _file(part),
    ListModel() => _list(part, model),
    NeverModel() => _error(
      "Cannot encode NeverModel property '${part.name}' - this type does not "
      'permit any value.',
    ),
    StringModel() => [_text(part, part.value)],
    AnyModel() => [
      _text(part, _json(_anyJson(part.value)), fallback: 'application/json'),
    ],
    MapModel() => _map(part),
    ClassModel() || CompositeModel() => _object(part),
    EnumModel() => [_text(part, _enum(part.value, model, part.encoding))],
    PrimitiveModel() => [
      _text(part, _primitive(part.value, model, part.encoding)),
    ],
    NamedModel() => _error(
      "Cannot encode cyclic AliasModel property '${part.name}'.",
    ),
  };

  MultipartAppend _text(
    _Part part,
    Expression text, {
    String fallback = 'text/plain',
    String? contentType,
    bool omitContentType = false,
    bool field = false,
    Expression? name,
  }) {
    final encoding = part.encoding.textEncoding;
    final plain = _dio && encoding == TextEncoding.utf8;
    return MultipartAppend(
      name: name ?? specLiteralString(part.name),
      value: plain
          ? text
          : textEncodingExpression(encoding).property('encode').call([text]),
      source: plain
          ? (field && part.headers == null
                ? MultipartValueSource.field
                : MultipartValueSource.text)
          : MultipartValueSource.bytes,
      contentType: omitContentType
          ? null
          : contentType ?? part.encoding.wireContentType ?? fallback,
      headers: part.headers,
    );
  }

  List<MultipartEmission> _file(_Part part, {bool listItem = false}) {
    final declared = part.encoding.wireContentType;
    if (!_dio) {
      return [
        MultipartAppend(
          name: specLiteralString(part.name),
          value: part.value,
          source: MultipartValueSource.file,
          filename: part.value
              .property('fileName')
              .ifNullThen(specLiteralString(part.name)),
          contentType: declared ?? 'application/octet-stream',
          headers: part.headers,
        ),
      ];
    }
    final contentType = listItem || declared == 'application/octet-stream'
        ? null
        : declared;
    final filename = refer('fileName').ifNullThen(specLiteralString(part.name));
    return [
      MultipartCode(
        Block.of([
          const Code('switch ('),
          part.value.code,
          const Code(') { case '),
          refer('TonikFileBytes', 'package:tonik_util/tonik_util.dart').code,
          const Code('(:final bytes, :final fileName):'),
        ]),
      ),
      MultipartAppend(
        name: specLiteralString(part.name),
        value: refer('bytes'),
        source: MultipartValueSource.bytes,
        filename: filename,
        contentType: contentType,
        headers: part.headers,
      ),
      MultipartCode(
        Block.of([
          const Code('case '),
          refer('TonikFilePath', 'package:tonik_util/tonik_util.dart').code,
          const Code('(:final path, :final fileName):'),
        ]),
      ),
      MultipartAppend(
        name: specLiteralString(part.name),
        value: refer('path'),
        source: MultipartValueSource.path,
        filename: filename,
        contentType: contentType,
        headers: part.headers,
      ),
      const MultipartCode(Code('}')),
    ];
  }

  List<MultipartEmission> _list(_Part part, ListModel model) {
    final encoding = part.encoding;
    final item = model.content.resolved;
    final contentBased =
        !encoding.isStyleBased &&
        encoding.contentType != null &&
        encoding.contentType != ContentType.text;
    if (_dio && encoding.style == EncodingStyle.deepObject) {
      return _error(
        'deepObject style is not supported for array multipart '
        'properties (property: ${part.name}).',
      );
    }
    if (item is ListModel && (!_dio || contentBased)) {
      return _error(
        'Arrays of arrays are not supported for multipart encoding '
        '(property: ${part.name}).',
      );
    }
    if (item is AliasModel) {
      return _error(
        'Cannot encode cyclic AliasModel list items for multipart '
        "property '${part.name}'.",
      );
    }
    final itemPart = _withValue(part, refer('item'));
    if (item is BinaryModel || item is Base64Model) {
      return _loop('item', part.value, _file(itemPart, listItem: true));
    }
    if (contentBased) {
      if (encoding.contentType != ContentType.json &&
          encoding.contentType != ContentType.bytes) {
        return _error(
          'Unsupported contentType "${encoding.rawContentType ?? ''}" '
          'for array multipart property "${part.name}". Only application/json '
          'is supported for content-based array serialization.',
        );
      }
      final variable = _dio ? 'e' : 'item';
      final itemValue = refer(variable);
      final itemJson = switch (item) {
        ClassModel() ||
        CompositeModel() ||
        EnumModel() => itemValue.property('toJson').call([]),
        DateTimeModel() =>
          itemValue.property('toTimeZonedIso8601String').call([]),
        AnyModel() when !_dio => _anyJson(itemValue),
        _ => null,
      };
      return [
        _text(
          part,
          _json(
            itemJson == null
                ? part.value
                : _mapped(part.value, itemJson, variable: variable),
          ),
          fallback: 'application/json',
        ),
      ];
    }
    if (item is ClassModel ||
        item is CompositeModel ||
        (!_dio && (item is MapModel || item is AnyModel))) {
      final json = switch (item) {
        MapModel() => refer('item'),
        AnyModel() => _anyJson(refer('item')),
        _ => refer('item').property('toJson').call([]),
      };
      return _loop('item', part.value, [
        _text(part, _json(json), fallback: 'application/json'),
      ]);
    }
    final itemText = _itemText(itemPart, item);
    if (encoding.explode ?? true) {
      return _loop('item', part.value, [_listText(part, itemText)]);
    }
    final strings = item is StringModel
        ? part.value
        : _mapped(part.value, itemText);
    if (encoding.style == EncodingStyle.spaceDelimited ||
        encoding.style == EncodingStyle.pipeDelimited) {
      final space = encoding.style == EncodingStyle.spaceDelimited;
      final encoded = strings
          .property(space ? 'toSpaceDelimited' : 'toPipeDelimited')
          .call([], {
            'explode': literalFalse,
            'allowEmpty': literalTrue,
            'alreadyEncoded': literalTrue,
            if (space) 'percentEncodeDelimiter': literalFalse,
            if (!_dio && (encoding.allowReserved ?? false))
              'allowReserved': literalTrue,
          });
      return _loop('item', encoded, [_listText(part, refer('item'))]);
    }
    final serialized = _dio
        ? strings.property('uriEncode').call([], {
            'allowEmpty': literalTrue,
            'textEncoding': textEncodingExpression(encoding.textEncoding),
            'alreadyEncoded': literalTrue,
          })
        : buildSimpleValueExpression(
            part.value,
            model,
            explode: false,
            allowEmpty: true,
          ).unsafeRawBody;
    return [_listText(part, serialized)];
  }

  MultipartAppend _listText(_Part part, Expression text) => _text(
    part,
    text,
    field: _dio,
    omitContentType:
        _dio &&
        part.encoding.textEncoding == TextEncoding.utf8 &&
        part.encoding.isStyleBased,
  );

  Expression _itemText(_Part part, Model model) {
    if (model is StringModel) return part.value;
    if (model is EnumModel) {
      return _dio
          ? part.value.property('uriEncode').call([], {
              'allowEmpty': literalTrue,
              'textEncoding': textEncodingExpression(
                part.encoding.textEncoding,
              ),
            })
          : _enum(part.value, model, part.encoding);
    }
    return _primitive(part.value, model, part.encoding);
  }

  Expression _enum(
    Expression value,
    EnumModel<dynamic> model,
    PartEncoding encoding,
  ) {
    final json = value.property('toJson').call([]);
    if (!_dio && encoding.contentType == ContentType.json) return _json(json);
    return model is EnumModel<String>
        ? json
        : json.property('toString').call([]);
  }

  Expression _primitive(Expression value, Model model, PartEncoding encoding) {
    if (encoding.contentType == ContentType.json && model is PrimitiveModel) {
      return _json(value);
    }
    return value
        .property(
          model is DateTimeModel ? 'toTimeZonedIso8601String' : 'toString',
        )
        .call([]);
  }

  List<MultipartEmission> _map(_Part part) {
    if (_dio && part.encoding.style == EncodingStyle.deepObject) {
      return _error(
        'deepObject style is not supported for map multipart '
        'properties (property: ${part.name}). '
        'Maps do not implement ParameterEncodable.toDeepObject().',
      );
    }
    if (_dio &&
        !part.encoding.isStyleBased &&
        part.encoding.contentType == ContentType.form) {
      return _urlEncodedMap(part);
    }
    return [_text(part, _json(part.value), fallback: 'application/json')];
  }

  List<MultipartEmission> _object(_Part part) {
    final encoding = part.encoding;
    if (encoding.style == EncodingStyle.deepObject) {
      final entries = part.value
          .property('toDeepObject')
          .call(
            [specLiteralString(part.name)],
            {
              'explode': literalTrue,
              'allowEmpty': literalTrue,
              if (!_dio && (encoding.allowReserved ?? false))
                'allowReserved': literalTrue,
            },
          );
      return _loop('entry', entries, [
        _text(
          part,
          refer('entry').property('value'),
          name: refer('entry').property('name'),
          field: _dio,
          omitContentType: _dio,
          contentType: 'application/x-www-form-urlencoded',
        ),
      ]);
    }
    if (encoding.isStyleBased) {
      if (encoding.style != EncodingStyle.form &&
          (!_dio || encoding.style != null)) {
        return _error(
          '${encoding.style?.name ?? 'unknown'} style is not '
          'supported for object multipart part ${part.name}',
        );
      }
      final entries =
          (part.isMergedObjectProperties
                  ? part.value
                  : part.value.property('parameterProperties').call([], {
                      'allowEmpty': literalTrue,
                    }))
              .property('toRawStyleParts')
              .call(
                [specLiteralString(part.name)],
                {'explode': literalBool(encoding.explode ?? true)},
              );
      final variable = _dio ? r'_$part' : 'entry';
      final partsVariable = '${part.normalizedName}RawParts';
      return [
        if (_dio)
          MultipartCode(declareFinal(partsVariable).assign(entries).statement),
        ..._loop(variable, _dio ? refer(partsVariable) : entries, [
          _text(
            part,
            refer(variable).property('value'),
            name: refer(variable).property('name'),
            omitContentType: _dio,
            contentType: 'text/plain',
          ),
        ]),
      ];
    }
    if (encoding.contentType == ContentType.form) {
      final entries = part.value
          .property('toForm')
          .call(
            [specLiteralString(part.name)],
            {
              'explode': literalTrue,
              'allowEmpty': literalTrue,
              'useQueryComponent': literalTrue,
              'textEncoding': textEncodingExpression(encoding.textEncoding),
            },
          );
      final variable = '${part.normalizedName}Entries';
      final joined = (_dio ? refer(variable) : entries)
          .property('map')
          .call([
            Method(
              (b) => b
                ..lambda = true
                ..requiredParameters.add(
                  Parameter((p) => p..name = _dio ? 'e' : 'entry'),
                )
                ..body = _dio
                    ? const Code(r"'${e.name}=${e.value}'")
                    : const Code(r"'${entry.name}=${entry.value}'"),
            ).closure,
          ])
          .property('join')
          .call([literalString('&')]);
      return [
        if (_dio)
          MultipartCode(declareFinal(variable).assign(entries).statement),
        _text(part, joined, fallback: 'application/x-www-form-urlencoded'),
      ];
    }
    return [
      _text(
        part,
        _json(
          part.isMergedObject
              ? part.value
              : part.value.property('toJson').call([]),
        ),
        fallback: 'application/json',
      ),
    ];
  }

  List<MultipartEmission> _urlEncodedMap(_Part part) {
    final encoding = textEncodingExpression(part.encoding.textEncoding);
    final variable = '${part.normalizedName}Parts';
    return [
      MultipartCode(
        declareFinal(
          variable,
        ).assign(literalList([], refer('String', 'dart:core'))).statement,
      ),
      MultipartCode(
        Block.of([
          const Code('for (final entry in ('),
          part.value.asA(refer('Map', 'dart:core')).code,
          const Code(').entries) {'),
          declareFinal(
            'value',
          ).assign(refer('entry').property('value')).statement,
          const Code('if (value == null) continue; if (value is '),
          refer('Map', 'dart:core').code,
          const Code(' || value is '),
          refer('List', 'dart:core').code,
          const Code(') { throw '),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart').code,
          Code(
            "('Standard URL encoding does not support nested values "
            "(property: ' ${specLiteralStringCode(part.name)} "
            r"', key: ${entry.key}). "
            "Only flat key=value pairs are allowed.');}",
          ),
          refer(variable).property('add').call([
            literalList([
              refer('entry')
                  .property('key')
                  .property('toString')
                  .call([])
                  .property('uriEncode')
                  .call([], {
                    'allowEmpty': literalTrue,
                    'useQueryComponent': literalTrue,
                    'textEncoding': encoding,
                  }),
              refer(
                'encodeAnyToForm',
                'package:tonik_util/tonik_util.dart',
              ).call(
                [refer('value')],
                {
                  'explode': literalTrue,
                  'allowEmpty': literalTrue,
                  'useQueryComponent': literalTrue,
                  'textEncoding': encoding,
                },
              ),
            ]).property('join').call([literalString('=')]),
          ]).statement,
          const Code('}'),
        ]),
      ),
      _text(
        part,
        refer(variable).property('join').call([literalString('&')]),
        fallback: 'application/x-www-form-urlencoded',
      ),
    ];
  }

  Expression? _headers(
    PartEncoding? encoding,
    String normalizedName,
    List<MultipartHeaderParamInfo> parameters,
    bool nullable,
    List<MultipartEmission> emissions,
  ) {
    final headers = encoding?.headers?.entries
        .where((entry) => entry.key.toLowerCase() != 'content-type')
        .toList();
    if (headers == null || headers.isEmpty) return null;
    final variable = '_\$${normalizedName}Headers';
    emissions.add(
      MultipartCode(
        declareFinal(variable)
            .assign(
              literalMap(
                {},
                refer('String', 'dart:core'),
                _dio
                    ? TypeReference(
                        (b) => b
                          ..symbol = 'List'
                          ..url = 'dart:core'
                          ..types.add(refer('String', 'dart:core')),
                      )
                    : refer('String', 'dart:core'),
              ),
            )
            .statement,
      ),
    );
    for (final entry in headers) {
      final header = entry.value.resolve();
      final parameter = parameters.firstWhere(
        (parameter) =>
            parameter.normalizedPropertyName == normalizedName &&
            parameter.rawHeaderName == entry.key,
      );
      final parameterValue = nullable && header.isRequired
          ? refer(parameter.name).nullChecked
          : refer(parameter.name);
      final serialized = buildSimpleValueExpression(
        parameterValue,
        header.model,
        explode: header.explode,
        allowEmpty: true,
      );
      final assignment = refer(variable)
          .index(specLiteralString(entry.key))
          .assign(
            _dio
                ? literalList([serialized.expression])
                : serialized.unsafeRawBody,
          )
          .statement;
      emissions.add(
        MultipartCode(
          header.isRequired
              ? assignment
              : Block.of([
                  Code('if (${parameter.name} != null) {'),
                  assignment,
                  const Code('}'),
                ]),
        ),
      );
    }
    return refer(variable);
  }

  PartEncoding _resolveEncoding(PartEncoding? encoding, Model model) {
    if (encoding?.isStyleBased ?? false) return encoding!;
    final defaultType = _defaultContentType(model, <Model>{});
    final contentType = encoding?.contentType ?? defaultType;
    final rawContentType =
        encoding?.rawContentType ??
        switch (contentType) {
          ContentType.json => 'application/json',
          ContentType.bytes => 'application/octet-stream',
          _ => 'text/plain',
        };
    return PartEncoding(
      contentType: contentType,
      rawContentType: rawContentType,
      wireContentType: encoding?.wireContentType ?? rawContentType,
      textEncoding: encoding?.textEncoding ?? TextEncoding.utf8,
      headers: encoding?.headers,
      style: null,
      explode: null,
      allowReserved: null,
    );
  }

  ContentType _defaultContentType(Model model, Set<Model> active) {
    if (!active.add(model)) return ContentType.json;
    try {
      return switch (model) {
        AliasModel() => _defaultContentType(model.model, active),
        ListModel() => _defaultContentType(model.content, active),
        BinaryModel() || Base64Model() => ContentType.bytes,
        ClassModel() ||
        AllOfModel() ||
        OneOfModel() ||
        AnyOfModel() ||
        AnyModel() ||
        MapModel() => ContentType.json,
        _ => ContentType.text,
      };
    } finally {
      active.remove(model);
    }
  }

  void _validateCompatibleDefinitions(MultipartPropertyPlan property) {
    final first = property.properties.first.model;
    for (final candidate in property.properties.skip(1)) {
      if (!_compatibleModels(first, candidate.model, <(Model, Model)>{})) {
        throw ArgumentError(
          'Multipart property "${property.rawName}" has incompatible '
          'definitions (${first.runtimeType} and '
          '${candidate.model.runtimeType}).',
        );
      }
    }
  }

  bool _compatibleModels(Model left, Model right, Set<(Model, Model)> active) {
    if (identical(left, right)) return true;
    final pair = (left, right);
    if (!active.add(pair)) return true;
    try {
      if (left is AliasModel) {
        return _compatibleModels(left.model, right, active);
      }
      if (right is AliasModel) {
        return _compatibleModels(left, right.model, active);
      }
      if (left is ListModel && right is ListModel) {
        return left.isContentNullable == right.isContentNullable &&
            _compatibleModels(left.content, right.content, active);
      }
      if (left is MapModel && right is MapModel) {
        return left.isValueNullable == right.isValueNullable &&
            _compatibleModels(left.valueModel, right.valueModel, active);
      }
      final leftObject = left is ClassModel || left is AllOfModel;
      final rightObject = right is ClassModel || right is AllOfModel;
      if (leftObject && rightObject) {
        if (!_compatibleAdditionalProperties(left, right, active)) {
          return false;
        }
        final leftProperties = _objectProperties(left, <Model>{});
        final rightProperties = _objectProperties(right, <Model>{});
        final overlapping = leftProperties.keys.toSet().intersection(
          rightProperties.keys.toSet(),
        );
        for (final name in overlapping) {
          for (final leftProperty in leftProperties[name]!) {
            for (final rightProperty in rightProperties[name]!) {
              final leftNullable =
                  leftProperty.isNullable ||
                  multipartModelIsNullable(leftProperty.model);
              final rightNullable =
                  rightProperty.isNullable ||
                  multipartModelIsNullable(rightProperty.model);
              if (leftNullable != rightNullable ||
                  !_compatibleModels(
                    leftProperty.model,
                    rightProperty.model,
                    active,
                  )) {
                return false;
              }
            }
          }
        }
        return true;
      }
      if (left is EnumModel && right is EnumModel) {
        // Distinct named enums generate distinct Dart types. Comparing their
        // instances dynamically would therefore reject even equal wire values.
        return false;
      }
      return left.runtimeType == right.runtimeType;
    } finally {
      active.remove(pair);
    }
  }

  bool _compatibleAdditionalProperties(
    Model left,
    Model right,
    Set<(Model, Model)> active,
  ) {
    final leftPolicy = _effectiveExplicitAdditionalProperties(left);
    final rightPolicy = _effectiveExplicitAdditionalProperties(right);
    if (leftPolicy == null || rightPolicy == null) return true;
    if (leftPolicy is ForbiddenAdditionalProperties ||
        rightPolicy is ForbiddenAdditionalProperties) {
      return leftPolicy is ForbiddenAdditionalProperties &&
          rightPolicy is ForbiddenAdditionalProperties;
    }
    final leftAllowed = leftPolicy as AllowedAdditionalProperties;
    final rightAllowed = rightPolicy as AllowedAdditionalProperties;
    return multipartModelIsNullable(leftAllowed.valueModel) ==
            multipartModelIsNullable(rightAllowed.valueModel) &&
        _compatibleModels(
          leftAllowed.valueModel,
          rightAllowed.valueModel,
          active,
        );
  }
}

AdditionalPropertiesPolicy? _effectiveExplicitAdditionalProperties(
  Model model,
) {
  final policy = switch (model) {
    ClassModel(:final additionalPropertiesPolicy) => additionalPropertiesPolicy,
    AllOfModel(:final additionalPropertiesPolicy) => additionalPropertiesPolicy,
    _ => null,
  };
  return switch (policy) {
    AllowedAdditionalProperties(
      origin: AdditionalPropertiesOrigin.implicitDefault,
    ) =>
      null,
    _ => policy,
  };
}

Map<String, List<Property>> _objectProperties(Model model, Set<Model> active) {
  if (!active.add(model)) return const {};
  try {
    switch (model) {
      case AliasModel():
        return _objectProperties(model.model, active);
      case ClassModel():
        final result = <String, List<Property>>{};
        for (final property in model.properties) {
          (result[property.name] ??= []).add(property);
        }
        return result;
      case AllOfModel():
        final result = <String, List<Property>>{};
        for (final member in model.models) {
          for (final entry in _objectProperties(member, active).entries) {
            (result[entry.key] ??= []).addAll(entry.value);
          }
        }
        return result;
      default:
        return const {};
    }
  } finally {
    active.remove(model);
  }
}

typedef _Part = ({
  String name,
  String normalizedName,
  Expression value,
  PartEncoding encoding,
  Expression? headers,
  bool isMergedObject,
  bool isMergedObjectProperties,
});

_Part _withValue(_Part part, Expression value) => (
  name: part.name,
  normalizedName: part.normalizedName,
  value: value,
  encoding: part.encoding,
  headers: part.headers,
  isMergedObject: part.isMergedObject,
  isMergedObjectProperties: part.isMergedObjectProperties,
);

Expression _objectMergeValue(
  Expression value, {
  required bool nullable,
  required bool asProperties,
}) {
  final member = asProperties ? 'parameterProperties' : 'toJson';
  return nullable
      ? value
            .nullSafeProperty(member)
            .call([], asProperties ? {'allowEmpty': literalTrue} : const {})
      : value
            .property(member)
            .call([], asProperties ? {'allowEmpty': literalTrue} : const {});
}

Expression _immutableMergeValue(Expression value, {required bool nullable}) =>
    nullable ? value.nullSafeProperty('unlock') : value.property('unlock');

Expression _access(Expression root, List<MultipartAccessSegment> path) {
  var result = root;
  for (final segment in path) {
    result = segment.receiverNullable
        ? result.nullSafeProperty(segment.name)
        : result.property(segment.name);
  }
  return result;
}

bool _occurrenceIsNullable(
  List<MultipartAccessSegment> path,
  Property property,
) =>
    path.any((segment) => segment.receiverNullable) ||
    property.isNullable ||
    multipartModelIsNullable(property.model) ||
    !property.isRequired ||
    property.isWriteOnly;

Expression _json(Expression value) =>
    refer('jsonEncode', 'dart:convert').call([value]);
Expression _anyJson(Expression value) => refer(
  'encodeAnyToJson',
  'package:tonik_util/tonik_util.dart',
).call([value]);
Expression _mapped(
  Expression value,
  Expression item, {
  String variable = 'item',
}) => value
    .property('map')
    .call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p..name = variable))
          ..body = item.code,
      ).closure,
    ])
    .property('toList')
    .call([]);

List<MultipartEmission> _error(String message) => [
  MultipartCode(
    generateEncodingExceptionExpression(message, raw: true).statement,
  ),
];

List<MultipartEmission> _loop(
  String variable,
  Expression values,
  List<MultipartEmission> body,
) => [
  MultipartCode(
    Block.of([
      Code('for (final $variable in '),
      values.code,
      const Code(') {'),
    ]),
  ),
  ...body,
  const MultipartCode(Code('}')),
];
