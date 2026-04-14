import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';

void main() {
  late Context context;
  late NameManager nameManager;
  late DartEmitter emitter;
  late CorePrefixedAllocator scopedAllocator;
  late DartEmitter scopedEmitter;

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    emitter = DartEmitter(useNullSafetySyntax: true);
    scopedAllocator = CorePrefixedAllocator();
    scopedEmitter = DartEmitter(
      useNullSafetySyntax: true,
      allocator: scopedAllocator,
    );
  });

  group('buildSimpleValueExpression', () {
    test('generates for primitive types', () {
      final value = refer('value');
      expect(
        buildSimpleValueExpression(
          value,
          model: StringModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleString()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: StringModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableString()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: IntegerModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleInt()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: IntegerModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableInt()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: BooleanModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleBool()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: BooleanModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableBool()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: DateTimeModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleDateTime()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: DateTimeModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableDateTime()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: DecimalModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleBigDecimal()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: DecimalModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableBigDecimal()',
      );
    });

    test('generates for enum types with explode false', () {
      final value = refer('value');
      final enumModel = EnumModel(
        isDeprecated: false,
        context: context,
        name: 'UserRole',
        values: {
          const EnumEntry(value: 'admin'),
          const EnumEntry(
            value: 'user',
          ),
        },
        isNullable: false,
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: enumModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'UserRole.fromSimple(value, explode: false, )',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: enumModel,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value == null ? null : UserRole.fromSimple(value, explode: false, )',
      );
    });

    test('generates for enum types with explode true', () {
      final value = refer('value');
      final enumModel = EnumModel(
        isDeprecated: false,
        context: context,
        name: 'UserRole',
        values: {
          const EnumEntry(value: 'admin'),
          const EnumEntry(value: 'user'),
        },
        isNullable: false,
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: enumModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(true),
        ).accept(emitter).toString(),
        'UserRole.fromSimple(value, explode: true, )',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: enumModel,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(true),
        ).accept(emitter).toString(),
        'value == null ? null : UserRole.fromSimple(value, explode: true, )',
      );
    });

    test('generates for class types with explode false', () {
      final value = refer('value');
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        name: 'User',
        properties: const [],
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: classModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'User.fromSimple(value, explode: false, )',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: classModel,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value == null ? null : User.fromSimple(value, explode: false, )',
      );
    });

    test('generates for class types with explode true', () {
      final value = refer('value');
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        name: 'User',
        properties: const [],
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: classModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(true),
        ).accept(emitter).toString(),
        'User.fromSimple(value, explode: true, )',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: classModel,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(true),
        ).accept(emitter).toString(),
        'value == null ? null : User.fromSimple(value, explode: true, )',
      );
    });

    test('generates for list types', () {
      final value = refer('value');
      final stringListModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: stringListModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleStringList()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: stringListModel,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableStringList()',
      );

      final intListModel = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: intListModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleStringList()'
        '.map((e) => e.decodeSimpleInt()).toList()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: intListModel,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableStringList()'
        '?.map((e) => e.decodeSimpleInt()).toList()',
      );
    });

    test('generates for alias types', () {
      final value = refer('value');
      final stringAlias = AliasModel(
        context: context,
        name: 'UserId',
        model: StringModel(context: context),
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: stringAlias,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleString()',
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: stringAlias,
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableString()',
      );
    });

    test('passes context parameter to decode methods when provided', () {
      final value = refer('value');

      expect(
        buildSimpleValueExpression(
          value,
          model: StringModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          contextProperty: 'name',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        "value.decodeSimpleString(context: r'name')",
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: IntegerModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'tonik_core',
          contextClass: 'Product',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        "value.decodeSimpleNullableInt(context: r'Product')",
      );

      // List type with context
      final intListModel = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: intListModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
          contextClass: 'Order',
          contextProperty: 'quantities',
          explode: literalBool(false),
        ).accept(emitter).toString(),
        '''value.decodeSimpleStringList(context: r'Order.quantities').map((e) => e.decodeSimpleInt(context: r'Order.quantities')).toList()''',
      );
    });

    group('with scoped emitter', () {
      test('generates for scoped enum types with explode false', () {
        final value = refer('value');
        final enumModel = EnumModel(
          isDeprecated: false,
          context: context,
          name: 'UserRole',
          values: {
            const EnumEntry(value: 'admin'),
            const EnumEntry(value: 'user'),
          },
          isNullable: false,
        );

        expect(
          buildSimpleValueExpression(
            value,
            model: enumModel,
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          '_i1.UserRole.fromSimple(value, explode: false, )',
        );
      });

      test('generates for scoped class types with explode false', () {
        final value = refer('value');
        final classModel = ClassModel(
          isDeprecated: false,
          context: context,
          name: 'User',
          properties: const [],
        );

        expect(
          buildSimpleValueExpression(
            value,
            model: classModel,
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          '_i1.User.fromSimple(value, explode: false, )',
        );
      });

      test('generates for scoped list of enums with explode false', () {
        final value = refer('value');
        final enumModel = EnumModel(
          isDeprecated: false,
          context: context,
          name: 'UserRole',
          values: {
            const EnumEntry(value: 'admin'),
            const EnumEntry(value: 'user'),
          },
          isNullable: false,
        );
        final listModel = ListModel(content: enumModel, context: context);

        expect(
          buildSimpleValueExpression(
            value,
            model: listModel,
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          equals(
            'value.decodeSimpleStringList()'
            '.map((e) => _i1.UserRole.fromSimple(e, explode: false, '
            ')).toList()',
          ),
        );
      });

      test('generates for scoped list of enums with explode true', () {
        final value = refer('value');
        final enumModel = EnumModel(
          isDeprecated: false,
          context: context,
          name: 'UserRole',
          values: {
            const EnumEntry(value: 'admin'),
            const EnumEntry(value: 'user'),
          },
          isNullable: false,
        );
        final listModel = ListModel(content: enumModel, context: context);

        expect(
          buildSimpleValueExpression(
            value,
            model: listModel,
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(true),
          ).accept(scopedEmitter).toString(),
          equals(
            'value.decodeSimpleStringList()'
            '.map((e) => _i1.UserRole.fromSimple(e, explode: true, )).toList()',
          ),
        );
      });
    });

    group('BinaryModel', () {
      test('generates TonikFileBytes wrapping for required BinaryModel', () {
        final value = refer('value');
        expect(
          buildSimpleValueExpression(
            value,
            model: BinaryModel(context: context),
            isRequired: true,
            nameManager: nameManager,
            package: 'tonik_core',
            explode: literalBool(false),
          ).accept(emitter).toString(),
          'TonikFileBytes(value.decodeSimpleBinary())',
        );
      });

      test(
        'generates null-checked TonikFileBytes for optional BinaryModel',
        () {
          final value = refer('value');
          expect(
            buildSimpleValueExpression(
              value,
              model: BinaryModel(context: context),
              isRequired: false,
              nameManager: nameManager,
              package: 'tonik_core',
              explode: literalBool(false),
            ).accept(emitter).toString(),
            'value == null ? null : '
            'TonikFileBytes(value.decodeSimpleBinary())',
          );
        },
      );

      test(
        'generates TonikFileBytes mapping for required List<BinaryModel>',
        () {
          final value = refer('value');
          final listModel = ListModel(
            content: BinaryModel(context: context),
            context: context,
          );
          expect(
            buildSimpleValueExpression(
              value,
              model: listModel,
              isRequired: true,
              nameManager: nameManager,
              package: 'tonik_core',
              explode: literalBool(false),
            ).accept(emitter).toString(),
            'value.decodeSimpleStringList()'
            '.map((e) => TonikFileBytes(e.decodeSimpleBinary())).toList()',
          );
        },
      );

      test('generates nullable TonikFileBytes mapping for optional '
          'List<BinaryModel>', () {
        final value = refer('value');
        final listModel = ListModel(
          content: BinaryModel(context: context),
          context: context,
        );
        expect(
          buildSimpleValueExpression(
            value,
            model: listModel,
            isRequired: false,
            nameManager: nameManager,
            package: 'tonik_core',
            explode: literalBool(false),
          ).accept(emitter).toString(),
          'value.decodeSimpleNullableStringList()'
          '?.map((e) => TonikFileBytes(e.decodeSimpleBinary())).toList()',
        );
      });
    });

    group('Base64Model', () {
      test('generates TonikFileBytes wrapping for required Base64Model', () {
        final value = refer('value');
        expect(
          buildSimpleValueExpression(
            value,
            model: Base64Model(context: context),
            isRequired: true,
            nameManager: nameManager,
            package: 'tonik_core',
            explode: literalBool(false),
          ).accept(emitter).toString(),
          'TonikFileBytes(value.decodeSimpleBase64())',
        );
      });

      test(
        'generates null-checked TonikFileBytes for optional Base64Model',
        () {
          final value = refer('value');
          expect(
            buildSimpleValueExpression(
              value,
              model: Base64Model(context: context),
              isRequired: false,
              nameManager: nameManager,
              package: 'tonik_core',
              explode: literalBool(false),
            ).accept(emitter).toString(),
            'value == null ? null : '
            'TonikFileBytes(value.decodeSimpleBase64())',
          );
        },
      );

      test(
        'generates TonikFileBytes mapping for required List<Base64Model>',
        () {
          final value = refer('value');
          final listModel = ListModel(
            content: Base64Model(context: context),
            context: context,
          );
          expect(
            buildSimpleValueExpression(
              value,
              model: listModel,
              isRequired: true,
              nameManager: nameManager,
              package: 'tonik_core',
              explode: literalBool(false),
            ).accept(emitter).toString(),
            'value.decodeSimpleStringList()'
            '.map((e) => TonikFileBytes(e.decodeSimpleBase64())).toList()',
          );
        },
      );

      test('generates nullable TonikFileBytes mapping for optional '
          'List<Base64Model>', () {
        final value = refer('value');
        final listModel = ListModel(
          content: Base64Model(context: context),
          context: context,
        );
        expect(
          buildSimpleValueExpression(
            value,
            model: listModel,
            isRequired: false,
            nameManager: nameManager,
            package: 'tonik_core',
            explode: literalBool(false),
          ).accept(emitter).toString(),
          'value.decodeSimpleNullableStringList()'
          '?.map((e) => TonikFileBytes(e.decodeSimpleBase64())).toList()',
        );
      });
    });

    group('List<ClassModel>', () {
      test(
        'generates SimpleDecodingException throw for required '
        'List<ClassModel>',
        () {
          final value = refer('value');
          final classModel = ClassModel(
            isDeprecated: false,
            context: context,
            name: 'User',
            properties: const [],
          );
          final listModel = ListModel(
            content: classModel,
            context: context,
          );
          expect(
            buildSimpleValueExpression(
              value,
              model: listModel,
              isRequired: true,
              nameManager: nameManager,
              package: 'my_package',
              explode: literalBool(false),
            ).accept(scopedEmitter).toString(),
            """throw  _i1.SimpleDecodingException('ClassModel is not supported in lists for simple decoding.')""",
          );
        },
      );

      test(
        'generates SimpleDecodingException throw for nullable '
        'List<ClassModel>',
        () {
          final value = refer('value');
          final classModel = ClassModel(
            isDeprecated: false,
            context: context,
            name: 'User',
            properties: const [],
          );
          final listModel = ListModel(
            content: classModel,
            context: context,
          );
          expect(
            buildSimpleValueExpression(
              value,
              model: listModel,
              isRequired: false,
              nameManager: nameManager,
              package: 'my_package',
              explode: literalBool(false),
            ).accept(scopedEmitter).toString(),
            """throw  _i1.SimpleDecodingException('ClassModel is not supported in lists for simple decoding.')""",
          );
        },
      );
    });

    group('NeverModel', () {
      test('generates throw for required NeverModel', () {
        final value = refer('value');
        expect(
          buildSimpleValueExpression(
            value,
            model: NeverModel(context: context),
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          """throw  _i1.SimpleDecodingException('Cannot decode NeverModel - this type does not permit any value.')""",
        );
      });

      test('generates null check before throw for optional NeverModel', () {
        final value = refer('value');
        expect(
          buildSimpleValueExpression(
            value,
            model: NeverModel(context: context),
            isRequired: false,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          """value == null ? null : throw  _i1.SimpleDecodingException('Cannot decode NeverModel - this type does not permit any value.')""",
        );
      });
    });

    group('unsupported model types generate runtime throws', () {
      test('ClassModel in list generates runtime throw', () {
        final value = refer('value');
        final model = ListModel(
          content: ClassModel(
            name: 'TestClass',
            properties: [],
            context: context,
            isDeprecated: false,
          ),
          context: context,
        );
        expect(
          buildSimpleValueExpression(
            value,
            model: model,
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          "throw  _i1.SimpleDecodingException("
          "'ClassModel is not supported in lists"
          " for simple decoding.')",
        );
      });

      test('nested ListModel generates runtime throw', () {
        final value = refer('value');
        final model = ListModel(
          content: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          context: context,
        );
        expect(
          buildSimpleValueExpression(
            value,
            model: model,
            isRequired: true,
            nameManager: nameManager,
            package: 'my_package',
            explode: literalBool(false),
          ).accept(scopedEmitter).toString(),
          "throw  _i1.SimpleDecodingException("
          "'Nested lists are not supported"
          " in simple decoding.')",
        );
      });

      test(
        'MapModel in list generates runtime throw',
        () {
          final value = refer('value');
          final model = ListModel(
            content: MapModel(
              valueModel: StringModel(context: context),
              context: context,
            ),
            context: context,
          );
          expect(
            buildSimpleValueExpression(
              value,
              model: model,
              isRequired: true,
              nameManager: nameManager,
              package: 'my_package',
              explode: literalBool(false),
            ).accept(scopedEmitter).toString(),
            "throw  _i1.SimpleDecodingException("
            "'Unsupported model type for simple decoding.')",
          );
        },
      );
    });
  });
}
