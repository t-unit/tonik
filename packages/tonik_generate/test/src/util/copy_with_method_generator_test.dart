import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';

void main() {
  final emitter = DartEmitter(useNullSafetySyntax: true);

  group('generateCopyWith', () {
    test('returns null when properties are empty', () {
      final result = generateCopyWith(
        className: 'TestClass',
        properties: const [],
      );

      expect(result, isNull);
    });

    group('getter', () {
      test('has correct name and type', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.getter.name, 'copyWith');
        expect(result.getter.type, MethodType.getter);
      });

      test('returns interface type with class as type parameter', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final returnType = result!.getter.returns;
        expect(returnType, isA<TypeReference>());
        final typeRef = returnType! as TypeReference;
        expect(typeRef.symbol, r'$$TestClassCopyWith');
        expect(typeRef.types.first.symbol, 'TestClass');
      });

      test('returns implementation instance', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.getter.lambda, isTrue);
        expect(result.getter.body.toString(), '_TestClassCopyWith(this)');
      });
    });

    group('interface class', () {
      test(r'has correct name with $$ prefix', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.interfaceClass.name, r'$$TestClassCopyWith');
      });

      test('is abstract', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.interfaceClass.abstract, isTrue);
      });

      test(r'has generic type parameter $Res', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.interfaceClass.types.length, 1);
        expect(result.interfaceClass.types.first.symbol, r'$Res');
      });

      test('has factory constructor redirecting to implementation', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final factory = result!.interfaceClass.constructors.first;
        expect(factory.factory, isTrue);
        expect(factory.requiredParameters.length, 1);
        expect(factory.requiredParameters.first.name, 'value');
        expect(factory.requiredParameters.first.type?.symbol, 'TestClass');
        expect(factory.redirect?.symbol, '_TestClassCopyWith');
      });

      test(r'has call method returning $Res', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final callMethod = result!.interfaceClass.methods.firstWhere(
          (m) => m.name == 'call',
        );
        expect(callMethod.returns?.symbol, r'$Res');
      });

      test('call method has nullable parameters for each property', () {
        final result = generateCopyWith(
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

        final callMethod = result!.interfaceClass.methods.firstWhere(
          (m) => m.name == 'call',
        );
        expect(callMethod.optionalParameters.length, 2);
        expect(callMethod.optionalParameters[0].name, 'name');
        expect(callMethod.optionalParameters[0].named, isTrue);
        expect(
          (callMethod.optionalParameters[0].type as TypeReference?)?.isNullable,
          isTrue,
        );
        expect(callMethod.optionalParameters[1].name, 'age');
      });

      test('has getter for each property', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final getters = result!.interfaceClass.methods
            .where((m) => m.type == MethodType.getter)
            .toList();
        expect(getters.length, 1);
        expect(getters.first.name, 'name');
        // Getter preserves original nullability
        // (String is non-nullable)
        // When isNullable is not set, it defaults to null
        // (which means non-nullable)
        expect(
          (getters.first.returns as TypeReference?)?.isNullable,
          isNot(isTrue),
        );
      });
    });

    group('implementation class', () {
      test('has correct name with _ prefix', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.implClass.name, '_TestClassCopyWith');
      });

      test('implements interface class', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        expect(result!.implClass.implements.length, 1);
        final impl = result.implClass.implements.first;
        expect(impl.symbol, r'$$TestClassCopyWith');
      });

      test('has static const _sentinel field', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final sentinel = result!.implClass.fields.firstWhere(
          (f) => f.name == '_sentinel',
        );
        expect(sentinel.static, isTrue);
        expect(sentinel.modifier, FieldModifier.constant);
      });

      test('has _value field of class type', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final valueField = result!.implClass.fields.firstWhere(
          (f) => f.name == '_value',
        );
        expect(valueField.modifier, FieldModifier.final$);
        expect(valueField.type?.symbol, 'TestClass');
      });

      test('has constructor that takes _value', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final ctor = result!.implClass.constructors.first;
        expect(ctor.requiredParameters.length, 1);
        expect(ctor.requiredParameters.first.toThis, isTrue);
      });

      test('getters delegate to _value', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final getter = result!.implClass.methods.firstWhere(
          (m) => m.name == 'name' && m.type == MethodType.getter,
        );
        expect(getter.lambda, isTrue);
        expect(getter.body.toString(), '_value.name');
      });

      test('call method uses Object? parameters with sentinel default', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final callMethod = result!.implClass.methods.firstWhere(
          (m) => m.name == 'call',
        );
        expect(callMethod.optionalParameters.length, 1);
        final param = callMethod.optionalParameters.first;
        expect(param.type, isA<Reference>());
        expect(param.type?.accept(emitter).toString(), 'Object?');
        expect(param.defaultTo.toString(), '_sentinel');
      });

      test('call method body uses identical check with sentinel', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'name',
              typeRef: TypeReference((b) => b..symbol = 'String'),
            ),
          ],
        );

        final callMethod = result!.implClass.methods.firstWhere(
          (m) => m.name == 'call',
        );
        const expectedCallMethod = r'''
          @override
          $Res call({Object? name = _sentinel}) {
            return (TestClass(name: identical(name, _sentinel, ) ? this.name : (name as String)) as $Res);
          }
        ''';
        expect(
          collapseWhitespace(callMethod.accept(emitter).toString()),
          collapseWhitespace(expectedCallMethod),
        );
      });
    });

    group('complex types', () {
      test('handles generic types correctly', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'items',
              typeRef: TypeReference(
                (b) => b
                  ..symbol = 'List'
                  ..types.add(refer('String')),
              ),
            ),
          ],
        );

        // Verify getter type via introspection
        final getter = result!.implClass.methods.firstWhere(
          (m) => m.name == 'items' && m.type == MethodType.getter,
        );
        expect(getter.returns?.accept(emitter).toString(), 'List<String>');

        // Verify call method has correct type cast
        final callMethod = result.implClass.methods.firstWhere(
          (m) => m.name == 'call',
        );
        const expectedCallMethod = r'''
          @override
          $Res call({Object? items = _sentinel}) {
            return (TestClass(items: identical(items, _sentinel, ) ? this.items : (items as List<String>)) as $Res);
          }
        ''';
        expect(
          collapseWhitespace(callMethod.accept(emitter).toString()),
          collapseWhitespace(expectedCallMethod),
        );
      });

      test('handles already nullable types correctly', () {
        final result = generateCopyWith(
          className: 'TestClass',
          properties: [
            (
              normalizedName: 'value',
              typeRef: TypeReference(
                (b) => b
                  ..symbol = 'int'
                  ..isNullable = true,
              ),
            ),
          ],
        );

        // Verify getter type via introspection
        final getter = result!.implClass.methods.firstWhere(
          (m) => m.name == 'value' && m.type == MethodType.getter,
        );
        final returnType = getter.returns as TypeReference?;
        expect(returnType?.symbol, 'int');
        expect(returnType?.isNullable, isTrue);
      });
    });
  });
}
