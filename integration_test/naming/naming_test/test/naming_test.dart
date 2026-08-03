import 'dart:typed_data';

import 'package:naming_api/src/api_client/default_api2.dart';
import 'package:naming_api/src/model/camel_case_collider.dart';
import 'package:naming_api/src/model/dollar_holder.dart';
import 'package:naming_api/src/model/duration.dart' as naming;
import 'package:naming_api/src/model/enum.dart' as naming;
import 'package:naming_api/src/model/enum_reserved_names.dart';
import 'package:naming_api/src/model/error.dart' as naming;
import 'package:naming_api/src/model/function.dart';
import 'package:naming_api/src/model/generated_method_collider.dart';
import 'package:naming_api/src/model/keyword_enum.dart';
import 'package:naming_api/src/model/keyword_property_names.dart';
import 'package:naming_api/src/model/multipart_name_collision_form.dart';
import 'package:naming_api/src/model/object_method_collider.dart';
import 'package:naming_api/src/model/self_referencer.dart';
import 'package:naming_api/src/model/simple_result.dart';
import 'package:naming_api/src/model/user.dart';
import 'package:naming_api/src/model/user_model.dart';
import 'package:naming_api/src/model/weird_property_names.dart';
import 'package:naming_api/src/server/server.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('keyword operationId method names', () {
    test('API client has escaped keyword method names', () {
      // The fact that DefaultApi2 compiles proves operationIds like
      // 'switch', 'class', 'return' are sanitized to '$switch', etc.
      expect(DefaultApi2, isNotNull);
    });
  });

  group('Object method property collisions', () {
    test('ObjectMethodCollider has escaped property names', () {
      const model = ObjectMethodCollider(
        $runtimeType: 'container',
        $hashCode: 42,
      );

      expect(model.$runtimeType, 'container');
      expect(model.$hashCode, 42);
    });

    test('ObjectMethodCollider preserves JSON keys', () {
      final model = ObjectMethodCollider.fromJson(const {
        'runtimeType': 'vm',
        'hashCode': 99,
        'noSuchMethod': 'fallback',
        'toString': 'debug',
      });

      expect(model.$runtimeType, 'vm');
      expect(model.$hashCode, 99);
      expect(model.$noSuchMethod, 'fallback');
      expect(model.$toString, 'debug');
    });

    test('ObjectMethodCollider toJson uses original keys', () {
      const model = ObjectMethodCollider(
        $runtimeType: 'vm',
        $hashCode: 99,
        $noSuchMethod: 'fallback',
        $toString: 'debug',
      );

      final json = model.toJson()! as Map<String, dynamic>;

      expect(json['runtimeType'], 'vm');
      expect(json['hashCode'], 99);
      expect(json['noSuchMethod'], 'fallback');
      expect(json['toString'], 'debug');
    });
  });

  group('Function schema name (built-in identifier)', () {
    test(r'Function schema generates as $Function', () {
      const fn = $Function(name: 'handler', arn: 'arn:aws:lambda:us-east-1');

      expect(fn.name, 'handler');
      expect(fn.arn, 'arn:aws:lambda:us-east-1');
    });

    test(r'$Function roundtrips through JSON', () {
      const fn = $Function(name: 'handler', arn: 'arn:aws:lambda:us-east-1');
      final json = fn.toJson();
      final restored = $Function.fromJson(json);

      expect(restored.name, fn.name);
      expect(restored.arn, fn.arn);
    });
  });

  group('schemas differing only in dollar signs', () {
    test('DollarHolder toJson emits both dollar-named classes', () {
      const holder = DollarHolder(
        first: $UserModel(a: 'alpha'),
        second: $$User(b: 'beta'),
      );

      expect(holder.toJson(), {
        'first': {'a': 'alpha'},
        'second': {'b': 'beta'},
      });
    });

    test('DollarHolder fromJson decodes both dollar-named classes', () {
      final holder = DollarHolder.fromJson(const {
        'first': {'a': 'alpha'},
        'second': {'b': 'beta'},
      });

      expect(holder.first, const $UserModel(a: 'alpha'));
      expect(holder.second, const $$User(b: 'beta'));
    });
  });

  group('dart:core type names as schemas', () {
    test('Enum schema is valid (not prefixed)', () {
      const model = naming.Enum(index: 0, name: 'active');
      expect(model.name, 'active');
    });

    test('Error schema is valid (not prefixed)', () {
      const model = naming.Error(code: 500, message: 'Internal');
      expect(model.code, 500);
    });

    test('Duration schema is valid (not prefixed)', () {
      const model = naming.Duration(milliseconds: 5000);
      expect(model.milliseconds, 5000);
    });
  });

  group('OpenAPI cancelToken parameters', () {
    test(
      'API method accepts cancelToken and portable cancellation',
      () async {
        final dio = _successfulDio();
        final api = _apiForDio(dio, 'http://localhost');
        final response = await api.getWithCancelTokenQuery(
          cancelToken: 'myToken',
          cancellation: TonikCancellation(),
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.requestOptions.cancelToken, isNotNull);
        expect(
          success.response.requestOptions.uri.queryParameters['cancelToken'],
          'myToken',
        );
      },
    );

    test(
      'API method sends cancelToken path and threads portable cancellation',
      () async {
        final dio = _successfulDio();
        final api = _apiForDio(dio, 'http://localhost');
        final response = await api.getWithCancelTokenPath(
          cancelToken: 'myToken',
          cancellation: TonikCancellation(),
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.requestOptions.cancelToken, isNotNull);
        expect(
          success.response.requestOptions.path,
          contains('myToken'),
        );
      },
    );

    test(
      'API method sends cancelToken header and threads portable cancellation',
      () async {
        final dio = _successfulDio();
        final api = _apiForDio(dio, 'http://localhost');
        final response = await api.getWithCancelTokenHeader(
          cancelToken: 'myToken',
          cancellation: TonikCancellation(),
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.requestOptions.cancelToken, isNotNull);
        expect(
          success.response.requestOptions.headers['cancelToken'],
          'myToken',
        );
      },
    );

    test(
      'API method sends cancelToken cookie and threads portable cancellation',
      () async {
        final dio = _successfulDio();
        final api = _apiForDio(dio, 'http://localhost');
        final response = await api.getWithCancelTokenCookie(
          cancelToken: 'myToken',
          cancellation: TonikCancellation(),
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.requestOptions.cancelToken, isNotNull);
        expect(
          success.response.requestOptions.headers['Cookie'],
          'cancelToken=myToken',
        );
      },
    );

    test(
      'API method preserves sanitized cancel token wire names',
      () async {
        final dio = _successfulDio();
        final api = _apiForDio(dio, 'http://localhost');
        final response = await api.getWithCancelTokenSanitized(
          cancelToken: 'myToken',
          cancellation: TonikCancellation(),
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.requestOptions.cancelToken, isNotNull);
        expect(
          success.response.requestOptions.uri.queryParameters['Cancel-Token'],
          'myToken',
        );
      },
    );

    test(
      'API method sends colliding query and body with portable cancellation',
      () async {
        final dio = _successfulDio();
        final api = _apiForDio(dio, 'http://localhost');
        final response = await api.postWithCancelTokenAndBody(
          body: const SimpleResult(id: 'test'),
          cancelToken: 'myToken',
          cancellation: TonikCancellation(),
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.requestOptions.cancelToken, isNotNull);
        expect(
          success.response.requestOptions.uri.queryParameters['cancelToken'],
          'myToken',
        );
      },
    );
  });

  group('keyword property names', () {
    test('KeywordPropertyNames has escaped field names', () {
      const model = KeywordPropertyNames(
        $class: 'MyClass',
        $return: 'value',
        $switch: 'on',
        $void: 'nothing',
        $is: true,
        $if: 'condition',
        $for: 'loop',
      );

      expect(model.$class, 'MyClass');
      expect(model.$return, 'value');
      expect(model.$is, isTrue);
    });

    test('KeywordPropertyNames preserves JSON keys', () {
      final model = KeywordPropertyNames.fromJson(const {
        'class': 'MyClass',
        'switch': 'on',
        'is': true,
      });

      expect(model.$class, 'MyClass');
      expect(model.$switch, 'on');
      expect(model.$is, isTrue);
    });

    test('KeywordPropertyNames toJson uses original keys', () {
      const model = KeywordPropertyNames($class: 'X', $is: false);
      final json = model.toJson()! as Map<String, dynamic>;

      expect(json['class'], 'X');
      expect(json['is'], isFalse);
    });
  });

  group('generated method name collisions', () {
    test('GeneratedMethodCollider has escaped field names', () {
      const model = GeneratedMethodCollider(
        $call: 'invoke',
        $fromJson: 'factory',
        $toJson: 'serializer',
        $copyWith: 'cloner',
      );

      expect(model.$call, 'invoke');
      expect(model.$fromJson, 'factory');
      expect(model.$toJson, 'serializer');
      expect(model.$copyWith, 'cloner');
    });

    test('GeneratedMethodCollider copyWith supports the call property', () {
      const model = GeneratedMethodCollider($call: 'before');

      final updated = model.copyWith($call: 'after');

      expect(updated.$call, 'after');
      expect(updated.toJson(), containsPair('call', 'after'));
    });
  });

  group('call parameter collision', () {
    test(r'uses $call in Dart and call on the wire', () async {
      final recorder = TestRequestRecorder();

      await _apiForDio(recorder, 'http://localhost').getWithCallQuery(
        $call: 'invoke',
      );

      expect(recorder.request!.uri.queryParameters, {'call': 'invoke'});
    });
  });

  group('camelCase normalization collisions', () {
    test('CamelCaseCollider deduplicates same-cased properties', () {
      const model = CamelCaseCollider(
        myField: 'first',
        myField2: 'second',
        myField3: 'third',
        myField4: 'fourth',
        myField5: 'fifth',
        myField6: 'sixth',
      );

      expect(model.myField, 'first');
      expect(model.myField2, 'second');
    });
  });

  group('keyword enum values', () {
    test('KeywordEnum has escaped values', () {
      expect(KeywordEnum.$switch.toJson(), 'switch');
      expect(KeywordEnum.$class.toJson(), 'class');
      expect(KeywordEnum.$return.toJson(), 'return');
      expect(KeywordEnum.$void.toJson(), 'void');
      expect(KeywordEnum.$null.toJson(), 'null');
      expect(KeywordEnum.$true.toJson(), 'true');
      expect(KeywordEnum.$false.toJson(), 'false');
    });
  });

  group('generated enum storage names', () {
    test('keeps rawValue as the enum case name', () {
      expect(EnumReservedNames.rawValue.toJson(), 'rawValue');
      expect(
        EnumReservedNames.fromJson('rawValue'),
        EnumReservedNames.rawValue,
      );
    });
  });

  group('self-referencing schema', () {
    test('SelfReferencer can nest', () {
      const child = SelfReferencer(name: 'child');
      const parent = SelfReferencer(
        name: 'parent',
        children: [child],
      );

      expect(parent.name, 'parent');
      expect(parent.children?.first.name, 'child');
    });
  });

  group('weird property names', () {
    test('WeirdPropertyNames handles special characters', () {
      const model = WeirdPropertyNames(
        screamingCase: 'LOUD',
        a: 'single',
        kebabCaseName: 'hyphenated',
      );

      expect(model.screamingCase, 'LOUD');
      expect(model.a, 'single');
      expect(model.kebabCaseName, 'hyphenated');
    });
  });

  group('parameter counter-suffix collision (GetParamCounterCollision)', () {
    test(
      'exposes four distinct Dart parameter names — tokenPath, tokenQuery, '
      'tokenQuery2, tokenQuery3 — and tokenQuery3 still serialises under the '
      'wire key "token"',
      () async {
        final recorder = TestRequestRecorder();

        final api = _apiForDio(recorder, 'http://localhost');

        // The named-arg call site IS the compile-time check on Dart names:
        // if any of the four were renamed, this wouldn't compile.
        await api.getParamCounterCollision(
          tokenPath: 'P',
          tokenQuery: 'A',
          tokenQuery2: 'B',
          tokenQuery3: 'C',
        );

        final uri = recorder.request!.uri;

        expect(
          uri.path,
          contains('/param-counter-collision/P'),
        );

        final params = uri.queryParametersAll;

        expect(
          params['token'],
          ['C'],
          reason:
              'tokenQuery3 must serialise under wire key "token" — the '
              'Dart-side counter rename must not change the on-the-wire name.',
        );
        expect(
          params['token_query'],
          ['A'],
          reason: 'tokenQuery must keep its raw wire name "token_query".',
        );
        expect(
          params['token_query2'],
          ['B'],
          reason: 'tokenQuery2 must keep its raw wire name "token_query2".',
        );
        expect(
          params.containsKey('token_query3'),
          isFalse,
          reason:
              'No query key should adopt the renamed Dart identifier — that '
              'would corrupt the outgoing request.',
        );
      },
    );
  });

  group(
    'location-suffix collision with declared name (GetParamSuffixCollision)',
    () {
      test(
        'exposes three distinct Dart parameter names — idPath2, idQuery, '
        'idPath — and each serialises under its declared wire key',
        () async {
          final recorder = TestRequestRecorder();

          final api = _apiForDio(recorder, 'http://localhost');

          await api.getParamSuffixCollision(
            idPath2: 'P',
            idQuery: 42,
            idPath: true,
          );

          final uri = recorder.request!.uri;

          expect(uri.path, contains('/param-suffix-collision/P'));

          final params = uri.queryParametersAll;

          expect(
            params['id'],
            ['42'],
            reason: 'idQuery must serialise under wire key "id".',
          );
          expect(
            params['idPath'],
            ['true'],
            reason:
                'The declared idPath parameter keeps both its Dart name and '
                'its wire key "idPath".',
          );
          expect(
            params.containsKey('idPath2'),
            isFalse,
            reason:
                'No query key should adopt the renamed Dart identifier — that '
                'would corrupt the outgoing request.',
          );
        },
      );
    },
  );

  group('hostile but valid query parameter names', () {
    test('uses valid Dart names while preserving the wire names', () async {
      final recorder = TestRequestRecorder();

      await _apiForDio(recorder, 'http://localhost').getHostileQueryNames(
        parameter: 'love',
        parameter2: 'cache-buster',
        expand: 'customer',
        metaLessThanFieldGreaterThanLessThanOperatorGreaterThan: 'value',
      );

      expect(recorder.request!.uri.queryParameters, {
        '❤️': 'love',
        '_': 'cache-buster',
        'expand[]': 'customer',
        'meta.<field>[<operator>]': 'value',
      });
    });
  });

  group('hostile server variable names', () {
    test('keeps every variable independently configurable', () {
      final server = BdBe29Da4Efb88F7DServer(
        field: 'one-value',
        field2: 'two-value',
        apiVersion: 'first-version',
        apiVersion2: 'second-version',
        $baseUrl: 'base-value',
        $serverConfig: 'config-value',
        $dio: 'dio-value',
      );

      expect(
        server.baseUrl,
        'https://one-value.two-value.example.com/'
        'first-version/second-version/base-value/config-value/dio-value',
      );
    });
  });

  group('multipart header name collisions', () {
    test('uses every distinct argument for its original wire header', () async {
      final recorder = TestRequestRecorder();

      await _apiForDio(
        recorder,
        'http://localhost',
      ).postMultipartNameCollisions(
        body: MultipartNameCollisionForm(
          file: TonikFileBytes(Uint8List.fromList([1, 2, 3])),
        ),
        fileCustom: 'query-value',
        fileTraceId: 'first-header',
        fileTraceIdPartHeader: 'second-header',
        fileTraceIdPartHeader2: 'third-header',
      );

      final request = recorder.request!;
      expect(request.uri.queryParameters, {
        'file_custom': 'query-value',
      });
      final formData = request.data as TestFormData;
      final headers = formData.files.single.value.headers;
      expect(headers.map, hasLength(3));
      expect(headers['X-Trace-Id'], ['first-header']);
      expect(headers['Trace-Id'], ['second-header']);
      expect(headers['Trace_Id'], ['third-header']);
    });
  });
}

DefaultApi2 _apiForDio(TestRequestRecorder recorder, String baseUrl) {
  return DefaultApi2(
    CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        recorder: recorder,
        response: const TestResponseStub(statusCode: 200),
      ),
    ),
  );
}

TestRequestRecorder _successfulDio() => TestRequestRecorder();
