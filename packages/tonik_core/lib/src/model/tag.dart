/// Represents a tag that groups related operations in an API.
class Tag {
  Tag({required this.name, this.description, this.nameOverride});

  final String name;

  String? description;
  String? nameOverride;

  @override
  String toString() =>
      'Tag{name: $name, nameOverride: $nameOverride, '
      'description: $description}';
}
