import 'package:meta/meta.dart';

/// Backend-neutral client configuration for a generated server.
///
/// An injected [client] is borrowed: generated servers never close it.
/// A client returned by [clientFactory], or a default client created when
/// neither field is provided, is owned and closed by the generated server.
@immutable
class ServerConfig<Client extends Object> {
  /// Creates configuration that lets the generated server create its default
  /// client.
  const ServerConfig() : client = null, clientFactory = null;

  /// Creates configuration that borrows [client].
  const ServerConfig.client(Client this.client) : clientFactory = null;

  /// Creates configuration that lazily invokes [clientFactory].
  const ServerConfig.clientFactory(Client Function() this.clientFactory)
    : client = null;

  /// A client borrowed by the generated server.
  ///
  /// The generated server preserves this object's identity and never closes
  /// it.
  final Client? client;

  /// Creates the client owned by the generated server.
  ///
  /// Generated servers invoke this lazily, cache the returned client, and
  /// close it when the server is closed.
  final Client Function()? clientFactory;
}
