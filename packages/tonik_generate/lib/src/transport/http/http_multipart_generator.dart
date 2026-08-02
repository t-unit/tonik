import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
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
  String bodyAccessor,
) {
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
    final part = _buildPart(
      property.model,
      property.name,
      value,
      encoding: content.multipartEncoding?[property],
    );

    if (isNullable) {
      statements.add(
        Block.of([
          const Code('if ('),
          accessor.code,
          const Code(' != null) {'),
          part,
          const Code('}'),
        ]),
      );
    } else {
      statements.add(part);
    }
  }

  statements.add(refer(r'_$multipartFiles').returned.statement);
  return statements;
}

Code _buildPart(
  Model model,
  String rawName,
  Expression value, {
  required PartEncoding? encoding,
}) {
  final resolved = model.resolved;
  return switch (resolved) {
    BinaryModel() || Base64Model() => _addFilePart(
      rawName,
      value,
      rawContentType: encoding?.rawContentType ?? 'application/octet-stream',
    ),
    ListModel() => _buildListParts(
      rawName,
      value,
      resolved,
      encoding: encoding,
    ),
    NeverModel() => generateEncodingExceptionExpression(
      "Cannot encode NeverModel property '$rawName' - this type does not "
      'permit any value.',
      raw: true,
    ).statement,
    StringModel() => _addTextPart(
      rawName,
      value,
      rawContentType: encoding?.rawContentType ?? 'text/plain',
    ),
    AnyModel() => _addTextPart(
      rawName,
      refer('jsonEncode', 'dart:convert').call([
        refer(
          'encodeAnyToJson',
          'package:tonik_util/tonik_util.dart',
        ).call([value]),
      ]),
      rawContentType: encoding?.rawContentType ?? 'application/json',
    ),
    MapModel() => _addTextPart(
      rawName,
      refer('jsonEncode', 'dart:convert').call([value]),
      rawContentType: encoding?.rawContentType ?? 'application/json',
    ),
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _addTextPart(
      rawName,
      refer(
        'jsonEncode',
        'dart:convert',
      ).call([value.property('toJson').call([])]),
      rawContentType: encoding?.rawContentType ?? 'application/json',
    ),
    EnumModel() => _addTextPart(
      rawName,
      _enumText(value, resolved, encoding?.contentType),
      rawContentType: encoding?.rawContentType ?? 'text/plain',
    ),
    DateTimeModel() => _addTextPart(
      rawName,
      _primitiveText(
        value,
        encoding?.contentType,
        method: 'toTimeZonedIso8601String',
      ),
      rawContentType: encoding?.rawContentType ?? 'text/plain',
    ),
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() => _addTextPart(
      rawName,
      _primitiveText(value, encoding?.contentType, method: 'toString'),
      rawContentType: encoding?.rawContentType ?? 'text/plain',
    ),
    AliasModel() => _buildPart(
      resolved,
      rawName,
      value,
      encoding: encoding,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for multipart encoding.',
    ).statement,
  };
}

Code _buildListParts(
  String rawName,
  Expression value,
  ListModel model, {
  required PartEncoding? encoding,
}) {
  final content = model.content.resolved;
  if (content is ListModel) {
    return generateEncodingExceptionExpression(
      'Arrays of arrays are not supported for multipart encoding '
      '(property: $rawName).',
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
        rawContentType: encoding?.rawContentType ?? 'application/octet-stream',
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
      rawContentType: encoding?.rawContentType ?? 'application/json',
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
        rawContentType: encoding?.rawContentType ?? 'application/json',
      ),
      const Code('}'),
    ]);
  }

  final explode = encoding?.explode ?? true;
  if (!explode) {
    final serialized = buildSimpleValueExpression(
      value,
      model,
      explode: false,
      allowEmpty: true,
    ).unsafeRawBody;
    return _addTextPart(
      rawName,
      serialized,
      rawContentType: encoding?.rawContentType ?? 'text/plain',
    );
  }

  return Block.of([
    const Code('for (final item in '),
    value.code,
    const Code(') {'),
    _addTextPart(
      rawName,
      _listItemText(refer('item'), content, encoding?.contentType),
      rawContentType: encoding?.rawContentType ?? 'text/plain',
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
  IntegerModel() ||
  DoubleModel() ||
  NumberModel() ||
  BooleanModel() ||
  DateModel() ||
  DecimalModel() ||
  UriModel() => _primitiveText(value, contentType, method: 'toString'),
  AliasModel() => _listItemText(value, model.resolved, contentType),
  _ => value.property('toString').call([]),
};

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
}) => _addPart(
  rawName,
  file.property('toBytes').call([]),
  rawContentType: rawContentType,
  filename: file.property('fileName').ifNullThen(specLiteralString(rawName)),
);

Code _addTextPart(
  String rawName,
  Expression text, {
  required String rawContentType,
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
  );
}

Code _addPart(
  String rawName,
  Expression bytes, {
  required String rawContentType,
  Expression? filename,
}) {
  final namedArguments = <String, Expression>{
    'filename': ?filename,
    'contentType': refer(
      'MediaType',
      'package:http/http.dart',
    ).property('parse').call([specLiteralString(rawContentType)]),
  };
  return refer(r'_$multipartFiles').property('add').call([
    refer(
      'MultipartFile',
      'package:http/http.dart',
    ).property('fromBytes').call(
      [specLiteralString(rawName), bytes],
      namedArguments,
    ),
  ]).statement;
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
