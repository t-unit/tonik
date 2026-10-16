import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Configuration for filtering which parts of the spec to generate.
@immutable
class const FilterConfig({
  /// Tags to include. If empty, all tags are included.
  required final List<String> includeTags,

  /// Tags to exclude from generation.
  required final List<String> excludeTags,

  /// Operation IDs to exclude from generation.
  required final List<String> excludeOperations,

  /// Schema names to exclude from generation.
  required final List<String> excludeSchemas,
}) {
  static const _listEquality = ListEquality<String>();

  @override
  String toString() =>
      'FilterConfig{includeTags: $includeTags, excludeTags: $excludeTags, '
      'excludeOperations: $excludeOperations, excludeSchemas: $excludeSchemas}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterConfig &&
          runtimeType == other.runtimeType &&
          _listEquality.equals(includeTags, other.includeTags) &&
          _listEquality.equals(excludeTags, other.excludeTags) &&
          _listEquality.equals(excludeOperations, other.excludeOperations) &&
          _listEquality.equals(excludeSchemas, other.excludeSchemas);

  @override
  int get hashCode => Object.hash(
    _listEquality.hash(includeTags),
    _listEquality.hash(excludeTags),
    _listEquality.hash(excludeOperations),
    _listEquality.hash(excludeSchemas),
  );
}
