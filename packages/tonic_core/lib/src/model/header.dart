import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

@immutable
class Header {
  const Header({
    required this.name,
    required this.description,
    required this.explode,
    required this.model,
    required this.isRequired,
    required this.isDeprecated,
  });

  final String name;
  final String? description;
  final bool explode;
  final Model model;

  final bool isRequired;
  final bool isDeprecated;

  @override
  String toString() => 'Header{name: $name, description: $description, '
      'explode: $explode, model: $model, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Header &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          explode == other.explode &&
          model == other.model &&
          isRequired == other.isRequired &&
          isDeprecated == other.isDeprecated;

  @override
  int get hashCode => Object.hash(
        name,
        description,
        explode,
        model,
        isRequired,
        isDeprecated,
      );
}
