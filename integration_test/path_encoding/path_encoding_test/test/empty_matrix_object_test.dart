import 'dart:convert';

import 'package:path_encoding_api/path_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('empty exploded map sends the request with a trailing slash', () async {
    final server = await RawRequestServer.start();
    final api = MatrixApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testMatrixExplodedCoordinates(
      coordinates: const {},
    );

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/items/');
    expect(request.uri.query, '');
  });

  test('nonempty exploded map keeps its property name and value', () async {
    final server = await RawRequestServer.start();
    final api = MatrixApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testMatrixExplodedCoordinates(
      coordinates: const {'x': '1'},
    );

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.path, '/items/;x=1');
  });

  test('empty collapsed map sends the request with a trailing slash', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('{}'),
    );
    final api = MatrixApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testMatrixMapString(values: const {});

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.path, '/matrix/map/string/');
  });

  test('model with all properties omitted expands to nothing', () async {
    final server = await RawRequestServer.start();
    final api = MatrixApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testMatrixOptionalObject(
      value: const OptionalObject(),
    );

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.path, '/matrix/object/optional/');
  });

  test('empty scalar string still expands to the parameter name', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('{}'),
    );
    final api = MatrixApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testMatrixPrimitiveString(value: '');

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.path, '/matrix/primitive/string/;value');
  });
}
