import 'package:dio/dio.dart';
import 'package:medama_api/medama_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8102;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  EventApi buildEventApi({required String responseStatus}) {
    return EventApi(
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

  group('postEventHit', () {
    group('request encoding - common', () {
      test('request path is /event/hit', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8102/event/hit',
        );
      });

      test('request method is POST', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('request encoding - EventLoad', () {
      test('encodes discriminator property e as "load"', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon-id',
              u: Uri.parse('https://example.com/page'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['e'], 'load');
      });

      test('encodes b (beacon ID) as string', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'my-beacon-12345',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['b'], 'my-beacon-12345');
      });

      test('encodes u (URL) as string', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/page?query=test&foo=bar'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['u'], 'https://example.com/page?query=test&foo=bar');
      });

      test('encodes p (unique user) as boolean true', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['p'], true);
      });

      test('encodes p (unique user) as boolean false', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: false,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['p'], false);
      });

      test('encodes q (visited before) as boolean', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: true,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['q'], true);
      });

      test('encodes optional r (referrer URL) when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
              r: 'https://google.com/search?q=test',
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['r'], 'https://google.com/search?q=test');
      });

      test('omits optional r (referrer URL) when not provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('r'), isFalse);
      });

      test('encodes optional t (timezone) when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
              t: 'America/New_York',
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['t'], 'America/New_York');
      });

      test('encodes optional d (custom properties) when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
              d: const EventLoadDModel(),
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('d'), isTrue);
      });

      test('encodes URL with unicode characters correctly', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/日本語/页面'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['u'], contains('example.com'));
      });
    });

    group('request encoding - EventUnload', () {
      test('encodes discriminator property e as "unload"', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventUnload(
            EventUnload(b: 'beacon-id', m: 5000),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['e'], 'unload');
      });

      test('encodes b (beacon ID) as string', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventUnload(
            EventUnload(b: 'unload-beacon-xyz', m: 5000),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['b'], 'unload-beacon-xyz');
      });

      test('encodes m (duration) as integer', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventUnload(
            EventUnload(b: 'beacon', m: 45000),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['m'], 45000);
      });

      test('encodes small duration correctly', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventUnload(
            EventUnload(b: 'beacon', m: 1),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['m'], 1);
      });

      test('encodes large duration correctly', () async {
        final api = buildEventApi(responseStatus: '204');

        // 1 hour in milliseconds
        final response = await api.postEventHit(
          body: const EventHitEventUnload(
            EventUnload(b: 'beacon', m: 3600000),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['m'], 3600000);
      });
    });

    group('request encoding - EventCustom', () {
      test('encodes discriminator property e as "custom"', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventCustom(
            EventCustom(g: 'example.com', d: EventCustomDModel()),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['e'], 'custom');
      });

      test('encodes g (group name/hostname) as string', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventCustom(
            EventCustom(g: 'shop.example.com', d: EventCustomDModel()),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['g'], 'shop.example.com');
      });

      test('encodes d (custom properties) as object', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventCustom(
            EventCustom(g: 'example.com', d: EventCustomDModel()),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('d'), isTrue);
        final dValue = requestBody['d'];
        expect(dValue, isA<Map<dynamic, dynamic>>());
        expect(dValue, isEmpty);
      });

      test('encodes optional b (beacon ID) when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventCustom(
            EventCustom(
              b: 'optional-beacon-id',
              g: 'example.com',
              d: EventCustomDModel(),
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['b'], 'optional-beacon-id');
      });

      test('omits optional b (beacon ID) when not provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: const EventHitEventCustom(
            EventCustom(g: 'example.com', d: EventCustomDModel()),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('b'), isFalse);
      });
    });

    group('request encoding - headers', () {
      test('User-Agent header is encoded when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(
          success.response.requestOptions.headers['User-Agent'],
          '''Mozilla%2F5.0%20(Windows%20NT%2010.0%3B%20Win64%3B%20x64)%20AppleWebKit%2F537.36''',
        );
      });

      test('Accept-Language header is encoded when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
          acceptLanguage: 'en-US,en;q=0.9,de;q=0.8',
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(
          success.response.requestOptions.headers['Accept-Language'],
          'en-US%2Cen%3Bq%3D0.9%2Cde%3Bq%3D0.8',
        );
      });

      test('both optional headers are encoded when provided', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
          userAgent: 'TestBrowser/1.0',
          acceptLanguage: 'fr-FR',
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(
          success.response.requestOptions.headers['User-Agent'],
          'TestBrowser%2F1.0',
        );
        expect(
          success.response.requestOptions.headers['Accept-Language'],
          'fr-FR',
        );
      });

      test('headers with special characters are preserved', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
          acceptLanguage: 'en-US,en;q=0.9,zh-CN;q=0.8,日本語;q=0.7',
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(
          success.response.requestOptions.headers['Accept-Language'],
          '''en-US%2Cen%3Bq%3D0.9%2Czh-CN%3Bq%3D0.8%2C%E6%97%A5%E6%9C%AC%E8%AA%9E%3Bq%3D0.7''',
        );
      });
    });

    group('response decoding - 204', () {
      test('204 response is decoded as PostEventHitResponse204', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        expect(response, isA<TonikSuccess<PostEventHitResponse>>());
        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(success.response.statusCode, 204);
        expect(success.value, isA<PostEventHitResponse204>());
      });

      test('204 response has no body content', () async {
        final api = buildEventApi(responseStatus: '204');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        // 204 No Content should have empty body
        final responseData = success.response.data as List<int>?;
        expect(responseData == null || responseData.isEmpty, isTrue);
      });
    });

    group('response decoding - 400', () {
      test('400 response is decoded as PostEventHitResponse400', () async {
        final api = buildEventApi(responseStatus: '400');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: '',
              u: Uri.parse('invalid'),
              p: true,
              q: false,
            ),
          ),
        );

        expect(response, isA<TonikSuccess<PostEventHitResponse>>());
        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<PostEventHitResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildEventApi(responseStatus: '400');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: '',
              u: Uri.parse('invalid'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final response400 = success.value as PostEventHitResponse400;

        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });
    });

    group('response decoding - 404', () {
      test('404 response is decoded as PostEventHitResponse404', () async {
        final api = buildEventApi(responseStatus: '404');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://unknown.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        expect(response, isA<TonikSuccess<PostEventHitResponse>>());
        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<PostEventHitResponse404>());
      });

      test('404 response body decodes error object', () async {
        final api = buildEventApi(responseStatus: '404');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://unknown.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final response404 = success.value as PostEventHitResponse404;

        expect(response404.body, isA<NotFoundError>());
        expect(response404.body.body.error, isA<NotFoundErrorBodyErrorModel>());
        expect(response404.body.body.error.code, isA<int>());
        expect(response404.body.body.error.message, isA<String>());
      });
    });

    group('response decoding - 500', () {
      test('500 response is decoded as PostEventHitResponse500', () async {
        final api = buildEventApi(responseStatus: '500');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        expect(response, isA<TonikSuccess<PostEventHitResponse>>());
        final success = response as TonikSuccess<PostEventHitResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<PostEventHitResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildEventApi(responseStatus: '500');

        final response = await api.postEventHit(
          body: EventHitEventLoad(
            EventLoad(
              b: 'beacon',
              u: Uri.parse('https://example.com/'),
              p: true,
              q: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PostEventHitResponse>;
        final response500 = success.value as PostEventHitResponse500;

        expect(response500.body, isA<InternalServerError>());
        expect(
          response500.body.body.error,
          isA<InternalServerErrorBodyErrorModel>(),
        );
        expect(response500.body.body.error.code, isA<int>());
        expect(response500.body.body.error.message, isA<String>());
      });
    });
  });

  group('getEventPing', () {
    group('request encoding - path and method', () {
      test('request path is /event/ping', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(
          success.response.requestOptions.path,
          startsWith('http://localhost:8102/event/ping'),
        );
      });

      test('request method is GET', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });
    });

    group('request encoding - query parameter u', () {
      test('u query parameter is encoded when provided', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing(
          u: 'https://example.com/page',
        );

        final success = response as TonikSuccess<GetEventPingResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['u'], 'https://example.com/page');
      });

      test('u query parameter encodes URL with query string', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing(
          u: 'https://example.com/page?param=value&other=test',
        );

        final success = response as TonikSuccess<GetEventPingResponse>;
        final uri = success.response.requestOptions.uri;
        expect(
          uri.queryParameters['u'],
          'https://example.com/page?param=value&other=test',
        );
      });

      test('u query parameter is omitted when not provided', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters.containsKey('u'), isFalse);
      });

      test('u query parameter encodes special characters', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing(
          u: 'https://example.com/search?q=hello world&lang=日本語',
        );

        final success = response as TonikSuccess<GetEventPingResponse>;
        final uri = success.response.requestOptions.uri;
        // The value should be properly encoded in the URL
        expect(uri.queryParameters['u'], contains('example.com'));
      });
    });

    group('request encoding - headers', () {
      test('If-Modified-Since header is encoded when provided', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing(
          ifModifiedSince: 'Wed, 21 Oct 2015 07:28:00 GMT',
        );

        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(
          success.response.requestOptions.headers['If-Modified-Since'],
          'Wed%2C%2021%20Oct%202015%2007%3A28%3A00%20GMT',
        );
      });

      test('If-Modified-Since header is omitted when not provided', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(
          success.response.requestOptions.headers.containsKey(
            'If-Modified-Since',
          ),
          isFalse,
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetEventPingResponse200', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        expect(response, isA<TonikSuccess<GetEventPingResponse>>());
        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetEventPingResponse200>());
      });

      test('200 response decodes text/plain body', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final response200 = success.value as GetEventPingResponse200;
        expect(response200.body.body, isA<String>());
      });

      test('200 response decodes Cache-Control header', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final response200 = success.value as GetEventPingResponse200;
        expect(response200.body.cacheControl, isA<String>());
      });

      test('200 response decodes Last-Modified header', () async {
        final api = buildEventApi(responseStatus: '200');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final response200 = success.value as GetEventPingResponse200;
        expect(response200.body.lastModified, isA<String>());
      });
    });

    group('response decoding - 400', () {
      test('400 response is decoded as GetEventPingResponse400', () async {
        final api = buildEventApi(responseStatus: '400');

        final response = await api.getEventPing();

        expect(response, isA<TonikSuccess<GetEventPingResponse>>());
        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetEventPingResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildEventApi(responseStatus: '400');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final response400 = success.value as GetEventPingResponse400;

        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });
    });

    group('response decoding - 500', () {
      test('500 response is decoded as GetEventPingResponse500', () async {
        final api = buildEventApi(responseStatus: '500');

        final response = await api.getEventPing();

        expect(response, isA<TonikSuccess<GetEventPingResponse>>());
        final success = response as TonikSuccess<GetEventPingResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetEventPingResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildEventApi(responseStatus: '500');

        final response = await api.getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final response500 = success.value as GetEventPingResponse500;

        expect(response500.body, isA<InternalServerError>());
        expect(
          response500.body.body.error,
          isA<InternalServerErrorBodyErrorModel>(),
        );
        expect(response500.body.body.error.code, isA<int>());
        expect(response500.body.body.error.message, isA<String>());
      });
    });
  });
}
