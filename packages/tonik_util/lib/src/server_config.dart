import 'package:meta/meta.dart';

/// Backend-neutral client configuration for a generated server.
///
/// An injected [client] is borrowed: generated servers never close it.
/// A client returned by [clientFactory], or a default client created when
/// neither field is provided, is owned and closed by the generated server.
@immutable
class const ServerConfig<Client extends Object>._({
  /// A client borrowed by the generated server.
  ///
  /// The generated server preserves this object's identity and never closes
  /// it.
  required final Client? client,

  /// Creates the client owned by the generated server.
  ///
  /// Generated servers invoke this lazily, cache the returned client, and
  /// close it when the server is closed.
  required final Client Function()? clientFactory,
}) {
  /// Uses the generated server's default client.
  const new() : this._(client: null, clientFactory: null);

  /// Borrows [client]; generated servers never close it.
  const new client(Client client) : this._(client: client, clientFactory: null);

  /// Lazily creates an owned client with [clientFactory].
  const new clientFactory(Client Function() clientFactory)
    : this._(client: null, clientFactory: clientFactory);
}
