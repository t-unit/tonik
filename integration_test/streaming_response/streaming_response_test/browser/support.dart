import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

const browserTestOrigin = String.fromEnvironment('STREAMING_TEST_ORIGIN');
const testDeadline = Duration(seconds: 5);

ServerConfig<Client> browserClientConfig<Client extends Object>(
  Object client,
) => ServerConfig.client(client as Client);

TonikSuccess<T, Object> requireSuccess<T>(TonikResult<T, Object> result) =>
    switch (result) {
      TonikSuccess() => result,
      TonikError(:final error, :final type) => fail(
        'Expected success, got $type: $error',
      ),
    };

final class ResponseControl {
  final http.Client _client = http.Client();

  Future<void> start({required String contentType, String initial = '\n'}) =>
      _post('start', {'contentType': contentType, 'initial': initial});

  Future<void> waitForRequest() => _post('wait');

  Future<void> write(String bytes) => _post('write', {'bytes': bytes});

  Future<void> finish() => _post('finish');

  Future<bool> get reachedEof async {
    final response = await _client
        .get(Uri.parse('$browserTestOrigin/control/state'))
        .timeout(testDeadline);
    expect(response.statusCode, 200, reason: response.body);
    return (jsonDecode(response.body) as Map<String, dynamic>)['eof'] as bool;
  }

  Future<void> _post(
    String action, [
    Map<String, String> data = const {},
  ]) async {
    final response = await _client
        .post(
          Uri.parse('$browserTestOrigin/control/$action'),
          body: jsonEncode(data),
        )
        .timeout(testDeadline);
    expect(response.statusCode, 200, reason: response.body);
  }

  void close() => _client.close();
}
