/// Represents a tag that groups related operations in an API.
class Tag({
  required final String name,
  required var String? description,
  required var String? nameOverride,
}) {
  @override
  String toString() =>
      'Tag{name: $name, nameOverride: $nameOverride, '
      'description: $description}';
}
