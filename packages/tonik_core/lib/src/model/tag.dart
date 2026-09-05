/// Represents a tag that groups related operations in an API.
class Tag({
  required final String name,
  var String? description,
  var String? nameOverride,
}) {
  @override
  String toString() =>
      'Tag{name: $name, nameOverride: $nameOverride, '
      'description: $description}';
}
