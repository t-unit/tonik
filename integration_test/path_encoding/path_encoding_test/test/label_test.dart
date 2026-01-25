import 'package:dio/dio.dart';
import 'package:path_encoding_api/path_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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

  group('Label style - Composite Types', () {
    test('oneOfPrimitive (string) encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelOneOfPrimitive(
        value: const OneOfPrimitiveString('test'),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/composite/oneOfPrimitive/.test',
      );
    });

    test('oneOfPrimitive (integer) encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelOneOfPrimitive(
        value: const OneOfPrimitiveInt(42),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/composite/oneOfPrimitive/.42',
      );
    });

    test('anyOfPrimitive (string) encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelAnyOfPrimitive(
        value: const AnyOfPrimitive(string: 'test'),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/composite/anyOfPrimitive/.test',
      );
    });

    test('anyOfPrimitive (integer) encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelAnyOfPrimitive(
        value: const AnyOfPrimitive(int: 123),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/composite/anyOfPrimitive/.123',
      );
    });

    test('oneOfComplex encodes object members', () async {
      final api = buildLabelApi();
      final response = await api.testLabelOneOfComplex(
        value: const OneOfComplexSimpleObject(
          SimpleObject(name: 'foo', count: 10),
        ),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/composite/oneOfComplex/.name,foo,count,10',
      );
    });

    test('allOfSimple encodes merged object', () async {
      final api = buildLabelApi();
      final response = await api.testLabelAllOfSimple(
        value: const AllOfSimple(
          simpleObject: SimpleObject(name: 'bar', count: 20),
          allOfSimpleModel: AllOfSimpleModel(extra: 'bonus'),
        ),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/composite/allOfSimple/.name,bar,count,20,extra,bonus',
      );
    });

    test('integerEnum encodes as .value', () async {
      final api = buildLabelApi();
      final response = await api.testLabelIntegerEnum(
        value: PriorityEnum.two,
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/label/primitive/integerEnum/.2',
      );
    });
  });

  group('Label style - Deeply Nested', () {
    test('deeply nested object fails with encoding error', () async {
      final api = buildLabelApi();
      final response = await api.testLabelDeeplyNested(
        value: const DeeplyNestedObject(
          name: 'outer',
          child: DeeplyNestedObjectChildModel(
            value: 1,
            nested: SimpleObject(name: 'inner', count: 5),
          ),
        ),
      );

      expect(
        response,
        isA<TonikError<EchoResponse>>(),
        reason: 'deeply nested objects cannot be encoded in label style',
      );
      final error = response as TonikError<EchoResponse>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
