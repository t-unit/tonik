import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:test/test.dart';

void main() {
  group('AnyModel type verification', () {
    test('AnyValue alias resolves to Object?', () {
      const value = 'any string' as AnyValue;
      expect(value, isA<Object?>());

      const numberValue = 42 as AnyValue;
      expect(numberValue, isA<Object?>());

      const nullValue = null as AnyValue;
      expect(nullValue, isNull);
    });

    test('ObjectWithAny has Object? property for anyData', () {
      const obj = ObjectWithAny(name: 'test', anyData: 'string value');
      expect(obj.anyData, isA<Object?>());
      expect(obj.anyData, 'string value');
    });
  });

  group('NeverModel type verification', () {
    test('ObjectWithNever can be instantiated with null neverField', () {
      const obj = ObjectWithNever(name: 'test');
      expect(obj.name, 'test');
      expect(obj.neverField, isNull);
    });

    test('ObjectWithNever.neverField has type NeverValid?', () {
      const obj = ObjectWithNever(name: 'test');
      expect(obj.neverField, isNull);
    });

    test('ObjectWithNever.fromJson parses when neverField is absent', () {
      // Per JSON Schema: schema: false means no value is valid for that field.
      // But if the field is optional/nullable and absent, parsing should succeed.
      final json = <String, Object?>{'name': 'parsed'};
      final obj = ObjectWithNever.fromJson(json);
      expect(obj.name, 'parsed');
      expect(obj.neverField, isNull);
    });

    test('ObjectWithNever.toJson serializes correctly', () {
      const obj = ObjectWithNever(name: 'serialize-test');
      final json = obj.toJson();
      expect(json, isA<Map<String, Object?>>());
      expect((json as Map<String, Object?>?)?['name'], 'serialize-test');
      expect(json?.containsKey('neverField'), isFalse);
    });

    test('ObjectWithNever.copyWith works with null neverField', () {
      const obj = ObjectWithNever(name: 'original');
      final copied = obj.copyWith(name: 'copied');
      expect(copied.name, 'copied');
      expect(copied.neverField, isNull);
    });
  });
}
