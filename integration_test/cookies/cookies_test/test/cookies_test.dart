import 'package:big_decimal/big_decimal.dart';
import 'package:cookies_api/cookies_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  CookiesApi buildCookiesApi({required String responseStatus}) {
    return CookiesApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  Future<String?> getCookieHeader() async {
    final recordedRequest = await imposterServer.takeRequest();
    return recordedRequest.headers['cookie'];
  }

  group('simple primitive cookies', () {
    test('string cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'abc123');

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'sessionId=abc123');
    });

    test('integer cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleIntegerCookie(userId: 42);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'userId=42');
    });

    test('boolean cookie - true', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleBooleanCookie(rememberMe: true);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'rememberMe=true');
    });

    test('boolean cookie - false', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleBooleanCookie(rememberMe: false);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'rememberMe=false');
    });

    test('number cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleNumberCookie(score: 98.5);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'score=98.5');
    });
  });

  group('optional cookies', () {
    test('optional cookie when provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalCookie(trackingId: 'track123');

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'trackingId=track123');
    });

    test('optional cookie when not provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalCookie();

      expect(response, isTonikSuccess);
      // No Cookie header should be set when no cookies are provided.
      expect(await getCookieHeader(), isNull);
    });
  });

  group('multiple cookies', () {
    test('multiple required cookies', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMultipleCookies(
        sessionId: 'session123',
        userId: 42,
      );

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'theme=light');
    });

    test('enum cookie - dark', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testEnumCookie(theme: ThemeEnum.dark);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'theme=dark');
    });

    test('enum cookie - system', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testEnumCookie(theme: ThemeEnum.system);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'theme=system');
    });
  });

  group('special characters in cookie values', () {
    test('cookie value with spaces', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(
        sessionId: 'hello world',
      );

      expect(response, isTonikSuccess);
      // Spaces should be percent-encoded in form style.
      expect(
        await getCookieHeader(),
        'sessionId=hello%20world',
      );
    });

    test('cookie value with equals sign', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a=b');

      expect(response, isTonikSuccess);
      // Equals sign must be percent-encoded to avoid ambiguity.
      expect(await getCookieHeader(), 'sessionId=a%3Db');
    });

    test('cookie value with ampersand', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a&b');

      expect(response, isTonikSuccess);
      // Ampersand should be percent-encoded.
      expect(await getCookieHeader(), 'sessionId=a%26b');
    });

    test('cookie value with multiple special characters', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a=b&c=d');

      expect(response, isTonikSuccess);
      // All special characters should be percent-encoded.
      expect(
        await getCookieHeader(),
        'sessionId=a%3Db%26c%3Dd',
      );
    });

    test('cookie value with semicolon', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a;b');

      expect(response, isTonikSuccess);
      // Semicolon must be encoded to avoid cookie separator ambiguity.
      expect(await getCookieHeader(), 'sessionId=a%3Bb');
    });

    test('cookie value with unicode', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'héllo');

      expect(response, isTonikSuccess);
      // UTF-8 encoded: é = 0xC3 0xA9 = %C3%A9.
      expect(await getCookieHeader(), 'sessionId=h%C3%A9llo');
    });

    test('cookie value with emoji', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'hi👋');

      expect(response, isTonikSuccess);
      // UTF-8 encoded: 👋 = F0 9F 91 8B = %F0%9F%91%8B.
      expect(
        await getCookieHeader(),
        'sessionId=hi%F0%9F%91%8B',
      );
    });

    test('cookie value with percent sign', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: '100%');

      expect(response, isTonikSuccess);
      // Percent sign must be encoded to avoid decoding ambiguity.
      expect(await getCookieHeader(), 'sessionId=100%25');
    });

    test('cookie value with plus sign', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testSimpleStringCookie(sessionId: 'a+b');

      expect(response, isTonikSuccess);
      // Plus sign should be percent-encoded in form style.
      expect(await getCookieHeader(), 'sessionId=a%2Bb');
    });
  });

  group('cookies combined with other parameters', () {
    test('cookie with query parameter', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testCombinedParams(
        sessionId: 'session123',
        filter: 'active',
      );

      expect(response, isTonikSuccess);
      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.headers['cookie'], 'sessionId=session123');
      expect(
        recordedRequest.uri.query,
        contains('filter=active'),
      );
    });

    test('cookie with header parameter', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testCombinedParams(
        sessionId: 'session123',
        requestId: 'req-456',
      );

      expect(response, isTonikSuccess);
      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.headers['cookie'], 'sessionId=session123');
      expect(
        recordedRequest.headers['x-request-id'],
        'req-456',
      );
    });

    test('cookie with path parameter', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testCombinedParamsWithPath(
        id: 123,
        authToken: 'token456',
      );

      expect(response, isTonikSuccess);
      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.headers['cookie'], 'authToken=token456');
      expect(recordedRequest.uri.toString(), contains('/123'));
    });
  });

  group('datetime cookies', () {
    test('datetime cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final dateTime = DateTime.utc(2024, 6, 15, 10, 30);
      final response = await api.testDateTimeCookie(lastVisit: dateTime);

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
      expect(cookie, isNotNull);
      expect(cookie, startsWith('lastVisit='));
      // Should be ISO 8601 format, URL-encoded.
      expect(cookie, contains('2024-06-15'));
    });

    test('date cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final date = Date(2024, 6, 15);
      final response = await api.testDateCookie(birthDate: date);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'birthDate=2024-06-15');
    });
  });

  group('uri cookies', () {
    test('uri cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final uri = Uri.parse('https://example.com/callback?foo=bar');
      final response = await api.testUriCookie(returnUrl: uri);

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
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

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'amount=123.456');
    });
  });

  group('nullable cookies', () {
    test('nullable cookie with value', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testNullableCookie(optionalValue: 'present');

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'optionalValue=present',
      );
    });

    test('nullable cookie without value', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testNullableCookie();

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), isNull);
    });
  });

  group('referenced cookies', () {
    test(r'cookie defined via $ref', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testRefCookie(session: 'ref-session-123');

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'session=ref-session-123',
      );
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

      expect(response, isTonikSuccess);
      final cookie = await getCookieHeader();
      expect(cookie, isNotNull);
      expect(cookie, contains('stringVal=test'));
      expect(cookie, contains('intVal=42'));
      expect(cookie, contains('boolVal=true'));
      expect(cookie, contains('numVal=3.14'));
      expect(cookie, contains('dateVal=2024-06-15'));
      expect(cookie, contains('datetimeVal='));
    });
  });

  group('array cookies', () {
    test('array of strings cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayCookie(tags: ['a', 'b', 'c']);

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'tags=a; tags=b; tags=c',
      );
    });

    test('array of strings with special characters', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayCookie(
        tags: ['hello world', 'a=b', 'special&chars'],
      );

      expect(response, isTonikSuccess);
      // Values should be URL-encoded.
      expect(
        await getCookieHeader(),
        'tags=hello%20world; tags=a%3Db; tags=special%26chars',
      );
    });

    test('empty array cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayCookie(tags: []);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), isNull);
    });

    test('array of integers cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayIntegerCookie(ids: [1, 2, 3, 100]);

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'ids=1; ids=2; ids=3; ids=100',
      );
    });

    test('single element array cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayIntegerCookie(ids: [42]);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'ids=42');
    });
  });

  group('object cookies', () {
    test('flat object cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testObjectCookie(
        user: const UserObject(id: 1, name: 'John'),
      );

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'id=1; name=John');
    });

    test('object cookie with special characters in values', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testObjectCookie(
        user: const UserObject(id: 42, name: 'John Doe'),
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'id=42; name=John%20Doe',
      );
    });
  });

  group('object cookie with unset optional member', () {
    test('omits the unset optional member from the cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testPartialObjectCookie(
        session: const PartialSession(id: '42'),
      );

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'session=id,42');
    });

    test(
      'keeps a defined empty-string member as a named empty value',
      () async {
        final api = buildCookiesApi(responseStatus: '204');
        final response = await api.testPartialObjectCookie(
          session: const PartialSession(id: '42', theme: ''),
        );

        expect(response, isTonikSuccess);
        expect(
          await getCookieHeader(),
          'session=id,42,theme,',
        );
      },
    );
  });

  group('composition cookies', () {
    test('oneOf cookie with string variant', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOneOfCookie(
        identifier: const OneOfIdentifierString('test-value'),
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'identifier=test-value',
      );
    });

    test('oneOf cookie with integer variant', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOneOfCookie(
        identifier: const OneOfIdentifierInt(12345),
      );

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'identifier=12345');
    });

    test('anyOf cookie with string variant', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAnyOfCookie(
        value: const AnyOfValue(string: 'test-value'),
      );

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'value=test-value');
    });

    test('anyOf cookie with integer variant', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAnyOfCookie(
        value: const AnyOfValue(int: 42),
      );

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'value=42');
    });

    test('allOf cookie encodes successfully', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAllOfCookie(
        entity: const AllOfEntity(
          allOfEntityModel: AllOfEntityModel(id: 1),
          allOfEntityModel2: AllOfEntityModel2(name: 'Test'),
        ),
      );

      expect(response, isTonikSuccess);
      // AllOf encodes all properties (form style, explode: true).
      expect(await getCookieHeader(), 'id=1; name=Test');
    });
  });

  group('map cookies', () {
    test('map with string values', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMapStringCookie(
        labels: {'color': 'blue', 'size': 'large'},
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'color=blue; size=large',
      );
    });

    test('map with integer values', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMapIntegerCookie(
        prefs: {'volume': 80, 'brightness': 50},
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'volume=80; brightness=50',
      );
    });

    test('map with single entry', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMapIntegerCookie(prefs: {'volume': 80});

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'volume=80');
    });

    test('empty map', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testMapIntegerCookie(prefs: {});

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), isNull);
    });

    test('optional map when provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalMapCookie(
        settings: {'timeout': 30},
      );

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'timeout=30');
    });

    test('optional map when not provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalMapCookie();

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), isNull);
    });
  });

  group('nested object cookies', () {
    test('nested object cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testNestedObjectCookie(
        profile: const NestedProfile(
          user: UserObject(id: 1, name: 'John'),
        ),
      );

      // Nested objects are not supported in form encoding.
      expect(response, isTonikError);
      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    });
  });

  group('AnyModel cookies', () {
    test('required AnyModel cookie with string value', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAnyCookie(data: 'hello');

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'data=hello');
    });

    test('required AnyModel cookie with integer value', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAnyCookie(data: 42);

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'data=42');
    });

    test('array of AnyModel cookie', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testArrayAnyCookie(items: ['a', 1, true]);

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'items=a; items=1; items=true',
      );
    });
  });

  group('alias-wrapped cookies', () {
    test('nested alias to list of booleans', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAliasBoolListCookie(
        flags: [true, false, true],
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'flags=true; flags=false; flags=true',
      );
    });

    test('nested alias to list of integers encodes as form list', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAliasIntListCookie(numbers: [1, 2, 3]);

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'numbers=1; numbers=2; numbers=3',
      );
    });

    test('alias to list of strings', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAliasStringListCookie(
        names: ['alice', 'bob', 'carol'],
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'names=alice; names=bob; names=carol',
      );
    });

    test('optional alias to list of integers when provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalAliasIntListCookie(
        numbers: [10, 20],
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'numbers=10; numbers=20',
      );
    });

    test('optional alias to list of integers when not provided', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testOptionalAliasIntListCookie();

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), isNull);
    });

    test('alias to map of integers', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAliasMapCookie(
        prefs: {'volume': 80, 'brightness': 50},
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'volume=80; brightness=50',
      );
    });

    test('alias to AnyModel scalar', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAliasAnyCookie(data: 'hello');

      expect(response, isTonikSuccess);
      expect(await getCookieHeader(), 'data=hello');
    });

    test('alias to list of AnyModel', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.testAliasArrayAnyCookie(
        items: ['a', 1, true],
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'items=a; items=1; items=true',
      );
    });
  });

  group('base64 (byte) cookies', () {
    test('scalar and array base64 cookies encode as base64 form', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.getBase64Cookies(
        binaryToken: const TonikFileBytes([104, 105]),
        binaryTokens: const [
          TonikFileBytes([97]),
          TonikFileBytes([98, 99]),
        ],
      );

      expect(response, isTonikSuccess);
      expect(
        await getCookieHeader(),
        'binaryToken=aGk%3D; binaryTokens=YQ%3D%3D; binaryTokens=YmM%3D',
      );
    });
  });

  group('binary cookies', () {
    test('binary scalar cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.getBinaryCookies(
        binaryData: const TonikFileBytes([1, 2, 3]),
      );

      expect(response, isTonikError);
      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(
        (error.error as EncodingException).message,
        'Binary data cannot be form-encoded for cookie binaryData',
      );
    });

    test('binary array cookie returns encoding error', () async {
      final api = buildCookiesApi(responseStatus: '204');
      final response = await api.getBinaryCookiesArray(
        binaryDataList: const [
          TonikFileBytes([1, 2, 3]),
          TonikFileBytes([4, 5, 6]),
        ],
      );

      expect(response, isTonikError);
      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(
        (error.error as EncodingException).message,
        'Binary data cannot be form-encoded for cookie binaryDataList',
      );
    });
  });
}
