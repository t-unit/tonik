import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

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
    declareFinal('formData')
        .assign(refer('FormData', 'package:dio/dio.dart').call([]))
        .statement,
  );

  // Filter out readOnly properties.
  final writeProperties =
      model.properties.where((p) => !p.isReadOnly).toList();

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

  // Resolve alias for property model matching.
  var resolved = model;
  if (resolved is AliasModel) {
    resolved = resolved.resolved;
  }

  return switch (resolved) {
    StringModel() => _buildStringFieldAddition(rawName, accessor),
    AnyModel() => _buildAnyFieldAddition(rawName, accessor),
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
      contentType == ContentType.json
          ? _buildJsonEncodeFieldAddition(rawName, accessor)
          : _buildPrimitiveFieldAddition(
              rawName,
              accessor,
              serializerMethod: 'toString',
            ),

    DateTimeModel() => contentType == ContentType.json
        ? _buildJsonEncodeFieldAddition(rawName, accessor)
        : _buildPrimitiveFieldAddition(
            rawName,
            accessor,
            serializerMethod: 'toTimeZonedIso8601String',
          ),

    EnumModel() => _buildEnumFieldAddition(rawName, accessor, resolved),

    BinaryModel() => _buildBinaryFileAddition(
      rawName,
      accessor,
      encoding: encoding,
    ),

    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() =>
      _buildComplexObjectFileAddition(
        rawName,
        accessor,
        encoding: encoding,
      ),

    ListModel() => _buildListFieldAddition(
      rawName,
      accessor,
      resolved,
      encoding: encoding,
    ),

    // AliasModel is already resolved above, so recurse for any other alias
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
}

Code _buildStringFieldAddition(String rawName, String accessor) {
  return refer('formData')
      .property('fields')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          refer(accessor),
        ]),
      ])
      .statement;
}

Code _buildPrimitiveFieldAddition(
  String rawName,
  String accessor, {
  required String serializerMethod,
}) {
  return refer('formData')
      .property('fields')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          refer(accessor).property(serializerMethod).call([]),
        ]),
      ])
      .statement;
}

Code _buildJsonEncodeFieldAddition(String rawName, String accessor) {
  return refer('formData')
      .property('fields')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          refer('jsonEncode', 'dart:convert').call([refer(accessor)]),
        ]),
      ])
      .statement;
}

Code _buildAnyFieldAddition(String rawName, String accessor) {
  return refer('formData')
      .property('fields')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          refer(accessor).property('toString').call([]),
        ]),
      ])
      .statement;
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

  return refer('formData')
      .property('fields')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          valueExpr,
        ]),
      ])
      .statement;
}

Code _buildBinaryFileAddition(
  String rawName,
  String accessor, {
  Map<String, MultipartPropertyEncoding>? encoding,
}) {
  final rawContentType = encoding?[rawName]?.rawContentType;
  final isDefaultContentType = rawContentType == null ||
      rawContentType == 'application/octet-stream';

  final namedArgs = <String, Expression>{
    'filename': literalString(rawName),
  };

  if (!isDefaultContentType) {
    namedArgs['contentType'] = refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([literalString(rawContentType)]);
  }

  return refer('formData')
      .property('files')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          refer('MultipartFile', 'package:dio/dio.dart')
              .property('fromBytes')
              .call([refer(accessor)], namedArgs),
        ]),
      ])
      .statement;
}

Code _buildListFieldAddition(
  String rawName,
  String accessor,
  ListModel listModel, {
  Map<String, MultipartPropertyEncoding>? encoding,
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
    return _buildListForLoop(
      rawName,
      accessor,
      _binaryItemExpression(rawName),
      isFile: true,
    );
  }

  if (contentModel is ClassModel ||
      contentModel is AllOfModel ||
      contentModel is OneOfModel ||
      contentModel is AnyOfModel) {
    return _buildListForLoop(
      rawName,
      accessor,
      _complexItemExpression(rawName, encoding: encoding),
      isFile: true,
    );
  }

  // For text-serializable types, build the item-to-string expression
  // and decide whether to go through an encoder.
  final itemExpr = _itemToStringExpression(
    contentModel,
    contentType: contentType,
  );

  final explode = propertyEncoding?.explode ?? true;

  if (explode) {
    // explode: true — for-loop adding each item as a separate field.
    return _buildListForLoop(rawName, accessor, itemExpr, isFile: false);
  }

  // explode: false — map items to strings, run through the style encoder,
  // then for-loop over the (single-element) result.
  final encoderCall = _buildEncoderCall(accessor, itemExpr, style: style);
  return Block.of([
    Code('for (final item in $encoderCall) {'),
    refer('formData')
        .property('fields')
        .property('add')
        .call([
          refer('MapEntry', 'dart:core').call([
            literalString(rawName),
            refer('item'),
          ]),
        ])
        .statement,
    const Code('}'),
  ]);
}

/// Builds a for-loop that iterates [accessor] and adds each item.
Code _buildListForLoop(
  String rawName,
  String accessor,
  String itemExpression, {
  required bool isFile,
}) {
  final target = isFile ? 'files' : 'fields';
  return Block.of([
    Code('for (final item in $accessor) {'),
    Code('formData.$target.add(MapEntry('),
    Code("'$rawName', $itemExpression));"),
    const Code('}'),
  ]);
}

/// Returns the expression string to serialize a single list item to a string
/// value, based on the content model type and content type.
String _itemToStringExpression(
  Model contentModel, {
  ContentType? contentType,
}) {
  return switch (contentModel) {
    StringModel() => 'item',
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() =>
      contentType == ContentType.json ? 'jsonEncode(item)' : 'item.toString()',
    DateTimeModel() => contentType == ContentType.json
        ? 'jsonEncode(item)'
        : 'item.toTimeZonedIso8601String()',
    EnumModel() => 'item.uriEncode(allowEmpty: true)',
    AliasModel() => _itemToStringExpression(
      contentModel.resolved,
      contentType: contentType,
    ),
    _ => 'item.toString()',
  };
}

/// Returns the expression string for a binary item in a for-loop.
String _binaryItemExpression(String rawName) {
  return "MultipartFile.fromBytes(item, filename: '$rawName')";
}

/// Returns the expression string for a complex object item in a for-loop.
String _complexItemExpression(
  String rawName, {
  Map<String, MultipartPropertyEncoding>? encoding,
}) {
  final rawContentType =
      encoding?[rawName]?.rawContentType ?? 'application/json';
  return 'MultipartFile.fromString(jsonEncode(item.toJson()), '
      "contentType: DioMediaType.parse('$rawContentType'))";
}

/// Builds the encoder call string for explode: false arrays.
///
/// Maps items to strings, then calls the appropriate style encoder.
String _buildEncoderCall(
  String accessor,
  String itemExpr, {
  MultipartEncodingStyle? style,
}) {
  final needsMapping = itemExpr != 'item';
  final mappedList = needsMapping
      ? '$accessor.map((item) => $itemExpr).toList()'
      : accessor;

  return switch (style) {
    MultipartEncodingStyle.spaceDelimited =>
      '$mappedList.toSpaceDelimited(explode: false, '
          'allowEmpty: true, alreadyEncoded: true, '
          'percentEncodeDelimiter: false)',
    MultipartEncodingStyle.pipeDelimited =>
      '$mappedList.toPipeDelimited(explode: false, '
          'allowEmpty: true, alreadyEncoded: true)',
    _ => '$mappedList.toForm(explode: false, '
        'allowEmpty: true, alreadyEncoded: true)',
  };
}

Code _buildComplexObjectFileAddition(
  String rawName,
  String accessor, {
  Map<String, MultipartPropertyEncoding>? encoding,
}) {
  final propertyEncoding = encoding?[rawName];

  if (propertyEncoding?.style == MultipartEncodingStyle.deepObject) {
    throw UnsupportedError(
      'deepObject style is not supported for complex object '
      'multipart properties (property: $rawName).',
    );
  }

  final rawContentType =
      propertyEncoding?.rawContentType ?? 'application/json';

  final namedArgs = <String, Expression>{
    'contentType': refer(
      'DioMediaType',
      'package:dio/dio.dart',
    ).property('parse').call([literalString(rawContentType)]),
  };

  return refer('formData')
      .property('files')
      .property('add')
      .call([
        refer('MapEntry', 'dart:core').call([
          literalString(rawName),
          refer('MultipartFile', 'package:dio/dio.dart')
              .property('fromString')
              .call([
                refer('jsonEncode', 'dart:convert')
                    .call([refer(accessor).property('toJson').call([])]),
              ], namedArgs),
        ]),
      ])
      .statement;
}
