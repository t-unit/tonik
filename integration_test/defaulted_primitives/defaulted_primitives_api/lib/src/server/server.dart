// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i1;

import 'package:dio/dio.dart' as _i3;
import 'package:tonik_util/tonik_util.dart' as _i2;

sealed class Server {
  Server({required this.baseUrl, required this.serverConfig});

  final _i1.String baseUrl;

  final _i2.ServerConfig serverConfig;

  _i3.Dio? _dio;

  _i3.Dio get dio {
    if (_dio == null) {
      _dio = _i3.Dio();
      serverConfig.configureDio(_dio!, baseUrl);
    }
    return _dio!;
  }
}

/// Server - https://api.example.com/v1
class ApiServer extends Server {
  ApiServer({super.serverConfig = const _i2.ServerConfig()})
    : super(baseUrl: r'https://api.example.com/v1');
}

/// Custom server with user-defined base URL
class CustomServer extends Server {
  CustomServer({
    required super.baseUrl,
    super.serverConfig = const _i2.ServerConfig(),
  });
}
