import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_form_query_parameter_expression_generator.dart';

void main() {
  group('buildToFormQueryParameterExpression', () {
    late Context context;

    setUp(() {
      context = Context.initial();
    });

    group('primitive types', () {
      test('generates expression for required string parameter', () {
        final parameter = QueryParameterObject(
          name: 'name',
          rawName: 'name',
          description: 'User name',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: StringModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'name',
          parameter,
          allowEmpty: false,
        );

        expect(expression, 'name.toForm(explode: false, allowEmpty: false)');
      });

      test('generates expression for optional string parameter', () {
        final parameter = QueryParameterObject(
          name: 'name',
          rawName: 'name',
          description: 'User name',
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: true,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: StringModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'name',
          parameter,
        );

        expect(expression, 'name.toForm(explode: false, allowEmpty: true)');
      });

      test('generates expression for integer parameter', () {
        final parameter = QueryParameterObject(
          name: 'age',
          rawName: 'age',
          description: 'User age',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: IntegerModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'age',
          parameter,
          allowEmpty: false,
        );

        expect(expression, 'age.toForm(explode: false, allowEmpty: false)');
      });

      test('generates expression for double parameter', () {
        final parameter = QueryParameterObject(
          name: 'price',
          rawName: 'price',
          description: 'Product price',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: DoubleModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'price',
          parameter,
          allowEmpty: false,
        );

        expect(expression, 'price.toForm(explode: false, allowEmpty: false)');
      });

      test('generates expression for number parameter', () {
        final parameter = QueryParameterObject(
          name: 'value',
          rawName: 'value',
          description: 'Numeric value',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: NumberModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'value',
          parameter,
          allowEmpty: false,
        );

        expect(expression, 'value.toForm(explode: false, allowEmpty: false)');
      });

      test('generates expression for boolean parameter', () {
        final parameter = QueryParameterObject(
          name: 'active',
          rawName: 'active',
          description: 'Is active',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: BooleanModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'active',
          parameter,
          allowEmpty: false,
        );

        expect(expression, 'active.toForm(explode: false, allowEmpty: false)');
      });

      test('generates expression for DateTime parameter', () {
        final parameter = QueryParameterObject(
          name: 'createdAt',
          rawName: 'created_at',
          description: 'Creation date',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: DateTimeModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'createdAt',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'createdAt.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for Date parameter', () {
        final parameter = QueryParameterObject(
          name: 'birthDate',
          rawName: 'birth_date',
          description: 'Birth date',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: DateModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'birthDate',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'birthDate.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for Decimal parameter', () {
        final parameter = QueryParameterObject(
          name: 'amount',
          rawName: 'amount',
          description: 'Decimal amount',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: DecimalModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'amount',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'amount.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for Uri parameter', () {
        final parameter = QueryParameterObject(
          name: 'website',
          rawName: 'website',
          description: 'Website URL',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: UriModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'website',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'website.toForm(explode: false, allowEmpty: false)',
        );
      });
    });

    group('complex types', () {
      test('generates expression for enum parameter', () {
        final parameter = QueryParameterObject(
          name: 'status',
          rawName: 'status',
          description: 'Status enum',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: EnumModel(
            context: context,
            values: const {'active', 'inactive'},
            isNullable: false,
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'status',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'status.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for class parameter', () {
        final parameter = QueryParameterObject(
          name: 'filter',
          rawName: 'filter',
          description: 'Filter object',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: ClassModel(context: context, properties: const []),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'filter',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'filter.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for AllOf parameter', () {
        final parameter = QueryParameterObject(
          name: 'combined',
          rawName: 'combined',
          description: 'Combined object',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: AllOfModel(
            context: context,
            models: {
              ClassModel(context: context, properties: const []),
              ClassModel(context: context, properties: const []),
            },
            name: 'CombinedModel',
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'combined',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'combined.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for OneOf parameter', () {
        final parameter = QueryParameterObject(
          name: 'value',
          rawName: 'value',
          description: 'OneOf value',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: OneOfModel(
            context: context,
            models: {
              (
                discriminatorValue: 'string',
                model: StringModel(context: context),
              ),
              (
                discriminatorValue: 'integer',
                model: IntegerModel(context: context),
              ),
            },
            name: 'OneOfValue',
            discriminator: 'type',
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'value',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'value.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for AnyOf parameter', () {
        final parameter = QueryParameterObject(
          name: 'flexible',
          rawName: 'flexible',
          description: 'AnyOf value',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: AnyOfModel(
            context: context,
            models: {
              (
                discriminatorValue: 'string',
                model: StringModel(context: context),
              ),
              (
                discriminatorValue: 'boolean',
                model: BooleanModel(context: context),
              ),
            },
            name: 'AnyOfValue',
            discriminator: 'type',
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'flexible',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'flexible.toForm(explode: false, allowEmpty: false)',
        );
      });
    });

    group('list types', () {
      test('generates expression for list of strings', () {
        final parameter = QueryParameterObject(
          name: 'tags',
          rawName: 'tags',
          description: 'List of tags',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: ListModel(
            context: context,
            content: StringModel(context: context),
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'tags',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'tags.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for list of integers', () {
        final parameter = QueryParameterObject(
          name: 'ids',
          rawName: 'ids',
          description: 'List of IDs',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: ListModel(
            context: context,
            content: IntegerModel(context: context),
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'ids',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'ids.map((e) => e.toString()).toList() '
              '.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for list of enums', () {
        final parameter = QueryParameterObject(
          name: 'statuses',
          rawName: 'statuses',
          description: 'List of statuses',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: ListModel(
            context: context,
            content: EnumModel(
              context: context,
              values: const {'active', 'inactive'},
              isNullable: false,
            ),
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'statuses',
          parameter,
          explode: true,
          allowEmpty: false,
        );

        expect(
          expression,
          'statuses.map((e) => e.toForm(explode: true, allowEmpty: false)) '
              '.toList().toForm(explode: true, allowEmpty: false)',
        );
      });

      test('generates expression for list of class models', () {
        final parameter = QueryParameterObject(
          name: 'filters',
          rawName: 'filters',
          description: 'List of filters',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: ListModel(
            context: context,
            content: ClassModel(context: context, properties: const []),
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'filters',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'filters.map((e) => e.toForm(explode: false, allowEmpty: false)) '
              '.toList().toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for nested list (list of lists)', () {
        final parameter = QueryParameterObject(
          name: 'matrix',
          rawName: 'matrix',
          description: 'Matrix of values',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: ListModel(
            context: context,
            content: ListModel(
              context: context,
              content: ClassModel(context: context, properties: const []),
            ),
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'matrix',
          parameter,
          explode: true,
          allowEmpty: false,
        );

        expect(
          expression,
          'matrix.map((e) => e.map((e) => e.toForm(explode: true, '
          'allowEmpty: false)).toList().toForm(explode: true, '
          'allowEmpty: false)).toList().toForm(explode: true, '
          'allowEmpty: false)',
        );
      });
    });

    group('alias types', () {
      test('generates expression for alias of string', () {
        final parameter = QueryParameterObject(
          name: 'userId',
          rawName: 'user_id',
          description: 'User ID alias',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: AliasModel(
            context: context,
            model: StringModel(context: context),
            name: 'UserId',
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'userId',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'userId.toForm(explode: false, allowEmpty: false)',
        );
      });

      test('generates expression for alias of class', () {
        final parameter = QueryParameterObject(
          name: 'filter',
          rawName: 'filter',
          description: 'Filter alias',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: AliasModel(
            context: context,
            model: ClassModel(context: context, properties: const []),
            name: 'FilterAlias',
          ),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'filter',
          parameter,
          allowEmpty: false,
        );

        expect(
          expression,
          'filter.toForm(explode: false, allowEmpty: false)',
        );
      });
    });

    group('explode and allowEmpty variations', () {
      test('generates with explode=true, allowEmpty=true', () {
        final parameter = QueryParameterObject(
          name: 'name',
          rawName: 'name',
          description: 'Name',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: true,
          explode: true,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: StringModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'name',
          parameter,
          explode: true,
        );

        expect(expression, 'name.toForm(explode: true, allowEmpty: true)');
      });

      test('generates with explode=false, allowEmpty=true', () {
        final parameter = QueryParameterObject(
          name: 'name',
          rawName: 'name',
          description: 'Name',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: true,
          explode: false,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: StringModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'name',
          parameter,
        );

        expect(expression, 'name.toForm(explode: false, allowEmpty: true)');
      });

      test('generates with explode=true, allowEmpty=false', () {
        final parameter = QueryParameterObject(
          name: 'name',
          rawName: 'name',
          description: 'Name',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: QueryParameterEncoding.form,
          allowReserved: false,
          model: StringModel(context: context),
          context: context,
        );

        final expression = buildToFormQueryParameterExpression(
          'name',
          parameter,
          explode: true,
          allowEmpty: false,
        );

        expect(expression, 'name.toForm(explode: true, allowEmpty: false)');
      });
    });
  });
}
