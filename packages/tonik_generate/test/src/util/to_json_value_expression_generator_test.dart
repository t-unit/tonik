import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String emit(Expression expr) => expr.accept(emitter).toString();

  group('buildToJsonValueExpression', () {
    test('for String property', () {
      final property = Property(
        name: 'testName',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('testName', property)),
        'testName',
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
        emit(buildToJsonPropertyExpression('testName', property)),
        'testName',
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
        emit(buildToJsonPropertyExpression('testAge', property)),
        'testAge',
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
        emit(buildToJsonPropertyExpression('startTime', property)),
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
      );
      expect(
        emit(buildToJsonPropertyExpression('dueDate', property)),
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
      );
      expect(
        emit(buildToJsonPropertyExpression('price', property)),
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
      );
      expect(
        emit(buildToJsonPropertyExpression('discountPrice', property)),
        'discountPrice?.toString()',
      );
    });

    test('for Binary property', () {
      final property = Property(
        name: 'thumbnail',
        model: BinaryModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      // Binary data: toBytes() then decode to String for JSON.
      expect(
        emit(buildToJsonPropertyExpression('thumbnail', property)),
        'thumbnail.toBytes().decodeToString()',
      );
    });

    test('for nullable Binary property', () {
      final property = Property(
        name: 'data',
        model: BinaryModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('data', property)),
        'data?.toBytes().decodeToString()',
      );
    });

    test('for Base64 property', () {
      final property = Property(
        name: 'thumbnail',
        model: Base64Model(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      // Base64 data: toBytes() then encode to base64 string for JSON.
      expect(
        emit(buildToJsonPropertyExpression('thumbnail', property)),
        'thumbnail.toBytes().encodeToBase64String()',
      );
    });

    test('for nullable Base64 property', () {
      final property = Property(
        name: 'data',
        model: Base64Model(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('data', property)),
        'data?.toBytes().encodeToBase64String()',
      );
    });

    test('for Enum property', () {
      final enumModel = EnumModel<String>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
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
      expect(
        emit(buildToJsonPropertyExpression('status', property)),
        'status.toJson()',
      );
    });

    test('for nullable Enum property', () {
      final enumModel = EnumModel<String>(
        isDeprecated: false,
        name: 'Priority',
        values: {
          const EnumEntry(value: 'high'),
          const EnumEntry(value: 'low'),
        },
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
        emit(buildToJsonPropertyExpression('priority', property)),
        'priority?.toJson()',
      );
    });

    test('for required property with nullable Enum type', () {
      final enumModel = EnumModel<String>(
        isDeprecated: false,
        name: 'Priority',
        values: {
          const EnumEntry(value: 'high'),
          const EnumEntry(value: 'low'),
        },
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
        emit(buildToJsonPropertyExpression('priority', property)),
        'priority?.toJson()',
      );
    });

    test('for required property with nullable ClassModel type', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Metadata',
        properties: const [],
        isNullable: true,
        context: context,
      );
      final property = Property(
        name: 'metadata',
        model: classModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      expect(
        emit(buildToJsonPropertyExpression('metadata', property)),
        'metadata?.toJson()',
      );
    });

    test('for required property with nullable AllOfModel type', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: const {},
        isNullable: true,
        context: context,
      );
      final property = Property(
        name: 'combined',
        model: allOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      expect(
        emit(buildToJsonPropertyExpression('combined', property)),
        'combined?.toJson()',
      );
    });

    test('for required property with nullable OneOfModel type', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: const {},
        discriminator: 'petType',
        isNullable: true,
        context: context,
      );
      final property = Property(
        name: 'pet',
        model: oneOfModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );

      expect(
        emit(buildToJsonPropertyExpression('pet', property)),
        'pet?.toJson()',
      );
    });

    test('for required property with nullable AnyOfModel type', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'Content',
        models: const {},
        discriminator: 'contentType',
        isNullable: true,
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
        emit(buildToJsonPropertyExpression('content', property)),
        'content?.toJson()',
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
      expect(emit(buildToJsonPropertyExpression('tags', property)), 'tags');
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
        emit(buildToJsonPropertyExpression('meetingTimes', property)),
        'meetingTimes.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('for List<Binary> property', () {
      final property = Property(
        name: 'images',
        model: ListModel(
          content: BinaryModel(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      // List of binary needs each element's bytes decoded to string
      expect(
        emit(buildToJsonPropertyExpression('images', property)),
        'images.map((e) => e.toBytes().decodeToString()).toList()',
      );
    });

    test('for List<Base64> property', () {
      final property = Property(
        name: 'images',
        model: ListModel(
          content: Base64Model(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      // List of base64 needs each element's bytes base64-encoded
      expect(
        emit(buildToJsonPropertyExpression('images', property)),
        'images.map((e) => e.toBytes().encodeToBase64String()).toList()',
      );
    });

    test('for List<ClassModel> property', () {
      final addressModel = ClassModel(
        name: 'Address',
        isDeprecated: false,
        properties: const [],
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
        emit(buildToJsonPropertyExpression('addresses', property)),
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
        emit(buildToJsonPropertyExpression('lineItems', property)),
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
      expect(emit(buildToJsonPropertyExpression('id', property)), 'id');
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
        emit(buildToJsonPropertyExpression('createdAt', property)),
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
      );
      expect(
        emit(buildToJsonPropertyExpression('updatedAt', property)),
        'updatedAt?.toTimeZonedIso8601String()',
      );
    });

    test('for AliasModel property (Class)', () {
      final addressModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
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
        emit(buildToJsonPropertyExpression('address', property)),
        'address.toJson()',
      );
    });

    test('for nullable AliasModel property (Class)', () {
      final addressModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
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
        emit(buildToJsonPropertyExpression('address', property)),
        'address?.toJson()',
      );
    });

    test('for ClassModel property', () {
      final addressModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
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
        emit(buildToJsonPropertyExpression('homeAddress', property)),
        'homeAddress.toJson()',
      );
    });

    test('for nullable ClassModel property', () {
      final addressModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
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
        emit(buildToJsonPropertyExpression('workAddress', property)),
        'workAddress?.toJson()',
      );
    });

    test('for AllOfModel property', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
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
        emit(buildToJsonPropertyExpression('combinedData', property)),
        'combinedData.toJson()',
      );
    });

    test('for nullable AllOfModel property', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
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
        emit(buildToJsonPropertyExpression('combinedData', property)),
        'combinedData?.toJson()',
      );
    });

    test('for OneOfModel property', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
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
      expect(
        emit(buildToJsonPropertyExpression('pet', property)),
        'pet.toJson()',
      );
    });

    test('for nullable OneOfModel property', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
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
      expect(
        emit(buildToJsonPropertyExpression('pet', property)),
        'pet?.toJson()',
      );
    });

    test('for AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
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
        emit(buildToJsonPropertyExpression('content', property)),
        'content.toJson()',
      );
    });
    test('for nullable AnyOfModel property', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
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
        emit(buildToJsonPropertyExpression('content', property)),
        'content?.toJson()',
      );
    });

    test('for required property with nullable AliasModel type (Class)', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final aliasModel = AliasModel(
        name: 'PrimaryAddress',
        model: classModel,
        isNullable: true,
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
        emit(buildToJsonPropertyExpression('address', property)),
        'address?.toJson()',
      );
    });

    test('for required property with nullable AliasModel type (DateTime)', () {
      final aliasModel = AliasModel(
        name: 'Timestamp',
        model: DateTimeModel(context: context),
        isNullable: true,
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
        emit(buildToJsonPropertyExpression('createdAt', property)),
        'createdAt?.toTimeZonedIso8601String()',
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
        emit(buildToJsonPropertyExpression('meetingTimes', property)),
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
      );
      expect(
        emit(buildToJsonPropertyExpression('meetingTimes', property)),
        'meetingTimes?.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('for Alias to List<ClassModel>', () {
      final addressModel = ClassModel(
        isDeprecated: false,
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
      );
      expect(
        emit(buildToJsonPropertyExpression('addresses', property)),
        'addresses.map((e) => e.toJson()).toList()',
      );
    });

    test('for nullable Alias to List<ClassModel>', () {
      final addressModel = ClassModel(
        isDeprecated: false,
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
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('addresses', property)),
        'addresses?.map((e) => e.toJson()).toList()',
      );
    });
  });

  group('buildToJsonPropertyExpression for MapModel', () {
    test('for Map<String, String> passes through without transformation', () {
      final mapModel = MapModel(
        valueModel: StringModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'metadata',
        model: mapModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('metadata', property)),
        'metadata',
      );
    });

    test('for Map<String, int> passes through without transformation', () {
      final mapModel = MapModel(
        valueModel: IntegerModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'counts',
        model: mapModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('counts', property)),
        'counts',
      );
    });

    test('for Map<String, ClassModel> transforms values via .map()', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final mapModel = MapModel(
        valueModel: classModel,
        context: context,
      );
      final property = Property(
        name: 'addresses',
        model: mapModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final result = emit(
        buildToJsonPropertyExpression('addresses', property),
      );
      expect(
        result,
        'addresses.map((k, v, ) => MapEntry(k, v.toJson(), ))',
      );
    });

    test('for nullable Map<String, ClassModel> uses null-safe map', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final mapModel = MapModel(
        valueModel: classModel,
        context: context,
      );
      final property = Property(
        name: 'addresses',
        model: mapModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      final result = emit(
        buildToJsonPropertyExpression('addresses', property),
      );
      expect(
        result,
        'addresses?.map((k, v, ) => MapEntry(k, v.toJson(), ))',
      );
    });

    test('for nullable MapModel uses null-safe map', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final mapModel = MapModel(
        valueModel: classModel,
        context: context,
        isNullable: true,
      );
      final property = Property(
        name: 'addresses',
        model: mapModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final result = emit(
        buildToJsonPropertyExpression('addresses', property),
      );
      expect(
        result,
        'addresses?.map((k, v, ) => MapEntry(k, v.toJson(), ))',
      );
    });

    test('for Map<String, DateTime> transforms values', () {
      final mapModel = MapModel(
        valueModel: DateTimeModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'timestamps',
        model: mapModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final result = emit(
        buildToJsonPropertyExpression('timestamps', property),
      );
      expect(
        result,
        'timestamps.map((k, v, ) => '
        'MapEntry(k, v.toTimeZonedIso8601String(), ))',
      );
    });

    test('for Map<String, EnumModel> transforms values', () {
      final enumModel = EnumModel<String>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
      );
      final mapModel = MapModel(
        valueModel: enumModel,
        context: context,
      );
      final property = Property(
        name: 'statuses',
        model: mapModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final result = emit(
        buildToJsonPropertyExpression('statuses', property),
      );
      expect(
        result,
        'statuses.map((k, v, ) => MapEntry(k, v.toJson(), ))',
      );
    });

    test(
      'for Map<String, ClassModel> with forceNonNullReceiver uses !',
      () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'Address',
          properties: const [],
          context: context,
        );
        final mapModel = MapModel(
          valueModel: classModel,
          context: context,
        );
        final property = Property(
          name: 'addresses',
          model: mapModel,
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
        );
        final result = emit(
          buildToJsonPropertyExpression(
            'addresses',
            property,
            forceNonNullReceiver: true,
          ),
        );
        expect(
          result,
          'addresses!.map((k, v, ) => MapEntry(k, v.toJson(), ))',
        );
      },
    );
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
        emit(buildToJsonPathParameterExpression('testName', parameter)),
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
        emit(buildToJsonPathParameterExpression('testAge', parameter)),
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
        emit(buildToJsonPathParameterExpression('startTime', parameter)),
        'startTime.toTimeZonedIso8601String()',
      );
    });

    test('for Enum parameter', () {
      final enumModel = EnumModel<String>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
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
        emit(buildToJsonPathParameterExpression('status', parameter)),
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
        emit(buildToJsonQueryParameterExpression('testName', parameter)),
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
        emit(buildToJsonQueryParameterExpression('testAge', parameter)),
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
        emit(buildToJsonQueryParameterExpression('startTime', parameter)),
        'startTime.toTimeZonedIso8601String()',
      );
    });

    test('for Enum parameter', () {
      final enumModel = EnumModel<String>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
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
        emit(buildToJsonQueryParameterExpression('status', parameter)),
        'status.toJson()',
      );
    });
  });

  group('buildToJsonPropertyExpression for NeverModel', () {
    test('for NeverModel property throws EncodingException', () {
      final property = Property(
        name: 'forbidden',
        model: NeverModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('forbidden', property)),
        contains('throw'),
      );
      expect(
        emit(buildToJsonPropertyExpression('forbidden', property)),
        contains('EncodingException'),
      );
    });

    test('for nullable NeverModel property throws EncodingException', () {
      final property = Property(
        name: 'forbidden',
        model: NeverModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      // Even for nullable NeverModel, we throw because there's no valid value
      expect(
        emit(buildToJsonPropertyExpression('forbidden', property)),
        contains('throw'),
      );
      expect(
        emit(buildToJsonPropertyExpression('forbidden', property)),
        contains('EncodingException'),
      );
    });

    test('for List of NeverModel property throws EncodingException', () {
      final listModel = ListModel(
        content: NeverModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'forbiddenList',
        model: listModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('forbiddenList', property)),
        contains('throw'),
      );
      expect(
        emit(buildToJsonPropertyExpression('forbiddenList', property)),
        contains('EncodingException'),
      );
    });

    test('for AliasModel wrapping NeverModel throws EncodingException', () {
      final aliasModel = AliasModel(
        name: 'ForbiddenAlias',
        model: NeverModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'forbiddenAlias',
        model: aliasModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('forbiddenAlias', property)),
        contains('throw'),
      );
      expect(
        emit(buildToJsonPropertyExpression('forbiddenAlias', property)),
        contains('EncodingException'),
      );
    });
  });

  group('buildToJsonPathParameterExpression for NeverModel', () {
    test('for NeverModel path parameter throws EncodingException', () {
      final parameter = PathParameterObject(
        name: 'forbidden',
        rawName: 'forbidden',
        description: 'Test path parameter',
        model: NeverModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        context: context,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPathParameterExpression('forbidden', parameter)),
        contains('throw'),
      );
      expect(
        emit(buildToJsonPathParameterExpression('forbidden', parameter)),
        contains('EncodingException'),
      );
    });
  });

  group('buildToJsonQueryParameterExpression for NeverModel', () {
    test('for NeverModel query parameter throws EncodingException', () {
      final parameter = QueryParameterObject(
        name: 'forbidden',
        rawName: 'forbidden',
        description: 'Test query parameter',
        model: NeverModel(context: context),
        encoding: QueryParameterEncoding.form,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        allowReserved: true,
      );
      expect(
        emit(buildToJsonQueryParameterExpression('forbidden', parameter)),
        contains('throw'),
      );
      expect(
        emit(buildToJsonQueryParameterExpression('forbidden', parameter)),
        contains('EncodingException'),
      );
    });
  });

  group('buildToJsonPropertyExpression for BinaryModel with forceNonNull', () {
    test('generates force non-null toBytes for Binary property', () {
      final property = Property(
        name: 'avatar',
        model: BinaryModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'avatar',
            property,
            forceNonNullReceiver: true,
          ),
        ),
        'avatar!.toBytes().decodeToString()',
      );
    });
  });

  group('buildToJsonPropertyExpression for Base64Model with forceNonNull', () {
    test('generates force non-null toBytes for Base64 property', () {
      final property = Property(
        name: 'avatar',
        model: Base64Model(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'avatar',
            property,
            forceNonNullReceiver: true,
          ),
        ),
        'avatar!.toBytes().encodeToBase64String()',
      );
    });
  });

  group('buildToJsonPropertyExpression for AnyModel', () {
    test('generates encodeAnyToJson call for AnyModel property', () {
      final property = Property(
        name: 'data',
        model: AnyModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('data', property)),
        'encodeAnyToJson(data)',
      );
    });

    test('generates encodeAnyToJson call for nullable AnyModel property', () {
      final property = Property(
        name: 'data',
        model: AnyModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(buildToJsonPropertyExpression('data', property)),
        'encodeAnyToJson(data)',
      );
    });
  });

  group('with useImmutableCollections', () {
    test('simple list produces .unlock', () {
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
      expect(
        emit(
          buildToJsonPropertyExpression(
            'tags',
            property,
            useImmutableCollections: true,
          ),
        ),
        'tags.unlock',
      );
    });

    test('nullable simple list produces ?.unlock', () {
      final property = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'tags',
            property,
            useImmutableCollections: true,
          ),
        ),
        'tags?.unlock',
      );
    });

    test('list with complex content produces .unlock.map(...).toList()', () {
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
        emit(
          buildToJsonPropertyExpression(
            'meetingTimes',
            property,
            useImmutableCollections: true,
          ),
        ),
        'meetingTimes.unlock.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('simple map produces .unlock', () {
      final property = Property(
        name: 'metadata',
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'metadata',
            property,
            useImmutableCollections: true,
          ),
        ),
        'metadata.unlock',
      );
    });

    test('nullable simple map produces ?.unlock', () {
      final property = Property(
        name: 'metadata',
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
        ),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'metadata',
            property,
            useImmutableCollections: true,
          ),
        ),
        'metadata?.unlock',
      );
    });

    test('map with complex content produces .unlock.map(...)', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final property = Property(
        name: 'addresses',
        model: MapModel(
          valueModel: classModel,
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'addresses',
            property,
            useImmutableCollections: true,
          ),
        ),
        'addresses.unlock.map((k, v, ) => MapEntry(k, v.toJson(), ))',
      );
    });

    test('nested list produces inner .unlock via transformation', () {
      final innerList = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final property = Property(
        name: 'matrix',
        model: ListModel(
          content: innerList,
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'matrix',
            property,
            useImmutableCollections: true,
          ),
        ),
        'matrix.unlock.map((e) => e.unlock).toList()',
      );
    });

    test('disabled by default does not add .unlock', () {
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
      expect(
        emit(buildToJsonPropertyExpression('tags', property)),
        'tags',
      );
    });

    test('forceNonNullReceiver simple list produces !.unlock', () {
      final property = Property(
        name: 'tags',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        isWriteOnly: true,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'tags',
            property,
            forceNonNullReceiver: true,
            useImmutableCollections: true,
          ),
        ),
        'tags!.unlock',
      );
    });

    test(
      'forceNonNullReceiver list with complex content '
      'produces !.unlock.map(...).toList()',
      () {
        final property = Property(
          name: 'times',
          model: ListModel(
            content: DateTimeModel(context: context),
            context: context,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          isWriteOnly: true,
        );
        expect(
          emit(
            buildToJsonPropertyExpression(
              'times',
              property,
              forceNonNullReceiver: true,
              useImmutableCollections: true,
            ),
          ),
          'times!.unlock.map((e) => e.toTimeZonedIso8601String()).toList()',
        );
      },
    );

    test('nullable list with complex content produces ?.unlock.map', () {
      final property = Property(
        name: 'times',
        model: ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'times',
            property,
            useImmutableCollections: true,
          ),
        ),
        'times?.unlock.map((e) => e.toTimeZonedIso8601String()).toList()',
      );
    });

    test('forceNonNullReceiver simple map produces !.unlock', () {
      final property = Property(
        name: 'meta',
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
        ),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        isWriteOnly: true,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'meta',
            property,
            forceNonNullReceiver: true,
            useImmutableCollections: true,
          ),
        ),
        'meta!.unlock',
      );
    });

    test(
      'forceNonNullReceiver map with complex content '
      'produces !.unlock.map(...)',
      () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'Addr',
          properties: const [],
          context: context,
        );
        final property = Property(
          name: 'addrs',
          model: MapModel(
            valueModel: classModel,
            context: context,
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          isWriteOnly: true,
        );
        expect(
          emit(
            buildToJsonPropertyExpression(
              'addrs',
              property,
              forceNonNullReceiver: true,
              useImmutableCollections: true,
            ),
          ),
          'addrs!.unlock.map((k, v, ) => MapEntry(k, v.toJson(), ))',
        );
      },
    );

    test('nullable map with complex content produces ?.unlock.map', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Addr',
        properties: const [],
        context: context,
      );
      final property = Property(
        name: 'addrs',
        model: MapModel(
          valueModel: classModel,
          context: context,
        ),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'addrs',
            property,
            useImmutableCollections: true,
          ),
        ),
        'addrs?.unlock.map((k, v, ) => MapEntry(k, v.toJson(), ))',
      );
    });

    test('alias wrapping list uses immutable transformation', () {
      final alias = AliasModel(
        name: 'TagList',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        context: context,
      );
      final property = Property(
        name: 'tags',
        model: alias,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      expect(
        emit(
          buildToJsonPropertyExpression(
            'tags',
            property,
            useImmutableCollections: true,
          ),
        ),
        'tags.unlock',
      );
    });
  });
}
