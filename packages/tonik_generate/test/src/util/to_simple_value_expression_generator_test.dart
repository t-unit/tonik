import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('buildToSimplePropertyExpression', () {
    test('for String property', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('testName', property),
        'testName.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for String property with custom parameters', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression(
          'testName',
          property,
          explode: true,
          allowEmpty: false,
        ),
        'testName.toSimple(explode: true, allowEmpty: false)',
      );
    });

    test('for nullable String property', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('testName', property),
        'testName?.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Integer property', () {
      final property = Property(
        name: 'testAge',
        model: IntegerModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('testAge', property),
        'testAge.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Double property', () {
      final property = Property(
        name: 'testPrice',
        model: DoubleModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('testPrice', property),
        'testPrice.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Number property', () {
      final property = Property(
        name: 'testNum',
        model: NumberModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('testNum', property),
        'testNum.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Boolean property', () {
      final property = Property(
        name: 'isActive',
        model: BooleanModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('isActive', property),
        'isActive.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for DateTime property', () {
      final property = Property(
        name: 'startTime',
        model: DateTimeModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('startTime', property),
        'startTime.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for BigDecimal property', () {
      final property = Property(
        name: 'amount',
        model: DecimalModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('amount', property),
        'amount.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Uri property', () {
      final property = Property(
        name: 'endpoint',
        model: UriModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('endpoint', property),
        'endpoint.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Date property', () {
      final property = Property(
        name: 'birthDate',
        model: DateModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('birthDate', property),
        'birthDate.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: false,
        context: context,
      );
      final property = Property(
        name: 'color',
        model: enumModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('color', property),
        'color.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for nullable Enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: true,
        context: context,
      );
      final property = Property(
        name: 'color',
        model: enumModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('color', property),
        'color?.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for List<String> property', () {
      final listModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final property = Property(
        name: 'tags',
        model: listModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('tags', property),
        'tags.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for List<int> property', () {
      final listModel = ListModel(
        context: context,
        content: IntegerModel(context: context),
      );
      final property = Property(
        name: 'scores',
        model: listModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('scores', property),
        'scores.map((e) => e.toString())'
        ' .toList().toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for List<double> property', () {
      final listModel = ListModel(
        context: context,
        content: DoubleModel(context: context),
      );
      final property = Property(
        name: 'prices',
        model: listModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('prices', property),
        'prices.map((e) => e.toString())'
        ' .toList().toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for List<bool> property', () {
      final listModel = ListModel(
        context: context,
        content: BooleanModel(context: context),
      );
      final property = Property(
        name: 'flags',
        model: listModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('flags', property),
        'flags.map((e) => e.toString())'
        ' .toList().toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for nullable List<String> property', () {
      final listModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final property = Property(
        name: 'tags',
        model: listModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('tags', property),
        'tags?.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for List with complex content (enum)', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );
      final listModel = ListModel(
        context: context,
        content: enumModel,
      );
      final property = Property(
        name: 'statuses',
        model: listModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('statuses', property),
        'statuses.map((e) => e.toSimple(explode: false, allowEmpty: true))'
        ' .toList().toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Alias property', () {
      final aliasModel = AliasModel(
        context: context,
        name: 'UserId',
        model: StringModel(context: context),
      );
      final property = Property(
        name: 'userId',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToSimplePropertyExpression('userId', property),
        'userId.toSimple(explode: false, allowEmpty: true)',
      );
    });
  });

  group('buildToSimplePathParameterExpression', () {
    test('for String parameter', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToSimplePathParameterExpression('userId', parameter),
        'userId.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Integer parameter with custom params', () {
      final parameter = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: 'ID parameter',
        model: IntegerModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToSimplePathParameterExpression(
          'id',
          parameter,
          explode: true,
          allowEmpty: false,
        ),
        'id.toSimple(explode: true, allowEmpty: false)',
      );
    });

    test('for DateTime parameter', () {
      final parameter = PathParameterObject(
        name: 'timestamp',
        rawName: 'timestamp',
        description: 'Timestamp parameter',
        model: DateTimeModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToSimplePathParameterExpression('timestamp', parameter),
        'timestamp.toSimple(explode: false, allowEmpty: true)',
      );
    });
  });

  group('buildToSimpleQueryParameterExpression', () {
    test('for String parameter', () {
      final parameter = QueryParameterObject(
        name: 'query',
        rawName: 'query',
        description: 'Search query parameter',
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: false,
      );
      expect(
        buildToSimpleQueryParameterExpression('query', parameter),
        'query.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for Boolean parameter with custom params', () {
      final parameter = QueryParameterObject(
        name: 'active',
        rawName: 'active',
        description: 'Active filter parameter',
        model: BooleanModel(context: context),
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: false,
      );
      expect(
        buildToSimpleQueryParameterExpression(
          'active',
          parameter,
          explode: true,
          allowEmpty: false,
        ),
        'active.toSimple(explode: true, allowEmpty: false)',
      );
    });
  });

  group('buildToSimpleHeaderParameterExpression', () {
    test('for String header', () {
      final parameter = RequestHeaderObject(
        name: 'authorization',
        rawName: 'Authorization',
        description: 'Authorization header',
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToSimpleHeaderParameterExpression('authorization', parameter),
        'authorization.toSimple(explode: false, allowEmpty: true)',
      );
    });

    test('for DateTime header with custom params', () {
      final parameter = RequestHeaderObject(
        name: 'ifModifiedSince',
        rawName: 'If-Modified-Since',
        description: 'If-Modified-Since header',
        model: DateTimeModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToSimpleHeaderParameterExpression(
          'ifModifiedSince',
          parameter,
          explode: true,
          allowEmpty: false,
        ),
        'ifModifiedSince.toSimple(explode: true, allowEmpty: false)',
      );
    });
  });
} 
