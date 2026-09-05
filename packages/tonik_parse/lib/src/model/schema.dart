import 'package:tonik_parse/src/model/discriminator.dart';

class Schema({
  required final String? ref,
  required final List<String?> type,
  required final String? format,
  required final List<String>? required,
  required final List<dynamic>? enumerated,
  required final List<Schema>? allOf,
  required final List<Schema>? anyOf,
  required final List<Schema>? oneOf,
  required final Schema? not,
  required final Schema? items,
  required final Map<String, Schema>? properties,
  required final String? description,
  required final bool? isNullable,
  required final Discriminator? discriminator,
  required final bool? isDeprecated,
  required final bool? uniqueItems,
  required final String? xDartName,
  required final List<String>? xDartEnum,
  required final Map<String, Schema>? defs,
  required final String? contentEncoding,
  required final String? contentMediaType,
  required final Schema? contentSchema,
  required final Object? rawDefault,
  final Object? additionalProperties,
  final bool? isReadOnly,
  final bool? isWriteOnly,

  /// Indicates if this schema is a boolean schema (true/false).
  ///
  /// - `true`: Always validates (accepts any value)
  /// - `false`: Never validates (rejects all values)
  /// - `null`: Not a boolean schema (standard object schema)
  final bool? isBooleanSchema,

  /// OpenAPI 3.0 singular example value.
  final Object? example,

  /// OpenAPI 3.1 array of inline example values.
  final List<Object?>? examples,
}) {
  factory fromJson(Object? json) {
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

  // bool | Schema | null

  bool get hasNullType => type.any((t) => t == null || t == 'null');

  List<String> get nonNullTypes =>
      type.nonNulls.where((t) => t != 'null').toList();

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

class const _AdditionalPropertiesConverter() {
  Object? fromJson(Object? json) {
    if (json == null) return null;
    if (json is bool) return json;
    if (json is Map<String, dynamic>) return Schema.fromJson(json);
    throw FormatException('Invalid additionalProperties value: $json');
  }
}

class const _SchemaTypeConverter() {
  List<String?> fromJson(dynamic json) {
    if (json == null) return [];
    if (json is String) return [json];
    if (json is List) {
      return [
        for (final element in json)
          switch (element) {
            null => null,
            final String type => type,
            _ => throw FormatException('Invalid type value: $json'),
          },
      ];
    }
    throw FormatException('Invalid type value: $json');
  }
}

/// Converts a single schema from JSON, handling all schema representations.
class const SchemaConverter() {
  Schema? fromJson(Object? json) {
    if (json == null) return null;
    return Schema.fromJson(json);
  }
}

/// Converts a list of schemas from JSON.
class const _SchemaListConverter() {
  List<Schema>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return json.map(Schema.fromJson).toList();
  }
}

/// Converts a map of schemas from JSON.
class const SchemaMapConverter() {
  Map<String, Schema>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return json.map((k, e) => MapEntry(k, Schema.fromJson(e)));
  }
}
