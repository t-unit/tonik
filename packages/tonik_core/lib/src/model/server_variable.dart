import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Represents a server variable for URL template substitution.
@immutable
class ServerVariable {
  const ServerVariable({
    required this.name,
    required this.defaultValue,
    this.enumValues,
    this.description,
  });

  final String name;
  final String defaultValue;
  final List<String>? enumValues;
  final String? description;

  @override
  String toString() =>
      'ServerVariable{'
      'name: $name, '
      'defaultValue: $defaultValue, '
      'enumValues: $enumValues, '
      'description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerVariable &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          defaultValue == other.defaultValue &&
          const ListEquality<String>().equals(enumValues, other.enumValues) &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
    name,
    defaultValue,
    enumValues == null ? null : const ListEquality<String>().hash(enumValues),
    description,
  );
}
