import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';

void main() {
  group('generateCopyWithMethod', () {
    test('generates method with no properties', () {
      final method = generateCopyWithMethod(
        className: 'TestClass',
        properties: const [],
      );

      expect(method.name, 'copyWith');
      expect(method.returns?.symbol, 'TestClass');
      expect(method.optionalParameters, isEmpty);
      expect(method.body.toString(), 'return TestClass(\n  \n);');
    });

    test('generates method with single property', () {
      final method = generateCopyWithMethod(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'name',
            typeRef: TypeReference((b) => b..symbol = 'String'),
          ),
        ],
      );

      expect(method.name, 'copyWith');
      expect(method.returns?.symbol, 'TestClass');
      expect(method.optionalParameters, hasLength(1));
      expect(method.optionalParameters.first.name, 'name');
      expect(method.optionalParameters.first.type?.symbol, 'String');
      expect(
        method.body.toString(),
        'return TestClass(\n  name: name ?? this.name,\n);',
      );
    });

    test('generates method with multiple properties', () {
      final method = generateCopyWithMethod(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'name',
            typeRef: TypeReference((b) => b..symbol = 'String'),
          ),
          (
            normalizedName: 'age',
            typeRef: TypeReference((b) => b..symbol = 'int'),
          ),
        ],
      );

      expect(method.name, 'copyWith');
      expect(method.returns!.symbol, 'TestClass');
      expect(method.optionalParameters, hasLength(2));
      expect(method.optionalParameters.map((p) => p.name).toList(), [
        'name',
        'age',
      ]);
      expect(
        method.body.toString(),
        'return TestClass(\n  name: name ?? this.name,\n  '
        'age: age ?? this.age,\n);',
      );
    });

    test('generates method with complex type references', () {
      final method = generateCopyWithMethod(
        className: 'TestClass',
        properties: [
          (
            normalizedName: 'items',
            typeRef: TypeReference(
              (b) =>
                  b
                    ..symbol = 'List'
                    ..url = 'dart:core'
                    ..types.add(refer('String')),
            ),
          ),
        ],
      );

      expect(method.optionalParameters.first.type!.symbol, 'List');
      expect(method.optionalParameters.first.type?.url, 'dart:core');
    });
  });
}
