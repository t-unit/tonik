import 'package:meta/meta.dart';

@immutable
class Tag {
  const Tag({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;

  @override
  String toString() => 'Tag{name: $name, description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => Object.hash(name, description);
}
