// Generated code won't have whitespcae in long lines, so we ignore this.
// ignore_for_file: missing_whitespace_between_adjacent_strings

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
    nameManager = NameManager(generator: NameGenerator());
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
        ).accept(emitter).toString(),
        'value.decodeSimpleNullableBigDecimal()',
      );
    });

    test('generates for enum types', () {
      final value = refer('value');
      final enumModel = EnumModel(
        context: context,
        name: 'UserRole',
        values: const {'admin', 'user'},
        isNullable: false,
      );

      expect(
        buildSimpleValueExpression(
          value,
          model: enumModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'tonik_core',
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
        ).accept(emitter).toString(),
        'value == null ? null : UserRole.fromSimple(value!, explode: true, )',
      );
    });

    test('generates for class types', () {
      final value = refer('value');
      final classModel = ClassModel(
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
        ).accept(emitter).toString(),
        'value == null ? null : User.fromSimple(value!, explode: true, )',
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
        ).accept(emitter).toString(),
        "value.decodeSimpleStringList(context: r'Order.quantities')"
        ".map((e) => e.decodeSimpleInt(context: r'Order.quantities')).toList()",
      );
    });

    group('with scoped emitter', () {
      test('generates for scoped enum types', () {
        final value = refer('value');
        final enumModel = EnumModel(
          context: context,
          name: 'UserRole',
          values: const {'admin', 'user'},
          isNullable: false,
        );

        expect(
          buildSimpleValueExpression(
            value,
            model: enumModel,
            isRequired: true,
            nameManager: nameManager,
            package: 'package:my_package/models.dart',
          ).accept(scopedEmitter).toString(),
          equals('_i1.UserRole.fromSimple(value, explode: true, )'),
        );
      });

      test('generates for scoped class types', () {
        final value = refer('value');
        final classModel = ClassModel(
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
            package: 'package:my_package/models.dart',
          ).accept(scopedEmitter).toString(),
          equals('_i1.User.fromSimple(value, explode: true, )'),
        );
      });

      test('generates for scoped list of classes', () {
        final value = refer('value');
        final enumModel = EnumModel(
          context: context,
          name: 'UserRole',
          values: const {'admin', 'user'},
          isNullable: false,
        );
        final listModel = ListModel(content: enumModel, context: context);

        expect(
          buildSimpleValueExpression(
            value,
            model: listModel,
            isRequired: true,
            nameManager: nameManager,
            package: 'package:my_package/models.dart',
          ).accept(scopedEmitter).toString(),
          equals(
            'value.decodeSimpleStringList()'
            '.map((e) => _i1.UserRole.fromSimple(e, explode: true, )).toList()',
          ),
        );
      });
    });
  });
}
