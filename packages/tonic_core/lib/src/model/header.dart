import 'package:tonic_core/tonic_core.dart';

class Header {
  Header({
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
  String toString() =>
      'Header{name: $name, description: $description, explode: $explode, model: $model, '
      'isRequired: $isRequired, isDeprecated: $isDeprecated}';
}
