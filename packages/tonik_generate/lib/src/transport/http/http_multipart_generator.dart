import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Lowers one multipart body to an ordered list of `package:http` parts.
///
/// Every OpenAPI part is represented as a `MultipartFile` in generated code.
/// This deliberately avoids `MultipartRequest.fields`, whose map shape cannot
/// preserve duplicate names or ordering relative to file parts.
List<Code> buildHttpMultipartBodyStatements(
  RequestContent content,
  String bodyAccessor, {
  List<MultipartHeaderParamInfo> headerParameters = const [],
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

  final statements = <Code>[
    declareFinal(r'_$multipartFiles')
        .assign(
          literalList(
            [],
            refer('MultipartFile', 'package:http/http.dart'),
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
      headerParameters: headerParameters,
      isPropertyOptional: isNullable,
    );
    final part = _buildPart(
      property.model,
      property.name,
      value,
      encoding: content.multipartEncoding?[property],
      headerVarName: headerResult?.headerVarName,
    );
    final partStatements = [
      ...?headerResult?.statements,
      part,
    ];

    if (isNullable) {
      statements.add(
        Block.of([
          const Code('if ('),
          accessor.code,
          const Code(' != null) {'),
          ...partStatements,
          const Code('}'),
        ]),
      );
    } else {
      statements.addAll(partStatements);
    }
  }

  statements.add(refer(r'_$multipartFiles').returned.statement);
  return statements;
}

/// Whether generated parts need a marker to retain Dio-compatible field
/// introspection while preserving ordered duplicate names on the wire.
bool httpMultipartContentHasPlainFields(RequestContent content) {
  final model = content.model.resolved;
  if (model is! ClassModel) return false;

  for (final property in model.properties.where(
    (property) => !property.isReadOnly,
  )) {
    final encoding = content.multipartEncoding?[property];
    if (_partUsesPlainFields(property.model, encoding)) return true;
  }
  return false;
}

bool _partUsesPlainFields(Model model, PartEncoding? encoding) {
  final hasHeaders =
      encoding?.headers?.keys.any(
        (name) => name.toLowerCase() != 'content-type',
      ) ??
      false;
  if (hasHeaders) return false;

  final resolved = model.resolved;
  if (resolved is ClassModel || resolved is CompositeModel) {
    return encoding?.style == EncodingStyle.deepObject;
  }
  if (resolved is! ListModel) return false;

  final content = resolved.content.resolved;
  if (content is BinaryModel || content is Base64Model) return false;

  final isStyleBased = encoding?.isStyleBased ?? false;
  if (!isStyleBased &&
      encoding?.contentType != null &&
      encoding?.contentType != ContentType.text) {
    return false;
  }
  return content is! ClassModel &&
      content is! CompositeModel &&
      content is! MapModel &&
      content is! AnyModel;
}

Code _buildPart(
  Model model,
  String rawName,
  Expression value, {
  required PartEncoding? encoding,
  required String? headerVarName,
}) {
  final resolved = model.resolved;
  return switch (resolved) {
    BinaryModel() || Base64Model() => _addFilePart(
      rawName,
      value,
      rawContentType: _rawContentType(
        encoding,
        'application/octet-stream',
      ),
      headerVarName: headerVarName,
    ),
    ListModel() => _buildListParts(
      rawName,
      value,
      resolved,
      encoding: encoding,
      headerVarName: headerVarName,
    ),
    NeverModel() => generateEncodingExceptionExpression(
      "Cannot encode NeverModel property '$rawName' - this type does not "
      'permit any value.',
      raw: true,
    ).statement,
    StringModel() => _addTextPart(
      rawName,
      value,
      rawContentType: _rawContentType(encoding, 'text/plain'),
      headerVarName: headerVarName,
    ),
    AnyModel() => _addTextPart(
      rawName,
      refer('jsonEncode', 'dart:convert').call([
        refer(
          'encodeAnyToJson',
          'package:tonik_util/tonik_util.dart',
        ).call([value]),
      ]),
      rawContentType: _rawContentType(encoding, 'application/json'),
      headerVarName: headerVarName,
    ),
    MapModel() => _buildMapPart(
      rawName,
      value,
      encoding: encoding,
      headerVarName: headerVarName,
    ),
    ClassModel() || CompositeModel() => _buildObjectPart(
      rawName,
      value,
      encoding: encoding,
      headerVarName: headerVarName,
    ),
    EnumModel() => _addTextPart(
      rawName,
      _enumText(value, resolved, encoding?.contentType),
      rawContentType: _rawContentType(encoding, 'text/plain'),
      headerVarName: headerVarName,
    ),
    DateTimeModel() => _addTextPart(
      rawName,
      _primitiveText(
        value,
        encoding?.contentType,
        method: 'toTimeZonedIso8601String',
      ),
      rawContentType: _rawContentType(encoding, 'text/plain'),
      headerVarName: headerVarName,
    ),
    PrimitiveModel() => _addTextPart(
      rawName,
      _primitiveText(value, encoding?.contentType, method: 'toString'),
      rawContentType: _rawContentType(encoding, 'text/plain'),
      headerVarName: headerVarName,
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
  required String? headerVarName,
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
        rawContentType: _rawContentType(
          encoding,
          'application/octet-stream',
        ),
        headerVarName: headerVarName,
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
      rawContentType: _rawContentType(encoding, 'application/json'),
      headerVarName: headerVarName,
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
        rawContentType: _rawContentType(encoding, 'application/json'),
        headerVarName: headerVarName,
      ),
      const Code('}'),
    ]);
  }

  final explode = encoding?.explode ?? true;
  if (!explode) {
    final delimited = switch (encoding?.style) {
      EncodingStyle.pipeDelimited => value.property('toPipeDelimited').call(
        [],
        {
          'explode': literalFalse,
          'allowEmpty': literalTrue,
          'alreadyEncoded': literalTrue,
        },
      ),
      EncodingStyle.spaceDelimited => value.property('toSpaceDelimited').call(
        [],
        {
          'explode': literalFalse,
          'allowEmpty': literalTrue,
          'alreadyEncoded': literalTrue,
          'percentEncodeDelimiter': literalFalse,
        },
      ),
      _ => null,
    };
    if (delimited != null) {
      return Block.of([
        const Code('for (final item in '),
        delimited.code,
        const Code(') {'),
        _addTextPart(
          rawName,
          refer('item'),
          rawContentType: _rawContentType(encoding, 'text/plain'),
          headerVarName: headerVarName,
          isPlainField: headerVarName == null,
        ),
        const Code('}'),
      ]);
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
      rawContentType: _rawContentType(encoding, 'text/plain'),
      headerVarName: headerVarName,
      isPlainField: headerVarName == null,
    );
  }

  return Block.of([
    const Code('for (final item in '),
    value.code,
    const Code(') {'),
    _addTextPart(
      rawName,
      _listItemText(refer('item'), content, encoding?.contentType),
      rawContentType: _rawContentType(encoding, 'text/plain'),
      headerVarName: headerVarName,
      isPlainField: headerVarName == null,
    ),
    const Code('}'),
  ]);
}

Code _buildMapPart(
  String rawName,
  Expression value, {
  required PartEncoding? encoding,
  required String? headerVarName,
}) {
  if (encoding?.style == EncodingStyle.deepObject) {
    return generateEncodingExceptionExpression(
      'deepObject style is not supported for map multipart properties '
      '(property: $rawName). Maps do not implement '
      'ParameterEncodable.toDeepObject().',
      raw: true,
    ).statement;
  }

  final isStyleBased = encoding?.isStyleBased ?? false;
  if (!isStyleBased && encoding?.contentType == ContentType.form) {
    return _addTextPart(
      rawName,
      Method(
        (method) => method
          ..lambda = false
          ..body = Block.of([
            declareFinal(
              'parts',
            ).assign(literalList([], refer('String', 'dart:core'))).statement,
            const Code('for (final entry in ('),
            value.asA(refer('Map', 'dart:core')).code,
            const Code(').entries) {'),
            const Code('  final value = entry.value;'),
            const Code('  if (value == null) continue;'),
            const Code('  if (value is '),
            refer('Map', 'dart:core').code,
            const Code(' || value is '),
            refer('List', 'dart:core').code,
            const Code(') {'),
            refer('EncodingException', 'package:tonik_util/tonik_util.dart')
                .newInstance([
                  literalString(
                    'Standard URL encoding does not support nested values '
                    '(property: $rawName). Only flat key=value pairs are '
                    'allowed.',
                  ),
                ])
                .thrown
                .statement,
            const Code('  }'),
            refer('parts').property('add').call([
              literalList([
                refer(
                  'Uri',
                  'dart:core',
                ).property('encodeQueryComponent').call([
                  refer('entry').property('key').property('toString').call([]),
                ]),
                refer('Uri', 'dart:core').property('encodeQueryComponent').call(
                  [
                    refer('value').property('toString').call([]),
                  ],
                ),
              ]).property('join').call([literalString('=')]),
            ]).statement,
            const Code('}'),
            refer(
              'parts',
            ).property('join').call([literalString('&')]).returned.statement,
          ]),
      ).closure.call([]),
      rawContentType: 'application/x-www-form-urlencoded',
      headerVarName: headerVarName,
    );
  }

  return _addTextPart(
    rawName,
    refer('jsonEncode', 'dart:convert').call([value]),
    rawContentType: _rawContentType(encoding, 'application/json'),
    headerVarName: headerVarName,
  );
}

Code _buildObjectPart(
  String rawName,
  Expression value, {
  required PartEncoding? encoding,
  required String? headerVarName,
}) {
  if (encoding?.style == EncodingStyle.deepObject) {
    final entries = value
        .property('toDeepObject')
        .call(
          [specLiteralString(rawName)],
          {'explode': literalTrue, 'allowEmpty': literalTrue},
        );
    return Block.of([
      const Code('for (final entry in '),
      entries.code,
      const Code(') {'),
      _addTextPartExpression(
        refer('entry').property('name'),
        refer('entry').property('value'),
        rawContentType: 'application/x-www-form-urlencoded',
        headerVarName: headerVarName,
        isPlainField: headerVarName == null,
      ),
      const Code('}'),
    ]);
  }

  final isStyleBased = encoding?.isStyleBased ?? false;
  if (isStyleBased) {
    final style = encoding?.style;
    if (style != null && style != EncodingStyle.form) {
      return generateEncodingExceptionExpression(
        '${style.name} style is not supported for object multipart part '
        '$rawName',
        raw: true,
      ).statement;
    }
    final parts = value
        .property('parameterProperties')
        .call([], {'allowEmpty': literalTrue})
        .property('toRawStyleParts')
        .call(
          [specLiteralString(rawName)],
          {'explode': literalBool(encoding?.explode ?? true)},
        );
    return Block.of([
      const Code(r'for (final _$part in '),
      parts.code,
      const Code(') {'),
      _addTextPartExpression(
        refer(r'_$part').property('name'),
        refer(r'_$part').property('value'),
        rawContentType: 'text/plain',
        headerVarName: headerVarName,
      ),
      const Code('}'),
    ]);
  }

  if (encoding?.contentType == ContentType.form) {
    final entries = value
        .property('toForm')
        .call(
          [specLiteralString(rawName)],
          {
            'explode': literalTrue,
            'allowEmpty': literalTrue,
            'useQueryComponent': literalTrue,
          },
        );
    final encoded = entries
        .property('map')
        .call([
          Method(
            (method) => method
              ..lambda = true
              ..requiredParameters.add(
                Parameter((parameter) => parameter..name = 'entry'),
              )
              ..body = const Code(r"'${entry.name}=${entry.value}'"),
          ).closure,
        ])
        .property('join')
        .call([literalString('&')]);
    return _addTextPart(
      rawName,
      encoded,
      rawContentType: 'application/x-www-form-urlencoded',
      headerVarName: headerVarName,
    );
  }

  return _addTextPart(
    rawName,
    refer('jsonEncode', 'dart:convert').call([
      value.property('toJson').call([]),
    ]),
    rawContentType: _rawContentType(encoding, 'application/json'),
    headerVarName: headerVarName,
  );
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

String _rawContentType(PartEncoding? encoding, String fallback) =>
    encoding?.rawContentType ?? fallback;

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
  required String? headerVarName,
}) => _addPart(
  rawName,
  file.property('toBytes').call([]),
  rawContentType: rawContentType,
  filename: file.property('fileName').ifNullThen(specLiteralString(rawName)),
  headerVarName: headerVarName,
);

Code _addTextPart(
  String rawName,
  Expression text, {
  required String rawContentType,
  required String? headerVarName,
  bool isPlainField = false,
}) {
  final encoding = _encoding(rawContentType);
  if (encoding == null) {
    return generateEncodingExceptionExpression(
      'Unsupported multipart text encoding: ${_charset(rawContentType)}.',
    ).statement;
  }
  return _addPart(
    rawName,
    encoding.property('encode').call([text]),
    rawContentType: rawContentType,
    headerVarName: headerVarName,
    isPlainField: isPlainField,
  );
}

Code _addTextPartExpression(
  Expression rawName,
  Expression text, {
  required String rawContentType,
  required String? headerVarName,
  bool isPlainField = false,
}) {
  final encoding = _encoding(rawContentType);
  if (encoding == null) {
    return generateEncodingExceptionExpression(
      'Unsupported multipart text encoding: ${_charset(rawContentType)}.',
    ).statement;
  }
  return _addPartExpression(
    rawName,
    encoding.property('encode').call([text]),
    rawContentType: rawContentType,
    headerVarName: headerVarName,
    isPlainField: isPlainField,
  );
}

Code _addPart(
  String rawName,
  Expression bytes, {
  required String rawContentType,
  required String? headerVarName,
  Expression? filename,
  bool isPlainField = false,
}) => _addPartExpression(
  specLiteralString(rawName),
  bytes,
  rawContentType: rawContentType,
  headerVarName: headerVarName,
  filename: filename,
  isPlainField: isPlainField,
);

Code _addPartExpression(
  Expression rawName,
  Expression bytes, {
  required String rawContentType,
  required String? headerVarName,
  Expression? filename,
  bool isPlainField = false,
}) {
  final namedArguments = <String, Expression>{
    'filename': ?filename,
    'contentType': refer(
      'MediaType',
      'package:http/http.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
    if (headerVarName != null) 'partHeaders': refer(headerVarName),
    if (isPlainField) 'isPlainField': literalTrue,
  };
  return refer(r'_$multipartFiles').property('add').call([
    (headerVarName == null && !isPlainField
            ? refer('MultipartFile', 'package:http/http.dart')
            : refer('_TonikMultipartFile'))
        .property('fromBytes')
        .call(
          [rawName, bytes],
          namedArguments,
        ),
  ]).statement;
}

final class _HeaderMapResult {
  const _HeaderMapResult(this.statements, this.headerVarName);

  final List<Code> statements;
  final String headerVarName;
}

_HeaderMapResult? _buildHeaderMapStatements(
  RequestContent content,
  String normalizedPropertyName,
  PartEncoding? encoding, {
  required List<MultipartHeaderParamInfo> headerParameters,
  required bool isPropertyOptional,
}) {
  final headers = encoding?.headers;
  if (headers == null || headers.isEmpty) return null;

  final filteredEntries = headers.entries
      .where((entry) => entry.key.toLowerCase() != 'content-type')
      .toList();
  if (filteredEntries.isEmpty) return null;

  final headerVarName = '_\$${normalizedPropertyName}Headers';
  final statements = <Code>[
    declareFinal(headerVarName)
        .assign(
          literalMap(
            {},
            refer('String', 'dart:core'),
            refer('String', 'dart:core'),
          ),
        )
        .statement,
  ];

  for (final entry in filteredEntries) {
    final header = entry.value.resolve();
    final parameter = headerParameters.firstWhere(
      (candidate) =>
          candidate.content == content &&
          candidate.normalizedPropertyName == normalizedPropertyName &&
          candidate.rawHeaderName == entry.key,
    );
    final parameterValue = isPropertyOptional && header.isRequired
        ? refer(parameter.name).nullChecked
        : refer(parameter.name);
    final serialized = buildSimpleValueExpression(
      parameterValue,
      header.model,
      explode: header.explode,
      allowEmpty: true,
    ).unsafeRawBody;
    final assignment = refer(
      headerVarName,
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

  return _HeaderMapResult(statements, headerVarName);
}

Expression? _encoding(String rawContentType) =>
    switch (_charset(rawContentType)) {
      'utf-8' || 'utf8' => refer('utf8', 'dart:convert'),
      'iso-8859-1' || 'latin1' => refer('latin1', 'dart:convert'),
      'us-ascii' || 'ascii' => refer('ascii', 'dart:convert'),
      _ => null,
    };

String _charset(String rawContentType) =>
    RegExp(
      r'(?:^|;)\s*charset\s*=\s*"?([^";\s]+)',
      caseSensitive: false,
    ).firstMatch(rawContentType)?.group(1)?.toLowerCase() ??
    'utf-8';
