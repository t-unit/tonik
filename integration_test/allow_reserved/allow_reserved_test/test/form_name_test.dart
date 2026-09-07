import 'package:allow_reserved_api/allow_reserved_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'escapes the declared name while allowing reserved value chars',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testFormReservedNames(
        filterSlashName: 'a/b?c:d@e',
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(request.uri.query, 'filter%2Fname=a/b?c:d@e');
    },
  );

  test('escapes the declared name and value without allowReserved', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testFormReservedNames(
      defaultSlashName: 'a/b?c:d@e',
    );

    requireSuccess(response);
    final request = await server.takeRequest();
    expect(request.uri.query, 'default%2Fname=a%2Fb%3Fc%3Ad%40e');
  });

  test(
    'escapes each repeated array name while retaining value slashes',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testFormReservedNames(
        repeatedSlashName: const ['a/b', 'c/d'],
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(request.uri.query, 'repeated%2Fname=a/b&repeated%2Fname=c/d');
    },
  );

  test(
    'escapes a collapsed object name while retaining value slashes',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testFormReservedNames(
        objectSlashName: const ReservedListObject(tags: ['a/b', 'c/d']),
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(request.uri.query, 'object%2Fname=tags,a/b,c/d');
    },
  );

  test(
    'escapes a collapsed object name and value without allowReserved',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testFormReservedNames(
        defaultObjectSlashName: const ReservedListObject(tags: ['a/b', 'c/d']),
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(request.uri.query, 'defaultObject%2Fname=tags,a%2Fb,c%2Fd');
    },
  );

  test(
    'escapes Date and enum names while retaining reserved enum chars',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testFormReservedNames(
        dateSlashName: Date(2024, 3, 15),
        enumSlashName: ReservedChoice.aSlashBc,
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(request.uri.query, 'date%2Fname=2024-03-15&enum%2Fname=a/b:c');
    },
  );
}
