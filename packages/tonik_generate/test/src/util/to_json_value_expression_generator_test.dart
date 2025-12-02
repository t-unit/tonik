import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('buildToJsonValueExpression', () {
    test('for String property', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(buildToJsonPropertyExpression('testName', property), 'testName');
    });

    test('for nullable String property', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(buildToJsonPropertyExpression('testName', property), 'testName');
    });

    test('for Integer property', () {
      final property = Property(
        name: 'testAge',
        model: IntegerModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(buildToJsonPropertyExpression('testAge', property), 'testAge');
    });

    test('for DateTime property', () {
      final property = Property(
        name: 'startTime',
        model: DateTimeModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('startTime', property),
        'startTime.toTimeZonedIso8601String()',
      );
    });

    test('for nullable Date property', () {
      final property = Property(
        name: 'dueDate',
        model: DateModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('dueDate', property),
        'dueDate?.toJson()',
      );
    });

    test('for Decimal property', () {
      final property = Property(
        name: 'price',
        model: DecimalModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('price', property),
        'price.toString()',
      );
    });

    test('for nullable Decimal property', () {
      final property = Property(
        name: 'discountPrice',
        model: DecimalModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('discountPrice', property),
        'discountPrice?.toString()',
      );
    });

    test('for Enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
        description: null,
      );
      final property = Property(
        name: 'status',
        model: enumModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('status', property),
        'status.toJson()',
      );
    });

    test('for nullable Enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Priority',
        values: const {'high', 'low'},
        isNullable: true,
        context: context,
        description: null,
      );
      final property = Property(
        name: 'priority',
        model: enumModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('priority', property),
        'priority?.toJson()',
      );
    });

    test('for required property with nullable Enum type', () {
      final enumModel = EnumModel<String>(
        name: 'Priority',
        values: const {'high', 'low'},
        isNullable: true,
        context: context,
        description: null,
      );
      final property = Property(
        name: 'priority',
        model: enumModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );

      expect(
        buildToJsonPropertyExpression('priority', property),
        'priority?.toJson()',
      );
    });

    test('for List<String> property', () {
      final property = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      // List<primitive> is handled directly
      expect(buildToJsonPropertyExpression('tags', property), 'tags');
    });

    test('for List<DateTime> property', () {
      final property = Property(
        name: 'meetingTimes',
        model: ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('meetingTimes', property),
        'meetingTimes.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('for List<ClassModel> property', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
        description: null,
      );
      final property = Property(
        name: 'addresses',
        model: ListModel(content: addressModel, context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('addresses', property),
        'addresses.map((e) => e.toJson()).toList()',
      );
    });

    test('for nullable List<DecimalModel> property', () {
      final property = Property(
        name: 'lineItems',
        model: ListModel(
          content: DecimalModel(context: context),
          context: context,
        ),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('lineItems', property),
        'lineItems?.map((e) => e.toString()).toList()',
      );
    });

    test('for AliasModel property (String)', () {
      final aliasModel = AliasModel(
        name: 'UserID',
        model: StringModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'id',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(buildToJsonPropertyExpression('id', property), 'id');
    });

    test('for AliasModel property (DateTime)', () {
      final aliasModel = AliasModel(
        name: 'Timestamp',
        model: DateTimeModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'createdAt',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('createdAt', property),
        'createdAt.toTimeZonedIso8601String()',
      );
    });

    test('for nullable AliasModel property (DateTime)', () {
      final aliasModel = AliasModel(
        name: 'Timestamp',
        model: DateTimeModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'updatedAt',
        model: aliasModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('updatedAt', property),
        'updatedAt?.toTimeZonedIso8601String()',
      );
    });

    test('for AliasModel property (Class)', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
        description: null,
      );
      final aliasModel = AliasModel(
        name: 'PrimaryAddress',
        model: addressModel,
        context: context,
      );
      final property = Property(
        name: 'address',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('address', property),
        'address.toJson()',
      );
    });

    test('for nullable AliasModel property (Class)', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
        description: null,
      );
      final aliasModel = AliasModel(
        name: 'PrimaryAddress',
        model: addressModel,
        context: context,
      );
      final property = Property(
        name: 'address',
        model: aliasModel,
        isRequired: false, // optional
        isNullable: true, // nullable
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('address', property),
        'address?.toJson()',
      );
    });

    test('for ClassModel property', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
        description: null,
      );
      final property = Property(
        name: 'homeAddress',
        model: addressModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('homeAddress', property),
        'homeAddress.toJson()',
      );
    });

    test('for nullable ClassModel property', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
        description: null,
      );
      final property = Property(
        name: 'workAddress',
        model: addressModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('workAddress', property),
        'workAddress?.toJson()',
      );
    });

    test('for AllOfModel property', () {
      final allOfModel = AllOfModel(
        name: 'Combined',
        models: const {},
        context: context,
        description: null,
      );
      final property = Property(
        name: 'combinedData',
        model: allOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('combinedData', property),
        'combinedData.toJson()',
      );
    });

    test('for nullable AllOfModel property', () {
      final allOfModel = AllOfModel(
        name: 'Combined',
        models: const {},
        context: context,
        description: null,
      );
      final property = Property(
        name: 'combinedData',
        model: allOfModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('combinedData', property),
        'combinedData?.toJson()',
      );
    });

    test('for OneOfModel property', () {
      final oneOfModel = OneOfModel(
        name: 'Pet',
        models: const {},
        discriminator: 'petType',
        context: context,
        description: null,
      );
      final property = Property(
        name: 'pet',
        model: oneOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(buildToJsonPropertyExpression('pet', property), 'pet.toJson()');
    });

    test('for nullable OneOfModel property', () {
      final oneOfModel = OneOfModel(
        name: 'Pet',
        models: const {},
        discriminator: 'petType',
        context: context,
        description: null,
      );
      final property = Property(
        name: 'pet',
        model: oneOfModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(buildToJsonPropertyExpression('pet', property), 'pet?.toJson()');
    });

    test('for AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        name: 'Content',
        models: const {},
        discriminator: 'contentType',
        context: context,
        description: null,
      );
      final property = Property(
        name: 'content',
        model: anyOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('content', property),
        'content.toJson()',
      );
    });
    test('for nullable AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        name: 'Content',
        models: const {},
        discriminator: 'contentType',
        context: context,
        description: null,
      );
      final property = Property(
        name: 'content',
        model: anyOfModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('content', property),
        'content?.toJson()',
      );
    });

    test('for Alias to List<DateTime>', () {
      final aliasModel = AliasModel(
        name: 'TimestampList',
        model: ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
        context: context,
      );
      final property = Property(
        name: 'meetingTimes',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('meetingTimes', property),
        'meetingTimes.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('for nullable Alias to List<DateTime>', () {
      final aliasModel = AliasModel(
        name: 'TimestampList',
        model: ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
        context: context,
      );
      final property = Property(
        name: 'meetingTimes',
        model: aliasModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('meetingTimes', property),
        'meetingTimes?.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('for Alias to List<ClassModel>', () {
      final addressModel = ClassModel(
        description: null,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final aliasModel = AliasModel(
        name: 'AddressList',
        model: ListModel(content: addressModel, context: context),
        context: context,
      );
      final property = Property(
        name: 'addresses',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('addresses', property),
        'addresses.map((e) => e.toJson()).toList()',
      );
    });

    test('for nullable Alias to List<ClassModel>', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
        description: null,
      );
      final aliasModel = AliasModel(
        name: 'AddressList',
        model: ListModel(content: addressModel, context: context),
        context: context,
      );
      final property = Property(
        name: 'addresses',
        model: aliasModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        description: null,
      );
      expect(
        buildToJsonPropertyExpression('addresses', property),
        'addresses?.map((e) => e.toJson()).toList()',
      );
    });
  });

  group('buildToJsonPathParameterExpression', () {
    test('for String parameter', () {
      final parameter = PathParameterObject(
        name: 'testName',
        rawName: 'testName',
        description: 'Test name parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToJsonPathParameterExpression('testName', parameter),
        'testName',
      );
    });

    test('for Integer parameter', () {
      final parameter = PathParameterObject(
        name: 'testAge',
        rawName: 'testAge',
        description: 'Test age parameter',
        model: IntegerModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToJsonPathParameterExpression('testAge', parameter),
        'testAge',
      );
    });

    test('for DateTime parameter', () {
      final parameter = PathParameterObject(
        name: 'startTime',
        rawName: 'startTime',
        description: 'Test start time parameter',
        model: DateTimeModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToJsonPathParameterExpression('startTime', parameter),
        'startTime.toTimeZonedIso8601String()',
      );
    });

    test('for Enum parameter', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
        description: null,
      );
      final parameter = PathParameterObject(
        name: 'status',
        rawName: 'status',
        description: 'Test status parameter',
        model: enumModel,
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
      );
      expect(
        buildToJsonPathParameterExpression('status', parameter),
        'status.toJson()',
      );
    });
  });

  group('buildToJsonQueryParameterExpression', () {
    test('for String parameter', () {
      final parameter = QueryParameterObject(
        name: 'testName',
        rawName: 'testName',
        description: 'Test name parameter',
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: true,
      );
      expect(
        buildToJsonQueryParameterExpression('testName', parameter),
        'testName',
      );
    });

    test('for Integer parameter', () {
      final parameter = QueryParameterObject(
        name: 'testAge',
        rawName: 'testAge',
        description: 'Test age parameter',
        model: IntegerModel(context: context),
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: true,
      );
      expect(
        buildToJsonQueryParameterExpression('testAge', parameter),
        'testAge',
      );
    });

    test('for DateTime parameter', () {
      final parameter = QueryParameterObject(
        name: 'startTime',
        rawName: 'startTime',
        description: 'Test start time parameter',
        model: DateTimeModel(context: context),
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: true,
      );
      expect(
        buildToJsonQueryParameterExpression('startTime', parameter),
        'startTime.toTimeZonedIso8601String()',
      );
    });

    test('for Enum parameter', () {
      final enumModel = EnumModel<String>(
        description: null,
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );
      final parameter = QueryParameterObject(
        name: 'status',
        rawName: 'status',
        description: 'Test status parameter',
        model: enumModel,
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: true,
      );
      expect(
        buildToJsonQueryParameterExpression('status', parameter),
        'status.toJson()',
      );
    });
  });
}
