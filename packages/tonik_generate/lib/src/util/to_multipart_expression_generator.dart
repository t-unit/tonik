import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Returns FormData construction statements; caller adds `return formData;`.
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
  // Style-based primitives serialize as plain strings.
  final effectiveRawContentType = rawContentType ?? 'text/plain';

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
      rawContentType: effectiveRawContentType,
      headerVarName: headerVarName,
    ),
    AnyModel() => _buildAnyModelFileAddition(
      rawName,
      accessor,
      rawContentType: rawContentType ?? 'application/json',
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
              rawContentType: effectiveRawContentType,
              headerVarName: headerVarName,
            )
          : _buildPrimitiveFileAddition(
              rawName,
              accessor,
              rawContentType: effectiveRawContentType,
              serializerMethod: 'toString',
              headerVarName: headerVarName,
            ),

    DateTimeModel() =>
      contentType == ContentType.json
          ? _buildJsonEncodeFileAddition(
              rawName,
              accessor,
              rawContentType: effectiveRawContentType,
              headerVarName: headerVarName,
            )
          : _buildPrimitiveFileAddition(
              rawName,
              accessor,
              rawContentType: effectiveRawContentType,
              serializerMethod: 'toTimeZonedIso8601String',
              headerVarName: headerVarName,
            ),

    EnumModel() => _buildEnumFileAddition(
      rawName,
      accessor,
      resolved,
      rawContentType: effectiveRawContentType,
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

/// Builds a string field as MultipartFile.fromString with explicit contentType.
Code _buildStringFileAddition(
  String rawName,
  String accessor, {
  required String rawContentType,
  String? headerVarName,
}) {
  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };
  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call([refer(accessor)], namedArgs),
    ]),
  ]).statement;
}

/// Builds a primitive field as MultipartFile.fromString with explicit
/// contentType.
Code _buildPrimitiveFileAddition(
  String rawName,
  String accessor, {
  required String rawContentType,
  required String serializerMethod,
  String? headerVarName,
}) {
  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };
  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call(
        [refer(accessor).property(serializerMethod).call([])],
        namedArgs,
      ),
    ]),
  ]).statement;
}

/// Builds an enum field as MultipartFile.fromString with explicit contentType.
Code _buildEnumFileAddition(
  String rawName,
  String accessor,
  EnumModel<dynamic> model, {
  required String rawContentType,
  String? headerVarName,
}) {
  final toJsonCall = refer(accessor).property('toJson').call([]);
  final valueExpr = model is EnumModel<String>
      ? toJsonCall
      : toJsonCall.property('toString').call([]);

  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };
  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call([valueExpr], namedArgs),
    ]),
  ]).statement;
}

/// Builds a json-encoded field as MultipartFile.fromString with explicit
/// contentType.
Code _buildJsonEncodeFileAddition(
  String rawName,
  String accessor, {
  required String rawContentType,
  String? headerVarName,
}) {
  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };
  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call(
        [
          refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
        ],
        namedArgs,
      ),
    ]),
  ]).statement;
}

/// Builds an AnyModel field as MultipartFile.fromString using encodeAnyToJson
/// for runtime-safe serialization of unknown types.
Code _buildAnyModelFileAddition(
  String rawName,
  String accessor, {
  required String rawContentType,
  String? headerVarName,
}) {
  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };
  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call(
        [
          refer('jsonEncode', 'dart:convert').call([
            refer(
              'encodeAnyToJson',
              'package:tonik_util/tonik_util.dart',
            ).call([refer(accessor)]),
          ]),
        ],
        namedArgs,
      ),
    ]),
  ]).statement;
}

Code _buildBinaryFileAddition(
  String rawName,
  String accessor, {
  PartEncoding? encoding,
  String? headerVarName,
}) {
  final rawContentType = encoding?.rawContentType;
  final isDefaultContentType =
      rawContentType == null || rawContentType == 'application/octet-stream';

  final headersArg = headerVarName != null ? 'headers: $headerVarName, ' : '';

  return Code.scope(
    (allocate) {
      final tonikFileBytes = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'TonikFileBytes'
            ..url = 'package:tonik_util/tonik_util.dart',
        ),
      );
      final tonikFilePath = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'TonikFilePath'
            ..url = 'package:tonik_util/tonik_util.dart',
        ),
      );
      final multipartFile = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'MultipartFile'
            ..url = 'package:dio/dio.dart',
        ),
      );
      final mapEntry = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'MapEntry'
            ..url = 'dart:core',
        ),
      );

      final contentTypeArg = isDefaultContentType
          ? ''
          : () {
              final dioMediaType = allocate(
                TypeReference(
                  (b) => b
                    ..symbol = 'DioMediaType'
                    ..url = 'package:dio/dio.dart',
                ),
              );
              final ct = specLiteralStringCode(rawContentType);
              return 'contentType: $dioMediaType.parse($ct), ';
            }();

      final escapedName = specLiteralStringCode(rawName);
      return '''
switch ($accessor) {
  case $tonikFileBytes(:final bytes, :final fileName):
    _\$formData.files.add($mapEntry(
      $escapedName,
      $multipartFile.fromBytes(bytes, filename: fileName ?? $escapedName, $contentTypeArg$headersArg),
    ));
  case $tonikFilePath(:final path, :final fileName):
    _\$formData.files.add($mapEntry(
      $escapedName,
      await $multipartFile.fromFile(path, filename: fileName ?? $escapedName, $contentTypeArg$headersArg),
    ));
}''';
    },
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
  final itemExpr = _itemToStringExpr(
    contentModel,
    contentType: contentType,
  );
  final isIdentity = contentModel is StringModel;

  final explode = propertyEncoding?.explode ?? true;

  // When headers are present, text items must be sent as
  // MultipartFile.fromString so the headers can be attached.
  if (headerVarName != null) {
    final fileItemExpr = refer('MultipartFile', 'package:dio/dio.dart')
        .property('fromString')
        .call([itemExpr], {'headers': refer(headerVarName)});
    if (explode) {
      return _buildListForLoop(
        rawName,
        refer(accessor),
        fileItemExpr,
        isFile: true,
      );
    }
    final encoderExpr = _buildEncoderExpr(
      accessor,
      itemExpr,
      needsMapping: !isIdentity,
      style: style,
    );
    // After the encoder, items are already strings.
    final encodedFileItemExpr = refer('MultipartFile', 'package:dio/dio.dart')
        .property('fromString')
        .call([refer('item')], {'headers': refer(headerVarName)});
    return _buildListForLoop(
      rawName,
      encoderExpr,
      encodedFileItemExpr,
      isFile: true,
    );
  }

  if (explode) {
    // explode: true — for-loop adding each item as a separate field.
    return _buildListForLoop(
      rawName,
      refer(accessor),
      itemExpr,
      isFile: false,
    );
  }

  final encoderExpr = _buildEncoderExpr(
    accessor,
    itemExpr,
    needsMapping: !isIdentity,
    style: style,
  );
  return _buildListForLoop(
    rawName,
    encoderExpr,
    refer('item'),
    isFile: false,
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

  // Always use application/json — text/plain is promoted since the spec does
  // not define how to serialize an array as a single text/plain part.
  const rawContentType = 'application/json';

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

  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'headers': refer(headerVarName),
  };

  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call([jsonExpr], namedArgs),
    ]),
  ]).statement;
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
          ? refer('jsonEncode', 'dart:convert').call([refer('item')])
          : refer('item').property('toString').call([]),
    DateTimeModel() =>
      contentType == ContentType.json
          ? refer('jsonEncode', 'dart:convert').call([refer('item')])
          : refer('item').property('toTimeZonedIso8601String').call([]),
    EnumModel() => refer('item').property('uriEncode').call(
      [],
      {'allowEmpty': literalTrue},
    ),
    AliasModel() => _itemToStringExpr(
      contentModel.resolved,
      contentType: contentType,
    ),
    _ => refer('item').property('toString').call([]),
  };
}

/// Returns an [Expression] for a binary item in a for-loop.
///
/// Generates a switch on the sealed TonikFile type.
Code _binaryItemExpr(String rawName, {String? headerVarName}) {
  final headersArg = headerVarName != null ? 'headers: $headerVarName, ' : '';

  return Code.scope(
    (allocate) {
      final tonikFileBytes = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'TonikFileBytes'
            ..url = 'package:tonik_util/tonik_util.dart',
        ),
      );
      final tonikFilePath = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'TonikFilePath'
            ..url = 'package:tonik_util/tonik_util.dart',
        ),
      );
      final multipartFile = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'MultipartFile'
            ..url = 'package:dio/dio.dart',
        ),
      );
      final mapEntry = allocate(
        TypeReference(
          (b) => b
            ..symbol = 'MapEntry'
            ..url = 'dart:core',
        ),
      );
      final escapedName = specLiteralStringCode(rawName);
      return '''
switch (item) {
  case $tonikFileBytes(:final bytes, :final fileName):
    _\$formData.files.add($mapEntry($escapedName, $multipartFile.fromBytes(bytes, filename: fileName ?? $escapedName, $headersArg)));
  case $tonikFilePath(:final path, :final fileName):
    _\$formData.files.add($mapEntry($escapedName, await $multipartFile.fromFile(path, filename: fileName ?? $escapedName, $headersArg)));
}''';
    },
  );
}

/// Returns an [Expression] for a complex object item in a for-loop.
Expression _complexItemExpr(
  String rawName, {
  PartEncoding? encoding,
  String? headerVarName,
}) {
  final rawContentType = encoding?.rawContentType ?? 'application/json';
  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
  };
  if (headerVarName != null) {
    namedArgs['headers'] = refer(headerVarName);
  }
  return refer(
    'MultipartFile',
    'package:dio/dio.dart',
  ).property('fromString').call([
    refer('jsonEncode', 'dart:convert').call([
      refer('item').property('toJson').call([]),
    ]),
  ], namedArgs);
}

/// Builds an [Expression] for the encoder call for explode: false arrays.
///
/// Maps items to strings via [itemExpr], then calls the appropriate style
/// encoder. Set [needsMapping] to false when [itemExpr] is identity
/// (i.e. the item is already a string).
Expression _buildEncoderExpr(
  String accessor,
  Expression itemExpr, {
  required bool needsMapping,
  EncodingStyle? style,
}) {
  Expression listExpr;
  if (needsMapping) {
    listExpr = refer(accessor)
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
  } else {
    listExpr = refer(accessor);
  }

  final encoderMethod = switch (style) {
    EncodingStyle.spaceDelimited => 'toSpaceDelimited',
    EncodingStyle.pipeDelimited => 'toPipeDelimited',
    _ => 'uriEncode',
  };

  final isDelimited =
      style == EncodingStyle.spaceDelimited ||
      style == EncodingStyle.pipeDelimited;

  final namedArgs = <String, Expression>{
    if (isDelimited) 'explode': literalFalse,
    'allowEmpty': literalTrue,
    'alreadyEncoded': literalTrue,
  };

  if (style == EncodingStyle.spaceDelimited) {
    namedArgs['percentEncodeDelimiter'] = literalFalse;
  }

  return listExpr.property(encoderMethod).call([], namedArgs);
}

Code _buildDeepObjectFileAddition(
  String rawName,
  String accessor, {
  String? headerVarName,
}) {
  final iterableExpr = refer(accessor)
      .property('toDeepObject')
      .call(
        [specLiteralString(rawName)],
        {'explode': literalTrue, 'allowEmpty': literalTrue},
      );

  if (headerVarName != null) {
    // With per-part headers: each bracket-notation entry becomes a file part.
    final fileExpr = refer('MultipartFile', 'package:dio/dio.dart')
        .property('fromString')
        .call(
          [refer('entry').property('value')],
          {'headers': refer(headerVarName)},
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
      headerVarName: headerVarName,
    );
  }

  // Default: JSON-encode the map directly (maps are natively serializable).
  final rawContentType = propertyEncoding?.rawContentType ?? 'application/json';

  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
  };

  if (headerVarName != null) {
    namedArgs['headers'] = refer(headerVarName);
  }

  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call([
        refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
      ], namedArgs),
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
  String? headerVarName,
}) {
  final propVarName = accessor.split('.').last.replaceAll('!', '');
  final partsVarName = '${propVarName}Parts';

  final contentTypeExpr = refer('DioMediaType', 'package:dio/dio.dart')
      .property('parse')
      .call([specLiteralString('application/x-www-form-urlencoded')]);

  final namedArgs = <String, Expression>{
    'contentType': contentTypeExpr,
    if (headerVarName != null) 'headers': refer(headerVarName),
  };

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
    declareFinal('value').assign(refer('entry').property('value')).statement,
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
    // <partsVarName>.add(
    //   Uri.encodeQueryComponent(entry.key.toString()) +
    //       '=' +
    //       Uri.encodeQueryComponent(value.toString()),
    // );
    refer(partsVarName).property('add').call([
      literalList([
        refer('Uri', 'dart:core').property('encodeQueryComponent').call([
          refer('entry').property('key').property('toString').call([]),
        ]),
        refer('Uri', 'dart:core').property('encodeQueryComponent').call([
          refer('value').property('toString').call([]),
        ]),
      ]).property('join').call([literalString('=')]),
    ]).statement,
    const Code('}'),
    // _$formData.files.add(MapEntry(...));
    refer(r'_$formData').property('files').property('add').call([
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        refer(
          'MultipartFile',
          'package:dio/dio.dart',
        ).property('fromString').call(
          [
            refer(partsVarName).property('join').call([literalString('&')]),
          ],
          namedArgs,
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
      headerVarName: headerVarName,
    );
  }

  if (propertyEncoding?.contentType == ContentType.form) {
    return _buildUrlEncodedObjectFileAddition(
      rawName,
      accessor,
      headerVarName: headerVarName,
    );
  }

  final rawContentType = propertyEncoding?.rawContentType ?? 'application/json';

  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
  };

  if (headerVarName != null) {
    namedArgs['headers'] = refer(headerVarName);
  }

  return refer(r'_$formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      specLiteralString(rawName),
      refer(
        'MultipartFile',
        'package:dio/dio.dart',
      ).property('fromString').call([
        refer(
          'jsonEncode',
          'dart:convert',
        ).call([refer(accessor).property('toJson').call([])]),
      ], namedArgs),
    ]),
  ]).statement;
}

Code _buildUrlEncodedObjectFileAddition(
  String rawName,
  String accessor, {
  String? headerVarName,
}) {
  final propVarName = accessor.split('.').last.replaceAll('!', '');
  final entriesVarName = '${propVarName}Entries';

  final contentTypeExpr = refer('DioMediaType', 'package:dio/dio.dart')
      .property('parse')
      .call([specLiteralString('application/x-www-form-urlencoded')]);

  final namedArgs = <String, Expression>{
    'contentType': contentTypeExpr,
    if (headerVarName != null) 'headers': refer(headerVarName),
  };

  final joinedBody = refer(entriesVarName)
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..lambda = true
            ..body = const Code(r"'${e.name}=${e.value}'"),
        ).closure,
      ])
      .property('join')
      .call([literalString('&')]);

  return Block.of([
    declareFinal(entriesVarName)
        .assign(
          refer(accessor).property('toForm').call(
            [specLiteralString(rawName)],
            {
              'explode': literalTrue,
              'allowEmpty': literalTrue,
              'useQueryComponent': literalTrue,
            },
          ),
        )
        .statement,
    refer(r'_$formData').property('files').property('add').call([
      refer('MapEntry', 'dart:core').call([
        specLiteralString(rawName),
        refer(
          'MultipartFile',
          'package:dio/dio.dart',
        ).property('fromString').call([joinedBody], namedArgs),
      ]),
    ]).statement,
  ]);
}

Code _buildRawStylePartsAddition(
  String rawName,
  String accessor, {
  required bool explode,
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
        refer('MultipartFile', 'package:dio/dio.dart').property('fromString')
            .call(
              [refer(r'_$part').property('value')],
              {if (headerVarName != null) 'headers': refer(headerVarName)},
            ),
      ]),
    ]).statement,
    const Code('}'),
  ]);
}

typedef MultipartHeaderParamInfo = ({
  RequestContent content,
  String name,
  String normalizedPropertyName,
  String rawHeaderName,
  Model model,
  bool isRequired,
  bool isDeprecated,
});

List<MultipartHeaderParamInfo> extractMultipartHeaderParamInfo(
  RequestContent content, {
  Set<String> reservedNames = const {},
}) {
  final encoding = content.multipartEncoding;
  if (encoding == null) return const [];

  final model = content.model.resolved;
  if (model is! ClassModel) return const [];

  final writeProperties = model.properties.where((p) => !p.isReadOnly).toList();
  final normalizedProps = normalizeProperties(writeProperties);

  final result = <MultipartHeaderParamInfo>[];
  final usedNames = reservedNames.map((name) => name.toLowerCase()).toSet();

  for (final (:normalizedName, :property) in normalizedProps) {
    final propertyEncoding = encoding[property];
    final headers = propertyEncoding?.headers;
    if (headers == null || headers.isEmpty) continue;

    final isPropertyOptional = !property.isRequired || property.isNullable;

    for (final entry in headers.entries) {
      final rawHeaderName = entry.key;
      final header = entry.value.resolve(name: rawHeaderName);
      final isRequired = !isPropertyOptional && header.isRequired;

      final baseName = normalizeMultipartHeaderName(
        normalizedName,
        rawHeaderName,
      );
      final paramName = _uniqueMultipartHeaderParameterName(
        baseName,
        usedNames,
      );

      result.add((
        content: content,
        name: paramName,
        normalizedPropertyName: normalizedName,
        rawHeaderName: rawHeaderName,
        model: header.model,
        isRequired: isRequired,
        isDeprecated: header.isDeprecated,
      ));
    }
  }

  return result;
}

/// Extracts all per-part header parameters using names scoped to one operation.
List<MultipartHeaderParamInfo> extractOperationMultipartHeaderParamInfo(
  Operation operation,
) {
  final hasRequestBody =
      operation.requestBody?.resolvedContent.isNotEmpty ?? false;
  if (!hasRequestBody) return const [];

  final normalized = normalizeRequestParameters(
    pathParameters: operation.pathParameters.map((p) => p.resolve()).toSet(),
    queryParameters: operation.queryParameters.map((p) => p.resolve()).toSet(),
    headers: operation.headers.map((p) => p.resolve()).toSet(),
    cookieParameters: operation.cookieParameters
        .map((p) => p.resolve())
        .toSet(),
    reservedNames: operationReservedParameterNames(hasRequestBody: true),
  );
  final usedNames = <String>{
    'body',
    'cancelToken',
    ...normalized.pathParameters.map((p) => p.normalizedName),
    ...normalized.queryParameters.map((p) => p.normalizedName),
    ...normalized.headers.map((p) => p.normalizedName),
    ...normalized.cookieParameters.map((p) => p.normalizedName),
  };
  final result = <MultipartHeaderParamInfo>[];

  for (final content in operation.requestBody!.resolvedContent) {
    if (content.contentType != ContentType.multipart) continue;
    final parameters = extractMultipartHeaderParamInfo(
      content,
      reservedNames: usedNames,
    );
    result.addAll(parameters);
    usedNames.addAll(parameters.map((parameter) => parameter.name));
  }

  return result;
}

String _uniqueMultipartHeaderParameterName(
  String baseName,
  Set<String> usedNames,
) {
  if (usedNames.add(baseName.toLowerCase())) return baseName;

  final suffixedBase = '${baseName}PartHeader';
  var candidate = suffixedBase;
  var counter = 2;
  while (!usedNames.add(candidate.toLowerCase())) {
    candidate = '$suffixedBase$counter';
    counter++;
  }
  return candidate;
}
