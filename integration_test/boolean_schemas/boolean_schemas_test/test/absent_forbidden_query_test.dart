import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'dispatches a valid filter with its forbidden property absent',
    () async {
      final server = await RawRequestServer.start();
      final api = BooleanSchemasApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );
      final filter = ProfileFilter.fromJson(const {'name': 'alice'});
      expect(filter.password, isNull);
      expect(filter.toJson(), {'name': 'alice'});

      final response = await api.searchProfiles(filter: filter);
      expect(response, isTonikSuccess);

      final request = await server.takeRequest();
      expect(request.method, 'GET');
      expect(request.uri.path, '/profiles');
      expect(request.uri.query, 'name=alice');
    },
  );

  test('preserves list query values beside a forbidden alias', () async {
    final server = await RawRequestServer.start();
    final api = BooleanSchemasApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );
    final filter = ProfileListFilter.fromJson(const {
      'tags': ['daily', 'weekly'],
    });
    expect(filter.password, isNull);
    expect(filter.toJson(), {
      'tags': ['daily', 'weekly'],
    });

    final response = await api.searchProfilesByTags(filter: filter);
    expect(response, isTonikSuccess);

    final request = await server.takeRequest();
    expect(request.uri.path, '/profiles/tags');
    expect(request.uri.query, 'tags=daily,weekly');
  });

  test(
    'preserves Any scalar query encoding beside a forbidden property',
    () async {
      final server = await RawRequestServer.start();
      final api = BooleanSchemasApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );
      final filter = ProfileMixedFilter.fromJson(const {'data': 42});
      expect(filter.password, isNull);
      expect(filter.toJson(), {'data': 42});

      final response = await api.searchProfilesByData(filter: filter);
      expect(response, isTonikSuccess);

      final request = await server.takeRequest();
      expect(request.uri.path, '/profiles/data');
      expect(request.uri.query, 'data=42');
    },
  );

  test('still rejects a present forbidden JSON value', () {
    expect(
      () =>
          ProfileFilter.fromJson(const {'name': 'alice', 'password': 'secret'}),
      throwsA(isA<JsonDecodingException>()),
    );
  });

  test('retains the existing rejection for List of Never parameter values', () {
    final shape = Shape.fromJson(const {'corner': <Object?>[]});

    expect(shape.parameterProperties, throwsA(isA<EncodingException>()));
    expect(shape.toJson(), {'corner': <Object?>[]});
  });
}
