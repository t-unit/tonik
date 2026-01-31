import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;


  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  BooleanSchemasApi buildApi({String responseStatus = '200'}) {
    return BooleanSchemasApi(
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

  group('JSON body with AnyModel', () {
    test('echoJsonAny roundtrip with string anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'test-name',
        anyData: 'string value',
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'test-name', 'anyData': 'string value'},
      );

      final body = success.value;
      expect(body.name, 'test-name');
      expect(body.anyData, 'string value');
    });

    test('echoJsonAny roundtrip with number anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(name: 'number-test', anyData: 123.45);

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'number-test', 'anyData': 123.45},
      );

      final body = success.value;
      expect(body.name, 'number-test');
      expect(body.anyData, 123.45);
    });

    test('echoJsonAny roundtrip with nested object anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'nested-test',
        anyData: {'nested': 'value', 'count': 42},
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {
          'name': 'nested-test',
          'anyData': {'nested': 'value', 'count': 42},
        },
      );

      final body = success.value;
      expect(body.name, 'nested-test');
      expect(body.anyData, {'nested': 'value', 'count': 42});
    });

    test('echoJsonAny roundtrip with array anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'array-test',
        anyData: [1, 'two', true, null],
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {
          'name': 'array-test',
          'anyData': [1, 'two', true, null],
        },
      );

      final body = success.value;
      expect(body.name, 'array-test');
      expect(body.anyData, [1, 'two', true, null]);
    });

    test('echoJsonAny roundtrip with boolean anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'bool-test',
        anyData: true,
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'bool-test', 'anyData': true},
      );

      final body = success.value;
      expect(body.name, 'bool-test');
      expect(body.anyData, true);
    });

    test('echoJsonAny roundtrip with null anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(name: 'null-test', anyData: null);

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'null-test', 'anyData': null},
      );

      final body = success.value;
      expect(body.name, 'null-test');
      expect(body.anyData, isNull);
    });

    test('echoJsonAny with optionalAny field', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'optional-test',
        anyData: 'required',
        optionalAny: 'optional value',
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'optional-test');
      expect(body.anyData, 'required');
      expect(body.optionalAny, 'optional value');
    });

    test('echoJsonAny with metadata field', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'metadata-test',
        anyData: 'data',
        metadata: ObjectWithAnyMetadataModel(version: 42),
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'metadata-test');
      expect(body.metadata?.version, 42);
    });
  });

  group('JSON array with AnyModel', () {
    test('postJsonAnyArray with mixed types', () async {
      final api = buildApi();
      const original = [
        'string',
        123,
        true,
        null,
        {'key': 'value'},
      ];

      final result = await api.postJsonAnyArray(body: original);
      final success = result as TonikSuccess<List<Object?>>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body, hasLength(5));
      expect(body[0], 'string');
      expect(body[1], 123);
      expect(body[2], true);
      expect(body[3], isNull);
      expect(body[4], {'key': 'value'});
    });

    test('postJsonAnyArray with nested arrays', () async {
      final api = buildApi();
      const original = [
        [1, 2, 3],
        ['a', 'b'],
        [true, false],
      ];

      final result = await api.postJsonAnyArray(body: original);
      final success = result as TonikSuccess<List<Object?>>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body, hasLength(3));
      expect(body[0], [1, 2, 3]);
    });

    test('postJsonAnyArray with empty array', () async {
      final api = buildApi();
      const original = <Object?>[];

      final result = await api.postJsonAnyArray(body: original);
      final success = result as TonikSuccess<List<Object?>>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body, isEmpty);
    });
  });

  group('Pure any/never JSON body', () {
    test('postPureAny with object', () async {
      final api = buildApi();
      final result = await api.postPureAny(body: {'key': 'value', 'num': 42});
      expect(result, isA<TonikSuccess<Object?>>());
      final success = result as TonikSuccess<Object?>;
      expect(success.response.statusCode, 200);
      expect(success.value, {'key': 'value', 'num': 42});
    });

    test('postPureAny with array', () async {
      final api = buildApi();
      final result = await api.postPureAny(body: [1, 2, 3]);
      expect(result, isA<TonikSuccess<Object?>>());
      final success = result as TonikSuccess<Object?>;
      expect(success.response.statusCode, 200);
      expect(success.value, [1, 2, 3]);
    });

    test('postPureAny with nested structures', () async {
      final api = buildApi();
      final result = await api.postPureAny(
        body: {
          'nested': [1, 'two', true],
          'flag': false,
        },
      );
      expect(result, isA<TonikSuccess<Object?>>());
      final success = result as TonikSuccess<Object?>;
      expect(success.response.statusCode, 200);
      expect(success.value, {
        'nested': [1, 'two', true],
        'flag': false,
      });
    });
  });

  group('Response with AnyModel', () {
    test('getResponseAny returns ObjectWithAny', () async {
      final api = buildApi();
      final result = await api.getResponseAny();
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, isNotEmpty);
      expect(body.anyData, isNotNull);
    });

    test('getResponseAnyArray returns List<Object?>', () async {
      final api = buildApi();
      final result = await api.getResponseAnyArray();
      final success = result as TonikSuccess<List<Object?>>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body, isNotEmpty);
    });
  });
}
