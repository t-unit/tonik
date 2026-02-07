import 'package:dio/dio.dart';
import 'package:path_encoding_api/path_encoding_api.dart';
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

  group('Matrix style - Composite Types', () {
    test('oneOfPrimitive (string) encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixOneOfPrimitive(
        value: const OneOfPrimitiveString('test'),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/composite/oneOfPrimitive/;value=test',
      );
    });

    test('oneOfPrimitive (integer) encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixOneOfPrimitive(
        value: const OneOfPrimitiveInt(42),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/composite/oneOfPrimitive/;value=42',
      );
    });

    test('anyOfPrimitive (string) encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixAnyOfPrimitive(
        value: const AnyOfPrimitive(string: 'test'),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/composite/anyOfPrimitive/;value=test',
      );
    });

    test('anyOfPrimitive (integer) encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixAnyOfPrimitive(
        value: const AnyOfPrimitive(int: 123),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/composite/anyOfPrimitive/;value=123',
      );
    });

    test('oneOfComplex encodes object members', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixOneOfComplex(
        value: const OneOfComplexSimpleObject(
          SimpleObject(name: 'foo', count: 10),
        ),
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/composite/oneOfComplex/;value=name,foo,count,10',
      );
    });

    test('allOfSimple encodes merged object', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixAllOfSimple(
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
        '/v1/matrix/composite/allOfSimple/;value=name,bar,count,20,extra,bonus',
      );
    });

    test('integerEnum encodes as ;param=value', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixIntegerEnum(
        value: PriorityEnum.two,
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/v1/matrix/primitive/integerEnum/;value=2',
      );
    });
  });

  group('Matrix style - Deeply Nested', () {
    test('deeply nested object fails with encoding error', () async {
      final api = buildMatrixApi();
      final response = await api.testMatrixDeeplyNested(
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
        reason: 'deeply nested objects cannot be encoded in matrix style',
      );
      final error = response as TonikError<EchoResponse>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
