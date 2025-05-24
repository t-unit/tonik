import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('ServerConfig', () {
    test('creates with default values', () {
      const config = ServerConfig();

      expect(config.baseOptions, isNull);
      expect(config.interceptors, isEmpty);
      expect(config.httpClientAdapter, isNull);
    });

    test('creates with custom values', () {
      final baseOptions = BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      );
      final interceptors = [LogInterceptor()];
      final httpClientAdapter = HttpClientAdapter();

      final config = ServerConfig(
        baseOptions: baseOptions,
        interceptors: interceptors,
        httpClientAdapter: httpClientAdapter,
      );

      expect(config.baseOptions, baseOptions);
      expect(config.interceptors, interceptors);
      expect(config.httpClientAdapter, httpClientAdapter);
    });

    test('creates dio with server url', () {
      const config = ServerConfig();
      final dio = Dio();
      config.configureDio(dio, 'https://api.example.com');
      expect(dio.options.baseUrl, 'https://api.example.com');
    });

    test('configures Dio instance preserving server URL', () {
      const serverUrl = 'https://api.example.com';
      final baseOptions = BaseOptions(
        baseUrl: 'https://should-be-overridden.com',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      );
      final interceptor = LogInterceptor();
      final httpClientAdapter = HttpClientAdapter();

      final config = ServerConfig(
        baseOptions: baseOptions,
        interceptors: [interceptor],
        httpClientAdapter: httpClientAdapter,
      );

      final dio = Dio(BaseOptions(baseUrl: serverUrl));
      config.configureDio(dio, serverUrl);

      // Check that server URL is preserved
      expect(dio.options.baseUrl, serverUrl);

      // Check that other options are applied
      expect(dio.options.connectTimeout, const Duration(seconds: 5));
      expect(dio.options.receiveTimeout, const Duration(seconds: 10));
      expect(dio.interceptors, contains(interceptor));
      expect(dio.httpClientAdapter, httpClientAdapter);
    });
  });
}
