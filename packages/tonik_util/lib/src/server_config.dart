import 'package:meta/meta.dart';

/// Backend-neutral client configuration for a generated server.
///
/// An injected [client] is borrowed: generated servers never close it.
/// A client returned by [clientFactory], or a default client created when
/// neither field is provided, is conceptually owned by the generated server.
/// Generated servers currently do not close owned clients either.
@immutable
class ServerConfig<Client extends Object> {
  /// Creates client configuration for a generated server.
  const ServerConfig({this.client, this.clientFactory})
    : assert(
        client == null || clientFactory == null,
        'client and clientFactory cannot both be provided',
      );

  /// A client borrowed by the generated server.
  ///
  /// The generated server preserves this object's identity and never closes
  /// it.
  final Client? client;

  /// Creates the client conceptually owned by the generated server.
  ///
  /// Generated servers invoke this lazily and cache the returned client. They
  /// currently do not close it.
  final Client Function()? clientFactory;
}
