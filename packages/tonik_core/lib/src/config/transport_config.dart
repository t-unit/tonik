import 'package:meta/meta.dart';

/// Transport backend emitted into a generated package.
enum TransportBackend {
  /// Generate a client backed by `package:dio`.
  dio,

  /// Generate a client backed by `package:http`.
  http,
}

/// Package-wide generation-time transport configuration.
@immutable
final class TransportConfig {
  const TransportConfig({this.backend = TransportBackend.dio});

  /// Backend emitted into the generated package.
  final TransportBackend backend;

  @override
  String toString() => 'TransportConfig{backend: $backend}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportConfig &&
          runtimeType == other.runtimeType &&
          backend == other.backend;

  @override
  int get hashCode => backend.hashCode;
}
