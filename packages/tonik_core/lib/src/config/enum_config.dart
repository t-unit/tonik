import 'package:meta/meta.dart';

/// Configuration for enum generation.
@immutable
class EnumConfig {
  const EnumConfig({
    this.generateUnknownCase = false,
    this.unknownCaseName = 'unknown',
  });

  /// Whether to generate an unknown case for forward compatibility.
  final bool generateUnknownCase;

  /// Name for the unknown case.
  final String unknownCaseName;

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
