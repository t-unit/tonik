# Authentication Guide

Tonik documents OpenAPI security requirements in generated library and method
comments. It does not generate authentication code. Configure authentication
on the selected HTTP client and pass that client through `ServerConfig`.

## Dio

Use a client factory for Dio options, interceptors, and adapters:

```dart
import 'package:dio/dio.dart';
import 'package:tonik_util/tonik_util.dart';
import 'package:your_api/your_api.dart';

final token = 'your-token';

final server = CustomServer(
  baseUrl: 'https://api.example.com',
  serverConfig: ServerConfig<Dio>.clientFactory(
    () => Dio(
      BaseOptions(connectTimeout: const Duration(seconds: 10)),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            handler.next(options);
          },
        ),
      ),
  ),
);
```

The factory is called lazily at most once per server. The generated server owns
the returned Dio instance and closes it when `server.close()` is called. The
generated server URL is applied after the factory returns, so it takes
precedence over `BaseOptions.baseUrl`.

If the application already owns a configured Dio instance, borrow it instead:

```dart
final dio = Dio()..interceptors.add(authInterceptor);
final config = ServerConfig<Dio>.client(dio);
```

The application remains responsible for closing an injected client.

## `package:http`

Wrap `http.Client` to add authentication to each request:

```dart
import 'package:http/http.dart' as http;
import 'package:tonik_util/tonik_util.dart';
import 'package:your_api/your_api.dart';

final class AuthClient extends http.BaseClient {
  AuthClient(this._token) : _inner = http.Client();

  final String _token;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final server = CustomServer(
  baseUrl: 'https://api.example.com',
  serverConfig: ServerConfig<http.Client>.clientFactory(
    () => AuthClient('your-token'),
  ),
);
```

The generated server owns and closes the factory-created wrapper. Pass an
existing wrapper with `ServerConfig<http.Client>.client(...)` when the
application should retain ownership.

Token refresh, retries, OAuth flows, API-key placement, and TLS configuration
belong in the interceptor or client wrapper. Tonik does not interpret security
schemes at runtime.

## Generated Security Documentation

Generated library documentation lists the security schemes declared by the
OpenAPI document. Generated API methods list their applicable schemes and
OAuth scopes. Use those comments to configure the client; they do not imply
runtime authentication support.

See [HTTP Backends](http_backends.md) for backend selection, client ownership,
and migration guidance.
