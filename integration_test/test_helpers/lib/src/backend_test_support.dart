import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'backend_test_support_dio.dart' as dio_backend;
import 'backend_test_support_http.dart' as http_backend;
import 'test_result.dart';

/// Creates the backend configuration required by the generated server.
///
/// [Client] is inferred from the generated server constructor.
ServerConfig<Client> testServerConfig<Client extends Object>({
  Map<String, String> headers = const {},
  TestRequestRecorder? recorder,
  TestResponseStub? response,
}) {
  if (Client == dio.Dio) {
    return dio_backend.dioTestServerConfig(
      headers: headers,
      recorder: recorder,
      response: response,
    ) as ServerConfig<Client>;
  }
  if (Client == http.Client) {
    return http_backend.httpTestServerConfig(
      headers: headers,
      recorder: recorder,
      response: response,
    ) as ServerConfig<Client>;
  }
  throw UnsupportedError('Unsupported integration client type: $Client.');
}

/// Requires a successful result and retains portable response details.
TestSuccess<T> requireSuccess<T, Response extends Object>(
  TonikResult<T, Response> result,
) =>
    switch (result) {
      TonikSuccess(:final value, :final response) => TestSuccess(
          value,
          _testResponse(response),
        ),
      TonikError(:final error, :final type) => fail(
          'Expected TonikSuccess, got TonikError($type, $error).',
        ),
    };

/// Requires an error result and retains portable response details.
TestError requireError<T, Response extends Object>(
  TonikResult<T, Response> result,
) =>
    switch (result) {
      TonikSuccess() => fail('Expected TonikError, got TonikSuccess.'),
      TonikError(
        :final error,
        :final stackTrace,
        :final type,
        :final response,
      ) =>
        TestError(
          error: error,
          stackTrace: stackTrace,
          type: type,
          response: response == null ? null : _testResponse(response),
        ),
    };

TestResponse _testResponse(Object response) {
  if (response is dio.Response<Object?>) {
    return dio_backend.dioTestResponse(response);
  }
  if (response is http.Response) {
    return http_backend.httpTestResponse(response);
  }
  throw UnsupportedError(
    'Unsupported integration response type: ${response.runtimeType}.',
  );
}
