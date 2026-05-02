import 'package:naming_api/src/api_client/default_api2.dart';
import 'package:naming_api/src/model/_function.dart';
import 'package:naming_api/src/model/camel_case_collider.dart';
import 'package:naming_api/src/model/duration.dart' as naming;
import 'package:naming_api/src/model/enum.dart' as naming;
import 'package:naming_api/src/model/error.dart' as naming;
import 'package:naming_api/src/model/generated_method_collider.dart';
import 'package:naming_api/src/model/keyword_enum.dart';
import 'package:naming_api/src/model/keyword_property_names.dart';
import 'package:naming_api/src/model/object_method_collider.dart';
import 'package:naming_api/src/model/self_referencer.dart';
import 'package:naming_api/src/model/weird_property_names.dart';
import 'package:naming_api/src/operation/create_with_body_cookie.dart';
import 'package:naming_api/src/operation/create_with_body_header.dart';
import 'package:naming_api/src/operation/create_with_body_query.dart';
import 'package:naming_api/src/operation/get_with_cancel_token_cookie.dart';
import 'package:naming_api/src/operation/get_with_cancel_token_header.dart';
import 'package:naming_api/src/operation/get_with_cancel_token_path.dart';
import 'package:naming_api/src/operation/get_with_cancel_token_query.dart';
import 'package:naming_api/src/operation/get_with_cancel_token_sanitized.dart';
import 'package:test/test.dart';

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

  group('body parameter collision', () {
    test('CreateWithBodyQuery compiles with suffixed param', () {
      expect(CreateWithBodyQuery, isNotNull);
    });

    test('CreateWithBodyHeader compiles with suffixed param', () {
      expect(CreateWithBodyHeader, isNotNull);
    });

    test('CreateWithBodyCookie compiles with suffixed param', () {
      expect(CreateWithBodyCookie, isNotNull);
    });
  });

  group('cancelToken parameter collision', () {
    test('GetWithCancelTokenQuery compiles with renamed user parameter', () {
      expect(GetWithCancelTokenQuery, isNotNull);
    });

    test('GetWithCancelTokenPath compiles with renamed user parameter', () {
      expect(GetWithCancelTokenPath, isNotNull);
    });

    test('GetWithCancelTokenHeader compiles with renamed user parameter', () {
      expect(GetWithCancelTokenHeader, isNotNull);
    });

    test('GetWithCancelTokenCookie compiles with renamed user parameter', () {
      expect(GetWithCancelTokenCookie, isNotNull);
    });

    test(
      'GetWithCancelTokenSanitized compiles when raw name sanitizes to '
      'cancelToken',
      () {
        expect(GetWithCancelTokenSanitized, isNotNull);
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
        $fromJson: 'factory',
        $toJson: 'serializer',
        $copyWith: 'cloner',
      );

      expect(model.$fromJson, 'factory');
      expect(model.$toJson, 'serializer');
      expect(model.$copyWith, 'cloner');
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
      expect(KeywordEnum.$switch.rawValue, 'switch');
      expect(KeywordEnum.$class.rawValue, 'class');
      expect(KeywordEnum.$return.rawValue, 'return');
      expect(KeywordEnum.$void.rawValue, 'void');
      expect(KeywordEnum.$null.rawValue, 'null');
      expect(KeywordEnum.$true.rawValue, 'true');
      expect(KeywordEnum.$false.rawValue, 'false');
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
}
