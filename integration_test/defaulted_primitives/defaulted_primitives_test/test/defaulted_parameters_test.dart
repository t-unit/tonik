import 'package:defaulted_primitives_api/defaulted_primitives_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

Dio _newDio({required void Function(RequestOptions) onRequest}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('operation parameter defaults — public static const accessors', () {
    test('query string default is reachable', () {
      expect(ListThings.regionDefault, 'us');
    });

    test('required-with-default query integer default is reachable', () {
      expect(ListThings.pageDefault, 1);
    });

    test('header integer default is reachable', () {
      expect(ListThings.retriesDefault, 5);
    });

    test('cookie boolean default is reachable', () {
      expect(ListThings.trackingDefault, isFalse);
    });

    test('path string default is reachable', () {
      expect(GetThing.idDefault, 'x');
    });
  });

  group('operation call() with no arguments uses defaults', () {
    test(
      'omitted query/header/cookie parameters serialise the default values',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListThings(dio).call();

        final options = captured!;
        final uri = options.uri;

        expect(uri.queryParameters['region'], 'us');
        expect(uri.queryParameters['page'], '1');

        final headers = options.headers;
        expect(headers['X-Retries'], '5');

        final cookie = headers['Cookie']! as String;
        expect(cookie, contains('tracking=false'));
      },
    );

    test(
      'omitted path parameter substitutes the default into the URL template',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await GetThing(dio).call();

        expect(captured!.uri.path, endsWith('/things/x'));
      },
    );
  });

  group('operation call() with explicit args overrides defaults', () {
    test('explicit query/header/cookie values replace the defaults', () async {
      RequestOptions? captured;
      final dio = _newDio(onRequest: (o) => captured = o);

      await ListThings(dio).call(
        region: 'eu',
        page: 7,
        retries: 9,
        tracking: true,
      );

      final options = captured!;
      final uri = options.uri;

      expect(uri.queryParameters['region'], 'eu');
      expect(uri.queryParameters['page'], '7');
      expect(options.headers['X-Retries'], '9');
      expect(options.headers['Cookie']! as String, contains('tracking=true'));
    });

    test('explicit path value replaces the default in the URL', () async {
      RequestOptions? captured;
      final dio = _newDio(onRequest: (o) => captured = o);

      await GetThing(dio).call(id: 'custom');

      expect(captured!.uri.path, endsWith('/things/custom'));
    });
  });
}
