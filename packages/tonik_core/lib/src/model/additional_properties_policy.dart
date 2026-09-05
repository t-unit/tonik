import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/model.dart';

enum AdditionalPropertiesOrigin() {
  implicitDefault,
  explicit,
}

sealed class const AdditionalPropertiesPolicy();

@immutable
final class const ForbiddenAdditionalProperties()
    extends AdditionalPropertiesPolicy {
  @override
  bool operator ==(Object other) => other is ForbiddenAdditionalProperties;

  @override
  int get hashCode => (ForbiddenAdditionalProperties).hashCode;

  @override
  String toString() => 'ForbiddenAdditionalProperties';
}

@immutable
final class const AllowedAdditionalProperties({
  required final Model valueModel,
  final AdditionalPropertiesOrigin origin = AdditionalPropertiesOrigin.explicit,
}) extends AdditionalPropertiesPolicy {
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
