import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

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

    test('Shape decode factories accept empty List<Never> properties', () {
      expect(
        Shape.fromJson(
          const <String, Object?>{'corner': <Object?>[]},
        ).corner,
        isEmpty,
      );
      expect(Shape.fromSimple('corner=', explode: true).corner, isEmpty);
      expect(Shape.fromForm('corner=', explode: true).corner, isEmpty);
    });

    test('Shape decode factories reject non-empty List<Never> properties', () {
      expect(
        () => Shape.fromJson(
          const <String, Object?>{
            'corner': <Object?>['forbidden'],
          },
        ),
        throwsA(isA<JsonDecodingException>()),
      );
      expect(
        () => Shape.fromSimple('corner=forbidden', explode: true),
        throwsA(isA<SimpleDecodingException>()),
      );
      expect(
        () => Shape.fromForm('corner=forbidden', explode: true),
        throwsA(isA<FormDecodingException>()),
      );
    });
  });
}
