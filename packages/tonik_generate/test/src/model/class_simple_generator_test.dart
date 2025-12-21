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
  final format = DartFormatter(
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
        isDeprecated: false,
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
          Property(
            name: 'thumbnail',
            model: BinaryModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final generatedClass = generator.generateClass(model);
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory Sample.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {
              r'flag',
              r'count',
              r'label',
              r'created',
              r'amount',
              r'thumbnail',
            },
            listKeys: {},
            context: r'Sample',
          );
          return Sample(
            flag: values[r'flag'].decodeSimpleBool(context: r'Sample.flag'),
            count: values[r'count'].decodeSimpleInt(context: r'Sample.count'),
            label: values[r'label'].decodeSimpleString(context: r'Sample.label'),
            created: values[r'created'].decodeSimpleDateTime(
              context: r'Sample.created',
            ),
            amount: values[r'amount'].decodeSimpleBigDecimal(
              context: r'Sample.amount',
            ),
            thumbnail: values[r'thumbnail'].decodeSimpleBinary(
              context: r'Sample.thumbnail',
            ),
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
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
      );
      final model = ClassModel(
        isDeprecated: false,
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
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory Order.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'status'},
            listKeys: {},
            context: r'Order',
          );
          return Order(
            status: Status.fromSimple(values[r'status'], explode: explode),
          );
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple for all nullable primitive types', () {
      final model = ClassModel(
        isDeprecated: false,
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
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory NullableSample.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'flag', r'count', r'label', r'created', r'amount'},
            listKeys: {},
            context: r'NullableSample',
          );
          return NullableSample(
            flag: values[r'flag'].decodeSimpleNullableBool(
              context: r'NullableSample.flag',
            ),
            count: values[r'count'].decodeSimpleNullableInt(
              context: r'NullableSample.count',
            ),
            label: values[r'label'].decodeSimpleNullableString(
              context: r'NullableSample.label',
            ),
            created: values[r'created'].decodeSimpleNullableDateTime(
              context: r'NullableSample.created',
            ),
            amount: values[r'amount'].decodeSimpleNullableBigDecimal(
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
          isDeprecated: false,
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
          isDeprecated: false,
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
        final fromSimpleConstructor = generatedClass.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimpleConstructor.factory, isTrue);
        expect(fromSimpleConstructor.requiredParameters.length, 1);
        expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
        expect(
          fromSimpleConstructor.requiredParameters[0].type
              ?.accept(emitter)
              .toString(),
          'String?',
        );
        expect(fromSimpleConstructor.optionalParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
        expect(
          fromSimpleConstructor.optionalParameters[0].type
              ?.accept(emitter)
              .toString(),
          'bool',
        );
        expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          factory Container.fromSimple(String? value, {required bool explode}) {
            final values = value.decodeObject(
              explode: explode,
              explodeSeparator: ',',
              expectedKeys: {r'value'},
              listKeys: {},
              context: r'Container',
            );
            return Container(
              value: PrimitiveOneOf.fromSimple(values[r'value'], explode: explode),
            );
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates fromSimple for OneOf model with mixed types attempting decode',
      () {
        final oneOfModel = OneOfModel(
          isDeprecated: false,
          name: 'MixedOneOf',
          models: {
            (discriminatorValue: 'int', model: IntegerModel(context: context)),
            (
              discriminatorValue: 'class',
              model: ClassModel(
                isDeprecated: false,
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
          isDeprecated: false,
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
        final fromSimpleConstructor = generatedClass.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimpleConstructor.factory, isTrue);
        expect(fromSimpleConstructor.requiredParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');

        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          factory Container.fromSimple(String? value, {required bool explode}) {
            final values = value.decodeObject(
              explode: explode,
              explodeSeparator: ',',
              expectedKeys: {r'value'},
              listKeys: {},
              context: r'Container',
            );
            return Container(
              value: MixedOneOf.fromSimple(values[r'value'], explode: explode),
            );
          }
        ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates fromSimple for mixed OneOf that attempts decoding',
      () {
        final oneOfModel = OneOfModel(
          isDeprecated: false,
          name: 'DynamicValue',
          models: {
            (discriminatorValue: 'str', model: StringModel(context: context)),
            (
              discriminatorValue: 'class',
              model: ClassModel(
                isDeprecated: false,
                name: 'ComplexData',
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
            ),
          },
          discriminator: 'type',
          context: context,
        );
        final model = ClassModel(
          isDeprecated: false,
          name: 'Wrapper',
          properties: [
            Property(
              name: 'data',
              model: oneOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);

        const expectedFromSimpleMethod = '''
          factory Wrapper.fromSimple(String? value, {required bool explode}) {
            final values = value.decodeObject(
              explode: explode,
              explodeSeparator: ',',
              expectedKeys: {r'data'},
              listKeys: {},
              context: r'Wrapper',
            );
            return Wrapper(
              data: DynamicValue.fromSimple(values[r'data'], explode: explode),
            );
          }
        ''';

        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedFromSimpleMethod)),
        );
      },
    );

    test('generates fromSimple for Alias targeting primitive type', () {
      final aliasModel = AliasModel(
        name: 'UserId',
        model: IntegerModel(context: context),
        context: context,
      );
      final model = ClassModel(
        isDeprecated: false,
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
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory UserIdHolder.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'id'},
            listKeys: {},
            context: r'UserIdHolder',
          );
          return UserIdHolder(
            id: values[r'id'].decodeSimpleInt(context: r'UserIdHolder.id'),
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
        isDeprecated: false,
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
        isDeprecated: false,
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
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory AliasHolder.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'value'},
            listKeys: {},
            context: r'AliasHolder',
          );
          return AliasHolder(
            value: PrimitiveOneOf.fromSimple(values[r'value'], explode: explode),
          );
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates fromSimple that throws for Alias targeting class',
      () {
        final aliasModel = AliasModel(
          name: 'UserAlias',
          model: ClassModel(
            isDeprecated: false,
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
          isDeprecated: false,
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
        final fromSimpleConstructor = generatedClass.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimpleConstructor.factory, isTrue);
        expect(fromSimpleConstructor.requiredParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');

        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          factory AliasHolder.fromSimple(String? value, {required bool explode}) {
            throw SimpleDecodingException(
              'Simple encoding not supported for AliasHolder: contains complex types',
            );
          }
        ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates fromSimple that throws for Alias targeting list',
      () {
        final aliasModel = AliasModel(
          name: 'StringListAlias',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          context: context,
        );
        final model = ClassModel(
          isDeprecated: false,
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
        final fromSimpleConstructor = generatedClass.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimpleConstructor.factory, isTrue);
        expect(fromSimpleConstructor.requiredParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters.length, 1);
        expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');

        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          factory AliasHolder.fromSimple(String? value, {required bool explode}) {
            throw SimpleDecodingException(
              'Simple encoding not supported for AliasHolder: contains complex types',
            );
          }
        ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('fromSimple throws for mixed simple and complex properties', () {
      final complexModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );
      final model = ClassModel(
        isDeprecated: false,
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
            model: complexModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );
      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');

      const expectedMethod = '''
        factory User.fromSimple(String? value, {required bool explode}) {
          throw SimpleDecodingException(
            'Simple encoding not supported for User: contains complex types',
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple for Uri property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'endpoint',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory Resource.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'endpoint'},
            listKeys: {},
            context: r'Resource',
          );
          return Resource(
            endpoint: values[r'endpoint'].decodeSimpleUri(
              context: r'Resource.endpoint',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple for nullable Uri property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'callback',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory Resource.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'callback'},
            listKeys: {},
            context: r'Resource',
          );
          return Resource(
            callback: values[r'callback'].decodeSimpleNullableUri(
              context: r'Resource.callback',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple for mixed Uri and primitive properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'endpoint',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'port',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'callback',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final fromSimpleConstructor = generatedClass.constructors.firstWhere(
        (c) => c.name == 'fromSimple',
      );

      expect(fromSimpleConstructor.factory, isTrue);
      expect(fromSimpleConstructor.requiredParameters.length, 1);
      expect(fromSimpleConstructor.requiredParameters[0].name, 'value');
      expect(
        fromSimpleConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromSimpleConstructor.optionalParameters.length, 1);
      expect(fromSimpleConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromSimpleConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromSimpleConstructor.optionalParameters[0].required, isTrue);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        factory Resource.fromSimple(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: ',',
            expectedKeys: {r'name', r'endpoint', r'port', r'callback'},
            listKeys: {},
            context: r'Resource',
          );
          return Resource(
            name: values[r'name'].decodeSimpleString(context: r'Resource.name'),
            endpoint: values[r'endpoint'].decodeSimpleUri(
              context: r'Resource.endpoint',
            ),
            port: values[r'port'].decodeSimpleInt(context: r'Resource.port'),
            callback: values[r'callback'].decodeSimpleNullableUri(
              context: r'Resource.callback',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('ClassGenerator toSimple generation', () {
    test('generates toSimple for class with only simple properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toSimpleMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toSimple',
      );

      expect(toSimpleMethod.returns?.accept(emitter).toString(), 'String');
      expect(toSimpleMethod.optionalParameters, hasLength(2));
      expect(
        toSimpleMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );
      expect(
        toSimpleMethod.optionalParameters.every((p) => p.required),
        isTrue,
      );

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toSimple for class with complex properties',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ComplexClass',
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
                isDeprecated: false,
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
        final toSimpleMethod = generatedClass.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );

        expect(toSimpleMethod.returns?.accept(emitter).toString(), 'String');

        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates toSimple for empty class', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'EmptyClass',
        properties: const [],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toSimpleMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toSimple',
      );

      expect(toSimpleMethod.returns?.accept(emitter).toString(), 'String');

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
