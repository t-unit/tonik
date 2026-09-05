import 'package:http/http.dart' as http;
import 'package:tonik_util/tonik_util.dart';

import 'test_result.dart';

ServerConfig<http.Client> httpTestServerConfig({
  required Map<String, String> headers,
}) => ServerConfig.clientFactory(() => _HeaderClient(headers));

final class _HeaderClient extends http.BaseClient {
  _HeaderClient(this._headers) : _inner = http.Client();

  final Map<String, String> _headers;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    for (final entry in _headers.entries) {
      request.headers.putIfAbsent(entry.key, () => entry.value);
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

TestResponse httpTestResponse(http.Response response) => TestResponse(
  statusCode: response.statusCode,
  headers: TestHeaders(response.headersSplitValues),
  data: response.bodyBytes,
);
