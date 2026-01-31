import 'package:dio/dio.dart';
import 'package:medama_api/medama_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  StatsApi buildStatsApi({required String responseStatus}) {
    return StatsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('getWebsiteIdSummary', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/summary',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - query parameters', () {
      test('previous=true query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
          previous: true,
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['previous'], 'true');
      });

      test('previous=false query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
          previous: false,
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['previous'], 'false');
      });

      test('interval query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
          interval: WebsiteHostnameSummaryParametersModel.day,
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['interval'], 'day');
      });

      test('start date query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');
        final startDate = DateTime.utc(2024, 1, 15, 10, 30);

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
          start: startDate,
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['start'], isNotNull);
      });

      test('end date query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');
        final endDate = DateTime.utc(2024, 1, 20, 15, 45);

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
          end: endDate,
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['end'], isNotNull);
      });

      test('omits optional parameters when not provided', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters.containsKey('previous'), isFalse);
        expect(uri.queryParameters.containsKey('interval'), isFalse);
        expect(uri.queryParameters.containsKey('start'), isFalse);
        expect(uri.queryParameters.containsKey('end'), isFalse);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdSummaryResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdSummary(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSummaryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdSummaryResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final response200 = success.value as GetWebsiteIdSummaryResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes StatsSummary', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final response200 = success.value as GetWebsiteIdSummaryResponse200;
        expect(response200.body.body, isA<StatsSummary>());
      });

      test('200 response decodes current stats', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final response200 = success.value as GetWebsiteIdSummaryResponse200;
        expect(response200.body.body.current, isA<StatsSummaryCurrentModel>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdSummaryResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdSummary(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSummaryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdSummaryResponse400>());
        },
      );

      test('400 response body decodes error object', () async {
        final api = buildStatsApi(responseStatus: '400');

        final response = await api.getWebsiteIdSummary(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
        final response400 = success.value as GetWebsiteIdSummaryResponse400;
        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });

      test(
        '401 response is decoded as GetWebsiteIdSummaryResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdSummary(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSummaryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdSummaryResponse401>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdSummaryResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdSummary(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSummaryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdSummaryResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdSummaryResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdSummary(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSummaryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSummaryResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdSummaryResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdPages', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/pages',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - query parameters', () {
      test('summary query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
          summary: true,
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['summary'], 'true');
      });

      test('limit query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
          limit: 50,
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['limit'], '50');
      });

      test('offset query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
          offset: 10,
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['offset'], '10');
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetWebsiteIdPagesResponse200', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdPagesResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetWebsiteIdPagesResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        final response200 = success.value as GetWebsiteIdPagesResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsPages', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        final response200 = success.value as GetWebsiteIdPagesResponse200;
        expect(response200.body.body, isA<StatsPages>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as GetWebsiteIdPagesResponse400', () async {
        final api = buildStatsApi(responseStatus: '400');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdPagesResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetWebsiteIdPagesResponse400>());
      });

      test('401 response is decoded as GetWebsiteIdPagesResponse401', () async {
        final api = buildStatsApi(responseStatus: '401');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdPagesResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetWebsiteIdPagesResponse401>());
      });

      test('404 response is decoded as GetWebsiteIdPagesResponse404', () async {
        final api = buildStatsApi(responseStatus: '404');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdPagesResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetWebsiteIdPagesResponse404>());
      });

      test('500 response is decoded as GetWebsiteIdPagesResponse500', () async {
        final api = buildStatsApi(responseStatus: '500');

        final response = await api.getWebsiteIdPages(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdPagesResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdPagesResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetWebsiteIdPagesResponse500>());
      });
    });
  });

  group('getWebsiteIdTime', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/time',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetWebsiteIdTimeResponse200', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdTimeResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetWebsiteIdTimeResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        final response200 = success.value as GetWebsiteIdTimeResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsTime', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        final response200 = success.value as GetWebsiteIdTimeResponse200;
        expect(response200.body.body, isA<StatsTime>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as GetWebsiteIdTimeResponse400', () async {
        final api = buildStatsApi(responseStatus: '400');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdTimeResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetWebsiteIdTimeResponse400>());
      });

      test('401 response is decoded as GetWebsiteIdTimeResponse401', () async {
        final api = buildStatsApi(responseStatus: '401');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdTimeResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetWebsiteIdTimeResponse401>());
      });

      test('404 response is decoded as GetWebsiteIdTimeResponse404', () async {
        final api = buildStatsApi(responseStatus: '404');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdTimeResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetWebsiteIdTimeResponse404>());
      });

      test('500 response is decoded as GetWebsiteIdTimeResponse500', () async {
        final api = buildStatsApi(responseStatus: '500');

        final response = await api.getWebsiteIdTime(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdTimeResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdTimeResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetWebsiteIdTimeResponse500>());
      });
    });
  });

  group('getWebsiteIdReferrers', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdReferrers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdReferrersResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/referrers',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdReferrers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdReferrersResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdReferrers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdReferrersResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - query parameters', () {
      test('grouped query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdReferrers(
          meSess: 'test_session',
          hostname: 'example.com',
          grouped: true,
        );

        final success = response as TonikSuccess<GetWebsiteIdReferrersResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['grouped'], 'true');
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdReferrersResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdReferrers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdReferrersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdReferrersResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdReferrersResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdReferrers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdReferrersResponse>;
        final response200 = success.value as GetWebsiteIdReferrersResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsReferrers', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdReferrers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdReferrersResponse>;
        final response200 = success.value as GetWebsiteIdReferrersResponse200;
        expect(response200.body.body, isA<StatsReferrers>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdReferrersResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdReferrers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdReferrersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdReferrersResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdReferrersResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdReferrersResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdReferrers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdReferrersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdReferrersResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdReferrersResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdReferrersResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdReferrers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdReferrersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdReferrersResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdReferrersResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdReferrersResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdReferrers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdReferrersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdReferrersResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdReferrersResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdReferrersResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdReferrers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdReferrersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdReferrersResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdReferrersResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdSources', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSources(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/sources',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSources(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSources(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdSourcesResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdSources(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSourcesResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdSourcesResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSources(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
        final response200 = success.value as GetWebsiteIdSourcesResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsUtmSources', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdSources(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
        final response200 = success.value as GetWebsiteIdSourcesResponse200;
        expect(response200.body.body, isA<StatsUtmSources>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdSourcesResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdSources(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSourcesResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdSourcesResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdSourcesResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdSources(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSourcesResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdSourcesResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdSourcesResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdSources(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSourcesResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdSourcesResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdSourcesResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdSources(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSourcesResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdSourcesResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdSourcesResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdSources(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdSourcesResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdSourcesResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdSourcesResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdMediums', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdMediums(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/mediums',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdMediums(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdMediums(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdMediumsResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdMediums(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdMediumsResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdMediumsResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdMediums(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
        final response200 = success.value as GetWebsiteIdMediumsResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsUtmMediums', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdMediums(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
        final response200 = success.value as GetWebsiteIdMediumsResponse200;
        expect(response200.body.body, isA<StatsUtmMediums>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdMediumsResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdMediums(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdMediumsResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdMediumsResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdMediumsResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdMediums(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdMediumsResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdMediumsResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdMediumsResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdMediums(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdMediumsResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdMediumsResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdMediumsResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdMediums(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdMediumsResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdMediumsResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdMediumsResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdMediums(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdMediumsResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdMediumsResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdMediumsResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdCampaigns', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCampaigns(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/campaigns',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCampaigns(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCampaigns(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdCampaignsResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdCampaigns(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCampaignsResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdCampaignsResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCampaigns(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
        final response200 = success.value as GetWebsiteIdCampaignsResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsUtmCampaigns', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCampaigns(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
        final response200 = success.value as GetWebsiteIdCampaignsResponse200;
        expect(response200.body.body, isA<StatsUtmCampaigns>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdCampaignsResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdCampaigns(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCampaignsResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdCampaignsResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdCampaignsResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdCampaigns(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCampaignsResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdCampaignsResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdCampaignsResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdCampaigns(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCampaignsResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdCampaignsResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdCampaignsResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdCampaigns(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCampaignsResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdCampaignsResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdCampaignsResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdCampaigns(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCampaignsResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdCampaignsResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdCampaignsResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdBrowsers', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdBrowsers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/browsers',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdBrowsers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdBrowsers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdBrowsersResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdBrowsers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdBrowsersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdBrowsersResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdBrowsers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
        final response200 = success.value as GetWebsiteIdBrowsersResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsBrowsers', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdBrowsers(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
        final response200 = success.value as GetWebsiteIdBrowsersResponse200;
        expect(response200.body.body, isA<StatsBrowsers>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdBrowsersResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdBrowsers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdBrowsersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdBrowsersResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdBrowsersResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdBrowsers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdBrowsersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdBrowsersResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdBrowsersResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdBrowsers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdBrowsersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdBrowsersResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdBrowsersResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdBrowsers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdBrowsersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdBrowsersResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdBrowsersResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdBrowsers(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdBrowsersResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdBrowsersResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdBrowsersResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdOs', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/os',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetWebsiteIdOsResponse200', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdOsResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetWebsiteIdOsResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        final response200 = success.value as GetWebsiteIdOsResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsOS', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        final response200 = success.value as GetWebsiteIdOsResponse200;
        expect(response200.body.body, isA<StatsOs>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as GetWebsiteIdOsResponse400', () async {
        final api = buildStatsApi(responseStatus: '400');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdOsResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetWebsiteIdOsResponse400>());
      });

      test('401 response is decoded as GetWebsiteIdOsResponse401', () async {
        final api = buildStatsApi(responseStatus: '401');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdOsResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetWebsiteIdOsResponse401>());
      });

      test('403 response is decoded as GetWebsiteIdOsResponse403', () async {
        final api = buildStatsApi(responseStatus: '403');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdOsResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.statusCode, 403);
        expect(success.value, isA<GetWebsiteIdOsResponse403>());
      });

      test('404 response is decoded as GetWebsiteIdOsResponse404', () async {
        final api = buildStatsApi(responseStatus: '404');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdOsResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetWebsiteIdOsResponse404>());
      });

      test('500 response is decoded as GetWebsiteIdOsResponse500', () async {
        final api = buildStatsApi(responseStatus: '500');

        final response = await api.getWebsiteIdOs(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsiteIdOsResponse>>());
        final success = response as TonikSuccess<GetWebsiteIdOsResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetWebsiteIdOsResponse500>());
      });
    });
  });

  group('getWebsiteIdDevice', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdDevice(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/devices',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdDevice(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdDevice(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdDeviceResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdDevice(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdDeviceResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdDeviceResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdDevice(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
        final response200 = success.value as GetWebsiteIdDeviceResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsDevices', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdDevice(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
        final response200 = success.value as GetWebsiteIdDeviceResponse200;
        expect(response200.body.body, isA<StatsDevices>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdDeviceResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdDevice(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdDeviceResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdDeviceResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdDeviceResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdDevice(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdDeviceResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdDeviceResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdDeviceResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdDevice(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdDeviceResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdDeviceResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdDeviceResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdDevice(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdDeviceResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdDeviceResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdDeviceResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdDevice(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdDeviceResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdDeviceResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdDeviceResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdCountry', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCountry(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/countries',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCountry(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCountry(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdCountryResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdCountry(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCountryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdCountryResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCountry(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
        final response200 = success.value as GetWebsiteIdCountryResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsCountries', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdCountry(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
        final response200 = success.value as GetWebsiteIdCountryResponse200;
        expect(response200.body.body, isA<StatsCountries>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdCountryResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdCountry(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCountryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdCountryResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdCountryResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdCountry(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCountryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdCountryResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdCountryResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdCountry(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCountryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdCountryResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdCountryResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdCountry(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCountryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdCountryResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdCountryResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdCountry(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdCountryResponse>>());
          final success = response as TonikSuccess<GetWebsiteIdCountryResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdCountryResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdLanguage', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdLanguage(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdLanguageResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/languages',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdLanguage(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdLanguageResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdLanguage(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdLanguageResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - query parameters', () {
      test('locale query parameter is encoded correctly', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdLanguage(
          meSess: 'test_session',
          hostname: 'example.com',
          locale: true,
        );

        final success = response as TonikSuccess<GetWebsiteIdLanguageResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['locale'], 'true');
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdLanguageResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdLanguage(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdLanguageResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdLanguageResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdLanguageResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdLanguage(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdLanguageResponse>;
        final response200 = success.value as GetWebsiteIdLanguageResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsLanguages', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdLanguage(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsiteIdLanguageResponse>;
        final response200 = success.value as GetWebsiteIdLanguageResponse200;
        expect(response200.body.body, isA<StatsLanguages>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdLanguageResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdLanguage(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdLanguageResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdLanguageResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdLanguageResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdLanguageResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdLanguage(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdLanguageResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdLanguageResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdLanguageResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdLanguageResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdLanguage(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdLanguageResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdLanguageResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdLanguageResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdLanguageResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdLanguage(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdLanguageResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdLanguageResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdLanguageResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdLanguageResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdLanguage(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdLanguageResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdLanguageResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdLanguageResponse500>());
        },
      );
    });
  });

  group('getWebsiteIdProperties', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdProperties(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success =
            response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/website/example.com/properties',
        );
      });

      test('request method is GET', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdProperties(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success =
            response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdProperties(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success =
            response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test(
        '200 response is decoded as GetWebsiteIdPropertiesResponse200',
        () async {
          final api = buildStatsApi(responseStatus: '200');

          final response = await api.getWebsiteIdProperties(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdPropertiesResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
          expect(success.response.statusCode, 200);
          expect(success.value, isA<GetWebsiteIdPropertiesResponse200>());
        },
      );

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdProperties(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success =
            response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
        final response200 = success.value as GetWebsiteIdPropertiesResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of StatsProperties', () async {
        final api = buildStatsApi(responseStatus: '200');

        final response = await api.getWebsiteIdProperties(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success =
            response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
        final response200 = success.value as GetWebsiteIdPropertiesResponse200;
        expect(response200.body.body, isA<StatsProperties>());
      });
    });

    group('response decoding - error responses', () {
      test(
        '400 response is decoded as GetWebsiteIdPropertiesResponse400',
        () async {
          final api = buildStatsApi(responseStatus: '400');

          final response = await api.getWebsiteIdProperties(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdPropertiesResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
          expect(success.response.statusCode, 400);
          expect(success.value, isA<GetWebsiteIdPropertiesResponse400>());
        },
      );

      test(
        '401 response is decoded as GetWebsiteIdPropertiesResponse401',
        () async {
          final api = buildStatsApi(responseStatus: '401');

          final response = await api.getWebsiteIdProperties(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdPropertiesResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
          expect(success.response.statusCode, 401);
          expect(success.value, isA<GetWebsiteIdPropertiesResponse401>());
        },
      );

      test(
        '403 response is decoded as GetWebsiteIdPropertiesResponse403',
        () async {
          final api = buildStatsApi(responseStatus: '403');

          final response = await api.getWebsiteIdProperties(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdPropertiesResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
          expect(success.response.statusCode, 403);
          expect(success.value, isA<GetWebsiteIdPropertiesResponse403>());
        },
      );

      test(
        '404 response is decoded as GetWebsiteIdPropertiesResponse404',
        () async {
          final api = buildStatsApi(responseStatus: '404');

          final response = await api.getWebsiteIdProperties(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdPropertiesResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
          expect(success.response.statusCode, 404);
          expect(success.value, isA<GetWebsiteIdPropertiesResponse404>());
        },
      );

      test(
        '500 response is decoded as GetWebsiteIdPropertiesResponse500',
        () async {
          final api = buildStatsApi(responseStatus: '500');

          final response = await api.getWebsiteIdProperties(
            meSess: 'test_session',
            hostname: 'example.com',
          );

          expect(response, isA<TonikSuccess<GetWebsiteIdPropertiesResponse>>());
          final success =
              response as TonikSuccess<GetWebsiteIdPropertiesResponse>;
          expect(success.response.statusCode, 500);
          expect(success.value, isA<GetWebsiteIdPropertiesResponse500>());
        },
      );
    });
  });
}
