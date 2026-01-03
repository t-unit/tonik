import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';

void main() {
  group('buildFromFormValueExpression', () {
    late NameManager nameManager;
    late Context context;

    setUp(() {
      nameManager = NameManager(generator: NameGenerator());
      context = Context.initial();
    });

    group('primitive types', () {
      test('generates correct expression for StringModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['name']"),
          model: StringModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'name',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          "values['name'].decodeFormString(context: r'TestClass.name')",
        );
      });

      test('generates correct expression for nullable StringModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['name']"),
          model: StringModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'name',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['name'].decodeFormNullableString("
            "context: r'TestClass.name')",
          ),
        );
      });

      test('generates correct expression for IntegerModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['count']"),
          model: IntegerModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'count',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          "values['count'].decodeFormInt(context: r'TestClass.count')",
        );
      });

      test('generates correct expression for nullable IntegerModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['count']"),
          model: IntegerModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'count',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['count'].decodeFormNullableInt("
            "context: r'TestClass.count')",
          ),
        );
      });

      test('generates correct expression for DoubleModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['price']"),
          model: DoubleModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'price',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['price'].decodeFormDouble(context: r'TestClass.price')",
          ),
        );
      });

      test('generates correct expression for nullable DoubleModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['price']"),
          model: DoubleModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'price',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['price'].decodeFormNullableDouble("
            "context: r'TestClass.price')",
          ),
        );
      });

      test('generates correct expression for NumberModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['value']"),
          model: NumberModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'value',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['value'].decodeFormDouble(context: r'TestClass.value')",
          ),
        );
      });

      test('generates correct expression for BooleanModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['active']"),
          model: BooleanModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'active',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['active'].decodeFormBool(context: r'TestClass.active')",
          ),
        );
      });

      test('generates correct expression for nullable BooleanModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['active']"),
          model: BooleanModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'active',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['active'].decodeFormNullableBool("
            "context: r'TestClass.active')",
          ),
        );
      });

      test('generates correct expression for DateTimeModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['timestamp']"),
          model: DateTimeModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'timestamp',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['timestamp'].decodeFormDateTime("
            "context: r'TestClass.timestamp')",
          ),
        );
      });

      test('generates correct expression for nullable DateTimeModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['timestamp']"),
          model: DateTimeModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'timestamp',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['timestamp'].decodeFormNullableDateTime("
            "context: r'TestClass.timestamp')",
          ),
        );
      });

      test('generates correct expression for DateModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['date']"),
          model: DateModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'date',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['date'].decodeFormDate(context: r'TestClass.date')",
          ),
        );
      });

      test('generates correct expression for nullable DateModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['date']"),
          model: DateModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'date',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['date'].decodeFormNullableDate(context: r'TestClass.date')",
          ),
        );
      });

      test('generates correct expression for DecimalModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['amount']"),
          model: DecimalModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'amount',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['amount'].decodeFormBigDecimal("
            "context: r'TestClass.amount')",
          ),
        );
      });

      test('generates correct expression for nullable DecimalModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['amount']"),
          model: DecimalModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'amount',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['amount'].decodeFormNullableBigDecimal("
            "context: r'TestClass.amount')",
          ),
        );
      });

      test('generates correct expression for UriModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['url']"),
          model: UriModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'url',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['url'].decodeFormUri(context: r'TestClass.url')",
          ),
        );
      });

      test('generates correct expression for nullable UriModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['url']"),
          model: UriModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'url',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['url'].decodeFormNullableUri("
            "context: r'TestClass.url')",
          ),
        );
      });
    });

    group('context handling', () {
      test('handles context with class only', () {
        final expression = buildFromFormValueExpression(
          refer("values['name']"),
          model: StringModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          "values['name'].decodeFormString(context: r'TestClass')",
        );
      });

      test('handles context with property only', () {
        final expression = buildFromFormValueExpression(
          refer("values['name']"),
          model: StringModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextProperty: 'name',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['name'].decodeFormString(context: r'name')",
          ),
        );
      });

      test('handles no context', () {
        final expression = buildFromFormValueExpression(
          refer("values['name']"),
          model: StringModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          "values['name'].decodeFormString()",
        );
      });
    });

    group('complex types', () {
      test('generates expression for ListModel with String content', () {
        final expression = buildFromFormValueExpression(
          refer("values['items']"),
          model: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'items',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['items'].decodeFormStringList(context: r'TestClass.items')",
          ),
        );
      });

      test('generates expression for ListModel with int content', () {
        final expression = buildFromFormValueExpression(
          refer("values['numbers']"),
          model: ListModel(
            content: IntegerModel(context: context),
            context: context,
          ),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'numbers',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            '''values['numbers'].decodeFormStringList(context: r'TestClass.numbers').map((e) => e.decodeFormInt(context: r'TestClass.numbers')).toList()''',
          ),
        );
      });

      test('generates expression for ClassModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['nested']"),
          model: ClassModel(
            isDeprecated: false,
            name: 'NestedClass',
            properties: const [],
            context: context,
          ),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          "NestedClass.fromForm(values['nested'], explode: true, )",
        );
      });

      test('generates expression for EnumModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['status']"),
          model: EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'inactive'),
            },
            isNullable: false,
            context: context,
          ),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          "Status.fromForm(values['status'], explode: true, )",
        );
      });
    });

    group('AliasModel handling', () {
      test('unwraps AliasModel to underlying primitive', () {
        final aliasModel = AliasModel(
          name: 'UserId',
          model: StringModel(context: context),
          context: context,
        );

        final expression = buildFromFormValueExpression(
          refer("values['userId']"),
          model: aliasModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'userId',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['userId'].decodeFormString("
            "context: r'TestClass.userId')",
          ),
        );
      });

      test('unwraps AliasModel wrapping ListModel', () {
        final aliasModel = AliasModel(
          name: 'UserList',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          context: context,
        );

        final expression = buildFromFormValueExpression(
          refer("values['users']"),
          model: aliasModel,
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'users',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          equals(
            "values['users'].decodeFormStringList(context: r'TestClass.users')",
          ),
        );
      });
    });

    group('NeverModel', () {
      test('generates throw for required NeverModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['neverField']"),
          model: NeverModel(context: context),
          isRequired: true,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'neverField',
        );

        final code = expression.accept(DartEmitter()).toString();
        expect(
          code,
          """throw  FormatDecodingException('Cannot decode NeverModel - this type does not permit any value.')""",
        );
      });

      test('generates null check before throw for optional NeverModel', () {
        final expression = buildFromFormValueExpression(
          refer("values['neverField']"),
          model: NeverModel(context: context),
          isRequired: false,
          nameManager: nameManager,
          package: 'test_package',
          contextClass: 'TestClass',
          contextProperty: 'neverField',
        );

        final code = expression.accept(DartEmitter()).toString();

        expect(
          code,
          """values['neverField'] == null ? null : throw  FormatDecodingException('Cannot decode NeverModel - this type does not permit any value.')""",
        );
      });
    });
  });
}
