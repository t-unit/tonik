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

  LabelApi buildLabelApi() {
    return LabelApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(baseOptions: BaseOptions()),
      ),
    );
  }

  group('Label style - Primitives', () {
    test('string value encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelPrimitiveString(value: 'blue');

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/primitive/string/.blue',
      );
    });

    test('integer value encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelPrimitiveInteger(value: 42);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/primitive/integer/.42',
      );
    });

    test('number value encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelPrimitiveNumber(value: 3.14);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/primitive/number/.3.14',
      );
    });

    test('boolean value encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelPrimitiveBoolean(value: true);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/primitive/boolean/.true',
      );
    });

    test('enum value encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelPrimitiveEnum(
        value: StatusEnum.active,
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/primitive/enum/.active',
      );
    });
  });

  group('Label style - Arrays', () {
    test('string array (explode=false) encodes as .val1,val2,val3', () async {
      final api = buildLabelApi();
      final response = await api.testLabelArrayString(
        values: ['blue', 'black', 'brown'],
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/array/string/.blue,black,brown',
      );
    });

    test('string array (explode=true) encodes as .val1.val2.val3', () async {
      final api = buildLabelApi();
      final response = await api.testLabelArrayStringExplode(
        values: ['blue', 'black', 'brown'],
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/array/string/explode/.blue.black.brown',
      );
    });

    test('integer array (explode=false) encodes as .val1,val2,val3', () async {
      final api = buildLabelApi();
      final response = await api.testLabelArrayInteger(values: [1, 2, 3]);

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/array/integer/.1,2,3',
      );
    });
  });

  group('Label style - Objects', () {
    test('object (explode=false) encodes as .k1,v1,k2,v2', () async {
      final api = buildLabelApi();
      final response = await api.testLabelObject(
        value: const SimpleObject(name: 'test', count: 5),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/object/.name,test,count,5',
      );
    });

    test('object (explode=true) encodes as .k1=v1.k2=v2', () async {
      final api = buildLabelApi();
      final response = await api.testLabelObjectExplode(
        value: const SimpleObject(name: 'test', count: 5),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/object/explode/.name=test.count=5',
      );
    });
  });

  group('Label style - Combined', () {
    test('multiple label params encode correctly', () async {
      final api = buildLabelApi();
      final response = await api.testLabelCombined(
        stringValue: 'hello',
        intValue: 42,
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/combined/.hello/.42',
      );
    });
  });
}
