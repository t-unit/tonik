import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late Context context;
  late NameManager manager;
  late StableModelSorter sorter;

  setUp(() {
    context = Context.initial();
    sorter = StableModelSorter();
    manager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: sorter,
    );
  });

  test('reserves colliding variants in model order before reverse lookup', () {
    final barBaz = ClassModel(
      name: 'BarBaz',
      isDeprecated: false,
      properties: const [],
      context: context,
      examples: const [],
    );
    final baz = ClassModel(
      name: 'Baz',
      isDeprecated: false,
      properties: const [],
      context: context,
      examples: const [],
    );
    final foo = OneOfModel(
      name: 'Foo',
      models: [(model: barBaz, discriminatorValue: null)],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final fooBar = OneOfModel(
      name: 'FooBar',
      models: [(model: baz, discriminatorValue: null)],
      context: context,
      isDeprecated: false,
      examples: const [],
    );

    manager.prime(
      models: [fooBar, foo, barBaz, baz],
      requestBodies: const [],
      responses: const [],
      operations: const [],
      tags: const [],
      servers: const [],
    );

    expect(
      manager.generateVariantName(
        parentClassName: 'Foo',
        model: barBaz,
        discriminatorValue: null,
      ),
      'FooBarBazModel',
    );
    expect(
      manager.generateVariantName(
        parentClassName: 'FooBar',
        model: baz,
        discriminatorValue: null,
      ),
      'FooBarBaz',
    );
  });

  test(
    'reserves nullable implementations alongside variants in model order',
    () {
      final member = ClassModel(
        name: 'Bar',
        isDeprecated: false,
        properties: const [],
        context: context,
        examples: const [],
      );
      final choice = OneOfModel(
        name: 'Foo',
        isNullable: true,
        models: [(model: member, discriminatorValue: null)],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final nullableObject = ClassModel(
        name: 'FooBar',
        isNullable: true,
        isDeprecated: false,
        properties: const [],
        context: context,
        examples: const [],
      );
      final generator = OneOfGenerator(
        nameManager: manager,
        package: 'test_api',
        stableModelSorter: sorter,
      );

      manager.prime(
        models: [choice, nullableObject, member],
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      expect(manager.rawObjectName('FooBar'), r'$RawFooBarModel');
      expect(manager.rawModelName(choice), r'$RawFoo');
      expect(
        manager.generateVariantName(
          parentClassName: r'$RawFoo',
          model: member,
          discriminatorValue: null,
        ),
        r'$RawFooBar',
      );
      final classes = generator.generateClasses(
        choice,
        manager.rawModelName(choice),
      );
      expect(classes.map((c) => c.name), [r'$RawFoo', r'$RawFooBar']);
      final first = generator.generate(choice);
      expect(generator.generate(choice), first);
      expect(manager.rawModelName(choice), r'$RawFoo');
    },
  );

  test('reserves nullable anyOf and allOf names before later variants', () {
    final member = ClassModel(
      name: 'Bar',
      isDeprecated: false,
      properties: const [],
      context: context,
      examples: const [],
    );
    final anyOf = AnyOfModel(
      name: 'FooBar',
      isNullable: true,
      models: [(model: member, discriminatorValue: null)],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final allOf = AllOfModel(
      name: 'FooBarModel',
      isNullable: true,
      models: [member],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final choice = OneOfModel(
      name: 'Foo',
      isNullable: true,
      models: [(model: member, discriminatorValue: null)],
      context: context,
      isDeprecated: false,
      examples: const [],
    );

    manager.prime(
      models: [anyOf, allOf, choice, member],
      requestBodies: const [],
      responses: const [],
      operations: const [],
      tags: const [],
      servers: const [],
    );

    expect(
      manager.generateVariantName(
        parentClassName: r'$RawFoo',
        model: member,
        discriminatorValue: null,
      ),
      r'$RawFooBarModel2',
    );
    expect(manager.rawModelName(allOf), r'$RawFooBarModel');
    expect(manager.rawModelName(anyOf), r'$RawFooBar');
    expect(
      AnyOfGenerator(
        nameManager: manager,
        package: 'test_api',
        stableModelSorter: sorter,
      ).generateClass(anyOf).name,
      r'$RawFooBar',
    );
    expect(
      AllOfGenerator(
        nameManager: manager,
        package: 'test_api',
        stableModelSorter: sorter,
      ).generateClass(allOf).name,
      r'$RawFooBarModel',
    );
  });

  test('nullable enum implementations reserve names before oneOf variants', () {
    final member = ClassModel(
      name: 'Bar',
      isDeprecated: false,
      properties: const [],
      context: context,
      examples: const [],
    );
    final enumeration = EnumModel<String>(
      name: 'FooBar',
      values: {const EnumEntry(value: 'active')},
      isNullable: true,
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final choice = OneOfModel(
      name: 'Foo',
      isNullable: true,
      models: [(model: member, discriminatorValue: null)],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final generator = EnumGenerator(nameManager: manager);

    manager.prime(
      models: [enumeration, choice, member],
      requestBodies: const [],
      responses: const [],
      operations: const [],
      tags: const [],
      servers: const [],
    );

    expect(
      manager.generateVariantName(
        parentClassName: r'$RawFoo',
        model: member,
        discriminatorValue: null,
      ),
      r'$RawFooBarModel',
    );
    expect(
      generator.generateEnum(enumeration, 'FooBar').enumValue.name,
      r'$RawFooBar',
    );
    final first = generator.generate(enumeration);
    expect(generator.generate(enumeration), first);
  });

  test('response wrappers avoid names reserved for model variants', () {
    final member = ClassModel(
      name: 'ResultResponse',
      isDeprecated: false,
      properties: const [],
      context: context,
      examples: const [],
    );
    final choice = OneOfModel(
      name: 'Get',
      models: [(model: member, discriminatorValue: null)],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final operation = Operation(
      operationId: 'getResult',
      context: context,
      tags: const {},
      isDeprecated: false,
      path: '/result',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      responses: const {},
      securitySchemes: const {},
    );

    manager.prime(
      models: [choice, member],
      requestBodies: const [],
      responses: const [],
      operations: [operation],
      tags: const [],
      servers: const [],
    );

    expect(manager.operationName(operation), 'GetResult');
    expect(
      manager.responseWrapperNames(operation).$1,
      'GetResultResponseWrapper',
    );
    expect(
      manager.generateVariantName(
        parentClassName: 'Get',
        model: member,
        discriminatorValue: null,
      ),
      'GetResultResponse',
    );
  });
}
