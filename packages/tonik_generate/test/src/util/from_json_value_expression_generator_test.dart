// Generated code won't have whitespcae in long lines, so we ignore this.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';

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

  group('buildFromJsonValueExpression', () {
    test('generates for primitive types', () {
      expect(
        buildFromJsonValueExpression(
          'value',
          model: StringModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonString()'),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: IntegerModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonInt()'),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: NumberModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonNum()'),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: DoubleModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonDouble()'),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: DecimalModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonBigDecimal()'),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: BooleanModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonBool()'),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: DateTimeModel(context: context),
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonDateTime()'),
      );
    });

    test('generates for alias types', () {
      // Test primitive alias
      final stringAlias = AliasModel(
        context: context,
        name: 'UserId',
        model: StringModel(context: context),
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: stringAlias,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonString()'),
      );

      // Test class alias
      final userModel = ClassModel(
        context: context,
        name: 'User',
        properties: const [],
      );
      final userAlias = AliasModel(
        context: context,
        name: 'UserReference',
        model: userModel,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: userAlias,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('User.fromJson(value)'),
      );

      // Test list alias
      final listModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final listAlias = AliasModel(
        context: context,
        name: 'StringList',
        model: listModel,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: listAlias,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonList<String>()'),
      );

      // Test nested alias
      final nestedAlias = AliasModel(
        context: context,
        name: 'NestedAlias',
        model: userAlias,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: nestedAlias,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('User.fromJson(value)'),
      );

      // Test alias with list of classes
      final userListModel = ListModel(content: userModel, context: context);
      final userListAlias = AliasModel(
        context: context,
        name: 'UserList',
        model: userListModel,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: userListAlias,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<Object?>()'
          '.map((e) => User.fromJson(e)).toList()',
        ),
      );

      // Test list of aliases
      final userAliasListModel = ListModel(
        content: userAlias,
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: userAliasListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<Object?>()'
          '.map((e) => User.fromJson(e)).toList()',
        ),
      );
    });

    test('generates for enum types', () {
      final enumModel = EnumModel(
        context: context,
        name: 'UserRole',
        values: const {'admin', 'user'},
        isNullable: false,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: enumModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('UserRole.fromJson(value)'),
      );
    });

    test('generates for class types', () {
      final classModel = ClassModel(
        context: context,
        name: 'User',
        properties: const [],
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: classModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('User.fromJson(value)'),
      );
    });

    test('generates for list of primitives', () {
      final listModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: listModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonList<String>()'),
      );

      // Test list of booleans
      final boolListModel = ListModel(
        content: BooleanModel(context: context),
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: boolListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals('value.decodeJsonList<bool>()'),
      );

      // Test list of dates
      final dateListModel = ListModel(
        content: DateModel(context: context),
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: dateListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<String>()'
          '.map((e) => e.decodeJsonDate()).toList()',
        ),
      );

      // Test list of date times
      final dateTimeListModel = ListModel(
        content: DateTimeModel(context: context),
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: dateTimeListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<String>()'
          '.map((e) => e.decodeJsonDateTime()).toList()',
        ),
      );

      // Test list of decimals
      final decimalListModel = ListModel(
        content: DecimalModel(context: context),
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: decimalListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<String>()'
          '.map((e) => e.decodeJsonBigDecimal()).toList()',
        ),
      );
    });

    test('generates for list of classes', () {
      final classModel = ClassModel(
        context: context,
        name: 'User',
        properties: const [],
      );
      final listModel = ListModel(content: classModel, context: context);
      expect(
        buildFromJsonValueExpression(
          'value',
          model: listModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<Object?>()'
          '.map((e) => User.fromJson(e)).toList()',
        ),
      );
    });

    test('generates for nested lists', () {
      final classModel = ClassModel(
        context: context,
        name: 'User',
        properties: const [],
      );
      final innerListModel = ListModel(content: classModel, context: context);
      final outerListModel = ListModel(
        content: innerListModel,
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: outerListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<Object?>()'
          '.map((e) => e.decodeJsonList<Object?>()'
          '.map((e) => User.fromJson(e)).toList()).toList()',
        ),
      );
    });

    test('generates for triple-nested lists', () {
      final classModel = ClassModel(
        context: context,
        name: 'User',
        properties: const [],
      );
      final innerListModel = ListModel(content: classModel, context: context);
      final middleListModel = ListModel(
        content: innerListModel,
        context: context,
      );
      final outerListModel = ListModel(
        content: middleListModel,
        context: context,
      );
      expect(
        buildFromJsonValueExpression(
          'value',
          model: outerListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<Object?>()'
          '.map((e) => e.decodeJsonList<Object?>()'
          '.map((e) => e.decodeJsonList<Object?>()'
          '.map((e) => User.fromJson(e)).toList()'
          ').toList()).toList()',
        ),
      );
    });

    test('generates for list of enums', () {
      final enumModel = EnumModel(
        context: context,
        name: 'UserRole',
        values: const {'admin', 'user'},
        isNullable: false,
      );
      final enumListModel = ListModel(content: enumModel, context: context);
      expect(
        buildFromJsonValueExpression(
          'value',
          model: enumListModel,
          nameManager: nameManager,
          package: 'package:my_package/my_package.dart',
        ).accept(emitter).toString(),
        equals(
          'value.decodeJsonList<Object?>()'
          '.map((e) => UserRole.fromJson(e)).toList()',
        ),
      );
    });

    group('with scoped emitter', () {
      test('generates for scoped enum types', () {
        final enumModel = EnumModel(
          context: context,
          name: 'UserRole',
          values: const {'admin', 'user'},
          isNullable: false,
        );
        expect(
          buildFromJsonValueExpression(
            'value',
            model: enumModel,
            nameManager: nameManager,
            package: 'package:my_package/models.dart',
          ).accept(scopedEmitter).toString(),
          equals('_i1.UserRole.fromJson(value)'),
        );
      });

      test('generates for scoped list of enums', () {
        final enumModel = EnumModel(
          context: context,
          name: 'UserRole',
          values: const {'admin', 'user'},
          isNullable: false,
        );
        final enumListModel = ListModel(content: enumModel, context: context);
        expect(
          buildFromJsonValueExpression(
            'value',
            model: enumListModel,
            nameManager: nameManager,
            package: 'package:my_package/models.dart',
          ).accept(scopedEmitter).toString(),
          equals(
            'value.decodeJsonList<_i1.Object?>()'
            '.map((e) => _i2.UserRole.fromJson(e)).toList()',
          ),
        );
      });
    });
  });
}
