import 'package:tonik_parse/src/model/discriminator.dart';

class Schema {
  Schema({
    required this.ref,
    required this.type,
    required this.format,
    required this.required,
    required this.enumerated,
    required this.allOf,
    required this.anyOf,
    required this.oneOf,
    required this.not,
    required this.items,
    required this.properties,
    required this.description,
    required this.isNullable,
    required this.discriminator,
    required this.isDeprecated,
    required this.uniqueItems,
    required this.xDartName,
    required this.xDartEnum,
    required this.defs,
    required this.contentEncoding,
    required this.contentMediaType,
    required this.contentSchema,
    required this.rawDefault,
    this.additionalProperties,
    this.isReadOnly,
    this.isWriteOnly,
    this.isBooleanSchema,
    this.example,
    this.examples,
  });

  factory Schema.fromJson(Object? json) {
    return switch (json) {
      final bool boolSchema => Schema(
        ref: null,
        type: [],
        format: null,
        required: null,
        enumerated: null,
        allOf: null,
        anyOf: null,
        oneOf: null,
        not: null,
        items: null,
        properties: null,
        description: null,
        isNullable: null,
        discriminator: null,
        isDeprecated: null,
        uniqueItems: null,
        xDartName: null,
        xDartEnum: null,
        defs: null,
        contentEncoding: null,
        contentMediaType: null,
        contentSchema: null,
        rawDefault: null,
        isBooleanSchema: boolSchema,
      ),
      // Bare type strings (e.g., 'string' instead of {'type': 'string'}).
      final String typeString => Schema(
        ref: null,
        type: [typeString],
        format: null,
        required: null,
        enumerated: null,
        allOf: null,
        anyOf: null,
        oneOf: null,
        not: null,
        items: null,
        properties: null,
        description: null,
        isNullable: null,
        discriminator: null,
        isDeprecated: null,
        uniqueItems: null,
        xDartName: null,
        xDartEnum: null,
        defs: null,
        contentEncoding: null,
        contentMediaType: null,
        contentSchema: null,
        rawDefault: null,
      ),
      final Map<String, dynamic> map => Schema(
        ref: map[r'$ref'] as String?,
        type: const _SchemaTypeConverter().fromJson(map['type']),
        format: map['format'] as String?,
        required: (map['required'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        enumerated: map['enum'] as List<dynamic>?,
        allOf: const _SchemaListConverter().fromJson(map['allOf'] as List?),
        anyOf: const _SchemaListConverter().fromJson(map['anyOf'] as List?),
        oneOf: const _SchemaListConverter().fromJson(map['oneOf'] as List?),
        not: const SchemaConverter().fromJson(map['not']),
        items: const SchemaConverter().fromJson(map['items']),
        properties: const SchemaMapConverter().fromJson(
          map['properties'] as Map<String, dynamic>?,
        ),
        description: map['description'] as String?,
        isNullable: map['nullable'] as bool?,
        discriminator: map['discriminator'] == null
            ? null
            : Discriminator.fromJson(
                map['discriminator'] as Map<String, dynamic>,
              ),
        isDeprecated: map['deprecated'] as bool?,
        uniqueItems: map['uniqueItems'] as bool?,
        xDartName: map['x-dart-name'] as String?,
        xDartEnum: (map['x-dart-enum'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        defs: const SchemaMapConverter().fromJson(
          map[r'$defs'] as Map<String, dynamic>?,
        ),
        contentEncoding: map['contentEncoding'] as String?,
        contentMediaType: map['contentMediaType'] as String?,
        contentSchema: const SchemaConverter().fromJson(map['contentSchema']),
        additionalProperties: const _AdditionalPropertiesConverter().fromJson(
          map['additionalProperties'],
        ),
        isReadOnly: map['readOnly'] as bool?,
        isWriteOnly: map['writeOnly'] as bool?,
        rawDefault: map['default'],
        example: map['example'],
        examples: map['examples'] as List<dynamic>?,
      ),
      _ => throw const FormatException('Failed to load Schema.'),
    };
  }

  final String? ref;
  final List<String> type;
  final String? format;
  final List<String>? required;
  final List<dynamic>? enumerated;
  final List<Schema>? allOf;
  final List<Schema>? anyOf;
  final List<Schema>? oneOf;
  final Schema? not;
  final Schema? items;
  final Map<String, Schema>? properties;
  final String? description;
  final bool? isNullable;
  final Discriminator? discriminator;
  final bool? isDeprecated;
  final bool? uniqueItems;
  final String? xDartName;
  final List<String>? xDartEnum;
  final Map<String, Schema>? defs;
  final String? contentEncoding;
  final String? contentMediaType;
  final Schema? contentSchema;
  final Object? additionalProperties; // bool | Schema | null

  final bool? isReadOnly;
  final bool? isWriteOnly;

  /// Raw value of the `default` keyword as parsed from the spec.
  ///
  /// `null` is overloaded: it means both "no `default` keyword present" and
  /// "`default: null`". The two are treated identically downstream by design.
  final Object? rawDefault;

  /// OpenAPI 3.0 singular example value.
  final Object? example;

  /// OpenAPI 3.1 array of inline example values.
  final List<Object?>? examples;

  /// Indicates if this schema is a boolean schema (true/false).
  ///
  /// - `true`: Always validates (accepts any value)
  /// - `false`: Never validates (rejects all values)
  /// - `null`: Not a boolean schema (standard object schema)
  final bool? isBooleanSchema;

  // We ignore externalDocs, xml, title, multipleOf, maximum,
  // exclusiveMaximum, minimum, exclusiveMinimum, maxLength, minLength, pattern,
  // maxItems, minItems, maxProperties, minProperties.
  @override
  String toString() =>
      'Schema{ref: $ref, type: $type, format: $format, required: $required, '
      'enumerated: $enumerated, allOf: $allOf, anyOf: $anyOf, oneOf: $oneOf, '
      'not: $not, items: $items, properties: $properties, description: '
      '$description, isNullable: $isNullable, discriminator: $discriminator, '
      'isDeprecated: $isDeprecated, uniqueItems: $uniqueItems, '
      'xDartName: $xDartName, xDartEnum: $xDartEnum, '
      'contentEncoding: $contentEncoding, contentMediaType: $contentMediaType, '
      'contentSchema: $contentSchema, '
      'additionalProperties: $additionalProperties, '
      'isReadOnly: $isReadOnly, '
      'isWriteOnly: $isWriteOnly, isBooleanSchema: $isBooleanSchema, '
      'rawDefault: $rawDefault, '
      'example: $example, examples: $examples}';
}

class _AdditionalPropertiesConverter {
  const _AdditionalPropertiesConverter();

  Object? fromJson(Object? json) {
    if (json == null) return null;
    if (json is bool) return json;
    if (json is Map<String, dynamic>) return Schema.fromJson(json);
    throw FormatException('Invalid additionalProperties value: $json');
  }
}

class _SchemaTypeConverter {
  const _SchemaTypeConverter();

  List<String> fromJson(dynamic json) {
    if (json == null) return [];
    if (json is String) return [json];
    if (json is List) return json.cast<String>();
    throw FormatException('Invalid type value: $json');
  }
}

/// Converts a single schema from JSON, handling all schema representations.
class SchemaConverter {
  const SchemaConverter();

  Schema? fromJson(Object? json) {
    if (json == null) return null;
    return Schema.fromJson(json);
  }
}

/// Converts a list of schemas from JSON.
class _SchemaListConverter {
  const _SchemaListConverter();

  List<Schema>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return json.map(Schema.fromJson).toList();
  }
}

/// Converts a map of schemas from JSON.
class SchemaMapConverter {
  const SchemaMapConverter();

  Map<String, Schema>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return json.map((k, e) => MapEntry(k, Schema.fromJson(e)));
  }
}
