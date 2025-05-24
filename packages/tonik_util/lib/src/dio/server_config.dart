import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// Configuration for server's Dio HTTP client.
///
/// Allows customization of BaseOptions, interceptors, and HTTP client adapter
/// while preserving the server's URL.
@immutable
class ServerConfig {
  /// Creates a new ServerConfig.
  ///
  /// Use this to configure a Dio instance for server communication while
  /// preserving the server's URL.
  const ServerConfig({
    this.baseOptions,
    this.interceptors = const [],
    this.httpClientAdapter,
  });

  /// Base options for the Dio HTTP client.
  ///
  /// Note: When configured, the baseUrl from these options will be ignored
  /// in favor of the server's URL.
  final BaseOptions? baseOptions;

  /// Interceptors to add to the Dio HTTP client.
  final List<Interceptor> interceptors;

  /// HTTP client adapter for the Dio HTTP client.
  final HttpClientAdapter? httpClientAdapter;

  /// Configures a Dio instance with this configuration.
  ///
  /// Always preserves the [serverUrl] regardless of any baseUrl
  /// in the baseOptions.
  void configureDio(Dio dio, String serverUrl) {
    if (baseOptions != null) {
      dio.options
        ..connectTimeout = baseOptions!.connectTimeout
        ..receiveTimeout = baseOptions!.receiveTimeout
        ..sendTimeout = baseOptions!.sendTimeout
        ..headers = Map<String, dynamic>.from(baseOptions!.headers)
        ..responseType = baseOptions!.responseType
        ..contentType = baseOptions!.contentType
        ..validateStatus = baseOptions!.validateStatus
        ..maxRedirects = baseOptions!.maxRedirects
        ..listFormat = baseOptions!.listFormat
        ..extra = Map<String, dynamic>.from(baseOptions!.extra);
    }

    // Set the server URL
    dio.options.baseUrl = serverUrl;
    
    // Add all interceptors
    for (final interceptor in interceptors) {
      dio.interceptors.add(interceptor);
    }
    
    // Set httpClientAdapter if provided
    if (httpClientAdapter != null) {
      dio.httpClientAdapter = httpClientAdapter!;
    }
  }
} 
