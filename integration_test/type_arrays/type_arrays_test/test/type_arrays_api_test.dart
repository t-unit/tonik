import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';
import 'package:type_arrays_api/type_arrays_api.dart';

void main() {
  const port = 8290;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  TypeArraysApi buildApi({String responseStatus = '200'}) {
    return TypeArraysApi(
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

  group('health endpoint', () {
    test('returns 200 with status', () async {
      final api = buildApi();
      final result = await api.health();

      if (result is TonikError) {
        final error = result as TonikError<HealthGet200BodyModel>;
        print('Error type: ${error.type}');
        print('Error: ${error.error}');
      }

      expect(result, isA<TonikSuccess<HealthGet200BodyModel>>());
      final success = result as TonikSuccess<HealthGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(success.value.status, 'ok');
    });
  });

  group('testSimpleTypes - JSON roundtrip', () {
    test('requiredStringOrNumber: string variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('hello'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(42),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;
      expect(success.response.statusCode, 200);

      // Verify request body encoding
      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['requiredStringOrNumber'], 'hello');
      expect(requestData['requiredIntOrBool'], 42);

      // Verify response decoding
      final output = success.value;
      expect(
        output.requiredStringOrNumber,
        isA<SimpleTypeArraysRequiredStringOrNumberOneOfModelString>(),
      );
      expect(
        (output.requiredStringOrNumber
                as SimpleTypeArraysRequiredStringOrNumberOneOfModelString)
            .value,
        'hello',
      );
    });

    test('requiredStringOrNumber: number variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelNumber(99.5),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['requiredStringOrNumber'], 99.5);

      final output = success.value;
      expect(
        output.requiredStringOrNumber,
        isA<SimpleTypeArraysRequiredStringOrNumberOneOfModelNumber>(),
      );
      expect(
        (output.requiredStringOrNumber
                as SimpleTypeArraysRequiredStringOrNumberOneOfModelNumber)
            .value,
        99.5,
      );
    });

    test('requiredIntOrBool: integer variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(42),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['requiredIntOrBool'], 42);

      final output = success.value;
      expect(
        output.requiredIntOrBool,
        isA<SimpleTypeArraysRequiredIntOrBoolOneOfModelInt>(),
      );
      expect(
        (output.requiredIntOrBool
                as SimpleTypeArraysRequiredIntOrBoolOneOfModelInt)
            .value,
        42,
      );
    });

    test('requiredIntOrBool: boolean variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool:
            SimpleTypeArraysRequiredIntOrBoolOneOfModelBool(false),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['requiredIntOrBool'], false);

      final output = success.value;
      expect(
        output.requiredIntOrBool,
        isA<SimpleTypeArraysRequiredIntOrBoolOneOfModelBool>(),
      );
      expect(
        (output.requiredIntOrBool
                as SimpleTypeArraysRequiredIntOrBoolOneOfModelBool)
            .value,
        false,
      );
    });

    test('optionalStringOrInt: string variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
        optionalStringOrInt:
            SimpleTypeArraysOptionalStringOrIntOneOfModelString('optional'),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['optionalStringOrInt'], 'optional');

      final output = success.value;
      expect(
        output.optionalStringOrInt,
        isA<SimpleTypeArraysOptionalStringOrIntOneOfModelString>(),
      );
      expect(
        (output.optionalStringOrInt!
                as SimpleTypeArraysOptionalStringOrIntOneOfModelString)
            .value,
        'optional',
      );
    });

    test('optionalStringOrInt: integer variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
        optionalStringOrInt:
            SimpleTypeArraysOptionalStringOrIntOneOfModelInt(123),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['optionalStringOrInt'], 123);

      final output = success.value;
      expect(
        output.optionalStringOrInt,
        isA<SimpleTypeArraysOptionalStringOrIntOneOfModelInt>(),
      );
      expect(
        (output.optionalStringOrInt!
                as SimpleTypeArraysOptionalStringOrIntOneOfModelInt)
            .value,
        123,
      );
    });

    test('threeTypes: string variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
        threeTypes: SimpleTypeArraysThreeTypesOneOfModelString('three'),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['threeTypes'], 'three');

      final output = success.value;
      expect(
        output.threeTypes,
        isA<SimpleTypeArraysThreeTypesOneOfModelString>(),
      );
      expect(
        (output.threeTypes! as SimpleTypeArraysThreeTypesOneOfModelString)
            .value,
        'three',
      );
    });

    test('threeTypes: number variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
        threeTypes: SimpleTypeArraysThreeTypesOneOfModelNumber(456.789),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['threeTypes'], 456.789);

      final output = success.value;
      expect(
        output.threeTypes,
        isA<SimpleTypeArraysThreeTypesOneOfModelNumber>(),
      );
      expect(
        (output.threeTypes! as SimpleTypeArraysThreeTypesOneOfModelNumber)
            .value,
        456.789,
      );
    });

    test('threeTypes: boolean variant', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
        threeTypes: SimpleTypeArraysThreeTypesOneOfModelBool(true),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['threeTypes'], true);

      final output = success.value;
      expect(
        output.threeTypes,
        isA<SimpleTypeArraysThreeTypesOneOfModelBool>(),
      );
      expect(
        (output.threeTypes! as SimpleTypeArraysThreeTypesOneOfModelBool).value,
        true,
      );
    });

    test('all optional fields omitted', () async {
      final api = buildApi();

      const input = SimpleTypeArrays(
        requiredStringOrNumber:
            SimpleTypeArraysRequiredStringOrNumberOneOfModelString('test'),
        requiredIntOrBool: SimpleTypeArraysRequiredIntOrBoolOneOfModelInt(1),
      );

      final result = await api.testSimpleTypes(body: input);

      expect(result, isA<TonikSuccess<SimpleTypeArrays>>());
      final success = result as TonikSuccess<SimpleTypeArrays>;
      expect(success.response.statusCode, 200);

      final output = success.value;
      expect(output.optionalStringOrInt, isNull);
      expect(output.threeTypes, isNull);
    });
  });

  group('testNullableTypes - JSON roundtrip', () {
    test('all fields populated with non-null values', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: 'required-value',
        nullableString: 'string-value',
        nullableNumber: 3.14,
        nullableBoolean: true,
        nullableStringOrNumber:
            NullableTypeArraysNullableStringOrNumberOneOfModelString(
          'mixed-string',
        ),
        nullableMultiType:
            NullableTypeArraysNullableMultiTypeOneOfModelInt(777),
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      // Verify request encoding
      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['requiredNullable'], 'required-value');
      expect(requestData['nullableString'], 'string-value');
      expect(requestData['nullableNumber'], 3.14);
      expect(requestData['nullableBoolean'], true);
      expect(requestData['nullableStringOrNumber'], 'mixed-string');
      expect(requestData['nullableMultiType'], 777);

      // Verify response decoding
      final output = success.value;
      expect(output.requiredNullable, 'required-value');
      expect(output.nullableString, 'string-value');
      expect(output.nullableNumber, 3.14);
      expect(output.nullableBoolean, true);
      expect(
        output.nullableStringOrNumber,
        isA<NullableTypeArraysNullableStringOrNumberOneOfModelString>(),
      );
      expect(
        (output.nullableStringOrNumber!
                as NullableTypeArraysNullableStringOrNumberOneOfModelString)
            .value,
        'mixed-string',
      );
      expect(
        output.nullableMultiType,
        isA<NullableTypeArraysNullableMultiTypeOneOfModelInt>(),
      );
      expect(
        (output.nullableMultiType!
                as NullableTypeArraysNullableMultiTypeOneOfModelInt)
            .value,
        777,
      );
    });

    test('all fields null', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: null,
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      // Verify request encoding includes null values
      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['requiredNullable'], isNull);
      expect(requestData['nullableString'], isNull);
      expect(requestData['nullableNumber'], isNull);
      expect(requestData['nullableBoolean'], isNull);
      expect(requestData['nullableStringOrNumber'], isNull);
      expect(requestData['nullableMultiType'], isNull);

      // Verify response decoding
      final output = success.value;
      expect(output.requiredNullable, isNull);
      expect(output.nullableString, isNull);
      expect(output.nullableNumber, isNull);
      expect(output.nullableBoolean, isNull);
      expect(output.nullableStringOrNumber, isNull);
      expect(output.nullableMultiType, isNull);
    });

    test('nullableStringOrNumber: string variant', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: null,
        nullableStringOrNumber:
            NullableTypeArraysNullableStringOrNumberOneOfModelString(
          'test-string',
        ),
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['nullableStringOrNumber'], 'test-string');

      final output = success.value;
      expect(
        output.nullableStringOrNumber,
        isA<NullableTypeArraysNullableStringOrNumberOneOfModelString>(),
      );
      expect(
        (output.nullableStringOrNumber!
                as NullableTypeArraysNullableStringOrNumberOneOfModelString)
            .value,
        'test-string',
      );
    });

    test('nullableStringOrNumber: number variant', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: null,
        nullableStringOrNumber:
            NullableTypeArraysNullableStringOrNumberOneOfModelNumber(42.5),
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['nullableStringOrNumber'], 42.5);

      final output = success.value;
      expect(
        output.nullableStringOrNumber,
        isA<NullableTypeArraysNullableStringOrNumberOneOfModelNumber>(),
      );
      expect(
        (output.nullableStringOrNumber!
                as NullableTypeArraysNullableStringOrNumberOneOfModelNumber)
            .value,
        42.5,
      );
    });

    test('nullableMultiType: string variant', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: null,
        nullableMultiType:
            NullableTypeArraysNullableMultiTypeOneOfModelString('multi-string'),
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['nullableMultiType'], 'multi-string');

      final output = success.value;
      expect(
        output.nullableMultiType,
        isA<NullableTypeArraysNullableMultiTypeOneOfModelString>(),
      );
      expect(
        (output.nullableMultiType!
                as NullableTypeArraysNullableMultiTypeOneOfModelString)
            .value,
        'multi-string',
      );
    });

    test('nullableMultiType: integer variant', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: null,
        nullableMultiType:
            NullableTypeArraysNullableMultiTypeOneOfModelInt(999),
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['nullableMultiType'], 999);

      final output = success.value;
      expect(
        output.nullableMultiType,
        isA<NullableTypeArraysNullableMultiTypeOneOfModelInt>(),
      );
      expect(
        (output.nullableMultiType!
                as NullableTypeArraysNullableMultiTypeOneOfModelInt)
            .value,
        999,
      );
    });

    test('nullableMultiType: boolean variant', () async {
      final api = buildApi();

      const input = NullableTypeArrays(
        requiredNullable: null,
        nullableMultiType:
            NullableTypeArraysNullableMultiTypeOneOfModelBool(false),
      );

      final result = await api.testNullableTypes(body: input);

      expect(result, isA<TonikSuccess<NullableTypeArrays>>());
      final success = result as TonikSuccess<NullableTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['nullableMultiType'], false);

      final output = success.value;
      expect(
        output.nullableMultiType,
        isA<NullableTypeArraysNullableMultiTypeOneOfModelBool>(),
      );
      expect(
        (output.nullableMultiType!
                as NullableTypeArraysNullableMultiTypeOneOfModelBool)
            .value,
        false,
      );
    });
  });

  group('testTopLevelTypeArray', () {
    test('returns string variant', () async {
      final api = buildApi();

      final result = await api.testTopLevelTypeArray(param: 'test-param');

      expect(result, isA<TonikSuccess<StringOrNumber>>());
      final success = result as TonikSuccess<StringOrNumber>;
      expect(success.response.statusCode, 200);

      // Verify path parameter encoding
      expect(success.response.requestOptions.uri.path, '/top-level/test-param');

      // Verify response is string variant
      expect(success.value, isA<StringOrNumberString>());
      expect((success.value as StringOrNumberString).value, 'test-value');
    });
  });

  group('testComposition - JSON roundtrip', () {
    test('with simple type array variants', () async {
      final api = buildApi();

      const input = CompositionWithTypeArrays(
        simpleTypeArray:
            CompositionWithTypeArraysSimpleTypeArrayOneOfModelString(
          'simple-string',
        ),
        nullableTypeArray:
            CompositionWithTypeArraysNullableTypeArrayOneOfModelInt(123),
      );

      final result = await api.testComposition(body: input);

      expect(result, isA<TonikSuccess<CompositionWithTypeArrays>>());
      final success = result as TonikSuccess<CompositionWithTypeArrays>;
      expect(success.response.statusCode, 200);

      // Verify request encoding
      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['simpleTypeArray'], 'simple-string');
      expect(requestData['nullableTypeArray'], 123);

      // Verify response decoding
      final output = success.value;
      expect(
        output.simpleTypeArray,
        isA<CompositionWithTypeArraysSimpleTypeArrayOneOfModelString>(),
      );
      expect(
        (output.simpleTypeArray!
                as CompositionWithTypeArraysSimpleTypeArrayOneOfModelString)
            .value,
        'simple-string',
      );
      expect(
        output.nullableTypeArray,
        isA<CompositionWithTypeArraysNullableTypeArrayOneOfModelInt>(),
      );
      expect(
        (output.nullableTypeArray!
                as CompositionWithTypeArraysNullableTypeArrayOneOfModelInt)
            .value,
        123,
      );
    });

    test('with number variants', () async {
      final api = buildApi();

      const input = CompositionWithTypeArrays(
        simpleTypeArray:
            CompositionWithTypeArraysSimpleTypeArrayOneOfModelNumber(99.99),
        nullableTypeArray:
            CompositionWithTypeArraysNullableTypeArrayOneOfModelBool(true),
      );

      final result = await api.testComposition(body: input);

      expect(result, isA<TonikSuccess<CompositionWithTypeArrays>>());
      final success = result as TonikSuccess<CompositionWithTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['simpleTypeArray'], 99.99);
      expect(requestData['nullableTypeArray'], true);

      final output = success.value;
      expect(
        output.simpleTypeArray,
        isA<CompositionWithTypeArraysSimpleTypeArrayOneOfModelNumber>(),
      );
      expect(
        (output.simpleTypeArray!
                as CompositionWithTypeArraysSimpleTypeArrayOneOfModelNumber)
            .value,
        99.99,
      );
      expect(
        output.nullableTypeArray,
        isA<CompositionWithTypeArraysNullableTypeArrayOneOfModelBool>(),
      );
      expect(
        (output.nullableTypeArray!
                as CompositionWithTypeArraysNullableTypeArrayOneOfModelBool)
            .value,
        true,
      );
    });

    test('with null nullable type array', () async {
      final api = buildApi();

      const input = CompositionWithTypeArrays(
        simpleTypeArray:
            CompositionWithTypeArraysSimpleTypeArrayOneOfModelString('test'),
      );

      final result = await api.testComposition(body: input);

      expect(result, isA<TonikSuccess<CompositionWithTypeArrays>>());
      final success = result as TonikSuccess<CompositionWithTypeArrays>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['simpleTypeArray'], 'test');
      expect(requestData['nullableTypeArray'], isNull);

      final output = success.value;
      expect(output.nullableTypeArray, isNull);
    });
  });

  group('testEdgeCases - JSON roundtrip', () {
    test('allPrimitives: string variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('all-string'),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      // Verify request encoding
      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitives'], 'all-string');

      // Verify response decoding
      final output = success.value;
      expect(
        output.allPrimitives,
        isA<EdgeCasesAllPrimitivesOneOfModelString>(),
      );
      expect(
        (output.allPrimitives! as EdgeCasesAllPrimitivesOneOfModelString).value,
        'all-string',
      );
    });

    test('allPrimitives: integer variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelInt(42),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitives'], 42);

      final output = success.value;
      expect(output.allPrimitives, isA<EdgeCasesAllPrimitivesOneOfModelInt>());
      expect(
        (output.allPrimitives! as EdgeCasesAllPrimitivesOneOfModelInt).value,
        42,
      );
    });

    test('allPrimitives: number variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelNumber(3.14),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitives'], 3.14);

      final output = success.value;
      expect(
        output.allPrimitives,
        isA<EdgeCasesAllPrimitivesOneOfModelNumber>(),
      );
      expect(
        (output.allPrimitives! as EdgeCasesAllPrimitivesOneOfModelNumber).value,
        3.14,
      );
    });

    test('allPrimitives: boolean variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelBool(true),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitives'], true);

      final output = success.value;
      expect(output.allPrimitives, isA<EdgeCasesAllPrimitivesOneOfModelBool>());
      expect(
        (output.allPrimitives! as EdgeCasesAllPrimitivesOneOfModelBool).value,
        true,
      );
    });

    test('allPrimitivesNullable: string variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        allPrimitivesNullable:
            EdgeCasesAllPrimitivesNullableOneOfModelString('nullable-string'),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitivesNullable'], 'nullable-string');

      final output = success.value;
      expect(
        output.allPrimitivesNullable,
        isA<EdgeCasesAllPrimitivesNullableOneOfModelString>(),
      );
      expect(
        (output.allPrimitivesNullable!
                as EdgeCasesAllPrimitivesNullableOneOfModelString)
            .value,
        'nullable-string',
      );
    });

    test('allPrimitivesNullable: integer variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        allPrimitivesNullable: EdgeCasesAllPrimitivesNullableOneOfModelInt(123),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitivesNullable'], 123);

      final output = success.value;
      expect(
        output.allPrimitivesNullable,
        isA<EdgeCasesAllPrimitivesNullableOneOfModelInt>(),
      );
      expect(
        (output.allPrimitivesNullable!
                as EdgeCasesAllPrimitivesNullableOneOfModelInt)
            .value,
        123,
      );
    });

    test('allPrimitivesNullable: number variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        allPrimitivesNullable:
            EdgeCasesAllPrimitivesNullableOneOfModelNumber(99.99),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitivesNullable'], 99.99);

      final output = success.value;
      expect(
        output.allPrimitivesNullable,
        isA<EdgeCasesAllPrimitivesNullableOneOfModelNumber>(),
      );
      expect(
        (output.allPrimitivesNullable!
                as EdgeCasesAllPrimitivesNullableOneOfModelNumber)
            .value,
        99.99,
      );
    });

    test('allPrimitivesNullable: boolean variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        allPrimitivesNullable:
            EdgeCasesAllPrimitivesNullableOneOfModelBool(false),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitivesNullable'], false);

      final output = success.value;
      expect(
        output.allPrimitivesNullable,
        isA<EdgeCasesAllPrimitivesNullableOneOfModelBool>(),
      );
      expect(
        (output.allPrimitivesNullable!
                as EdgeCasesAllPrimitivesNullableOneOfModelBool)
            .value,
        false,
      );
    });

    test('allPrimitivesNullable: null variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['allPrimitivesNullable'], isNull);

      final output = success.value;
      expect(output.allPrimitivesNullable, isNull);
    });

    test('integerAndNumber: integer variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(456),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['integerAndNumber'], 456);

      final output = success.value;
      expect(
        output.integerAndNumber,
        isA<EdgeCasesIntegerAndNumberOneOfModelInt>(),
      );
      expect(
        (output.integerAndNumber! as EdgeCasesIntegerAndNumberOneOfModelInt)
            .value,
        456,
      );
    });

    test('integerAndNumber: number variant', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelNumber(3.14159),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;

      final requestData =
          success.response.requestOptions.data as Map<String, dynamic>;
      expect(requestData['integerAndNumber'], 3.14159);

      final output = success.value;
      expect(
        output.integerAndNumber,
        isA<EdgeCasesIntegerAndNumberOneOfModelNumber>(),
      );
      expect(
        (output.integerAndNumber! as EdgeCasesIntegerAndNumberOneOfModelNumber)
            .value,
        3.14159,
      );
    });

    test('all optional fields omitted', () async {
      final api = buildApi();

      const input = EdgeCases(
        allPrimitives: EdgeCasesAllPrimitivesOneOfModelString('test'),
        integerAndNumber: EdgeCasesIntegerAndNumberOneOfModelInt(1),
      );

      final result = await api.testEdgeCases(body: input);

      expect(result, isA<TonikSuccess<EdgeCases>>());
      final success = result as TonikSuccess<EdgeCases>;
      expect(success.response.statusCode, 200);

      final output = success.value;
      expect(output.allPrimitivesNullable, isNull);
      expect(output.stringOrDateTime, isNull);
      expect(output.nullableArrayOfStrings, isNull);
      expect(output.arrayOfNullableStrings, isNull);
      expect(output.mergedTypeArrays, isNull);
      expect(output.deepNesting, isNull);
    });
  });
}
