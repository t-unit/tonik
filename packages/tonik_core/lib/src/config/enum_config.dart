import 'package:meta/meta.dart';

/// Configuration for enum generation.
@immutable
class const EnumConfig({
  /// Whether to generate an unknown case for forward compatibility.
  final bool generateUnknownCase = false,

  /// Name for the unknown case.
  final String unknownCaseName = 'unknown',
}) {
  @override
  String toString() =>
      'EnumConfig{generateUnknownCase: $generateUnknownCase, '
      'unknownCaseName: $unknownCaseName}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnumConfig &&
          runtimeType == other.runtimeType &&
          generateUnknownCase == other.generateUnknownCase &&
          unknownCaseName == other.unknownCaseName;

  @override
  int get hashCode => Object.hash(generateUnknownCase, unknownCaseName);
}
