import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/to_json_value_expression_generator.dart';

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
      );
      expect(buildToJsonValueExpression('testName', property), 'testName');
    });

    test('for nullable String property', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(buildToJsonValueExpression('testName', property), 'testName');
    });

    test('for Integer property', () {
      final property = Property(
        name: 'testAge',
        model: IntegerModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(buildToJsonValueExpression('testAge', property), 'testAge');
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
        buildToJsonValueExpression('startTime', property),
        'startTime.toIso8601String()',
      );
    });

    test('for nullable Date property', () {
      final property = Property(
        name: 'dueDate',
        model: DateModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('dueDate', property),
        'dueDate?.toIso8601String()',
      );
    });

    test('for Decimal property', () {
      final property = Property(
        name: 'price',
        model: DecimalModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(buildToJsonValueExpression('price', property), 'price.toString()');
    });

    test('for nullable Decimal property', () {
      final property = Property(
        name: 'discountPrice',
        model: DecimalModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('discountPrice', property),
        'discountPrice?.toString()',
      );
    });

    test('for Enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );
      final property = Property(
        name: 'status',
        model: enumModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(buildToJsonValueExpression('status', property), 'status.toJson()');
    });

    test('for nullable Enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Priority',
        values: const {'high', 'low'},
        isNullable: true,
        context: context,
      );
      final property = Property(
        name: 'priority',
        model: enumModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('priority', property),
        'priority?.toJson()',
      );
    });

    test('for required property with nullable Enum type', () {
      final enumModel = EnumModel<String>(
        name: 'Priority',
        values: const {'high', 'low'}, 
        isNullable: true,
        context: context,
      );
      final property = Property(
        name: 'priority',
        model: enumModel,
        isRequired: true, 
        isNullable: false,
        isDeprecated: false,
      );

      expect(
        buildToJsonValueExpression('priority', property),
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
      );
      // List<primitive> is handled directly
      expect(buildToJsonValueExpression('tags', property), 'tags');
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
      );
      expect(
        buildToJsonValueExpression('meetingTimes', property),
        'meetingTimes.map((e) => e.toIso8601String()).toList()',
      );
    });

    test('for List<ClassModel> property', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
        context: context,
      );
      final property = Property(
        name: 'addresses',
        model: ListModel(content: addressModel, context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('addresses', property),
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
      );
      expect(
        buildToJsonValueExpression('lineItems', property),
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
      );
      expect(buildToJsonValueExpression('id', property), 'id');
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
      );
      expect(
        buildToJsonValueExpression('createdAt', property),
        'createdAt.toIso8601String()',
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
      );
      expect(
        buildToJsonValueExpression('updatedAt', property),
        'updatedAt?.toIso8601String()',
      );
    });

    test('for AliasModel property (Class)', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
        context: context,
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
      );
      expect(
        buildToJsonValueExpression('address', property),
        'address.toJson()',
      );
    });

    test('for nullable AliasModel property (Class)', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
        context: context,
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
      );
      expect(
        buildToJsonValueExpression('address', property),
        'address?.toJson()',
      );
    });

    test('for ClassModel property', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
        context: context,
      );
      final property = Property(
        name: 'homeAddress',
        model: addressModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('homeAddress', property),
        'homeAddress.toJson()',
      );
    });

    test('for nullable ClassModel property', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
        context: context,
      );
      final property = Property(
        name: 'workAddress',
        model: addressModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('workAddress', property),
        'workAddress?.toJson()',
      );
    });

    test('for AllOfModel property', () {
      final allOfModel = AllOfModel(
        name: 'Combined',
        models: const {},
        context: context,
      );
      final property = Property(
        name: 'combinedData',
        model: allOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('combinedData', property),
        'combinedData.toJson()',
      );
    });

    test('for nullable AllOfModel property', () {
      final allOfModel = AllOfModel(
        name: 'Combined',
        models: const {},
        context: context,
      );
      final property = Property(
        name: 'combinedData',
        model: allOfModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('combinedData', property),
        'combinedData?.toJson()',
      );
    });

    test('for OneOfModel property', () {
      final oneOfModel = OneOfModel(
        name: 'Pet',
        models: const {},
        discriminator: 'petType',
        context: context,
      );
      final property = Property(
        name: 'pet',
        model: oneOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(buildToJsonValueExpression('pet', property), 'pet.toJson()');
    });

    test('for nullable OneOfModel property', () {
      final oneOfModel = OneOfModel(
        name: 'Pet',
        models: const {},
        discriminator: 'petType',
        context: context,
      );
      final property = Property(
        name: 'pet',
        model: oneOfModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(buildToJsonValueExpression('pet', property), 'pet?.toJson()');
    });

    test('for AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        name: 'Content',
        models: const {},
        discriminator: 'contentType',
        context: context,
      );
      final property = Property(
        name: 'content',
        model: anyOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('content', property),
        'content.toJson()',
      );
    });
    test('for nullable AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        name: 'Content',
        models: const {},
        discriminator: 'contentType',
        context: context,
      );
      final property = Property(
        name: 'content',
        model: anyOfModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('content', property),
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
      );
      expect(
        buildToJsonValueExpression('meetingTimes', property),
        'meetingTimes.map((e) => e.toIso8601String()).toList()',
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
      );
      expect(
        buildToJsonValueExpression('meetingTimes', property),
        'meetingTimes?.map((e) => e.toIso8601String()).toList()',
      );
    });

    test('for Alias to List<ClassModel>', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
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
      );
      expect(
        buildToJsonValueExpression('addresses', property),
        'addresses.map((e) => e.toJson()).toList()',
      );
    });

    test('for nullable Alias to List<ClassModel>', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: const {},
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
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        buildToJsonValueExpression('addresses', property),
        'addresses?.map((e) => e.toJson()).toList()',
      );
    });
  });
}
