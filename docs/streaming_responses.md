# Streaming Responses

Tonik generates a single-subscription `Stream<TonikResult<T, R>>` for these response
media types with an explicit, usable `itemSchema`, regardless of OpenAPI version.
`T` is the item model; `R` is the backend-native response type:

| Media type | Item decoding |
|---|---|
| `application/x-ndjson` | One JSON value per record |
| `application/jsonl` | One JSON value per record |
| `text/event-stream` | SSE event map converted to the item model |

## Describe the Items

Use `itemSchema` in the response's content map:

```yaml
content:
  application/x-ndjson:
    itemSchema:
      type: object
      required: [value]
      properties:
        value: {type: integer}
```

Inline/referenced models, aliases, unions, and collections work as items,
including immutable collections. The item type can be nullable; `itemSchema: true`
uses `Object?`, and `false` uses `Never`, allowing an empty stream but rejecting
every item. The stream and result themselves are nonnullable.

`itemSchema` takes precedence over `schema` and `contentTypes` mappings. Items
are converted independently, without complete-schema or whole-sequence validation.
Missing, null, or non-parsable `itemSchema` keeps ordinary complete-body defaults
or configured handling. A media name or array `schema` alone enables neither
streaming nor buffered sequence-to-array decoding.

Media references support `#/components/mediaTypes/Name` and chains there, not
other target locations. Media `$ref` siblings are ignored; applicable siblings
on an item-schema `$ref` use normal schema handling. Missing internal targets
fail when resolved. External media uses defaults or omission; resolved external
schemas, including item schemas, throw `UnimplementedError`.

## Consume and Cancel

This example uses the [streaming fixture](../integration_test/streaming_response/openapi.yaml).
Replace its package import and URL for your API.

```dart
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:tonik_util/tonik_util.dart';

Future<void> main() async {
  final server = CustomServer(baseUrl: 'https://api.example.com');
  final api = StreamingApi(server);
  final cancellation = TonikCancellation();
  switch (await api.getItems(cancellation: cancellation)) {
    case TonikSuccess(:final value):
      await for (final item in value) {
        switch (item) {
          case TonikSuccess(:final value):
            print(value.value);
          case TonikError(:final error, :final type):
            print('Stream failed ($type): $error');
        }
      }
    case TonikError(:final error):
      print('Request failed: $error');
  }
  server.close();
}
```

Incremental backends select the response and decode modeled headers before
returning, without waiting for an item or EOF. Existing status/media variants,
header wrappers, and aliases keep the stream in their body field. Complete
alternatives buffer normally; modeled HTTP errors and application-error union
items remain ordinary variants or data.

Consume once; `toList()` waits for EOF and retains every item. For manual control,
use `listen()` and its subscription's `pause()`, `resume()`, or `cancel()`;
`break` in an `await for` also cancels. Call the supplied
`cancellation.cancel()` to abandon a pending request or an unlistened response.
Signals are forwarded to the backend; network buffering still applies.
[Client ownership](http_backends.md#client-configuration-and-ownership) is unchanged.

Pre-return failures use the outer `TonikError`. Each streamed item is a
`TonikSuccess`; the first failure is a `TonikError` data event, then the stream
ends. Error results retain the native response, cause, stack trace, and error type:
framing/conversion failures are `decoding`, transport failures are `network`,
and backend abort events are `cancelled` when applicable. No error catch is
needed for these failures. Subscription cancellation emits no further results.

## Framing

**NDJSON/JSONL:** strict UTF-8 without a BOM, with LF/CRLF record boundaries.
Empty records are skipped, whitespace-only records fail, and valid final records
without a newline are accepted. Skipping empty JSONL records and accepting
unterminated NDJSON records are fixed, non-configurable receive leniencies.
NDJSON allows raw CR only before a delimiting LF; JSONL also permits it as JSON
whitespace outside strings, never as a record separator.

**SSE:** replacement UTF-8 decoding, one initial BOM removed, and LF/CRLF/CR
boundaries. A blank line dispatches a block containing `data`, including empty
data. Unfinished events at EOF, comments, and unknown fields are discarded.

- The envelope has string `data` (multiline values joined with LF) and optional
  `event`, `id`, and integer `retry`. Explicit empty strings are preserved.
- Fields are case-sensitive, split at the first colon, and lose one leading
  ASCII space when present. Colonless `data` supplies an empty value.
- For `event`, `id`, and `retry`, the last valid value wins. NUL-containing IDs
  and retries other than nonempty ASCII digits are ignored without erasing earlier
  valid values. Only the last valid retry in a dispatched event is range-checked:
  `0`–`9007199254740991`
  (`2^53 - 1`), otherwise a decoding error. IDs/retries are not inherited.

`data` stays a string even with embedded-JSON annotations. Tonik does not
reconnect, replay, send `Last-Event-ID`, or schedule retries.

## Backends and Metadata

| Backend | Delivery |
|---|---|
| Dio on native Dart | Incremental |
| `package:http` on native Dart and browsers | Incremental |
| Dio standard browser adapter | Finite responses buffered until completion |

For incremental browser streaming, [generate with `--backend http`](configuration.md#http-backend).
Dio's default browser adapter [cannot deliver an endless stream](https://github.com/cfug/dio/issues/1740); pending requests can
still be cancelled. Custom clients/middleware may buffer or ignore abort;
resource-release timing is backend-dependent. HTTP 1.6.0 native
abort-before-listen has a resource-release limitation.

Native status, headers, and request metadata remain on `.response`, including
each item result:

- **Dio:** `dio.Response<Object?>`.
- **HTTP:** ordinary operations use `http.Response`; streaming-capable operations
  use `http.BaseResponse`. Streamed/no-body branches retain `http.StreamedResponse`
  metadata; buffered branches carry `http.Response`.

The typed stream and native body share one consumption. Use `.response` for
metadata, without also reading its raw stream. There is no replayable copy or
second buffered API. See [HTTP Backends](http_backends.md#native-boundary).

Streamed requests, parameters, headers, multipart streams, JSON Text Sequences
(`application/json-seq`), and structured streaming suffixes remain unsupported.
Maintained native/browser checks are described in [Contributing](../CONTRIBUTING.md#common-commands).
