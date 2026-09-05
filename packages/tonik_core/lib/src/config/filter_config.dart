import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Configuration for filtering which parts of the spec to generate.
@immutable
class const FilterConfig({
  /// Tags to include. If empty, all tags are included.
  final List<String> includeTags = const [],

  /// Tags to exclude from generation.
  final List<String> excludeTags = const [],

  /// Operation IDs to exclude from generation.
  final List<String> excludeOperations = const [],

  /// Schema names to exclude from generation.
  final List<String> excludeSchemas = const [],
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
