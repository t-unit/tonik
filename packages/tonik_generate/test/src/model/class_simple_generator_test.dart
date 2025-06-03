import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ClassGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;
  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = ClassGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ClassGenerator fromSimple generation', () {
    test('generates fromSimple for all supported primitive types', () {
      final model = ClassModel(
        name: 'Sample',
        properties: [
          Property(
            name: 'flag',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'count',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'label',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'created',
            model: DateTimeModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'amount',
            model: DecimalModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = r'''
        factory Sample.fromSimple(String? value) {
          final properties = value.decodeSimpleStringList(context: r'Sample');
          if (properties.length < 5) {
            throw SimpleDecodingException('Invalid value for Sample: $value');
          }
          return Sample(
            flag: properties[0].decodeSimpleBool(context: r'Sample.flag'),
            count: properties[1].decodeSimpleInt(context: r'Sample.count'),
            label: properties[2].decodeSimpleString(context: r'Sample.label'),
            created: properties[3].decodeSimpleDateTime(context: r'Sample.created'),
            amount: properties[4].decodeSimpleBigDecimal(context: r'Sample.amount'),
          );
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple for enum property', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );
      final model = ClassModel(
        name: 'Order',
        properties: [
          Property(
            name: 'status',
            model: enumModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = r'''
        factory Order.fromSimple(String? value) {
          final properties = value.decodeSimpleStringList(context: r'Order');
          if (properties.length < 1) {
            throw SimpleDecodingException('Invalid value for Order: $value');
          }
          return Order(status: Status.fromSimple(properties[0]));
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('does not generate fromSimple for unsupported properties', () {
      final model = ClassModel(
        name: 'User',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'address',
            model: ClassModel(
              name: 'Address',
              properties: const [],
              context: context,
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final hasFromSimple = generatedClass.constructors.any(
        (c) => c.name == 'fromSimple',
      );
      expect(hasFromSimple, isFalse);
    });

    test('generates fromSimple for all nullable primitive types', () {
      final model = ClassModel(
        name: 'NullableSample',
        properties: [
          Property(
            name: 'flag',
            model: BooleanModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'count',
            model: IntegerModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'label',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'created',
            model: DateTimeModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'amount',
            model: DecimalModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = r'''
        factory NullableSample.fromSimple(String? value) {
          final properties = value.decodeSimpleStringList(context: r'NullableSample');
          if (properties.length < 5) {
            throw SimpleDecodingException('Invalid value for NullableSample: $value');
          }
          return NullableSample(
            flag: properties[0].decodeSimpleNullableBool(
              context: r'NullableSample.flag',
            ),
            count: properties[1].decodeSimpleNullableInt(
              context: r'NullableSample.count',
            ),
            label: properties[2].decodeSimpleNullableString(
              context: r'NullableSample.label',
            ),
            created: properties[3].decodeSimpleNullableDateTime(
              context: r'NullableSample.created',
            ),
            amount: properties[4].decodeSimpleNullableBigDecimal(
              context: r'NullableSample.amount',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates fromSimple for OneOf model with all supported primitive types',
      () {
        final oneOfModel = OneOfModel(
          name: 'PrimitiveOneOf',
          models: {
            (discriminatorValue: 'int', model: IntegerModel(context: context)),
            (discriminatorValue: 'bool', model: BooleanModel(context: context)),
            (discriminatorValue: 'str', model: StringModel(context: context)),
          },
          discriminator: 'type',
          context: context,
        );
        final model = ClassModel(
          name: 'Container',
          properties: [
            Property(
              name: 'value',
              model: oneOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );
        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = r'''
          factory Container.fromSimple(String? value) {
            final properties = value.decodeSimpleStringList(context: r'Container');
            if (properties.length < 1) {
              throw SimpleDecodingException('Invalid value for Container: $value');
            }
            return Container(value: PrimitiveOneOf.fromSimple(properties[0]));
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'does not generate fromSimple for OneOf model with unsupported type',
      () {
        final oneOfModel = OneOfModel(
          name: 'MixedOneOf',
          models: {
            (discriminatorValue: 'int', model: IntegerModel(context: context)),
            (
              discriminatorValue: 'class',
              model: ClassModel(
                name: 'Address',
                properties: const [],
                context: context,
              ),
            ),
          },
          discriminator: 'type',
          context: context,
        );
        final model = ClassModel(
          name: 'Container',
          properties: [
            Property(
              name: 'value',
              model: oneOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );
        final generatedClass = generator.generateClass(model);
        final hasFromSimple = generatedClass.constructors.any(
          (c) => c.name == 'fromSimple',
        );
        expect(hasFromSimple, isFalse);
      },
    );

    test('generates fromSimple for Alias targeting primitive type', () {
      final aliasModel = AliasModel(
        name: 'UserId',
        model: IntegerModel(context: context),
        context: context,
      );
      final model = ClassModel(
        name: 'UserIdHolder',
        properties: [
          Property(
            name: 'id',
            model: aliasModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = r'''
        factory UserIdHolder.fromSimple(String? value) {
          final properties = value.decodeSimpleStringList(context: r'UserIdHolder');
          if (properties.length < 1) {
            throw SimpleDecodingException('Invalid value for UserIdHolder: $value');
          }
          return UserIdHolder(
            id: properties[0].decodeSimpleInt(context: r'UserIdHolder.id'),
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple for Alias targeting OneOf with primitives', () {
      final oneOfModel = OneOfModel(
        name: 'PrimitiveOneOf',
        models: {
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );
      final aliasModel = AliasModel(
        name: 'MyAlias',
        model: oneOfModel,
        context: context,
      );
      final model = ClassModel(
        name: 'AliasHolder',
        properties: [
          Property(
            name: 'value',
            model: aliasModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = r'''
        factory AliasHolder.fromSimple(String? value) {
          final properties = value.decodeSimpleStringList(context: r'AliasHolder');
          if (properties.length < 1) {
            throw SimpleDecodingException('Invalid value for AliasHolder: $value');
          }
          return AliasHolder(value: PrimitiveOneOf.fromSimple(properties[0]));
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('does not generate fromSimple for Alias targeting class', () {
      final aliasModel = AliasModel(
        name: 'UserAlias',
        model: ClassModel(
          name: 'User',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
        context: context,
      );
      final model = ClassModel(
        name: 'AliasHolder',
        properties: [
          Property(
            name: 'user',
            model: aliasModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final hasFromSimple = generatedClass.constructors.any(
        (c) => c.name == 'fromSimple',
      );
      expect(hasFromSimple, isFalse);
    });

    test('does not generate fromSimple for Alias targeting list', () {
      final aliasModel = AliasModel(
        name: 'StringListAlias',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        context: context,
      );
      final model = ClassModel(
        name: 'AliasHolder',
        properties: [
          Property(
            name: 'list',
            model: aliasModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final hasFromSimple = generatedClass.constructors.any(
        (c) => c.name == 'fromSimple',
      );
      expect(hasFromSimple, isFalse);
    });
  });
}
