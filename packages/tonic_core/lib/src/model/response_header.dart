import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

sealed class ResponseHeader {
  const ResponseHeader({required this.name});

  final String name;
}

@immutable
class ResponseHeaderAlias extends ResponseHeader {
  const ResponseHeaderAlias({required super.name, required this.header});

  final ResponseHeader header;

  @override
  String toString() => 'HeaderAlias{name: $name, header: $header}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseHeaderAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          header == other.header;

  @override
  int get hashCode => Object.hash(name, header);
}

@immutable
class ResponseHeaderObject extends ResponseHeader {
  const ResponseHeaderObject({
    required super.name,
    required this.description,
    required this.explode,
    required this.model,
    required this.isRequired,
    required this.isDeprecated,
  });

  final String? description;
  final bool explode;
  final Model model;

  final bool isRequired;
  final bool isDeprecated;

  @override
  String toString() => 'HeaderObject{name: $name, description: $description, '
      'explode: $explode, model: $model, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseHeaderObject &&
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
