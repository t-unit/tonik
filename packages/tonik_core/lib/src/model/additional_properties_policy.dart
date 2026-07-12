import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/model.dart';

/// Source of an additional-properties policy.
enum AdditionalPropertiesOrigin { implicitDefault, explicit }

/// Additional-properties policy of an object-like schema.
sealed class AdditionalPropertiesPolicy {
  const AdditionalPropertiesPolicy();
}

/// Forbids additional properties.
@immutable
final class ForbiddenAdditionalProperties extends AdditionalPropertiesPolicy {
  const ForbiddenAdditionalProperties();

  @override
  bool operator ==(Object other) => other is ForbiddenAdditionalProperties;

  @override
  int get hashCode => (ForbiddenAdditionalProperties).hashCode;

  @override
  String toString() => 'ForbiddenAdditionalProperties';
}

/// Allows additional properties whose values use [valueModel].
@immutable
final class AllowedAdditionalProperties extends AdditionalPropertiesPolicy {
  const AllowedAdditionalProperties({
    required this.valueModel,
    this.origin = AdditionalPropertiesOrigin.explicit,
  });

  final Model valueModel;
  final AdditionalPropertiesOrigin origin;

  @override
  bool operator ==(Object other) =>
      other is AllowedAdditionalProperties &&
      other.valueModel == valueModel &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(valueModel, origin);

  @override
  String toString() =>
      'AllowedAdditionalProperties{origin: ${origin.name}, '
      'valueModel: ${valueModel.runtimeType}}';
}
