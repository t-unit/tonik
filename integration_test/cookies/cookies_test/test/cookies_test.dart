import 'package:big_decimal/big_decimal.dart';
import 'package:cookies_api/cookies_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 9090;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  CookiesApi buildCookiesApi({required String responseStatus}) {
    return CookiesApi(
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

  String? getCookieHeader(TonikResult<void> response) {
    if (response is TonikSuccess<void>) {
      return response.response.requestOptions.headers['Cookie'] as String?;
    }
    return null;
  }

  group('simple primitive cookies', () {
    test('string cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'abc123');

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'sessionId=abc123');
    });

    test('integer cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleIntegerCookie(userId: 42);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'userId=42');
    });

    test('boolean cookie - true', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleBooleanCookie(rememberMe: true);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'rememberMe=true');
    });

    test('boolean cookie - false', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleBooleanCookie(rememberMe: false);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'rememberMe=false');
    });

    test('number cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleNumberCookie(score: 98.5);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'score=98.5');
    });
  });

  group('optional cookies', () {
    test('optional cookie when provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalCookie(trackingId: 'track123');

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'trackingId=track123');
    });

    test('optional cookie when not provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalCookie();

      expect(response, isA<TonikSuccess<void>>());
      // No Cookie header should be set when no cookies are provided.
      expect(getCookieHeader(response), isNull);
    });
  });

  group('multiple cookies', () {
    test('multiple required cookies', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMultipleCookies(
        sessionId: 'session123',
        userId: 42,
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, contains('sessionId=session123'));
      expect(cookie, contains('userId=42'));
      expect(cookie, contains('; '));
    });

    test('multiple cookies with optional provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMultipleCookies(
        sessionId: 'session123',
        userId: 42,
        preferences: 'dark-mode',
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, contains('sessionId=session123'));
      expect(cookie, contains('userId=42'));
      expect(cookie, contains('preferences=dark-mode'));
    });

    test('multiple cookies without optional', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMultipleCookies(
        sessionId: 'session123',
        userId: 42,
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, isNot(contains('preferences=')));
    });
  });

  group('mixed required and optional cookies', () {
    test('only required cookies', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMixedCookies(
        authToken: 'auth123',
        csrfToken: 'csrf456',
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, contains('authToken=auth123'));
      expect(cookie, contains('csrfToken=csrf456'));
      expect(cookie, isNot(contains('locale=')));
      expect(cookie, isNot(contains('darkMode=')));
    });

    test('all cookies provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMixedCookies(
        authToken: 'auth123',
        csrfToken: 'csrf456',
        locale: 'en-US',
        darkMode: true,
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, contains('authToken=auth123'));
      expect(cookie, contains('csrfToken=csrf456'));
      expect(cookie, contains('locale=en-US'));
      expect(cookie, contains('darkMode=true'));
    });

    test('some optional cookies provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMixedCookies(
        authToken: 'auth123',
        csrfToken: 'csrf456',
        darkMode: false,
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, contains('authToken=auth123'));
      expect(cookie, contains('csrfToken=csrf456'));
      expect(cookie, isNot(contains('locale=')));
      expect(cookie, contains('darkMode=false'));
    });
  });

  group('enum cookies', () {
    test('enum cookie - light', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testEnumCookie(theme: ThemeEnum.light);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'theme=light');
    });

    test('enum cookie - dark', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testEnumCookie(theme: ThemeEnum.dark);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'theme=dark');
    });

    test('enum cookie - system', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testEnumCookie(theme: ThemeEnum.system);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'theme=system');
    });
  });

  group('special characters in cookie values', () {
    test('cookie value with spaces', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(
        sessionId: 'hello world',
      );

      expect(response, isA<TonikSuccess<void>>());
      // Spaces should be percent-encoded in form style.
      expect(getCookieHeader(response), 'sessionId=hello%20world');
    });

    test('cookie value with equals sign', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a=b');

      expect(response, isA<TonikSuccess<void>>());
      // Equals sign must be percent-encoded to avoid ambiguity.
      expect(getCookieHeader(response), 'sessionId=a%3Db');
    });

    test('cookie value with ampersand', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a&b');

      expect(response, isA<TonikSuccess<void>>());
      // Ampersand should be percent-encoded.
      expect(getCookieHeader(response), 'sessionId=a%26b');
    });

    test('cookie value with multiple special characters', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a=b&c=d');

      expect(response, isA<TonikSuccess<void>>());
      // All special characters should be percent-encoded.
      expect(getCookieHeader(response), 'sessionId=a%3Db%26c%3Dd');
    });

    test('cookie value with semicolon', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a;b');

      expect(response, isA<TonikSuccess<void>>());
      // Semicolon must be encoded to avoid cookie separator ambiguity.
      expect(getCookieHeader(response), 'sessionId=a%3Bb');
    });

    test('cookie value with unicode', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'héllo');

      expect(response, isA<TonikSuccess<void>>());
      // UTF-8 encoded: é = 0xC3 0xA9 = %C3%A9.
      expect(getCookieHeader(response), 'sessionId=h%C3%A9llo');
    });

    test('cookie value with emoji', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'hi👋');

      expect(response, isA<TonikSuccess<void>>());
      // UTF-8 encoded: 👋 = F0 9F 91 8B = %F0%9F%91%8B.
      expect(getCookieHeader(response), 'sessionId=hi%F0%9F%91%8B');
    });

    test('cookie value with percent sign', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: '100%');

      expect(response, isA<TonikSuccess<void>>());
      // Percent sign must be encoded to avoid decoding ambiguity.
      expect(getCookieHeader(response), 'sessionId=100%25');
    });

    test('cookie value with plus sign', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a+b');

      expect(response, isA<TonikSuccess<void>>());
      // Plus sign should be percent-encoded in form style.
      expect(getCookieHeader(response), 'sessionId=a%2Bb');
    });
  });

  group('cookies combined with other parameters', () {
    test('cookie with query parameter', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testCombinedParams(
        sessionId: 'session123',
        filter: 'active',
      );

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'sessionId=session123');

      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        contains('filter=active'),
      );
    });

    test('cookie with header parameter', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testCombinedParams(
        sessionId: 'session123',
        requestId: 'req-456',
      );

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'sessionId=session123');

      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.headers['X-Request-Id'],
        'req-456',
      );
    });

    test('cookie with path parameter', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testCombinedParamsWithPath(
        id: 123,
        authToken: 'token456',
      );

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'authToken=token456');

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.path, contains('/123'));
    });
  });

  group('datetime cookies', () {
    test('datetime cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final dateTime = DateTime.utc(2024, 6, 15, 10, 30);
      final response = await api.testDateTimeCookie(lastVisit: dateTime);

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, isNotNull);
      expect(cookie, startsWith('lastVisit='));
      // Should be ISO 8601 format, URL-encoded.
      expect(cookie, contains('2024-06-15'));
    });

    test('date cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final date = Date(2024, 6, 15);
      final response = await api.testDateCookie(birthDate: date);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'birthDate=2024-06-15');
    });
  });

  group('uri cookies', () {
    test('uri cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final uri = Uri.parse('https://example.com/callback?foo=bar');
      final response = await api.testUriCookie(returnUrl: uri);

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, isNotNull);
      expect(cookie, startsWith('returnUrl='));
      // URI should be encoded.
      expect(cookie, contains('example.com'));
    });
  });

  group('decimal cookies', () {
    test('decimal cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final amount = BigDecimal.parse('123.456');
      final response = await api.testDecimalCookie(amount: amount);

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'amount=123.456');
    });
  });

  group('nullable cookies', () {
    test('nullable cookie with value', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testNullableCookie(optionalValue: 'present');

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'optionalValue=present');
    });

    test('nullable cookie without value', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testNullableCookie();

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), isNull);
    });
  });

  group('referenced cookies', () {
    test(r'cookie defined via $ref', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testRefCookie(session: 'ref-session-123');

      expect(response, isA<TonikSuccess<void>>());
      expect(getCookieHeader(response), 'session=ref-session-123');
    });
  });

  group('all primitive types', () {
    test('all primitive types as cookies', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAllPrimitiveCookies(
        stringVal: 'test',
        intVal: 42,
        boolVal: true,
        numVal: 3.14,
        dateVal: Date(2024, 6, 15),
        datetimeVal: DateTime.utc(2024, 6, 15, 10, 30),
      );

      expect(response, isA<TonikSuccess<void>>());
      final cookie = getCookieHeader(response);
      expect(cookie, isNotNull);
      expect(cookie, contains('stringVal=test'));
      expect(cookie, contains('intVal=42'));
      expect(cookie, contains('boolVal=true'));
      expect(cookie, contains('numVal=3.14'));
      expect(cookie, contains('dateVal=2024-06-15'));
      expect(cookie, contains('datetimeVal='));
    });
  });

  group('unsupported complex types', () {
    test('array cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayCookie(tags: ['a', 'b', 'c']);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    });

    test('object cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testObjectCookie(
        user: const UserObject(id: 1, name: 'John'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    });

    test(
      'oneOf cookie encodes successfully when variant is primitive',
      () async {
        final api = buildCookiesApi(responseStatus: '204');
        final response = await api.testOneOfCookie(
          identifier: const OneOfIdentifierString('test-value'),
        );

        // oneOf with primitive variants can encode successfully.
        expect(response, isA<TonikSuccess<void>>());
        final cookie = getCookieHeader(response);
        expect(cookie, isNotNull);
        expect(cookie, contains('identifier='));
      },
    );

    test(
      'anyOf cookie encodes successfully when variant is primitive',
      () async {
        final api = buildCookiesApi(responseStatus: '204');
        final response = await api.testAnyOfCookie(
          value: const AnyOfValue(string: 'test-value'),
        );

        // anyOf with primitive variants can encode successfully.
        expect(response, isA<TonikSuccess<void>>());
        final cookie = getCookieHeader(response);
        expect(cookie, isNotNull);
        expect(cookie, contains('value='));
      },
    );

    test('allOf cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAllOfCookie(
        entity: const AllOfEntity(
          allOfEntityModel: AllOfEntityModel(id: 1),
          allOfEntityModel2: AllOfEntityModel2(name: 'Test'),
        ),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    });

    test('nested object cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testNestedObjectCookie(
        profile: const NestedProfile(
          user: UserObject(id: 1, name: 'John'),
        ),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    });
  });
}
