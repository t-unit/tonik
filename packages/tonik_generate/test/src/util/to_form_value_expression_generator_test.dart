import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_form_value_expression_generator.dart';

void main() {
  group('buildToFormPropertyExpression', () {
    late Context context;

    setUp(() {
      context = Context.initial();
    });

    group('primitive types', () {
      test('generates correct expression for StringModel', () {
        final property = Property(
          name: 'name',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('name', property);
        expect(
          result,
          equals('name.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable StringModel', () {
        final property = Property(
          name: 'name',
          model: StringModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('name', property);
        expect(
          result,
          equals('name?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for IntegerModel', () {
        final property = Property(
          name: 'count',
          model: IntegerModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('count', property);
        expect(
          result,
          equals('count.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable IntegerModel', () {
        final property = Property(
          name: 'count',
          model: IntegerModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('count', property);
        expect(
          result,
          equals('count?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for DoubleModel', () {
        final property = Property(
          name: 'price',
          model: DoubleModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('price', property);
        expect(
          result,
          equals('price.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable DoubleModel', () {
        final property = Property(
          name: 'price',
          model: DoubleModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('price', property);
        expect(
          result,
          equals('price?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for NumberModel', () {
        final property = Property(
          name: 'value',
          model: NumberModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('value', property);
        expect(
          result,
          equals('value.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for BooleanModel', () {
        final property = Property(
          name: 'active',
          model: BooleanModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('active', property);
        expect(
          result,
          equals('active.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable BooleanModel', () {
        final property = Property(
          name: 'active',
          model: BooleanModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('active', property);
        expect(
          result,
          equals('active?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for DateTimeModel', () {
        final property = Property(
          name: 'timestamp',
          model: DateTimeModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('timestamp', property);
        expect(
          result,
          equals('timestamp.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable DateTimeModel', () {
        final property = Property(
          name: 'timestamp',
          model: DateTimeModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('timestamp', property);
        expect(
          result,
          equals('timestamp?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for DateModel', () {
        final property = Property(
          name: 'date',
          model: DateModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('date', property);
        expect(
          result,
          equals('date.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable DateModel', () {
        final property = Property(
          name: 'date',
          model: DateModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('date', property);
        expect(
          result,
          equals('date?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for DecimalModel', () {
        final property = Property(
          name: 'amount',
          model: DecimalModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('amount', property);
        expect(
          result,
          equals('amount.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable DecimalModel', () {
        final property = Property(
          name: 'amount',
          model: DecimalModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('amount', property);
        expect(
          result,
          equals('amount?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for UriModel', () {
        final property = Property(
          name: 'url',
          model: UriModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('url', property);
        expect(
          result,
          equals('url.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('generates correct expression for nullable UriModel', () {
        final property = Property(
          name: 'url',
          model: UriModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('url', property);
        expect(
          result,
          equals('url?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });
    });

    group('required nullable properties', () {
      test(
        'generates correct expression for required nullable StringModel',
        () {
          final property = Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            description: null,
          );

          final result = buildToFormPropertyExpression('name', property);
          expect(
            result,
            equals(
              "name?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
            ),
          );
        },
      );

      test(
        'generates correct expression for required nullable IntegerModel',
        () {
          final property = Property(
            name: 'count',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            description: null,
          );

          final result = buildToFormPropertyExpression('count', property);
          expect(
            result,
            equals(
              "count?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
            ),
          );
        },
      );

      test(
        'generates correct expression for required nullable DoubleModel',
        () {
          final property = Property(
            name: 'price',
            model: DoubleModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            description: null,
          );

          final result = buildToFormPropertyExpression('price', property);
          expect(
            result,
            equals(
              "price?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
            ),
          );
        },
      );

      test(
        'generates correct expression for required nullable BooleanModel',
        () {
          final property = Property(
            name: 'active',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            description: null,
          );

          final result = buildToFormPropertyExpression('active', property);
          expect(
            result,
            equals(
              "active?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
            ),
          );
        },
      );

      test(
        'generates correct expression for required nullable DateTimeModel',
        () {
          final property = Property(
            name: 'timestamp',
            model: DateTimeModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            description: null,
          );

          final result = buildToFormPropertyExpression('timestamp', property);
          expect(
            result,
            equals(
              'timestamp?.toForm(explode: explode, '
              "allowEmpty: allowEmpty) ?? ''",
            ),
          );
        },
      );

      test('generates correct expression for required nullable DateModel', () {
        final property = Property(
          name: 'date',
          model: DateModel(context: context),
          isRequired: true,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('date', property);
        expect(
          result,
          equals(
            "date?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
          ),
        );
      });

      test(
        'generates correct expression for required nullable DecimalModel',
        () {
          final property = Property(
            name: 'amount',
            model: DecimalModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            description: null,
          );

          final result = buildToFormPropertyExpression('amount', property);
          expect(
            result,
            equals(
              "amount?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
            ),
          );
        },
      );

      test('generates correct expression for required nullable UriModel', () {
        final property = Property(
          name: 'url',
          model: UriModel(context: context),
          isRequired: true,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('url', property);
        expect(
          result,
          equals(
            "url?.toForm(explode: explode, allowEmpty: allowEmpty) ?? ''",
          ),
        );
      });
    });

    group('complex types', () {
      test('throws for ListModel', () {
        final property = Property(
          name: 'items',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        expect(
          () => buildToFormPropertyExpression('items', property),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('throws for ClassModel', () {
        final property = Property(
          name: 'nested',
          model: ClassModel(
            isDeprecated: false,
            name: 'NestedClass',
            properties: const [],
            context: context,
            description: null,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        expect(
          () => buildToFormPropertyExpression('nested', property),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('throws for EnumModel', () {
        final property = Property(
          name: 'status',
          model: EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: const {'active', 'inactive'},
            isNullable: false,
            context: context,
            description: null,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        expect(
          () => buildToFormPropertyExpression('status', property),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('AliasModel handling', () {
      test('unwraps AliasModel to underlying primitive', () {
        final property = Property(
          name: 'userId',
          model: AliasModel(
            name: 'UserId',
            model: StringModel(context: context),
            context: context,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('userId', property);
        expect(
          result,
          equals('userId.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('unwraps nullable AliasModel to underlying primitive', () {
        final property = Property(
          name: 'userId',
          model: AliasModel(
            name: 'UserId',
            model: StringModel(context: context),
            context: context,
          ),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          description: null,
        );

        final result = buildToFormPropertyExpression('userId', property);
        expect(
          result,
          equals('userId?.toForm(explode: explode, allowEmpty: allowEmpty)'),
        );
      });

      test('throws for AliasModel wrapping complex type', () {
        final property = Property(
          name: 'users',
          model: AliasModel(
            name: 'UserList',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
            context: context,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          description: null,
        );

        expect(
          () => buildToFormPropertyExpression('users', property),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });
  });
}
