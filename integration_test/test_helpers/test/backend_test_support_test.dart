import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('testServerConfig', () {
    test('infers and creates the Dio client required by a server', () async {
      final recorder = TestRequestRecorder();
      final server = _DioServer(
        serverConfig: testServerConfig(
          headers: {'X-Test': 'dio'},
          recorder: recorder,
          response: const TestResponseStub(),
        ),
      );
      final client = server.serverConfig.clientFactory!();
      addTearDown(() => client.close());

      await client.get<Object?>('https://example.com/dio');

      expect(recorder.request?.uri, Uri.parse('https://example.com/dio'));
      expect(recorder.request?.headers['X-Test'], 'dio');
    });

    test('infers and creates the HTTP client required by a server', () async {
      final recorder = TestRequestRecorder();
      final server = _HttpServer(
        serverConfig: testServerConfig(
          headers: {
            'X-Test': 'configured',
            'X-Default': 'configured',
          },
          recorder: recorder,
          response: const TestResponseStub(),
        ),
      );
      final client = server.serverConfig.clientFactory!();
      addTearDown(client.close);

      await client.get(
        Uri.parse('https://example.com/http'),
        headers: {'X-Test': 'operation'},
      );

      expect(recorder.request?.uri, Uri.parse('https://example.com/http'));
      expect(recorder.request?.headers['X-Test'], 'operation');
      expect(recorder.request?.headers['X-Default'], 'configured');
    });
  });

  group('requireSuccess', () {
    test('normalizes a Dio response and preserves the decoded value', () {
      final request = dio.RequestOptions(
        baseUrl: 'https://example.com',
        path: '/dio',
        method: 'POST',
      );
      final result = TonikSuccess<String, dio.Response<Object?>>(
        'dio-value',
        dio.Response<Object?>(
          requestOptions: request,
          statusCode: 201,
          data: {'created': true},
        ),
      );

      final success = requireSuccess(result);

      expect(success.value, 'dio-value');
      expect(success.response.statusCode, 201);
      expect(success.response.requestOptions.uri, request.uri);
      expect(success.response.requestOptions.method, 'POST');
      expect(success.response.data, {'created': true});
    });

    test('normalizes an HTTP response and preserves the decoded value', () {
      final request = http.Request(
        'POST',
        Uri.parse('https://example.com/http'),
      );
      final result = TonikSuccess<String, http.Response>(
        'http-value',
        http.Response.bytes(
          [1, 2, 3],
          202,
          request: request,
          headers: {
            'x-values': 'first, second',
            'set-cookie': 'id=one; Expires=Wed, 21 Oct 2015 07:28:00 GMT,'
                'session=two; Path=/',
          },
        ),
      );

      final success = requireSuccess(result);

      expect(success.value, 'http-value');
      expect(success.response.statusCode, 202);
      expect(success.response.requestOptions.uri, request.url);
      expect(success.response.requestOptions.method, 'POST');
      expect(success.response.data, [1, 2, 3]);
      expect(success.response.headers['x-values'], ['first', 'second']);
      expect(success.response.headers['set-cookie'], [
        'id=one; Expires=Wed, 21 Oct 2015 07:28:00 GMT',
        'session=two; Path=/',
      ]);
    });
  });
}

final class _DioServer {
  const _DioServer({required this.serverConfig});

  final ServerConfig<dio.Dio> serverConfig;
}

final class _HttpServer {
  const _HttpServer({required this.serverConfig});

  final ServerConfig<http.Client> serverConfig;
}
