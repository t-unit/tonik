import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/discriminator.dart';

part 'schema.g.dart';

@JsonSerializable(createToJson: false)
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
    this.isBooleanSchema,
  });

  factory Schema.fromJson(Object? json) {
    if (json is bool) {
      return Schema(
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
        isBooleanSchema: json,
      );
    }

    // Handle bare type strings (e.g., 'string' instead of {'type': 'string'}).
    if (json is String) {
      return Schema(
        ref: null,
        type: [json],
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
      );
    }

    return _$SchemaFromJson(json! as Map<String, dynamic>);
  }

  @JsonKey(name: r'$ref')
  final String? ref;
  @_SchemaTypeConverter()
  final List<String> type;
  final String? format;
  final List<String>? required;
  @JsonKey(name: 'enum')
  final List<dynamic>? enumerated;
  @_SchemaListConverter()
  final List<Schema>? allOf;
  @_SchemaListConverter()
  final List<Schema>? anyOf;
  @_SchemaListConverter()
  final List<Schema>? oneOf;
  @SchemaConverter()
  final Schema? not;
  @SchemaConverter()
  final Schema? items;
  @SchemaMapConverter()
  final Map<String, Schema>? properties;
  final String? description;
  @JsonKey(name: 'nullable')
  final bool? isNullable;
  final Discriminator? discriminator;
  @JsonKey(name: 'deprecated')
  final bool? isDeprecated;
  final bool? uniqueItems;
  @JsonKey(name: 'x-dart-name')
  final String? xDartName;
  @JsonKey(name: 'x-dart-enum')
  final List<String>? xDartEnum;
  @JsonKey(name: r'$defs')
  @SchemaMapConverter()
  final Map<String, Schema>? defs;
  @JsonKey(name: 'contentEncoding')
  final String? contentEncoding;
  @JsonKey(name: 'contentMediaType')
  final String? contentMediaType;

  /// Indicates if this schema is a boolean schema (true/false).
  ///
  /// - `true`: Always validates (accepts any value)
  /// - `false`: Never validates (rejects all values)
  /// - `null`: Not a boolean schema (standard object schema)
  @JsonKey(includeFromJson: false)
  final bool? isBooleanSchema;

  // We ignore example, externalDocs, xml, writeOnly, readOnly, default, title,
  // multipleOf, maximum, exclusiveMaximum, minimum, exclusiveMinimum,
  // maxLength, minLength, pattern, maxItems, minItems, maxProperties,
  // minProperties additionalProperties and externalDocs properties.

  @override
  String toString() =>
      'Schema{ref: $ref, type: $type, format: $format, required: $required, '
      'enumerated: $enumerated, allOf: $allOf, anyOf: $anyOf, oneOf: $oneOf, '
      'not: $not, items: $items, properties: $properties, description: '
      '$description, isNullable: $isNullable, discriminator: $discriminator, '
      'isDeprecated: $isDeprecated, uniqueItems: $uniqueItems, '
      'xDartName: $xDartName, xDartEnum: $xDartEnum, '
      'contentEncoding: $contentEncoding, contentMediaType: $contentMediaType, '
      'isBooleanSchema: $isBooleanSchema}';
}

class _SchemaTypeConverter implements JsonConverter<List<String>, dynamic> {
  const _SchemaTypeConverter();

  @override
  List<String> fromJson(dynamic json) {
    if (json == null) return [];
    if (json is String) return [json];
    if (json is List) return json.cast<String>();
    throw FormatException('Invalid type value: $json');
  }

  @override
  dynamic toJson(List<String> types) {
    if (types.isEmpty) return null;
    if (types.length == 1) return types.first;
    return types;
  }
}

/// Converts a single schema from JSON, handling all schema representations.
class SchemaConverter implements JsonConverter<Schema?, Object?> {
  const SchemaConverter();

  @override
  Schema? fromJson(Object? json) {
    if (json == null) return null;
    return Schema.fromJson(json);
  }

  @override
  Object? toJson(Schema? schema) => throw UnimplementedError();
}

/// Converts a list of schemas from JSON.
class _SchemaListConverter
    implements JsonConverter<List<Schema>?, List<dynamic>?> {
  const _SchemaListConverter();

  @override
  List<Schema>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return json.map(Schema.fromJson).toList();
  }

  @override
  List<dynamic>? toJson(List<Schema>? schemas) => throw UnimplementedError();
}

/// Converts a map of schemas from JSON.
class SchemaMapConverter
    implements JsonConverter<Map<String, Schema>?, Map<String, dynamic>?> {
  const SchemaMapConverter();

  @override
  Map<String, Schema>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return json.map((k, e) => MapEntry(k, Schema.fromJson(e)));
  }

  @override
  Map<String, dynamic>? toJson(Map<String, Schema>? schemas) =>
      throw UnimplementedError();
}
