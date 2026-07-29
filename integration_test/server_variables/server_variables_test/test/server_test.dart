import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:server_variables_api/server_variables_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('Static server', () {
    test('Server2 has correct static URL', () {
      final server = Server2();
      expect(server.baseUrl, 'https://production.example.com/api/v1');
    });

    test('Server2 can be instantiated with custom config', () {
      final server = Server2();
      expect(server.baseUrl, 'https://production.example.com/api/v1');
    });
  });

  group('Server with enum variable', () {
    test('Server3 uses default region', () {
      final server = Server3();
      expect(server.baseUrl, 'https://us-east.example.com/api/v1');
      expect(server.region, Server3Region.usEast);
    });

    test('Server3 can use different region', () {
      final server = Server3(region: Server3Region.euCentral);
      expect(server.baseUrl, 'https://eu-central.example.com/api/v1');
      expect(server.region, Server3Region.euCentral);
    });

    test('Server3 supports all enum values', () {
      expect(
        Server3().baseUrl, // default is usEast
        'https://us-east.example.com/api/v1',
      );
      expect(
        Server3(region: Server3Region.usWest).baseUrl,
        'https://us-west.example.com/api/v1',
      );
      expect(
        Server3(region: Server3Region.euCentral).baseUrl,
        'https://eu-central.example.com/api/v1',
      );
      expect(
        Server3(region: Server3Region.apSoutheast).baseUrl,
        'https://ap-southeast.example.com/api/v1',
      );
    });

    test('Server3Region enum has correct values', () {
      expect(Server3Region.usEast.value, 'us-east');
      expect(Server3Region.usWest.value, 'us-west');
      expect(Server3Region.euCentral.value, 'eu-central');
      expect(Server3Region.apSoutheast.value, 'ap-southeast');
    });
  });

  group('Server with string variable', () {
    test('Server4 uses default environment', () {
      final server = Server4();
      expect(server.baseUrl, 'https://dev.staging.example.com/api/v1');
      expect(server.environment, 'dev');
    });

    test('Server4 can use custom environment', () {
      final server = Server4(environment: 'qa');
      expect(server.baseUrl, 'https://qa.staging.example.com/api/v1');
      expect(server.environment, 'qa');
    });

    test('Server4 accepts any string value', () {
      expect(
        Server4(environment: 'test').baseUrl,
        'https://test.staging.example.com/api/v1',
      );
      expect(
        Server4(environment: 'staging').baseUrl,
        'https://staging.staging.example.com/api/v1',
      );
      expect(
        Server4(environment: 'my-custom-env').baseUrl,
        'https://my-custom-env.staging.example.com/api/v1',
      );
    });
  });

  group('Server with multiple variables', () {
    test('Server5 uses all default values', () {
      final server = Server5();
      expect(server.baseUrl, 'https://default.us-east.example.com:443/api/v1');
      expect(server.tenant, 'default');
      expect(server.region, Server5Region.usEast);
      expect(server.port, Server5Port.fourHundredFortyThree);
    });

    test('Server5 can customize all variables', () {
      final server = Server5(
        tenant: 'acme',
        region: Server5Region.euCentral,
        port: Server5Port.eightThousandFourHundredFortyThree,
      );
      expect(server.baseUrl, 'https://acme.eu-central.example.com:8443/api/v1');
      expect(server.tenant, 'acme');
      expect(server.region, Server5Region.euCentral);
      expect(server.port, Server5Port.eightThousandFourHundredFortyThree);
    });

    test('Server5 can mix default and custom values', () {
      final server = Server5(
        tenant: 'widgets-inc',
        region: Server5Region.usWest,
        // port uses default
      );
      expect(
        server.baseUrl,
        'https://widgets-inc.us-west.example.com:443/api/v1',
      );
    });

    test('Server5Region enum has correct values', () {
      expect(Server5Region.usEast.value, 'us-east');
      expect(Server5Region.usWest.value, 'us-west');
      expect(Server5Region.euCentral.value, 'eu-central');
    });

    test('Server5Port enum has correct values', () {
      expect(Server5Port.fourHundredFortyThree.value, '443');
      expect(Server5Port.eightThousandFourHundredFortyThree.value, '8443');
    });
  });

  group('Server with enum variable whose default is not a member', () {
    test('Server6 builds URL from explicitly provided zone', () {
      expect(
        Server6(zone: Server6Zone.usEast).baseUrl,
        'https://us-east.fallback.example.com/api/v1',
      );
      expect(
        Server6(zone: Server6Zone.euWest).baseUrl,
        'https://eu-west.fallback.example.com/api/v1',
      );
      expect(
        Server6(zone: Server6Zone.apSouth).baseUrl,
        'https://ap-south.fallback.example.com/api/v1',
      );
    });

    test('Server6Zone has only the declared values', () {
      expect(Server6Zone.values, hasLength(3));
      expect(Server6Zone.usEast.value, 'us-east');
      expect(Server6Zone.euWest.value, 'eu-west');
      expect(Server6Zone.apSouth.value, 'ap-south');
    });
  });

  group('CustomServer', () {
    test('CustomServer can use any base URL', () {
      final server = CustomServer(baseUrl: 'https://custom.example.com/api');
      expect(server.baseUrl, 'https://custom.example.com/api');
    });

    test('CustomServer works with localhost', () {
      final server = CustomServer(baseUrl: 'http://localhost:3000');
      expect(server.baseUrl, 'http://localhost:3000');
    });
  });

  group('Server base class', () {
    test('all servers extend Server', () {
      expect(Server2(), isA<Server>());
      expect(Server3(), isA<Server>());
      expect(Server4(), isA<Server>());
      expect(Server5(), isA<Server>());
      expect(Server6(zone: Server6Zone.usEast), isA<Server>());
      expect(CustomServer(baseUrl: 'https://test.com'), isA<Server>());
    });
  });

  group('Dio client resolution', () {
    test('borrows an injected Dio lazily and preserves its identity', () {
      const injectedBaseUrl = 'https://injected.example.com';
      const serverBaseUrl = 'https://server.example.com';
      final injected = Dio(BaseOptions(baseUrl: injectedBaseUrl));
      final server = CustomServer(
        baseUrl: serverBaseUrl,
        serverConfig: ServerConfig<Dio>.client(injected),
      );

      expect(injected.options.baseUrl, injectedBaseUrl);

      final resolved = server.dio;

      expect(resolved, same(injected));
      expect(resolved.options.baseUrl, serverBaseUrl);
      expect(server.dio, same(resolved));
    });

    test(
      'invokes a Dio factory lazily once and applies the server URL last',
      () {
        const factoryBaseUrl = 'https://factory.example.com';
        const serverBaseUrl = 'https://server.example.com';
        var factoryCalls = 0;
        late Dio created;
        final server = CustomServer(
          baseUrl: serverBaseUrl,
          serverConfig: ServerConfig<Dio>.clientFactory(
            () {
              factoryCalls++;
              return created = Dio(BaseOptions(baseUrl: factoryBaseUrl));
            },
          ),
        );

        expect(factoryCalls, 0);

        final resolved = server.dio;

        expect(factoryCalls, 1);
        expect(resolved, same(created));
        expect(resolved.options.baseUrl, serverBaseUrl);
        expect(server.dio, same(resolved));
        expect(factoryCalls, 1);
      },
    );

    test('API client construction does not resolve a Dio factory', () {
      var factoryCalls = 0;
      final server = CustomServer(
        baseUrl: 'https://server.example.com',
        serverConfig: ServerConfig<Dio>.clientFactory(() {
          factoryCalls++;
          return Dio();
        }),
      );

      final api = HealthApi(server);

      expect(api, isA<HealthApi>());
      expect(factoryCalls, 0);
    });

    test('factory preserves Dio configuration while server URL wins', () {
      const serverBaseUrl = 'https://server.example.com';
      final adapter = _TrackingAdapter();
      final interceptor = InterceptorsWrapper();
      final options = BaseOptions(
        baseUrl: 'https://factory.example.com',
        connectTimeout: const Duration(seconds: 17),
        headers: {'x-client-header': 'preserved'},
      );
      late Dio created;
      final server = CustomServer(
        baseUrl: serverBaseUrl,
        serverConfig: ServerConfig<Dio>.clientFactory(() {
          return created = (Dio(options)
            ..interceptors.add(interceptor)
            ..httpClientAdapter = adapter);
        }),
      );

      final resolved = server.dio;

      expect(resolved, same(created));
      expect(resolved.options.baseUrl, serverBaseUrl);
      expect(resolved.options.connectTimeout, const Duration(seconds: 17));
      expect(resolved.options.headers['x-client-header'], 'preserved');
      expect(resolved.interceptors, contains(same(interceptor)));
      expect(resolved.httpClientAdapter, same(adapter));
      server.close();
    });

    test('creates one default Dio lazily and applies the server URL', () {
      const serverBaseUrl = 'https://server.example.com';
      final server = CustomServer(baseUrl: serverBaseUrl);

      final resolved = server.dio;

      expect(resolved.options.baseUrl, serverBaseUrl);
      expect(server.dio, same(resolved));
    });
  });

  group('Dio client lifecycle', () {
    test('close before use does not resolve a factory', () {
      var factoryCalls = 0;
      CustomServer(
          baseUrl: 'https://server.example.com',
          serverConfig: ServerConfig<Dio>.clientFactory(() {
            factoryCalls++;
            return Dio();
          }),
        )
        ..close()
        ..close();

      expect(factoryCalls, 0);
    });

    test('closes a factory-created Dio exactly once', () {
      final adapter = _TrackingAdapter();
      final server = CustomServer(
        baseUrl: 'https://server.example.com',
        serverConfig: ServerConfig<Dio>.clientFactory(
          () => Dio()..httpClientAdapter = adapter,
        ),
      );

      expect(server.dio.httpClientAdapter, same(adapter));

      server
        ..close()
        ..close();

      expect(adapter.closeCalls, 1);
    });

    test('never closes an injected Dio', () {
      final adapter = _TrackingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final server = CustomServer(
        baseUrl: 'https://server.example.com',
        serverConfig: ServerConfig<Dio>.client(dio),
      );

      expect(server.dio, same(dio));

      server
        ..close()
        ..close();

      expect(adapter.closeCalls, 0);
      dio.close();
      expect(adapter.closeCalls, 1);
    });

    test('direct access and operations share one stable close error', () async {
      final adapter = _TrackingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final server = CustomServer(
        baseUrl: 'https://server.example.com',
        serverConfig: ServerConfig<Dio>.client(dio),
      );
      final api = HealthApi(server);
      server.close();

      final firstError = _captureDioAccessError(server);
      final secondError = _captureDioAccessError(server);
      final result = await api.getHealth();

      expect(firstError, isA<StateError>());
      expect(secondError, same(firstError));
      expect(
        firstError.toString(),
        'Bad state: Cannot access Dio after the server has been closed.',
      );
      expect(
        result,
        isA<TonikError<HealthStatus, Response<Object?>>>(),
      );
      final error = result as TonikError<HealthStatus, Response<Object?>>;
      expect(error.type, TonikErrorType.other);
      expect(error.error, same(firstError));
      expect(error.response, isNull);
      expect(error.stackTrace, isNot(StackTrace.empty));
      expect(adapter.fetchCalls, 0);
    });
  });

  group('portable cancellation', () {
    test('pre-cancelled API calls do not resolve or dispatch Dio', () async {
      final adapter = _TrackingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://injected.example.com'))
        ..httpClientAdapter = adapter;
      final server = CustomServer(
        baseUrl: 'https://server.example.com',
        serverConfig: ServerConfig<Dio>.client(dio),
      );
      final api = HealthApi(server);
      final cancellation = TonikCancellation()..cancel('no longer needed');

      final result = await api.getHealth(cancellation: cancellation);

      expect(
        result,
        isA<TonikError<HealthStatus, Response<Object?>>>(),
      );
      final error = result as TonikError<HealthStatus, Response<Object?>>;
      expect(error.type, TonikErrorType.cancelled);
      expect(error.response, isNull);
      expect(adapter.fetchCalls, 0);
      expect(dio.options.baseUrl, 'https://injected.example.com');
    });

    test('in-flight cancellation cancels Dio and maps the result', () async {
      final adapter = _TrackingAdapter(waitForCancellation: true);
      final dio = Dio()..httpClientAdapter = adapter;
      final server = CustomServer(
        baseUrl: 'https://server.example.com',
        serverConfig: ServerConfig<Dio>.client(dio),
      );
      final api = HealthApi(server);
      final cancellation = TonikCancellation();

      final future = api.getHealth(cancellation: cancellation);
      await adapter.dispatched.future;
      cancellation.cancel('navigation');
      final result = await future;

      expect(adapter.fetchCalls, 1);
      expect(
        result,
        isA<TonikError<HealthStatus, Response<Object?>>>(),
      );
      final error = result as TonikError<HealthStatus, Response<Object?>>;
      expect(error.type, TonikErrorType.cancelled);
    });

    test(
      'post-operation cancellation preserves the successful result',
      () async {
        final adapter = _TrackingAdapter();
        final dio = Dio()..httpClientAdapter = adapter;
        final server = CustomServer(
          baseUrl: 'https://server.example.com',
          serverConfig: ServerConfig<Dio>.client(dio),
        );
        final api = HealthApi(server);
        final cancellation = TonikCancellation();

        final result = await api.getHealth(cancellation: cancellation);
        cancellation.cancel('too late');
        await Future<void>.delayed(Duration.zero);

        expect(adapter.fetchCalls, 1);
        expect(
          result,
          isA<TonikSuccess<HealthStatus, Response<Object?>>>(),
        );
        final success = result as TonikSuccess<HealthStatus, Response<Object?>>;
        expect(success.value.status, HealthStatusStatusModel.healthy);
        expect(success.response.statusCode, 200);
        expect(cancellation.isCancelled, isTrue);
      },
    );
  });
}

Object _captureDioAccessError(Server server) {
  try {
    server.dio;
  } on Object catch (error) {
    return error;
  }
  throw StateError('Expected Dio access to fail.');
}

class _TrackingAdapter implements HttpClientAdapter {
  _TrackingAdapter({this.waitForCancellation = false});

  final bool waitForCancellation;
  final Completer<void> dispatched = Completer<void>();
  int fetchCalls = 0;
  int closeCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCalls++;
    if (!dispatched.isCompleted) {
      dispatched.complete();
    }

    if (waitForCancellation) {
      final cancellation = cancelFuture;
      if (cancellation == null) {
        throw StateError('Expected a Dio cancellation future.');
      }
      await cancellation;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );
    }

    return ResponseBody.fromString(
      '{"status":"healthy","timestamp":"2026-07-27T12:00:00Z"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {
    closeCalls++;
  }
}
