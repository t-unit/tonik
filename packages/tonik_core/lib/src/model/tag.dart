/// Represents a tag that groups related operations in an API.
class Tag {
  Tag({required this.name, this.description, this.nameOverride});

  final String name;

  String? description;
  String? nameOverride;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          nameOverride == other.nameOverride;

  @override
  int get hashCode => Object.hash(name, description, nameOverride);

  @override
  String toString() =>
      'Tag{name: $name, nameOverride: $nameOverride, '
      'description: $description}';
}
