import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/text_encoding_expression.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Lowers one multipart body to an ordered list of `package:http` parts.
///
/// Every OpenAPI part is represented as a `MultipartFile` in generated code.
/// This deliberately avoids `MultipartRequest.fields`, whose map shape cannot
/// preserve duplicate names or ordering relative to file parts.
List<Code> buildHttpMultipartBodyStatements(
  RequestContent content,
  String bodyAccessor, {
  List<MultipartHeaderParamInfo>? headerParameters,
}) {
  final model = content.model.resolved;
  if (model is! ClassModel) {
    return [
      refer('UnsupportedError', 'dart:core')
          .newInstance([
            literalString(
              'Multipart request bodies require an object schema '
              '(ClassModel). Got: ${model.runtimeType}.',
            ),
          ])
          .thrown
          .statement,
    ];
  }

  final normalizedHeaderParameters =
      (headerParameters ?? extractMultipartHeaderParamInfo(content))
          .where((parameter) => identical(parameter.content, content))
          .toList();
  final usesCustomParts = normalizedHeaderParameters.isNotEmpty;
  final target = (
    variableName: usesCustomParts ? r'_$multipartParts' : r'_$multipartFiles',
    usesCustomParts: usesCustomParts,
  );
  final partType = usesCustomParts
      ? refer(
          'TonikMultipartPart',
          'package:tonik_util/tonik_util.dart',
        )
      : refer('MultipartFile', 'package:http/http.dart');
  final statements = <Code>[
    declareFinal(target.variableName)
        .assign(
          literalList(
            [],
            partType,
          ),
        )
        .statement,
  ];
  final properties = normalizeProperties(
    model.properties.where((property) => !property.isReadOnly).toList(),
  );

  for (final (:normalizedName, :property) in properties) {
    final isNullable = property.isNullable || !property.isRequired;
    final accessor = refer(bodyAccessor).property(normalizedName);
    final value = isNullable ? accessor.nullChecked : accessor;
    final headerResult = _buildHeaderMapStatements(
      content,
      normalizedName,
      content.multipartEncoding?[property],
      headerParameters: normalizedHeaderParameters,
      isPropertyOptional: isNullable,
    );
    final part = _buildPart(
      property.model,
      property.name,
      value,
      encoding: content.multipartEncoding?[property],
      target: target,
      headers: headerResult == null ? null : refer(headerResult.variableName),
    );
    final encodedPart = headerResult == null
        ? part
        : Block.of([...headerResult.statements, part]);

    if (isNullable) {
      statements.add(
        Block.of([
          const Code('if ('),
          accessor.code,
          const Code(' != null) {'),
          encodedPart,
          const Code('}'),
        ]),
      );
    } else {
      statements.add(encodedPart);
    }
  }

  statements.add(
    usesCustomParts
        ? refer(
            'TonikMultipartBody',
            'package:tonik_util/tonik_util.dart',
          ).newInstance([refer(target.variableName)]).returned.statement
        : refer(target.variableName).returned.statement,
  );
  return statements;
}

typedef _MultipartTarget = ({String variableName, bool usesCustomParts});

Code _buildPart(
  Model model,
  String rawName,
  Expression value, {
  required PartEncoding? encoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final resolved = model.resolved;
  return switch (resolved) {
    BinaryModel() || Base64Model() => _addFilePart(
      rawName,
      value,
      rawContentType: _wireContentType(
        encoding,
        'application/octet-stream',
      ),
      target: target,
      headers: headers,
    ),
    ListModel() => _buildListParts(
      rawName,
      value,
      resolved,
      encoding: encoding,
      target: target,
      headers: headers,
    ),
    NeverModel() => generateEncodingExceptionExpression(
      "Cannot encode NeverModel property '$rawName' - this type does not "
      'permit any value.',
      raw: true,
    ).statement,
    StringModel() => _addTextPart(
      rawName,
      value,
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    AnyModel() => _addTextPart(
      rawName,
      refer('jsonEncode', 'dart:convert').call([
        refer(
          'encodeAnyToJson',
          'package:tonik_util/tonik_util.dart',
        ).call([value]),
      ]),
      rawContentType: _wireContentType(encoding, 'application/json'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    MapModel() => _addTextPart(
      rawName,
      refer('jsonEncode', 'dart:convert').call([value]),
      rawContentType: _wireContentType(encoding, 'application/json'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    ClassModel() || CompositeModel() => _buildObjectPart(
      rawName,
      value,
      encoding: encoding,
      target: target,
      headers: headers,
    ),
    EnumModel() => _addTextPart(
      rawName,
      _enumText(value, resolved, encoding?.contentType),
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    DateTimeModel() => _addTextPart(
      rawName,
      _primitiveText(
        value,
        encoding?.contentType,
        method: 'toTimeZonedIso8601String',
      ),
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    PrimitiveModel() => _addTextPart(
      rawName,
      _primitiveText(value, encoding?.contentType, method: 'toString'),
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    NamedModel() => generateEncodingExceptionExpression(
      "Cannot encode cyclic AliasModel property '$rawName'.",
      raw: true,
    ).statement,
  };
}

Code _buildListParts(
  String rawName,
  Expression value,
  ListModel model, {
  required PartEncoding? encoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final content = model.content.resolved;
  if (content is ListModel) {
    return generateEncodingExceptionExpression(
      'Arrays of arrays are not supported for multipart encoding '
      '(property: $rawName).',
      raw: true,
    ).statement;
  }

  if (content is AliasModel) {
    return generateEncodingExceptionExpression(
      'Cannot encode cyclic AliasModel list items for multipart property '
      "'$rawName'.",
      raw: true,
    ).statement;
  }

  if (content is BinaryModel || content is Base64Model) {
    return Block.of([
      const Code('for (final item in '),
      value.code,
      const Code(') {'),
      _addFilePart(
        rawName,
        refer('item'),
        rawContentType: _wireContentType(
          encoding,
          'application/octet-stream',
        ),
        target: target,
        headers: headers,
      ),
      const Code('}'),
    ]);
  }

  final isStyleBased = encoding?.isStyleBased ?? false;
  if (!isStyleBased &&
      encoding?.contentType != null &&
      encoding?.contentType != ContentType.text) {
    if (encoding?.contentType != ContentType.json &&
        encoding?.contentType != ContentType.bytes) {
      return generateEncodingExceptionExpression(
        'Unsupported contentType "${encoding?.rawContentType ?? ''}" for '
        'array multipart property "$rawName". Only application/json is '
        'supported for content-based array serialization.',
        raw: true,
      ).statement;
    }
    return _addTextPart(
      rawName,
      refer('jsonEncode', 'dart:convert').call([
        _jsonListValue(value, content),
      ]),
      rawContentType: _wireContentType(encoding, 'application/json'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    );
  }

  if (content is ClassModel ||
      content is AllOfModel ||
      content is OneOfModel ||
      content is AnyOfModel ||
      content is MapModel ||
      content is AnyModel) {
    final itemJson = switch (content) {
      MapModel() => refer('item'),
      AnyModel() => refer(
        'encodeAnyToJson',
        'package:tonik_util/tonik_util.dart',
      ).call([refer('item')]),
      _ => refer('item').property('toJson').call([]),
    };
    return Block.of([
      const Code('for (final item in '),
      value.code,
      const Code(') {'),
      _addTextPart(
        rawName,
        refer('jsonEncode', 'dart:convert').call([itemJson]),
        rawContentType: _wireContentType(encoding, 'application/json'),
        textEncoding: _textEncoding(encoding),
        target: target,
        headers: headers,
      ),
      const Code('}'),
    ]);
  }

  final explode = encoding?.explode ?? true;
  if (!explode) {
    if (encoding?.style == EncodingStyle.pipeDelimited ||
        encoding?.style == EncodingStyle.spaceDelimited) {
      return _buildDelimitedListParts(
        rawName,
        value,
        content,
        encoding: encoding!,
        target: target,
        headers: headers,
      );
    }
    final serialized = buildSimpleValueExpression(
      value,
      model,
      explode: false,
      allowEmpty: true,
    ).unsafeRawBody;
    return _addTextPart(
      rawName,
      serialized,
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    );
  }

  return Block.of([
    const Code('for (final item in '),
    value.code,
    const Code(') {'),
    _addTextPart(
      rawName,
      _listItemText(refer('item'), content, encoding?.contentType),
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    ),
    const Code('}'),
  ]);
}

Code _buildObjectPart(
  String rawName,
  Expression value, {
  required PartEncoding? encoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  if (encoding?.style == EncodingStyle.deepObject) {
    return _buildDeepObjectParts(
      rawName,
      value,
      encoding: encoding!,
      target: target,
      headers: headers,
    );
  }

  if (encoding?.isStyleBased ?? false) {
    if (encoding?.style == EncodingStyle.form) {
      return _buildRawStyleObjectParts(
        rawName,
        value,
        explode: encoding?.explode ?? true,
        textEncoding: encoding!.textEncoding,
        target: target,
        headers: headers,
      );
    }
    return generateEncodingExceptionExpression(
      '${encoding?.style?.name ?? 'unknown'} style is not supported for '
      'object multipart part $rawName',
      raw: true,
    ).statement;
  }

  if (encoding?.contentType == ContentType.form) {
    return _buildUrlEncodedObjectPart(
      rawName,
      value,
      rawContentType: _wireContentType(
        encoding,
        'application/x-www-form-urlencoded',
      ),
      textEncoding: _textEncoding(encoding),
      target: target,
      headers: headers,
    );
  }

  return _addTextPart(
    rawName,
    refer(
      'jsonEncode',
      'dart:convert',
    ).call([value.property('toJson').call([])]),
    rawContentType: _wireContentType(encoding, 'application/json'),
    textEncoding: _textEncoding(encoding),
    target: target,
    headers: headers,
  );
}

Code _buildDeepObjectParts(
  String rawName,
  Expression value, {
  required PartEncoding encoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final namedArguments = <String, Expression>{
    'explode': literalTrue,
    'allowEmpty': literalTrue,
    if (encoding.allowReserved ?? false) 'allowReserved': literalTrue,
  };
  final entries = value.property('toDeepObject').call(
    [specLiteralString(rawName)],
    namedArguments,
  );
  return Block.of([
    const Code('for (final entry in '),
    entries.code,
    const Code(') {'),
    _addTextPartExpression(
      refer('entry').property('name'),
      refer('entry').property('value'),
      rawContentType: 'application/x-www-form-urlencoded',
      textEncoding: encoding.textEncoding,
      target: target,
      headers: headers,
    ),
    const Code('}'),
  ]);
}

Code _buildUrlEncodedObjectPart(
  String rawName,
  Expression value, {
  required String rawContentType,
  required TextEncoding textEncoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final entries = value
      .property('toForm')
      .call(
        [specLiteralString(rawName)],
        {
          'explode': literalTrue,
          'allowEmpty': literalTrue,
          'useQueryComponent': literalTrue,
          'textEncoding': textEncodingExpression(textEncoding),
        },
      );
  final joined = entries
      .property('map')
      .call([
        Method(
          (builder) => builder
            ..lambda = true
            ..requiredParameters.add(Parameter((p) => p..name = 'entry'))
            ..body = const Code(r"'${entry.name}=${entry.value}'"),
        ).closure,
      ])
      .property('join')
      .call([literalString('&')]);
  return _addTextPart(
    rawName,
    joined,
    rawContentType: rawContentType,
    textEncoding: textEncoding,
    target: target,
    headers: headers,
  );
}

Code _buildRawStyleObjectParts(
  String rawName,
  Expression value, {
  required bool explode,
  required TextEncoding textEncoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final entries = value
      .property('parameterProperties')
      .call([], {'allowEmpty': literalTrue})
      .property('toRawStyleParts')
      .call(
        [specLiteralString(rawName)],
        {'explode': literalBool(explode)},
      );
  return Block.of([
    const Code('for (final entry in '),
    entries.code,
    const Code(') {'),
    _addTextPartExpression(
      refer('entry').property('name'),
      refer('entry').property('value'),
      rawContentType: 'text/plain',
      textEncoding: textEncoding,
      target: target,
      headers: headers,
    ),
    const Code('}'),
  ]);
}

Code _buildDelimitedListParts(
  String rawName,
  Expression value,
  Model content, {
  required PartEncoding encoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final needsMapping = content is! StringModel;
  final list = needsMapping
      ? value
            .property('map')
            .call([
              Method(
                (builder) => builder
                  ..lambda = true
                  ..requiredParameters.add(Parameter((p) => p..name = 'item'))
                  ..body = _listItemText(
                    refer('item'),
                    content,
                    encoding.contentType,
                  ).code,
              ).closure,
            ])
            .property('toList')
            .call([])
      : value;
  final isSpaceDelimited = encoding.style == EncodingStyle.spaceDelimited;
  final encoded = list
      .property(
        isSpaceDelimited ? 'toSpaceDelimited' : 'toPipeDelimited',
      )
      .call(
        [],
        {
          'explode': literalFalse,
          'allowEmpty': literalTrue,
          'alreadyEncoded': literalTrue,
          if (isSpaceDelimited) 'percentEncodeDelimiter': literalFalse,
          if (encoding.allowReserved ?? false) 'allowReserved': literalTrue,
        },
      );
  return Block.of([
    const Code('for (final item in '),
    encoded.code,
    const Code(') {'),
    _addTextPart(
      rawName,
      refer('item'),
      rawContentType: _wireContentType(encoding, 'text/plain'),
      textEncoding: encoding.textEncoding,
      target: target,
      headers: headers,
    ),
    const Code('}'),
  ]);
}

Expression _jsonListValue(Expression value, Model content) {
  if (content is ClassModel ||
      content is AllOfModel ||
      content is OneOfModel ||
      content is AnyOfModel) {
    return value
        .property('map')
        .call([
          Method(
            (builder) => builder
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'item'))
              ..body = refer('item').property('toJson').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  }
  if (content is EnumModel) {
    return value
        .property('map')
        .call([
          Method(
            (builder) => builder
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'item'))
              ..body = refer('item').property('toJson').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  }
  if (content is DateTimeModel) {
    return value
        .property('map')
        .call([
          Method(
            (builder) => builder
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'item'))
              ..body = refer(
                'item',
              ).property('toTimeZonedIso8601String').call([]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  }
  if (content is AnyModel) {
    return value
        .property('map')
        .call([
          Method(
            (builder) => builder
              ..lambda = true
              ..requiredParameters.add(Parameter((p) => p..name = 'item'))
              ..body = refer(
                'encodeAnyToJson',
                'package:tonik_util/tonik_util.dart',
              ).call([refer('item')]).code,
          ).closure,
        ])
        .property('toList')
        .call([]);
  }
  return value;
}

Expression _listItemText(
  Expression value,
  Model model,
  ContentType? contentType,
) => switch (model) {
  StringModel() => value,
  EnumModel() => _enumText(value, model, contentType),
  DateTimeModel() => _primitiveText(
    value,
    contentType,
    method: 'toTimeZonedIso8601String',
  ),
  PrimitiveModel() => _primitiveText(value, contentType, method: 'toString'),
  _ => value.property('toString').call([]),
};

String _wireContentType(PartEncoding? encoding, String fallback) =>
    encoding?.wireContentType ?? fallback;

TextEncoding _textEncoding(PartEncoding? encoding) =>
    encoding?.textEncoding ?? TextEncoding.utf8;

Expression _primitiveText(
  Expression value,
  ContentType? contentType, {
  required String method,
}) {
  if (contentType == ContentType.json) {
    return refer('jsonEncode', 'dart:convert').call([value]);
  }
  return value.property(method).call([]);
}

Expression _enumText(
  Expression value,
  EnumModel<dynamic> model,
  ContentType? contentType,
) {
  final json = value.property('toJson').call([]);
  if (contentType == ContentType.json) {
    return refer('jsonEncode', 'dart:convert').call([json]);
  }
  return model is EnumModel<String> ? json : json.property('toString').call([]);
}

Code _addFilePart(
  String rawName,
  Expression file, {
  required String rawContentType,
  required _MultipartTarget target,
  required Expression? headers,
}) => _addPart(
  specLiteralString(rawName),
  file.property('toBytes').call([]),
  rawContentType: rawContentType,
  filename: file.property('fileName').ifNullThen(specLiteralString(rawName)),
  target: target,
  headers: headers,
);

Code _addTextPart(
  String rawName,
  Expression text, {
  required String rawContentType,
  required TextEncoding textEncoding,
  required _MultipartTarget target,
  required Expression? headers,
}) => _addTextPartExpression(
  specLiteralString(rawName),
  text,
  rawContentType: rawContentType,
  textEncoding: textEncoding,
  target: target,
  headers: headers,
);

Code _addTextPartExpression(
  Expression name,
  Expression text, {
  required String rawContentType,
  required TextEncoding textEncoding,
  required _MultipartTarget target,
  required Expression? headers,
}) {
  final bytes = textEncodingExpression(
    textEncoding,
  ).property('encode').call([text]);
  return _addPart(
    name,
    bytes,
    rawContentType: rawContentType,
    target: target,
    headers: headers,
  );
}

Code _addPart(
  Expression name,
  Expression bytes, {
  required String rawContentType,
  required _MultipartTarget target,
  required Expression? headers,
  Expression? filename,
}) {
  if (target.usesCustomParts) {
    return refer(target.variableName).property('add').call([
      refer(
        'TonikMultipartPart',
        'package:tonik_util/tonik_util.dart',
      ).newInstance(
        [],
        {
          'name': name,
          'bytes': bytes,
          'contentType': specLiteralString(rawContentType),
          'filename': ?filename,
          'headers': ?headers,
        },
      ),
    ]).statement;
  }

  final namedArguments = <String, Expression>{
    'filename': ?filename,
    'contentType': refer(
      'MediaType',
      'package:http/http.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
  };
  return refer(target.variableName).property('add').call([
    refer(
      'MultipartFile',
      'package:http/http.dart',
    ).property('fromBytes').call(
      [name, bytes],
      namedArguments,
    ),
  ]).statement;
}

final class _HeaderMapResult {
  const _HeaderMapResult(this.statements, this.variableName);

  final List<Code> statements;
  final String variableName;
}

_HeaderMapResult? _buildHeaderMapStatements(
  RequestContent content,
  String normalizedPropertyName,
  PartEncoding? encoding, {
  required List<MultipartHeaderParamInfo> headerParameters,
  required bool isPropertyOptional,
}) {
  final entries = encoding?.headers?.entries
      .where((entry) => entry.key.toLowerCase() != 'content-type')
      .toList();
  if (entries == null || entries.isEmpty) return null;

  final variableName = '_\$${normalizedPropertyName}Headers';
  final statements = <Code>[
    declareFinal(variableName)
        .assign(
          literalMap(
            {},
            refer('String', 'dart:core'),
            refer('String', 'dart:core'),
          ),
        )
        .statement,
  ];

  for (final entry in entries) {
    final header = entry.value.resolve();
    final parameter = headerParameters.firstWhere(
      (parameter) =>
          identical(parameter.content, content) &&
          parameter.normalizedPropertyName == normalizedPropertyName &&
          parameter.rawHeaderName == entry.key,
    );
    final parameterReference = isPropertyOptional && header.isRequired
        ? refer(parameter.name).nullChecked
        : refer(parameter.name);
    final serialized = buildSimpleValueExpression(
      parameterReference,
      header.model,
      explode: header.explode,
      allowEmpty: true,
    ).unsafeRawBody;
    final assignment = refer(
      variableName,
    ).index(specLiteralString(entry.key)).assign(serialized).statement;

    if (header.isRequired) {
      statements.add(assignment);
    } else {
      statements.add(
        Block.of([
          const Code('if ('),
          refer(parameter.name).code,
          const Code(' != null) {'),
          assignment,
          const Code('}'),
        ]),
      );
    }
  }

  return _HeaderMapResult(statements, variableName);
}
