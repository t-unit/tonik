# HTTP Backends

Tonik generates a client backed by either
[`package:dio`](https://pub.dev/packages/dio) or
[`package:http`](https://pub.dev/packages/http). Dio is the default.

Backend selection happens during generation and applies to the whole generated
package. To switch, change the configuration and regenerate. See
[Configuration](configuration.md#http-backend).

## Portable API

Models, servers, API clients, operation parameters, decoded values,
`TonikCancellation`, and error categories have the same shape with both
backends:

```dart
import 'package:tonik_util/tonik_util.dart';
import 'package:your_api/your_api.dart';

final server = CustomServer(baseUrl: 'https://api.example.com');
final api = PetApi(server);
final cancellation = TonikCancellation();

try {
  final result = await api.getPetById(
    petId: 1,
    cancellation: cancellation,
  );

  switch (result) {
    case TonikSuccess(:final value):
      print(value);
    case TonikError(:final type):
      print(type);
  }
} finally {
  server.close();
}
```

Code that only uses this surface can switch backends without changing its API
calls or result handling.

## Client Configuration and Ownership

Generated servers accept the shared `ServerConfig<Client>` type:

| Configuration | Client lifetime | Closed by `server.close()` |
|---|---|---|
| `const ServerConfig()` | Created lazily by the server | Yes |
| `ServerConfig.client(client)` | Supplied and owned by the caller | No |
| `ServerConfig.clientFactory(factory)` | Created lazily and cached by the server | Yes |

`server.close()` is safe to call more than once. A closed server cannot be used
for another request.

## Native Boundary

Client customization and raw response inspection use backend-native types:

| | Dio | `package:http` |
|---|---|---|
| Server configuration | `ServerConfig<Dio>` | `ServerConfig<http.Client>` |
| Resolved client | `server.dio` | `server.client` |
| Result response | `dio.Response<Object?>` | `http.Response` |

`TonikSuccess.response` contains the completed native response.
`TonikError.response` contains it when the backend produced a complete
response, otherwise it is `null`. Code that reads these fields is intentionally
backend-specific.

For authentication and other request customization, see the
[Authentication Guide](authentication.md).

With `package:http`, a custom client controls whether it honors request
cancellation. Response headers use `headersSplitValues`; the original
distinction between repeated field lines and comma-separated values cannot
always be recovered.

## Migrating Existing Clients

Regenerate the client package before updating application code. Regeneration
provides the selected backend, portable cancellation, lifecycle handling, and
the curated public exports.

Then update affected call sites:

1. Move Dio configuration into a client factory:

   ```dart
   // Before
   final config = ServerConfig(
     baseOptions: BaseOptions(connectTimeout: const Duration(seconds: 10)),
     interceptors: [authInterceptor],
   );

   // After
   final config = ServerConfig<Dio>.clientFactory(
     () => Dio(
       BaseOptions(connectTimeout: const Duration(seconds: 10)),
     )..interceptors.add(authInterceptor),
   );
   ```

2. Replace Dio cancellation tokens with `TonikCancellation`:

   ```dart
   // Before
   final cancellation = CancelToken();
   final result = await api.getPetById(
     petId: 1,
     cancelToken: cancellation,
   );

   // After
   final cancellation = TonikCancellation();
   final result = await api.getPetById(
     petId: 1,
     cancellation: cancellation,
   );
   ```

   `cancellation.cancel()` still cancels the request.

3. Call operations through generated API clients. Replace direct construction
   of classes such as `GetPetById` with `PetApi(server).getPetById(...)`.
   Low-level operation classes are no longer exported from the package root.

4. Add the native response type to explicit result annotations:

   ```dart
   // Before
   TonikResult<GetPetByIdResponse>

   // Dio output
   TonikResult<GetPetByIdResponse, dio.Response<Object?>>

   // package:http output
   TonikResult<GetPetByIdResponse, http.Response>
   ```

   Inferred result variables and patterns that only read `value`, `error`, or
   `type` usually need no change.

Application code that imports a backend type directly should also declare that
backend package as a direct dependency.

To move an existing generated package from Dio to `package:http`, select the
new backend and regenerate. Only custom client setup and code that inspects the
native response should require backend-specific changes.
