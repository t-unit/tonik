import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Normalizes readOnly and writeOnly properties in ClassModels.
///
/// Properties marked as readOnly or writeOnly are set to non-required,
/// because they will be absent in at least one serialization direction:
/// - writeOnly properties are excluded from deserialization (fromJson).
/// - readOnly properties are excluded from serialization (toJson) and
///   parameter encoding (fromSimple, fromForm).
@immutable
class ReadWriteOnlyNormalizer {
  const ReadWriteOnlyNormalizer();

  static final _log = Logger('ReadWriteOnlyNormalizer');

  void apply(ApiDocument document) {
    document.models.forEach(_normalizeModel);
  }

  void _normalizeModel(Model model) {
    if (model is! ClassModel) return;

    for (final property in model.properties) {
      if ((property.isReadOnly || property.isWriteOnly) &&
          property.isRequired) {
        final direction = property.isReadOnly ? 'readOnly' : 'writeOnly';
        _log.warning(
          'Making $direction property "${property.name}" non-required '
          'on ${model.name ?? 'anonymous'} '
          'at ${model.context}.',
        );
        property.isRequired = false;
      }
    }
  }
}
