import 'dart:convert';

import 'package:nullable_bodies_api/nullable_bodies_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('rejects an omitted required nullable property', () {
    expect(
      () => Profile.fromJson(const <String, Object?>{}),
      throwsA(
        isA<JsonDecodingException>().having(
          (error) => error.message,
          'message',
          'Missing required property Profile.nickname.',
        ),
      ),
    );
  });

  test('preserves explicit null while omitting absent optional properties', () {
    final profile = Profile.fromJson(const {'nickname': null});

    expect(profile.nickname, isNull);
    expect(profile.bio, isNull);
    expect(profile.toJson(), {'nickname': null});
  });

  test('accepts nonnull values for required and optional properties', () {
    final profile = Profile.fromJson(const {
      'nickname': 'daily',
      'bio': 'Reports',
    });

    expect(profile.nickname, 'daily');
    expect(profile.bio, 'Reports');
    expect(profile.toJson(), {'nickname': 'daily', 'bio': 'Reports'});
  });

  test('requires a property whose nullable schema is referenced', () {
    expect(
      () => AliasProfile.fromJson(const <String, Object?>{}),
      throwsA(isA<JsonDecodingException>()),
    );
    expect(AliasProfile.fromJson(const {'nickname': null}).nickname, isNull);
  });

  test('requires read-only properties in responses', () {
    expect(
      () => DirectionalProfile.fromJson(const <String, Object?>{}),
      throwsA(isA<JsonDecodingException>()),
    );
  });

  test('accepts absent required write-only properties in responses', () {
    final profile = DirectionalProfile.fromJson(const {'nickname': null});

    expect(profile.nickname, isNull);
    expect(profile.credential, isNull);
  });

  test('retains existing default fallback and explicit null behavior', () {
    final omitted = DefaultProfile.fromJson(const <String, Object?>{});
    final explicitNull = DefaultProfile.fromJson(const {'nickname': null});

    expect(omitted.nickname, 'guest');
    expect(explicitNull.nickname, isNull);
  });

  test(
    'operation reports a missing required nullable property as an error',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'application/json'},
        responseBody: utf8.encode('{}'),
      );
      final api = NullableBodiesApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getProfile();

      final error = requireError(response);
      expect(error.type, TonikErrorType.decoding);
    },
  );

  test('operation accepts an explicit null required property', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json'},
      responseBody: utf8.encode('{"nickname":null}'),
    );
    final api = NullableBodiesApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getProfile();

    final success = requireSuccess(response);
    expect(success.value.toJson(), {'nickname': null});
  });
}
