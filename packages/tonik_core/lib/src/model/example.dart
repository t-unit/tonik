import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class const Example({
  required final String? name,
  required final String? summary,
  required final String? description,
  required final Object? value,
}) {
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Example) return false;
    return name == other.name &&
        summary == other.summary &&
        description == other.description &&
        const DeepCollectionEquality().equals(value, other.value);
  }

  @override
  int get hashCode => Object.hash(
    name,
    summary,
    description,
    const DeepCollectionEquality().hash(value),
  );

  @override
  String toString() =>
      'Example(name: $name, summary: $summary, '
      'description: $description, value: $value)';
}
