// The probe must catch ArgumentError to verify assertions-disabled behavior.
// ignore_for_file: avoid_catching_errors

import 'package:dio/dio.dart';
import 'package:server_variables_api/server_variables_api.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const injectedBaseUrl = 'https://injected.example.com';
  final injected = Dio(BaseOptions(baseUrl: injectedBaseUrl));
  var factoryCalls = 0;
  final server = CustomServer(
    baseUrl: 'https://server.example.com',
    serverConfig: ServerConfig<Dio>(
      client: injected,
      clientFactory: () {
        factoryCalls++;
        return Dio();
      },
    ),
  );

  try {
    server.dio;
  } on ArgumentError {
    if (factoryCalls != 0) {
      throw StateError('The conflicting factory was invoked.');
    }
    if (injected.options.baseUrl != injectedBaseUrl) {
      throw StateError('The injected client was mutated before validation.');
    }
    return;
  }

  throw StateError('Conflicting client configuration did not throw.');
}
