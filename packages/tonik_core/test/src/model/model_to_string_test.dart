import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('toString cycle safety', () {
    test('ClassModel with direct circular reference does not overflow', () {
      final modelA = ClassModel(
        name: 'A',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final modelB = ClassModel(
        name: 'B',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      modelA.properties = [
        Property(
          name: 'b',
          model: modelB,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];
      modelB.properties = [
        Property(
          name: 'a',
          model: modelA,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(modelA.toString, returnsNormally);
      expect(modelA.toString(), contains('ClassModel{name: A'));
    });

    test('self-referential ClassModel does not overflow', () {
      final model = ClassModel(
        name: 'Node',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      model.properties = [
        Property(
          name: 'parent',
          model: model,
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
        ),
      ];

      expect(model.toString, returnsNormally);
      expect(model.toString(), contains('ClassModel{name: Node'));
    });

    test('transitive cycle A -> B -> C -> A does not overflow', () {
      final modelA = ClassModel(
        name: 'A',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final modelB = ClassModel(
        name: 'B',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final modelC = ClassModel(
        name: 'C',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      modelA.properties = [
        Property(
          name: 'b',
          model: modelB,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];
      modelB.properties = [
        Property(
          name: 'c',
          model: modelC,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];
      modelC.properties = [
        Property(
          name: 'a',
          model: modelA,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(modelA.toString, returnsNormally);
      expect(modelB.toString, returnsNormally);
      expect(modelC.toString, returnsNormally);
    });

    test('AnyOfModel with circular reference does not overflow', () {
      final classModel = ClassModel(
        name: 'Inner',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final anyOf = AnyOfModel(
        name: 'Outer',
        models: {(discriminatorValue: null, model: classModel)},
        context: context,
        isDeprecated: false,
      );
      classModel.properties = [
        Property(
          name: 'ref',
          model: anyOf,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(anyOf.toString, returnsNormally);
      expect(anyOf.toString(), contains('AnyOfModel{name: Outer'));
    });

    test('OneOfModel with circular reference does not overflow', () {
      final classModel = ClassModel(
        name: 'Inner',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final oneOf = OneOfModel(
        name: 'Outer',
        models: {(discriminatorValue: null, model: classModel)},
        context: context,
        isDeprecated: false,
      );
      classModel.properties = [
        Property(
          name: 'ref',
          model: oneOf,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(oneOf.toString, returnsNormally);
    });

    test('AllOfModel with circular reference does not overflow', () {
      final classModel = ClassModel(
        name: 'Inner',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final allOf = AllOfModel(
        name: 'Outer',
        models: {classModel},
        context: context,
        isDeprecated: false,
      );
      classModel.properties = [
        Property(
          name: 'ref',
          model: allOf,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(allOf.toString, returnsNormally);
    });

    test('AliasModel with circular reference does not overflow', () {
      final classModel = ClassModel(
        name: 'Inner',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final alias = AliasModel(
        name: 'Wrapper',
        model: classModel,
        context: context,
      );
      classModel.properties = [
        Property(
          name: 'ref',
          model: alias,
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(alias.toString, returnsNormally);
      expect(alias.toString(), contains('AliasModel{name: Wrapper'));
    });

    test('ListModel with circular reference does not overflow', () {
      final classModel = ClassModel(
        name: 'Inner',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      final listModel = ListModel(
        name: 'Items',
        content: classModel,
        context: context,
      );
      classModel.properties = [
        Property(
          name: 'children',
          model: listModel,
          isRequired: false,
          isNullable: false,
          isDeprecated: false,
        ),
      ];

      expect(listModel.toString, returnsNormally);
      expect(listModel.toString(), contains('ListModel{name: Items'));
    });
  });

  group('toString output format', () {
    test('ClassModel lists property names', () {
      final model = ClassModel(
        name: 'User',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'email',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
        isDeprecated: false,
      );

      final result = model.toString();
      expect(result, contains('properties: [id, email]'));
    });

    test('Property shows model ref without recursing', () {
      final prop = Property(
        name: 'value',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      final result = prop.toString();
      expect(result, contains('model: StringModel'));
    });

    test('AliasModel shows model ref without recursing', () {
      final alias = AliasModel(
        name: 'MyAlias',
        model: StringModel(context: context),
        context: context,
      );

      final result = alias.toString();
      expect(result, contains('model: StringModel'));
    });

    test('ListModel shows content ref without recursing', () {
      final list = ListModel(
        name: 'Items',
        content: ClassModel(
          name: 'Item',
          properties: [],
          context: context,
          isDeprecated: false,
        ),
        context: context,
      );

      final result = list.toString();
      expect(result, contains('content: ClassModel(Item)'));
    });

    test('AllOfModel shows model refs without recursing', () {
      final allOf = AllOfModel(
        name: 'Combined',
        models: {
          ClassModel(
            name: 'Base',
            properties: [],
            context: context,
            isDeprecated: false,
          ),
        },
        context: context,
        isDeprecated: false,
      );

      final result = allOf.toString();
      expect(result, contains('models: {ClassModel(Base)}'));
    });
  });
}
