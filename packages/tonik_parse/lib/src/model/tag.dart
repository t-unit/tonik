import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class Tag {
  Tag({required this.name, required this.description});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  final String name;
  final String? description;

  // We ignore externalDocs property.

  @override
  String toString() => 'Tag{name: $name, description: $description}';
}
