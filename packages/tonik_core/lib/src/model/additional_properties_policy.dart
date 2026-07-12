import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/model.dart';

/// Whether an additional-properties policy was written in the document or
/// is the JSON Schema default for an omitted keyword.
enum AdditionalPropertiesOrigin { implicitDefault, explicit }

/// Semantic additional-properties policy of an object-like schema.
///
/// Unrestricted additional properties are not a separate category: they are
/// [AllowedAdditionalProperties] with an [AnyModel] value model.
sealed class AdditionalPropertiesPolicy {
  const AdditionalPropertiesPolicy();
}

/// `additionalProperties: false` — extra keys are schema-invalid; no map
/// field is generated and no runtime validation is performed.
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

/// Additional properties are allowed and their values use [valueModel].
///
/// [origin] defaults to explicit because a hand-constructed policy models a
/// written keyword; only an omitted keyword is the implicit default, which
/// the model constructors and the importer supply themselves.
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
