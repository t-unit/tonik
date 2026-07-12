import 'package:tonik_core/src/model/model.dart';
import 'package:tonik_core/src/util/context.dart';

/// Whether an additional-properties policy was written in the document or
/// is the JSON Schema default for an omitted keyword.
enum AdditionalPropertiesOrigin { implicitDefault, explicit }

/// Semantic additional-properties policy of an object-like schema.
///
/// Unrestricted additional properties are not a separate category: they are
/// [AllowedAdditionalProperties] with an [AnyModel] value model.
sealed class AdditionalPropertiesPolicy {
  const AdditionalPropertiesPolicy();

  /// Normalizes a legacy [AdditionalProperties] state into a policy.
  ///
  /// One-to-one with the importer states: an omitted keyword (null) is the
  /// implicit JSON Schema default, `true`/`{}` are explicit Any values, a
  /// schema is an explicit typed value, and `false` is forbidden.
  factory AdditionalPropertiesPolicy.fromLegacy(
    AdditionalProperties? legacy,
    Context context,
  ) => switch (legacy) {
    null => AllowedAdditionalProperties(
      valueModel: AnyModel(context: context),
      origin: AdditionalPropertiesOrigin.implicitDefault,
    ),
    UnrestrictedAdditionalProperties() => AllowedAdditionalProperties(
      valueModel: AnyModel(context: context),
      origin: AdditionalPropertiesOrigin.explicit,
    ),
    TypedAdditionalProperties(:final valueModel) => AllowedAdditionalProperties(
      valueModel: valueModel,
      origin: AdditionalPropertiesOrigin.explicit,
    ),
    NoAdditionalProperties() => const ForbiddenAdditionalProperties(),
  };

  /// Projects this policy back onto the legacy [AdditionalProperties] view
  /// consumed by not-yet-migrated generators.
  AdditionalProperties? get legacyView => switch (this) {
    ForbiddenAdditionalProperties() => const NoAdditionalProperties(),
    AllowedAdditionalProperties(
      valueModel: AnyModel(),
      origin: AdditionalPropertiesOrigin.implicitDefault,
    ) =>
      null,
    AllowedAdditionalProperties(
      valueModel: AnyModel(),
      origin: AdditionalPropertiesOrigin.explicit,
    ) =>
      const UnrestrictedAdditionalProperties(),
    AllowedAdditionalProperties(:final valueModel) => TypedAdditionalProperties(
      valueModel: valueModel,
    ),
  };
}

/// `additionalProperties: false` — extra keys are schema-invalid; no map
/// field is generated and no runtime validation is performed.
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
final class AllowedAdditionalProperties extends AdditionalPropertiesPolicy {
  const AllowedAdditionalProperties({
    required this.valueModel,
    required this.origin,
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
