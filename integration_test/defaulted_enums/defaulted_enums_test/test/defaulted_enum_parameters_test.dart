import 'package:defaulted_enums_api/defaulted_enums_api.dart';
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
  group(
    'operation parameter enum defaults — public static const accessors',
    () {
      test('query enum default is reachable on the operation class', () {
        expect(ListSubscriptions.statusDefault, Status.active);
      });
    },
  );

  group('operation call() — enum query parameter wire encoding', () {
    test(
      'omitted enum query parameter serialises the default variant on the wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(dio).call();

        expect(captured!.uri.queryParameters['status'], 'active');
      },
    );

    test(
      'explicit enum value replaces the default on the wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(dio).call(status: Status.archived);

        expect(captured!.uri.queryParameters['status'], 'archived');
      },
    );
  });

  group('operation call() — enum header parameter wire encoding', () {
    test(
      'omitted enum header parameter serialises the default variant on the '
      'wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(dio).call();

        expect(captured!.headers['X-Mode'], 'auto');
      },
    );

    test(
      'explicit enum header value replaces the default on the wire',
      () async {
        RequestOptions? captured;
        final dio = _newDio(onRequest: (o) => captured = o);

        await ListSubscriptions(
          dio,
        ).call(mode: SubscriptionsParametersModel2.manual);

        expect(captured!.headers['X-Mode'], 'manual');
      },
    );
  });
}
