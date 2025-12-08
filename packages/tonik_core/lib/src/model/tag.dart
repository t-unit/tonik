/// Represents a tag that groups related operations in an API.
class Tag {
  Tag({required this.name, this.description, this.nameOverride});

  // ID - immutable
  final String name;

  // Metadata/Config - mutable
  String? description;
  String? nameOverride;

  @override
  String toString() =>
      'Tag{name: $name, nameOverride: $nameOverride, '
      'description: $description}';
}
