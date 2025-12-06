import 'package:dio/dio.dart';
import 'package:path_encoding_api/path_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8090;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  MatrixApi buildMatrixApi() {
    return MatrixApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(baseOptions: BaseOptions()),
      ),
    );
  }

  group('Matrix style - Primitives', () {
    test('string value encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixPrimitiveString(value: 'blue');

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/primitive/string/;value=blue',
      );
    });

    test('integer value encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixPrimitiveInteger(value: 42);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/primitive/integer/;value=42',
      );
    });

    test('number value encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixPrimitiveNumber(value: 3.14);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/primitive/number/;value=3.14',
      );
    });

    test('boolean value encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixPrimitiveBoolean(value: true);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/primitive/boolean/;value=true',
      );
    });

    test('enum value encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixPrimitiveEnum(
        value: StatusEnum.active,
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/primitive/enum/;value=active',
      );
    });
  });

  group('Matrix style - Arrays', () {
    test('string array (explode=false) encodes as ;param=v1,v2,v3', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixArrayString(
        values: ['blue', 'black', 'brown'],
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/array/string/;values=blue,black,brown',
      );
    });

    test(
      'string array (explode=true) encodes as ;param=v1;param=v2;param=v3',
      () async {
        final api = buildMatrixApi();
        final response = await api.testMatrixArrayStringExplode(
          values: ['blue', 'black', 'brown'],
        );

        expect(response, isA<TonikSuccess<EchoResponse>>());
        final success = response as TonikSuccess<EchoResponse>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.uri.path,
          '/v1/matrix/array/string/explode/;values=blue;values=black;values=brown',
        );
      },
    );

    test('integer array (explode=false) encodes as ;param=v1,v2,v3', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixArrayInteger(values: [1, 2, 3]);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/array/integer/;values=1,2,3',
      );
    });
  });

  group('Matrix style - Objects', () {
    test('object (explode=false) encodes as ;param=k1,v1,k2,v2', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixObject(
        value: const SimpleObject(name: 'test', count: 5),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/object/;value=name,test,count,5',
      );
    });

    test('object (explode=true) encodes as ;k1=v1;k2=v2', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixObjectExplode(
        value: const SimpleObject(name: 'test', count: 5),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/object/explode/;name=test;count=5',
      );
    });
  });

  group('Matrix style - Combined', () {
    test('multiple matrix params encode correctly', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixCombined(
        stringValue: 'hello',
        intValue: 42,
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/combined/;stringValue=hello/;intValue=42',
      );
    });
  });
}
