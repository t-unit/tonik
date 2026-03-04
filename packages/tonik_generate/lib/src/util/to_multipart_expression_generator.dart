import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Builds FormData construction statements for single-content multipart bodies.
///
/// Returns a [List<Code>] containing FormData construction and field additions.
/// The caller is responsible for adding `return formData;`.
List<Code> buildMultipartBodyStatements(
  RequestContent content,
  String bodyAccessor,
  NameManager nameManager,
  String package,
) {
  return _buildMultipartFields(content, bodyAccessor, nameManager, package);
}

/// Builds an IIFE expression that constructs and returns a FormData instance.
///
/// For use in multi-content switch arms. Produces:
/// `() { final formData = FormData(); ...; return formData; }()`
Expression buildMultipartBodyExpression(
  RequestContent content,
  String bodyAccessor,
  NameManager nameManager,
  String package,
) {
  final statements = _buildMultipartFields(
    content,
    bodyAccessor,
    nameManager,
    package,
  );

  // Only add `return formData;` when the model resolved to a ClassModel
  // (i.e., formData was actually declared). For non-ClassModel bodies,
  // the statements contain only a throw.
  var model = content.model;
  if (model is AliasModel) {
    model = model.resolved;
  }
  final bodyStatements = [
    ...statements,
    if (model is ClassModel) refer('formData').returned.statement,
  ];

  return Method(
    (b) => b
      ..lambda = false
      ..body = Block.of(bodyStatements),
  ).closure.call([]);
}

List<Code> _buildMultipartFields(
  RequestContent content,
  String bodyAccessor,
  NameManager nameManager,
  String package,
) {
  final statements = <Code>[];

  // Resolve through alias chains.
  var model = content.model;
  if (model is AliasModel) {
    model = model.resolved;
  }

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
      'formData',
    ).assign(refer('FormData', 'package:dio/dio.dart').call([])).statement,
  );

  // Filter out readOnly properties.
  final writeProperties = model.properties.where((p) => !p.isReadOnly).toList();

  final normalizedProps = normalizeProperties(writeProperties);

  for (final (:normalizedName, :property) in normalizedProps) {
    final rawName = property.name;
    final isNullable = property.isNullable || !property.isRequired;

    final fieldCode = _buildFieldCode(
      property.model,
      rawName,
      bodyAccessor,
      normalizedName,
      isNullable,
      encoding: content.encoding,
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

  return statements;
}

Code? _buildFieldCode(
  Model model,
  String rawName,
  String bodyAccessor,
  String normalizedName,
  bool isNullable, {
  Map<String, MultipartPropertyEncoding>? encoding,
}) {
  final accessor = '$bodyAccessor.$normalizedName${isNullable ? '!' : ''}';
  final propertyEncoding = encoding?[rawName];
  final contentType = propertyEncoding?.contentType;

  // Build per-part header statements and variable name (if any).
  final headerResult = _buildHeaderMapStatements(
    normalizedName,
    propertyEncoding,
    isPropertyOptional: isNullable,
  );

  // Resolve alias for property model matching.
  var resolved = model;
  if (resolved is AliasModel) {
    resolved = resolved.resolved;
  }

  final hasHeaders = headerResult != null;
  final headerVarName = headerResult?.headerVarName;

  final fieldCode = switch (resolved) {
    // When headers are present, field types that normally go to
    // formData.fields must be promoted to formData.files via
    // MultipartFile.fromString so the per-part headers are attached.
    StringModel() =>
      hasHeaders
          ? _buildStringFileAddition(rawName, accessor, headerVarName!)
          : _buildStringFieldAddition(rawName, accessor),
    AnyModel() =>
      hasHeaders
          ? _buildPrimitiveFileAddition(
              rawName,
              accessor,
              headerVarName!,
              serializerMethod: 'toString',
            )
          : _buildAnyFieldAddition(rawName, accessor),
    NeverModel() => generateEncodingExceptionExpression(
      "Cannot encode NeverModel property '$rawName' "
      '- this type does not permit any value.',
    ).statement,

    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() =>
      hasHeaders
          ? contentType == ContentType.json
                ? _buildJsonEncodeFileAddition(
                    rawName,
                    accessor,
                    headerVarName!,
                  )
                : _buildPrimitiveFileAddition(
                    rawName,
                    accessor,
                    headerVarName!,
                    serializerMethod: 'toString',
                  )
          : contentType == ContentType.json
          ? _buildJsonEncodeFieldAddition(rawName, accessor)
          : _buildPrimitiveFieldAddition(
              rawName,
              accessor,
              serializerMethod: 'toString',
            ),

    DateTimeModel() =>
      hasHeaders
          ? contentType == ContentType.json
                ? _buildJsonEncodeFileAddition(
                    rawName,
                    accessor,
                    headerVarName!,
                  )
                : _buildPrimitiveFileAddition(
                    rawName,
                    accessor,
                    headerVarName!,
                    serializerMethod: 'toTimeZonedIso8601String',
                  )
          : contentType == ContentType.json
          ? _buildJsonEncodeFieldAddition(rawName, accessor)
          : _buildPrimitiveFieldAddition(
              rawName,
              accessor,
              serializerMethod: 'toTimeZonedIso8601String',
            ),

    EnumModel() =>
      hasHeaders
          ? _buildEnumFileAddition(rawName, accessor, resolved, headerVarName!)
          : _buildEnumFieldAddition(rawName, accessor, resolved),

    BinaryModel() => _buildBinaryFileAddition(
      rawName,
      accessor,
      encoding: encoding,
      headerVarName: headerVarName,
    ),

    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildComplexObjectFileAddition(
      rawName,
      accessor,
      encoding: encoding,
      headerVarName: headerVarName,
    ),

    ListModel() => _buildListFieldAddition(
      rawName,
      accessor,
      resolved,
      encoding: encoding,
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
    ),

    _ => throw UnimplementedError(
      'Unsupported model type for multipart encoding: ${model.runtimeType}',
    ),
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
  MultipartPropertyEncoding? encoding, {
  bool isPropertyOptional = false,
}) {
  final headers = encoding?.headers;
  if (headers == null || headers.isEmpty) return null;

  // Filter out Content-Type (case-insensitive) per OAS spec.
  final filteredEntries = headers.entries
      .where((e) => e.key.toLowerCase() != 'content-type')
      .toList();

  if (filteredEntries.isEmpty) return null;

  final headerVarName = '${normalizedPropertyName}Headers';
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

  // Add an entry for each header.
  for (final entry in filteredEntries) {
    final rawHeaderName = entry.key;
    final header = entry.value.resolve();
    final paramName = normalizeMultipartHeaderName(
      normalizedPropertyName,
      rawHeaderName,
    );

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
        .index(literalString(rawHeaderName))
        .assign(literalList([serializeExpr]))
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

Code _buildStringFieldAddition(String rawName, String accessor) {
  return refer('formData').property('fields').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer(accessor),
    ]),
  ]).statement;
}

/// Builds a string field as MultipartFile.fromString with per-part headers.
Code _buildStringFileAddition(
  String rawName,
  String accessor,
  String headerVarName,
) {
  return refer('formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer('MultipartFile', 'package:dio/dio.dart')
          .property('fromString')
          .call(
            [refer(accessor)],
            {'headers': refer(headerVarName)},
          ),
    ]),
  ]).statement;
}

/// Builds a primitive field as MultipartFile.fromString with per-part headers.
Code _buildPrimitiveFileAddition(
  String rawName,
  String accessor,
  String headerVarName, {
  required String serializerMethod,
}) {
  return refer('formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer('MultipartFile', 'package:dio/dio.dart')
          .property('fromString')
          .call(
            [refer(accessor).property(serializerMethod).call([])],
            {'headers': refer(headerVarName)},
          ),
    ]),
  ]).statement;
}

/// Builds an enum field as MultipartFile.fromString with per-part headers.
Code _buildEnumFileAddition(
  String rawName,
  String accessor,
  EnumModel<dynamic> model,
  String headerVarName,
) {
  final toJsonCall = refer(accessor).property('toJson').call([]);
  final valueExpr = model is EnumModel<String>
      ? toJsonCall
      : toJsonCall.property('toString').call([]);

  return refer('formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer('MultipartFile', 'package:dio/dio.dart')
          .property('fromString')
          .call(
            [valueExpr],
            {'headers': refer(headerVarName)},
          ),
    ]),
  ]).statement;
}

Code _buildPrimitiveFieldAddition(
  String rawName,
  String accessor, {
  required String serializerMethod,
}) {
  return refer('formData').property('fields').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer(accessor).property(serializerMethod).call([]),
    ]),
  ]).statement;
}

Code _buildJsonEncodeFieldAddition(String rawName, String accessor) {
  return refer('formData').property('fields').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
    ]),
  ]).statement;
}

/// Builds a json-encoded field as MultipartFile.fromString with per-part
/// headers.
Code _buildJsonEncodeFileAddition(
  String rawName,
  String accessor,
  String headerVarName,
) {
  return refer('formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer('MultipartFile', 'package:dio/dio.dart')
          .property('fromString')
          .call(
            [
              refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
            ],
            {'headers': refer(headerVarName)},
          ),
    ]),
  ]).statement;
}

Code _buildAnyFieldAddition(String rawName, String accessor) {
  return refer('formData').property('fields').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      refer(accessor).property('toString').call([]),
    ]),
  ]).statement;
}

Code _buildEnumFieldAddition(
  String rawName,
  String accessor,
  EnumModel<dynamic> model,
) {
  final toJsonCall = refer(accessor).property('toJson').call([]);
  final valueExpr = model is EnumModel<String>
      ? toJsonCall
      : toJsonCall.property('toString').call([]);

  return refer('formData').property('fields').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
      valueExpr,
    ]),
  ]).statement;
}

Code _buildBinaryFileAddition(
  String rawName,
  String accessor, {
  Map<String, MultipartPropertyEncoding>? encoding,
  String? headerVarName,
}) {
  final rawContentType = encoding?[rawName]?.rawContentType;
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
              return "contentType: $dioMediaType.parse('$rawContentType'), ";
            }();

      return '''
switch ($accessor) {
  case $tonikFileBytes(:final bytes, :final fileName):
    formData.files.add($mapEntry(
      '$rawName',
      $multipartFile.fromBytes(bytes, filename: fileName ?? '$rawName', $contentTypeArg$headersArg),
    ));
  case $tonikFilePath(:final fileName):
    formData.files.add($mapEntry(
      '$rawName',
      $multipartFile.fromBytes($accessor.toBytes(), filename: fileName ?? '$rawName', $contentTypeArg$headersArg),
    ));
}''';
    },
  );
}

Code _buildListFieldAddition(
  String rawName,
  String accessor,
  ListModel listModel, {
  Map<String, MultipartPropertyEncoding>? encoding,
  String? headerVarName,
}) {
  final propertyEncoding = encoding?[rawName];
  final style = propertyEncoding?.style;
  final contentType = propertyEncoding?.contentType;

  // deepObject is not supported for arrays.
  if (style == MultipartEncodingStyle.deepObject) {
    return generateEncodingExceptionExpression(
      'deepObject style is not supported for array '
      'multipart properties (property: $rawName).',
    ).statement;
  }

  // Resolve content model through aliases.
  var contentModel = listModel.content;
  if (contentModel is AliasModel) {
    contentModel = contentModel.resolved;
  }

  // Binary and complex objects always use a for-loop (can't be delimited).
  if (contentModel is BinaryModel) {
    return _buildBinaryListForLoop(
      rawName,
      accessor,
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
        encoding: encoding,
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

  // explode: false — map items to strings, run through the style encoder,
  // then for-loop over the (single-element) result.
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
    refer('formData').property(target).property('add').call([
      refer('MapEntry', 'dart:core').call([
        literalString(rawName),
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
      return '''
switch (item) {
  case $tonikFileBytes(:final bytes, :final fileName):
    formData.files.add($mapEntry('$rawName', $multipartFile.fromBytes(bytes, filename: fileName ?? '$rawName', $headersArg)));
  case $tonikFilePath(:final fileName):
    formData.files.add($mapEntry('$rawName', $multipartFile.fromBytes(item.toBytes(), filename: fileName ?? '$rawName', $headersArg)));
}''';
    },
  );
}

/// Returns an [Expression] for a complex object item in a for-loop.
Expression _complexItemExpr(
  String rawName, {
  Map<String, MultipartPropertyEncoding>? encoding,
  String? headerVarName,
}) {
  final rawContentType =
      encoding?[rawName]?.rawContentType ?? 'application/json';
  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([literalString(rawContentType)]),
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
  MultipartEncodingStyle? style,
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
    MultipartEncodingStyle.spaceDelimited => 'toSpaceDelimited',
    MultipartEncodingStyle.pipeDelimited => 'toPipeDelimited',
    _ => 'toForm',
  };

  final namedArgs = <String, Expression>{
    'explode': literalFalse,
    'allowEmpty': literalTrue,
    'alreadyEncoded': literalTrue,
  };

  if (style == MultipartEncodingStyle.spaceDelimited) {
    namedArgs['percentEncodeDelimiter'] = literalFalse;
  }

  return listExpr.property(encoderMethod).call([], namedArgs);
}

Code _buildComplexObjectFileAddition(
  String rawName,
  String accessor, {
  Map<String, MultipartPropertyEncoding>? encoding,
  String? headerVarName,
}) {
  final propertyEncoding = encoding?[rawName];

  if (propertyEncoding?.style == MultipartEncodingStyle.deepObject) {
    throw UnsupportedError(
      'deepObject style is not supported for complex object '
      'multipart properties (property: $rawName).',
    );
  }

  final rawContentType = propertyEncoding?.rawContentType ?? 'application/json';

  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([literalString(rawContentType)]),
  };

  if (headerVarName != null) {
    namedArgs['headers'] = refer(headerVarName);
  }

  return refer('formData').property('files').property('add').call([
    refer('MapEntry', 'dart:core').call([
      literalString(rawName),
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

/// Information about a per-part header parameter in multipart encoding.
typedef MultipartHeaderParamInfo = ({
  String name,
  Model model,
  bool isRequired,
});

/// Extracts per-part header parameters from a multipart request content.
///
/// Returns info needed to generate method parameters or call arguments.
/// Content-Type headers are filtered per OAS spec.
List<MultipartHeaderParamInfo> extractMultipartHeaderParamInfo(
  RequestContent content,
) {
  final encoding = content.encoding;
  if (encoding == null) return const [];

  var model = content.model;
  if (model is AliasModel) {
    model = model.resolved;
  }
  if (model is! ClassModel) return const [];

  final writeProperties = model.properties.where((p) => !p.isReadOnly).toList();
  final normalizedProps = normalizeProperties(writeProperties);

  final result = <MultipartHeaderParamInfo>[];

  for (final (:normalizedName, :property) in normalizedProps) {
    final propertyEncoding = encoding[property.name];
    final headers = propertyEncoding?.headers;
    if (headers == null || headers.isEmpty) continue;

    final isPropertyOptional = !property.isRequired || property.isNullable;

    final filteredEntries = headers.entries
        .where((e) => e.key.toLowerCase() != 'content-type')
        .toList();

    for (final entry in filteredEntries) {
      final rawHeaderName = entry.key;
      final header = entry.value.resolve(name: rawHeaderName);
      final isRequired = !isPropertyOptional && header.isRequired;

      final paramName = normalizeMultipartHeaderName(
        normalizedName,
        rawHeaderName,
      );

      result.add((
        name: paramName,
        model: header.model,
        isRequired: isRequired,
      ));
    }
  }

  return result;
}
