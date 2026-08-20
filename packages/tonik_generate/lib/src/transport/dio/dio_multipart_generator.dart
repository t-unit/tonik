import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/text_encoding_expression.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Lowers a multipart request plan to Dio FormData construction statements.
BuiltStatements buildMultipartBodyStatements(
  RequestContent content,
  String bodyAccessor,
  NameManager nameManager,
  String package, {
  List<MultipartHeaderParamInfo>? headerParameters,
}) {
  return BuiltStatements.simple(
    _buildMultipartFields(
      content,
      bodyAccessor,
      nameManager,
      package,
      headerParameters: headerParameters,
    ),
  );
}

/// Builds an IIFE producing a FormData instance:
/// `() { final formData = FormData(); ...; return formData; }()`.
/// For use in multi-content switch arms.
BuiltExpression buildMultipartBodyExpression(
  RequestContent content,
  String bodyAccessor,
  NameManager nameManager,
  String package, {
  List<MultipartHeaderParamInfo>? headerParameters,
}) {
  final statements = _buildMultipartFields(
    content,
    bodyAccessor,
    nameManager,
    package,
    headerParameters: headerParameters,
  );

  return BuiltExpression.simple(
    Method(
      (b) => b
        ..modifier = MethodModifier.async
        ..lambda = false
        ..body = Block.of(statements),
    ).closure.call([]).awaited,
  );
}

List<Code> _buildMultipartFields(
  RequestContent content,
  String bodyAccessor,
  NameManager nameManager,
  String package, {
  List<MultipartHeaderParamInfo>? headerParameters,
}) {
  final statements = <Code>[];

  // Resolve through alias chains.
  final model = content.model.resolved;

  // Non-ClassModel: generate runtime UnsupportedError.
  if (model is! ClassModel) {
    statements.add(
      refer('UnsupportedError', 'dart:core')
          .call([
            literalString(
              'Multipart request bodies require an object schema '
              '(ClassModel). Got: ${model.runtimeType}.',
            ),
          ])
          .thrown
          .statement,
    );
    return statements;
  }

  // FormData construction.
  statements.add(
    declareFinal(
      r'_$formData',
    ).assign(refer('FormData', 'package:dio/dio.dart').call([])).statement,
  );

  // Filter out readOnly properties.
  final writeProperties = model.properties.where((p) => !p.isReadOnly).toList();

  final normalizedProps = normalizeProperties(writeProperties);
  final normalizedHeaderParameters =
      headerParameters ?? extractMultipartHeaderParamInfo(content);

  for (final (:normalizedName, :property) in normalizedProps) {
    final rawName = property.name;
    final isNullable = property.isNullable || !property.isRequired;

    final fieldCode = _buildFieldCode(
      property.model,
      rawName,
      bodyAccessor,
      normalizedName,
      isNullable,
      encoding: content.multipartEncoding?[property],
      headerParameters: normalizedHeaderParameters,
    );

    if (fieldCode == null) continue;

    if (isNullable) {
      statements
        ..add(Code('if ($bodyAccessor.$normalizedName != null) {'))
        ..add(fieldCode)
        ..add(const Code('}'));
    } else {
      statements.add(fieldCode);
    }
  }

  statements.add(refer(r'_$formData').returned.statement);

  return statements;
}

Code? _buildFieldCode(
  Model model,
  String rawName,
  String bodyAccessor,
  String normalizedName,
  bool isNullable, {
  required List<MultipartHeaderParamInfo> headerParameters,
  PartEncoding? encoding,
}) {
  final accessor = '$bodyAccessor.$normalizedName${isNullable ? '!' : ''}';
  final contentType = encoding?.contentType;
  final rawContentType = encoding?.rawContentType;
  final wireContentType = encoding?.wireContentType;
  final textEncoding = encoding?.textEncoding ?? TextEncoding.utf8;
  // Style-based primitives serialize as plain strings.
  final effectiveWireContentType =
      wireContentType ?? rawContentType ?? 'text/plain';

  final headerResult = _buildHeaderMapStatements(
    normalizedName,
    encoding,
    headerParameters: headerParameters,
    isPropertyOptional: isNullable,
  );

  var resolved = model;
  if (resolved is AliasModel) {
    resolved = resolved.resolved;
  }

  final headerVarName = headerResult?.headerVarName;

  final fieldCode = switch (resolved) {
    StringModel() => _buildStringFileAddition(
      rawName,
      accessor,
      wireContentType: effectiveWireContentType,
      textEncoding: textEncoding,
      headerVarName: headerVarName,
    ),
    AnyModel() => _buildAnyModelFileAddition(
      rawName,
      accessor,
      wireContentType: wireContentType ?? rawContentType ?? 'application/json',
      textEncoding: textEncoding,
      headerVarName: headerVarName,
    ),
    NeverModel() => generateEncodingExceptionExpression(
      "Cannot encode NeverModel property '$rawName' "
      '- this type does not permit any value.',
      raw: true,
    ).statement,

    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() =>
      contentType == ContentType.json
          ? _buildJsonEncodeFileAddition(
              rawName,
              accessor,
              wireContentType: effectiveWireContentType,
              textEncoding: textEncoding,
              headerVarName: headerVarName,
            )
          : _buildPrimitiveFileAddition(
              rawName,
              accessor,
              wireContentType: effectiveWireContentType,
              textEncoding: textEncoding,
              serializerMethod: 'toString',
              headerVarName: headerVarName,
            ),

    DateTimeModel() =>
      contentType == ContentType.json
          ? _buildJsonEncodeFileAddition(
              rawName,
              accessor,
              wireContentType: effectiveWireContentType,
              textEncoding: textEncoding,
              headerVarName: headerVarName,
            )
          : _buildPrimitiveFileAddition(
              rawName,
              accessor,
              wireContentType: effectiveWireContentType,
              textEncoding: textEncoding,
              serializerMethod: 'toTimeZonedIso8601String',
              headerVarName: headerVarName,
            ),

    EnumModel() => _buildEnumFileAddition(
      rawName,
      accessor,
      resolved,
      wireContentType: effectiveWireContentType,
      textEncoding: textEncoding,
      headerVarName: headerVarName,
    ),

    BinaryModel() || Base64Model() => _buildBinaryFileAddition(
      rawName,
      accessor,
      encoding: encoding,
      headerVarName: headerVarName,
    ),

    MapModel() => _buildMapModelFileAddition(
      rawName,
      accessor,
      propertyEncoding: encoding,
      headerVarName: headerVarName,
    ),

    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildComplexObjectFileAddition(
      rawName,
      accessor,
      propertyEncoding: encoding,
      headerVarName: headerVarName,
    ),

    ListModel() => _buildListFieldAddition(
      rawName,
      accessor,
      resolved,
      propertyEncoding: encoding,
      headerVarName: headerVarName,
    ),

    // AliasModel is already resolved above, so recurse for any other alias.
    AliasModel() => _buildFieldCode(
      resolved,
      rawName,
      bodyAccessor,
      normalizedName,
      isNullable,
      encoding: encoding,
      headerParameters: headerParameters,
    ),

    _ => generateEncodingExceptionExpression(
      'Unsupported model type for multipart encoding.',
    ).statement,
  };

  if (fieldCode == null) return null;
  if (headerResult == null) return fieldCode;

  return Block.of([...headerResult.statements, fieldCode]);
}

/// Result of building per-part header map statements.
class _HeaderMapResult {
  const _HeaderMapResult(this.statements, this.headerVarName);
  final List<Code> statements;
  final String headerVarName;
}

/// Builds the header map variable declaration and entry addition statements
/// for a multipart property's per-part headers.
///
/// Returns `null` if there are no non-Content-Type headers.
_HeaderMapResult? _buildHeaderMapStatements(
  String normalizedPropertyName,
  PartEncoding? encoding, {
  required List<MultipartHeaderParamInfo> headerParameters,
  bool isPropertyOptional = false,
}) {
  final headers = encoding?.headers;
  if (headers == null || headers.isEmpty) return null;

  // Filter out Content-Type (case-insensitive) per OAS spec.
  final filteredEntries = headers.entries
      .where((e) => e.key.toLowerCase() != 'content-type')
      .toList();

  if (filteredEntries.isEmpty) return null;

  final headerVarName = '_\$${normalizedPropertyName}Headers';
  final statements = <Code>[
    // Declare the headers map.
    declareFinal(headerVarName)
        .assign(
          literalMap(
            {},
            refer('String', 'dart:core'),
            TypeReference(
              (b) => b
                ..symbol = 'List'
                ..url = 'dart:core'
                ..types.add(refer('String', 'dart:core')),
            ),
          ),
        )
        .statement,
  ];

  for (final entry in filteredEntries) {
    final rawHeaderName = entry.key;
    final header = entry.value.resolve();
    final paramName = headerParameters
        .firstWhere(
          (parameter) =>
              parameter.normalizedPropertyName == normalizedPropertyName &&
              parameter.rawHeaderName == rawHeaderName,
        )
        .name;

    // When the property is optional, required header params are nullable
    // at the method level but must be non-null here.
    final paramRef = isPropertyOptional && header.isRequired
        ? refer(paramName).nullChecked
        : refer(paramName);

    final serializeExpr = buildSimpleValueExpression(
      paramRef,
      header.model,
      explode: header.explode,
      allowEmpty: true,
    );

    final assignStatement = refer(headerVarName)
        .index(specLiteralString(rawHeaderName))
        .assign(literalList([serializeExpr.expression]))
        .statement;

    if (!header.isRequired) {
      // Wrap optional header in null check.
      statements
        ..add(Code('if ($paramName != null) {'))
        ..add(assignStatement)
        ..add(const Code('}'));
    } else {
      statements.add(assignStatement);
    }
  }

  return _HeaderMapResult(statements, headerVarName);
}

/// Builds a string field with its semantically selected byte encoding.
Code _buildStringFileAddition(
  String rawName,
  String accessor, {
  required String? wireContentType,
  required TextEncoding textEncoding,
  String? headerVarName,
}) => refer(r'_$formData').property('files').property('add').call([
  refer('MapEntry', 'dart:core').call([
    specLiteralString(rawName),
    _textMultipartFile(
      refer(accessor),
      wireContentType: wireContentType,
      textEncoding: textEncoding,
      headerVarName: headerVarName,
    ),
  ]),
]).statement;

/// Builds a primitive field with its semantically selected byte encoding.
Code _buildPrimitiveFileAddition(
  String rawName,
  String accessor, {
  required String? wireContentType,
  required TextEncoding textEncoding,
  required String serializerMethod,
  String? headerVarName,
}) => refer(r'_$formData').property('files').property('add').call([
  refer('MapEntry', 'dart:core').call([
    specLiteralString(rawName),
    _textMultipartFile(
      refer(accessor).property(serializerMethod).call([]),
      wireContentType: wireContentType,
      textEncoding: textEncoding,
      headerVarName: headerVarName,
    ),
  ]),
]).statement;

/// Builds an enum field with its semantically selected byte encoding.
Code _buildEnumFileAddition(
  String rawName,
  String accessor,
  EnumModel<dynamic> model, {
  required String? wireContentType,
  required TextEncoding textEncoding,
  String? headerVarName,
}) {
  final toJsonCall = refer(accessor).property('toJson').call([]);
  final valueExpr = model is EnumModel<String>
      ? toJsonCall
      : toJsonCall.property('toString').call([]);

  return refer(r'_$formData').property('files').property('add').call(
    [
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        _textMultipartFile(
          valueExpr,
          wireContentType: wireContentType,
          textEncoding: textEncoding,
          headerVarName: headerVarName,
        ),
      ]),
    ],
  ).statement;
}

/// Builds a JSON-encoded field with its semantically selected byte encoding.
Code _buildJsonEncodeFileAddition(
  String rawName,
  String accessor, {
  required String? wireContentType,
  required TextEncoding textEncoding,
  String? headerVarName,
}) {
  return refer(
    r'_$formData',
  ).property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      _textMultipartFile(
        refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
        wireContentType: wireContentType,
        textEncoding: textEncoding,
        headerVarName: headerVarName,
      ),
    ]),
  ]).statement;
}

/// Builds an AnyModel field as MultipartFile.fromString using encodeAnyToJson
/// for runtime-safe serialization of unknown types.
Code _buildAnyModelFileAddition(
  String rawName,
  String accessor, {
  required String? wireContentType,
  required TextEncoding textEncoding,
  String? headerVarName,
}) {
  return refer(r'_$formData').property('files').property('add').call(
    [
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        _textMultipartFile(
          refer('jsonEncode', 'dart:convert').call([
            refer(
              'encodeAnyToJson',
              'package:tonik_util/tonik_util.dart',
            ).call([refer(accessor)]),
          ]),
          wireContentType: wireContentType,
          textEncoding: textEncoding,
          headerVarName: headerVarName,
        ),
      ]),
    ],
  ).statement;
}

Expression _textMultipartFile(
  Expression text, {
  required String? wireContentType,
  required TextEncoding textEncoding,
  String? headerVarName,
}) {
  final namedArguments = <String, Expression>{
    if (wireContentType != null)
      'contentType': refer(
        'DioMediaType',
        'package:dio/dio.dart',
      ).property('parse').call([specLiteralString(wireContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };
  final multipartFile = refer('MultipartFile', 'package:dio/dio.dart');
  if (textEncoding == TextEncoding.utf8) {
    return multipartFile.property('fromString').call([text], namedArguments);
  }
  final bytes = textEncodingExpression(
    textEncoding,
  ).property('encode').call([text]);
  return multipartFile.property('fromBytes').call([
    bytes,
  ], namedArguments);
}

Code _buildBinaryFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? encoding,
  String? headerVarName,
}) {
  final rawContentType = encoding?.wireContentType ?? encoding?.rawContentType;
  final isDefaultContentType =
      rawContentType == null || rawContentType == 'application/octet-stream';

  return _binaryFileSwitch(
    refer(accessor),
    rawName,
    rawContentType: isDefaultContentType ? null : rawContentType,
    headerVarName: headerVarName,
  );
}

Code _buildListFieldAddition(
  String rawName,
  String accessor,
  ListModel listModel, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  final style = propertyEncoding?.style;
  final contentType = propertyEncoding?.contentType;

  // deepObject is not supported for arrays.
  if (style == EncodingStyle.deepObject) {
    return generateEncodingExceptionExpression(
      'deepObject style is not supported for array '
      'multipart properties (property: $rawName).',
      raw: true,
    ).statement;
  }

  // Resolve content model through aliases.
  var contentModel = listModel.content;
  if (contentModel is AliasModel) {
    contentModel = contentModel.resolved;
  }

  // Binary and complex objects always use a for-loop (can't be delimited).
  if (contentModel is BinaryModel || contentModel is Base64Model) {
    return _buildBinaryListForLoop(
      rawName,
      accessor,
      headerVarName: headerVarName,
    );
  }

  // Explicit application/json → single JSON blob (content-based).
  // Unsupported explicit types (e.g. form) → content-based handler throws.
  // null / text/plain → fall through to for-loop (one part per element).
  final isStyleBased = propertyEncoding?.isStyleBased ?? false;
  if (!isStyleBased && contentType != null && contentType != ContentType.text) {
    return _buildContentBasedListAddition(
      rawName,
      accessor,
      contentModel,
      propertyEncoding: propertyEncoding,
      headerVarName: headerVarName,
    );
  }

  if (contentModel is ClassModel ||
      contentModel is AllOfModel ||
      contentModel is OneOfModel ||
      contentModel is AnyOfModel) {
    return _buildListForLoop(
      rawName,
      refer(accessor),
      _complexItemExpr(
        rawName,
        encoding: propertyEncoding,
        headerVarName: headerVarName,
      ),
      isFile: true,
    );
  }

  // For text-serializable types, build the item-to-string expression
  // and decide whether to go through an encoder.
  final textEncoding = propertyEncoding?.textEncoding ?? TextEncoding.utf8;
  final itemExpr = _itemToStringExpr(
    contentModel,
    contentType: contentType,
    textEncoding: textEncoding,
  );
  final isIdentity = contentModel is StringModel;

  final explode = propertyEncoding?.explode ?? true;

  if (explode) {
    if (headerVarName != null || textEncoding != TextEncoding.utf8) {
      final fileItemExpr = _textMultipartFile(
        itemExpr,
        wireContentType:
            textEncoding == TextEncoding.utf8 &&
                (propertyEncoding?.isStyleBased ?? false)
            ? null
            : propertyEncoding?.wireContentType ??
                  propertyEncoding?.rawContentType,
        textEncoding: textEncoding,
        headerVarName: headerVarName,
      );
      return _buildListForLoop(
        rawName,
        refer(accessor),
        fileItemExpr,
        isFile: true,
      );
    }

    return _buildListForLoop(
      rawName,
      refer(accessor),
      itemExpr,
      isFile: false,
    );
  }

  return _buildNonExplodedListAddition(
    rawName,
    accessor,
    itemExpr,
    needsMapping: !isIdentity,
    style: style,
    propertyEncoding: propertyEncoding,
    headerVarName: headerVarName,
  );
}

/// Builds a single multipart file part for a non-binary array in content-based
/// mode (no style/explode/allowReserved set).
///
/// Serializes the whole list as JSON via `jsonEncode`, applying any necessary
/// per-element mapping first (e.g. `.toJson()` for complex objects,
/// `.toTimeZonedIso8601String()` for DateTime, `.uriEncode()` for enums).
Code _buildContentBasedListAddition(
  String rawName,
  String accessor,
  Model contentModel, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  // Array-of-arrays is not supported: the spec recurses into items but there
  // is no meaningful single-part serialization for nested lists.
  if (contentModel is ListModel) {
    return generateEncodingExceptionExpression(
      'Arrays of arrays are not supported for multipart encoding '
      '(property: $rawName).',
      raw: true,
    ).statement;
  }

  // Only application/json and text/plain are supported for content-based array
  // serialization. text/plain is promoted to application/json (the OAS spec
  // does not define how to serialize an array as a single text/plain part).
  // ContentType.bytes covers AnyModel defaults and falls through to JSON.
  final explicitContentType = propertyEncoding?.contentType;
  if (explicitContentType != null &&
      explicitContentType != ContentType.json &&
      explicitContentType != ContentType.text &&
      explicitContentType != ContentType.bytes) {
    final explicitRaw = propertyEncoding?.rawContentType ?? '';
    return generateEncodingExceptionExpression(
      'Unsupported contentType "$explicitRaw" for array multipart '
      'property "$rawName". Only application/json is supported for '
      'content-based array serialization.',
      raw: true,
    ).statement;
  }

  final wireContentType =
      propertyEncoding?.wireContentType ?? 'application/json';
  final textEncoding = propertyEncoding?.textEncoding ?? TextEncoding.utf8;

  final Expression jsonArg;
  if (contentModel is ClassModel ||
      contentModel is AllOfModel ||
      contentModel is OneOfModel ||
      contentModel is AnyOfModel) {
    // Complex objects: map each item to its JSON representation first.
    jsonArg = refer(accessor)
        .property('map')
        .call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'e'))
              ..body = refer('e').property('toJson').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  } else if (contentModel is DateTimeModel) {
    // DateTime: map each item to its ISO 8601 string representation.
    jsonArg = refer(accessor)
        .property('map')
        .call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'e'))
              ..body = refer(
                'e',
              ).property('toTimeZonedIso8601String').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  } else if (contentModel is EnumModel) {
    // Enums: map each item to its JSON representation for JSON-encoded arrays.
    jsonArg = refer(accessor)
        .property('map')
        .call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'e'))
              ..body = refer('e').property('toJson').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  } else {
    // Primitives (String, int, double, bool, etc.) are JSON-serializable
    // directly — pass the list as-is.
    jsonArg = refer(accessor);
  }

  final jsonExpr = refer('jsonEncode', 'dart:convert').call([jsonArg]);

  return refer(r'_$formData').property('files').property('add').call(
    [
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        _textMultipartFile(
          jsonExpr,
          wireContentType: wireContentType,
          textEncoding: textEncoding,
          headerVarName: headerVarName,
        ),
      ]),
    ],
  ).statement;
}

/// Builds a for-loop that iterates [iterableExpr] and adds each item.
Code _buildListForLoop(
  String rawName,
  Expression iterableExpr,
  Expression itemExpression, {
  required bool isFile,
}) {
  final target = isFile ? 'files' : 'fields';
  return Block.of([
    const Code('for (final item in '),
    iterableExpr.code,
    const Code(') {'),
    refer(r'_$formData').property(target).property('add').call([
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        itemExpression,
      ]),
    ]).statement,
    const Code('}'),
  ]);
}

Code _buildNonExplodedListAddition(
  String rawName,
  String accessor,
  Expression itemExpr, {
  required bool needsMapping,
  required EncodingStyle? style,
  required PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  final listExpr = _buildStringListExpr(
    accessor,
    itemExpr,
    needsMapping: needsMapping,
  );

  if (style == EncodingStyle.spaceDelimited ||
      style == EncodingStyle.pipeDelimited) {
    final encoderMethod = style == EncodingStyle.spaceDelimited
        ? 'toSpaceDelimited'
        : 'toPipeDelimited';
    final namedArgs = <String, Expression>{
      'explode': literalFalse,
      'allowEmpty': literalTrue,
      'alreadyEncoded': literalTrue,
      if (style == EncodingStyle.spaceDelimited)
        'percentEncodeDelimiter': literalFalse,
    };
    final iterableExpr = listExpr.property(encoderMethod).call([], namedArgs);
    final textEncoding = propertyEncoding?.textEncoding ?? TextEncoding.utf8;
    final usesFile = headerVarName != null || textEncoding != TextEncoding.utf8;
    final itemValue = usesFile
        ? _textMultipartFile(
            refer('item'),
            wireContentType:
                textEncoding == TextEncoding.utf8 &&
                    (propertyEncoding?.isStyleBased ?? false)
                ? null
                : propertyEncoding?.wireContentType ??
                      propertyEncoding?.rawContentType,
            textEncoding: textEncoding,
            headerVarName: headerVarName,
          )
        : refer('item');
    return _buildListForLoop(
      rawName,
      iterableExpr,
      itemValue,
      isFile: usesFile,
    );
  }

  // Unlike delimited encoders, non-exploded form encoding returns a scalar
  // String, so it represents one multipart part rather than an iterable.
  final valueExpr = listExpr.property('uriEncode').call([], {
    'allowEmpty': literalTrue,
    'alreadyEncoded': literalTrue,
  });
  final textEncoding = propertyEncoding?.textEncoding ?? TextEncoding.utf8;
  final usesFile = headerVarName != null || textEncoding != TextEncoding.utf8;
  final value = usesFile
      ? _textMultipartFile(
          valueExpr,
          wireContentType:
              textEncoding == TextEncoding.utf8 &&
                  (propertyEncoding?.isStyleBased ?? false)
              ? null
              : propertyEncoding?.wireContentType ??
                    propertyEncoding?.rawContentType,
          textEncoding: textEncoding,
          headerVarName: headerVarName,
        )
      : valueExpr;
  final target = usesFile ? 'files' : 'fields';

  return refer(r'_$formData').property(target).property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      value,
    ]),
  ]).statement;
}

/// Builds a for-loop for binary list items, embedding a switch on the
/// sealed `TonikFile` type inside each iteration.
Code _buildBinaryListForLoop(
  String rawName,
  String accessor, {
  String? headerVarName,
}) {
  final switchBody = _binaryItemExpr(rawName, headerVarName: headerVarName);
  return Block.of([
    Code('for (final item in $accessor) {'),
    switchBody,
    const Code('}'),
  ]);
}

/// Returns an [Expression] to serialize a single list item to a string
/// value, based on the content model type and content type.
Expression _itemToStringExpr(
  Model contentModel, {
  ContentType? contentType,
  TextEncoding textEncoding = TextEncoding.utf8,
}) {
  return switch (contentModel) {
    StringModel() => refer('item'),
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() =>
      contentType == ContentType.json
          ? refer('jsonEncode', 'dart:convert').call([
              refer('item'),
            ])
          : refer('item').property('toString').call([]),
    DateTimeModel() =>
      contentType == ContentType.json
          ? refer('jsonEncode', 'dart:convert').call([
              refer('item'),
            ])
          : refer(
              'item',
            ).property('toTimeZonedIso8601String').call([]),
    EnumModel() =>
      textEncoding == TextEncoding.utf8
          ? refer(
              'item',
            ).property('uriEncode').call([], {'allowEmpty': literalTrue})
          : refer('item')
                .property('toForm')
                .call(
                  [literalString('')],
                  {
                    'explode': literalFalse,
                    'allowEmpty': literalTrue,
                    'textEncoding': textEncodingExpression(textEncoding),
                  },
                )
                .property('single')
                .property('value'),
    AliasModel() => _itemToStringExpr(
      contentModel.resolved,
      contentType: contentType,
      textEncoding: textEncoding,
    ),
    _ => refer('item').property('toString').call([]),
  };
}

/// Returns an [Expression] for a binary item in a for-loop.
///
/// Generates a switch on the sealed TonikFile type.
Code _binaryItemExpr(String rawName, {String? headerVarName}) {
  return _binaryFileSwitch(
    refer('item'),
    rawName,
    headerVarName: headerVarName,
  );
}

Code _binaryFileSwitch(
  Expression file,
  String rawName, {
  String? rawContentType,
  String? headerVarName,
}) {
  final multipartFile = refer('MultipartFile', 'package:dio/dio.dart');
  final fileArguments = <String, Expression>{
    'filename': refer(
      'fileName',
    ).ifNullThen(specLiteralString(rawName)),
    if (rawContentType != null)
      'contentType': refer(
        'DioMediaType',
        'package:dio/dio.dart',
      ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };

  Code addFile(Expression value) =>
      refer(r'_$formData').property('files').property('add').call([
        refer('MapEntry', 'dart:core').call([
          specLiteralString(rawName),
          value,
        ]),
      ]).statement;

  return Block.of([
    const Code('switch ('),
    file.code,
    const Code(') {\n'),
    const Code('case '),
    refer(
      'TonikFileBytes',
      'package:tonik_util/tonik_util.dart',
    ).code,
    const Code('(:final bytes, :final fileName):\n'),
    addFile(
      multipartFile.property('fromBytes').call([
        refer('bytes'),
      ], fileArguments),
    ),
    const Code('case '),
    refer(
      'TonikFilePath',
      'package:tonik_util/tonik_util.dart',
    ).code,
    const Code('(:final path, :final fileName):\n'),
    addFile(
      multipartFile.property('fromFile').call([
        refer('path'),
      ], fileArguments).awaited,
    ),
    const Code('}\n'),
  ]);
}

/// Returns an [Expression] for a complex object item in a for-loop.
Expression _complexItemExpr(
  String rawName, {
  PartEncoding? encoding,
  String? headerVarName,
}) {
  return _textMultipartFile(
    refer('jsonEncode', 'dart:convert').call([
      refer('item').property('toJson').call([]),
    ]),
    wireContentType:
        encoding?.wireContentType ??
        encoding?.rawContentType ??
        'application/json',
    textEncoding: encoding?.textEncoding ?? TextEncoding.utf8,
    headerVarName: headerVarName,
  );
}

/// Builds the string-list input used by non-exploded array encoders.
///
/// When [needsMapping] is false, [itemExpr] is ignored.
Expression _buildStringListExpr(
  String accessor,
  Expression itemExpr, {
  required bool needsMapping,
}) {
  if (needsMapping) {
    return refer(accessor)
        .property('map')
        .call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'item'))
              ..body = itemExpr.code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  }
  return refer(accessor);
}

Code _buildDeepObjectFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  final iterableExpr = refer(accessor)
      .property('toDeepObject')
      .call(
        [specLiteralString(rawName)],
        {'explode': literalTrue, 'allowEmpty': literalTrue},
      );

  final textEncoding = propertyEncoding?.textEncoding ?? TextEncoding.utf8;
  if (headerVarName != null || textEncoding != TextEncoding.utf8) {
    // Per-part headers and non-UTF-8 encodings require byte-aware file parts.
    final fileExpr = _textMultipartFile(
      refer('entry').property('value'),
      wireContentType: null,
      textEncoding: textEncoding,
      headerVarName: headerVarName,
    );
    return Block.of([
      const Code('for (final entry in '),
      iterableExpr.code,
      const Code(') {'),
      refer(r'_$formData').property('files').property('add').call([
        refer('MapEntry', 'dart:core').call([
          refer('entry').property('name'),
          fileExpr,
        ]),
      ]).statement,
      const Code('}'),
    ]);
  }

  // Without headers: each bracket-notation entry becomes a plain form field.
  return Block.of([
    const Code('for (final entry in '),
    iterableExpr.code,
    const Code(') {'),
    refer(r'_$formData').property('fields').property('add').call([
      refer('MapEntry', 'dart:core').call([
        refer('entry').property('name'),
        refer('entry').property('value'),
      ]),
    ]).statement,
    const Code('}'),
  ]);
}

/// Builds a multipart file part for a [MapModel] property.
///
/// Maps are directly JSON-serializable and do not have `.toJson()` or
/// `.toDeepObject()` methods. This handler routes encoding correctly:
/// - **deepObject**: throws an `EncodingException` (maps don't implement
///   `ParameterEncodable.toDeepObject()`).
/// - **URL-encoded (`application/x-www-form-urlencoded`)**: iterates map
///   entries directly, encoding each as a flat `key=value` pair. Nested
///   values (`Map` or `List`) throw an `EncodingException` at runtime.
/// - **Default (JSON)**: passes the map directly to `jsonEncode()`.
Code _buildMapModelFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  // deepObject is not supported for plain maps.
  if (propertyEncoding?.style == EncodingStyle.deepObject) {
    return generateEncodingExceptionExpression(
      'deepObject style is not supported for map '
      'multipart properties (property: $rawName). '
      'Maps do not implement ParameterEncodable.toDeepObject().',
      raw: true,
    ).statement;
  }

  // Content-based mode with application/x-www-form-urlencoded → URL-encode
  // the map entries directly (no .toJson() call needed).
  final isStyleBased = propertyEncoding?.isStyleBased ?? false;
  if (!isStyleBased && propertyEncoding?.contentType == ContentType.form) {
    return _buildUrlEncodedMapFileAddition(
      rawName,
      accessor,
      propertyEncoding: propertyEncoding,
      headerVarName: headerVarName,
    );
  }

  // Default: JSON-encode the map directly (maps are natively serializable).
  return refer(
    r'_$formData',
  ).property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      _textMultipartFile(
        refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
        wireContentType:
            propertyEncoding?.wireContentType ??
            propertyEncoding?.rawContentType ??
            'application/json',
        textEncoding: propertyEncoding?.textEncoding ?? TextEncoding.utf8,
        headerVarName: headerVarName,
      ),
    ]),
  ]).statement;
}

/// Builds a URL-encoded (`application/x-www-form-urlencoded`) file part for a
/// [MapModel] property.
///
/// Unlike complex objects (ClassModel, AllOfModel, etc.), maps are already
/// `Map<String, T>` and don't need `.toJson()`. This iterates the map entries
/// directly, encoding each as a flat `key=value` pair. Nested values (`Map` or
/// `List`) throw an `EncodingException` at runtime — standard URL encoding
/// (RFC 3986) does not support nested structures.
Code _buildUrlEncodedMapFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  final propVarName = accessor.split('.').last.replaceAll('!', '');
  final partsVarName = '${propVarName}Parts';

  return Block.of([
    // final <propName>Parts = <String>[];
    declareFinal(partsVarName)
        .assign(
          literalList(
            [],
            refer('String', 'dart:core'),
          ),
        )
        .statement,
    // for (final entry in (<accessor> as Map).entries) {
    const Code('for (final entry in ('),
    refer(accessor).asA(refer('Map', 'dart:core')).code,
    const Code(').entries) {'),
    // final value = entry.value;
    declareFinal(
      'value',
    ).assign(refer('entry').property('value')).statement,
    // if (value == null) continue;
    const Code('if (value == null) continue;'),
    // if (value is Map || value is List) { throw EncodingException(...); }
    const Code('if (value is '),
    refer('Map', 'dart:core').code,
    const Code(' || value is '),
    refer('List', 'dart:core').code,
    const Code(') {'),
    Block.of([
      const Code('throw '),
      refer('EncodingException', 'package:tonik_util/tonik_util.dart').code,
      Code(
        "('Standard URL encoding does not support nested values "
        "(property: ' ${specLiteralStringCode(rawName)} "
        r"', key: ${entry.key}). "
        "Only flat key=value pairs are allowed.');",
      ),
    ]),
    const Code('}'),
    // Add one encoded key/value pair using the value's typed form encoder.
    refer(partsVarName).property('add').call([
      literalList([
        refer('entry')
            .property('key')
            .property('toString')
            .call([])
            .property('uriEncode')
            .call([], {
              'allowEmpty': literalTrue,
              'useQueryComponent': literalTrue,
              if ((propertyEncoding?.textEncoding ?? TextEncoding.utf8) !=
                  TextEncoding.utf8)
                'textEncoding': textEncodingExpression(
                  propertyEncoding!.textEncoding,
                ),
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
            if ((propertyEncoding?.textEncoding ?? TextEncoding.utf8) !=
                TextEncoding.utf8)
              'textEncoding': textEncodingExpression(
                propertyEncoding!.textEncoding,
              ),
          },
        ),
      ]).property('join').call([literalString('=')]),
    ]).statement,
    const Code('}'),
    // _$formData.files.add(MapEntry(...));
    refer(r'_$formData').property('files').property('add').call([
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        _textMultipartFile(
          refer(
            partsVarName,
          ).property('join').call([literalString('&')]),
          wireContentType:
              propertyEncoding?.wireContentType ??
              'application/x-www-form-urlencoded',
          textEncoding: propertyEncoding?.textEncoding ?? TextEncoding.utf8,
          headerVarName: headerVarName,
        ),
      ]),
    ]).statement,
  ]);
}

Code _buildComplexObjectFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  if (propertyEncoding?.style == EncodingStyle.deepObject) {
    return _buildDeepObjectFileAddition(
      rawName,
      accessor,
      propertyEncoding: propertyEncoding,
      headerVarName: headerVarName,
    );
  }

  final isStyleBased = propertyEncoding?.isStyleBased ?? false;

  // Explicit style fields take precedence over contentType.
  if (isStyleBased) {
    final style = propertyEncoding?.style;
    if (style != null && style != EncodingStyle.form) {
      return generateEncodingExceptionExpression(
        '${style.name} style is not supported for object multipart '
        'part $rawName',
        raw: true,
      ).statement;
    }
    return _buildRawStylePartsAddition(
      rawName,
      accessor,
      explode: propertyEncoding?.explode ?? true,
      propertyEncoding: propertyEncoding,
      headerVarName: headerVarName,
    );
  }

  if (propertyEncoding?.contentType == ContentType.form) {
    return _buildUrlEncodedObjectFileAddition(
      rawName,
      accessor,
      propertyEncoding: propertyEncoding,
      headerVarName: headerVarName,
    );
  }

  return refer(r'_$formData').property('files').property('add').call(
    [
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        _textMultipartFile(
          refer(
            'jsonEncode',
            'dart:convert',
          ).call([refer(accessor).property('toJson').call([])]),
          wireContentType:
              propertyEncoding?.wireContentType ??
              propertyEncoding?.rawContentType ??
              'application/json',
          textEncoding: propertyEncoding?.textEncoding ?? TextEncoding.utf8,
          headerVarName: headerVarName,
        ),
      ]),
    ],
  ).statement;
}

Code _buildUrlEncodedObjectFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  final propVarName = accessor.split('.').last.replaceAll('!', '');
  final entriesVarName = '${propVarName}Entries';

  final textEncoding = propertyEncoding?.textEncoding ?? TextEncoding.utf8;
  final joinedBody = refer(entriesVarName)
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..lambda = true
            ..body = refer(r"'${e.name}=${e.value}'").code,
        ).closure,
      ])
      .property('join')
      .call([literalString('&')]);

  return Block.of([
    declareFinal(entriesVarName)
        .assign(
          refer(accessor)
              .property('toForm')
              .call(
                [specLiteralString(rawName)],
                {
                  'explode': literalTrue,
                  'allowEmpty': literalTrue,
                  'useQueryComponent': literalTrue,
                  if (textEncoding != TextEncoding.utf8)
                    'textEncoding': textEncodingExpression(textEncoding),
                },
              ),
        )
        .statement,
    refer(r'_$formData').property('files').property('add').call([
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        _textMultipartFile(
          joinedBody,
          wireContentType:
              propertyEncoding?.wireContentType ??
              'application/x-www-form-urlencoded',
          textEncoding: textEncoding,
          headerVarName: headerVarName,
        ),
      ]),
    ]).statement,
  ]);
}

Code _buildRawStylePartsAddition(
  String rawName,
  String accessor, {
  required bool explode,
  PartEncoding? propertyEncoding,
  String? headerVarName,
}) {
  final propVarName = accessor.split('.').last.replaceAll('!', '');
  final partsVarName = '${propVarName}RawParts';

  return Block.of([
    declareFinal(partsVarName)
        .assign(
          refer(accessor)
              .property('parameterProperties')
              .call([], {'allowEmpty': literalTrue})
              .property('toRawStyleParts')
              .call(
                [specLiteralString(rawName)],
                {'explode': literalBool(explode)},
              ),
        )
        .statement,
    Code('for (final _\$part in $partsVarName) {'),
    refer(r'_$formData').property('files').property('add').call([
      refer('MapEntry', 'dart:core').call([
        refer(r'_$part').property('name'),
        _textMultipartFile(
          refer(r'_$part').property('value'),
          wireContentType: null,
          textEncoding: propertyEncoding?.textEncoding ?? TextEncoding.utf8,
          headerVarName: headerVarName,
        ),
      ]),
    ]).statement,
    const Code('}'),
  ]);
}
