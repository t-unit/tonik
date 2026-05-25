import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class Example {
  const Example({
    this.name,
    this.summary,
    this.description,
    this.value,
  });

  final String? name;
  final String? summary;
  final String? description;
  final Object? value;

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
