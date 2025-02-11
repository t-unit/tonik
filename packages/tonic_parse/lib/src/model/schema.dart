import 'package:json_annotation/json_annotation.dart';
import 'package:tonic_parse/src/model/discriminator.dart';
import 'package:tonic_parse/src/model/reference.dart';

part 'schema.g.dart';

@JsonSerializable()
class Schema {
  Schema({
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
  });

  factory Schema.fromJson(Map<String, dynamic> json) => _$SchemaFromJson(json);

  final String? type;
  final String? format;
  final List<String>? required;
  @JsonKey(name: 'enum')
  final List<dynamic>? enumerated;
  final List<ReferenceWrapper<Schema>>? allOf;
  final List<ReferenceWrapper<Schema>>? anyOf;
  final List<ReferenceWrapper<Schema>>? oneOf;
  final ReferenceWrapper<Schema>? not;
  final ReferenceWrapper<Schema>? items;
  final Map<String, ReferenceWrapper<Schema>>? properties;
  final String? description;
  @JsonKey(name: 'nullable')
  final bool? isNullable;
  final Discriminator? discriminator;
  @JsonKey(name: 'deprecated')
  final bool? isDeprecated;
  final bool? uniqueItems;

  // We ignore example, externalDocs, xml, writeOnly, readOnly, default, title,
  // multipleOf, maximum, exclusiveMaximum, minimum, exclusiveMinimum,
  // maxLength, minLength, pattern, maxItems, minItems, maxProperties,
  // minProperties additionalProperties and externalDocs properties.

  @override
  String toString() =>
      'Schema{type: $type, format: $format, required: $required, '
      'enumerated: $enumerated, allOf: $allOf, anyOf: $anyOf, oneOf: $oneOf, '
      'not: $not, items: $items, properties: $properties, description: '
      '$description, isNullable: $isNullable, discriminator: $discriminator, '
      'isDeprecated: $isDeprecated, uniqueItems: $uniqueItems}';
}
