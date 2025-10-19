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
      const expectedMethod = r'''
        factory Sample.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for Sample');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return Sample(
            flag: values['flag'].decodeSimpleBool(context: r'Sample.flag'),
            count: values['count'].decodeSimpleInt(context: r'Sample.count'),
            label: values['label'].decodeSimpleString(context: r'Sample.label'),
            created: values['created'].decodeSimpleDateTime(
              context: r'Sample.created',
            ),
            amount: values['amount'].decodeSimpleBigDecimal(
              context: r'Sample.amount',
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
      const expectedMethod = r'''
        factory Order.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for Order');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return Order(status: Status.fromSimple(values['status'], explode: explode));
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
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
      const expectedMethod = r'''
        factory NullableSample.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for NullableSample');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return NullableSample(
            flag: values['flag'].decodeSimpleNullableBool(
              context: r'NullableSample.flag',
            ),
            count: values['count'].decodeSimpleNullableInt(
              context: r'NullableSample.count',
            ),
            label: values['label'].decodeSimpleNullableString(
              context: r'NullableSample.label',
            ),
            created: values['created'].decodeSimpleNullableDateTime(
              context: r'NullableSample.created',
            ),
            amount: values['amount'].decodeSimpleNullableBigDecimal(
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
        const expectedMethod = r'''
          factory Container.fromSimple(String? value, {required bool explode}) {
            if (value == null || value.isEmpty) {
              throw SimpleDecodingException('Invalid empty value for Container');
            }
            final values = <String, String>{};
            if (explode) {
              final pairs = value.split(',');
              for (final pair in pairs) {
                final parts = pair.split('=');
                if (parts.length != 2) {
                  throw SimpleDecodingException('Invalid key=value pair format: $pair');
                }
                values[Uri.decodeComponent(parts[0])] = parts[1];
              }
            } else {
              final parts = value.split(',');
              if (parts.length % 2 != 0) {
                throw SimpleDecodingException(
                  'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
                );
              }
              for (var i = 0; i < parts.length; i += 2) {
                values[Uri.decodeComponent(parts[i])] = parts[i + 1];
              }
            }
            return Container(
              value: PrimitiveOneOf.fromSimple(values['value'], explode: explode),
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
      'generates fromSimple constructor that throws for OneOf model with '
      'unsupported type',
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
            throw EncodingException(
              'Simple encoding not supported for Container: contains complex types',
            );
          }
        ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
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

      // Verify the generated method uses the new DRY structure
      final classCode = format(generatedClass.accept(emitter).toString());
      expect(
        classCode,
        contains(
          '''factory UserIdHolder.fromSimple(String? value, {required bool explode})''',
        ),
      );
      expect(classCode, contains('final values = <String, String>{};'));
      expect(classCode, contains('if (explode)'));
      expect(classCode, contains('Uri.decodeComponent(parts[0])'));
      expect(
        classCode,
        contains(
          '''
return UserIdHolder(
      id: values['id'].decodeSimpleInt(context: r'UserIdHolder.id'),
    );''',
        ),
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
      const expectedMethod = r'''
        factory AliasHolder.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for AliasHolder');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return AliasHolder(
            value: PrimitiveOneOf.fromSimple(values['value'], explode: explode),
          );
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates fromSimple constructor that throws for Alias targeting class',
      () {
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
          throw EncodingException(
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
      'generates fromSimple constructor that throws for Alias targeting list',
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
          throw EncodingException(
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

    test('fromSimple handles unsupported complex properties', () {
      final complexModel = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
      );
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
          throw EncodingException(
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
      const expectedMethod = r'''
        factory Resource.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for Resource');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return Resource(
            endpoint: values['endpoint'].decodeSimpleUri(
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
      const expectedMethod = r'''
        factory Resource.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for Resource');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return Resource(
            callback: values['callback'].decodeSimpleNullableUri(
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
      const expectedMethod = r'''
        factory Resource.fromSimple(String? value, {required bool explode}) {
          if (value == null || value.isEmpty) {
            throw SimpleDecodingException('Invalid empty value for Resource');
          }
          final values = <String, String>{};
          if (explode) {
            final pairs = value.split(',');
            for (final pair in pairs) {
              final parts = pair.split('=');
              if (parts.length != 2) {
                throw SimpleDecodingException('Invalid key=value pair format: $pair');
              }
              values[Uri.decodeComponent(parts[0])] = parts[1];
            }
          } else {
            final parts = value.split(',');
            if (parts.length % 2 != 0) {
              throw SimpleDecodingException(
                'Invalid alternating key-value format: expected even number of parts, got ${parts.length}',
              );
            }
            for (var i = 0; i < parts.length; i += 2) {
              values[Uri.decodeComponent(parts[i])] = parts[i + 1];
            }
          }
          return Resource(
            name: values['name'].decodeSimpleString(context: r'Resource.name'),
            endpoint: values['endpoint'].decodeSimpleUri(
              context: r'Resource.endpoint',
            ),
            port: values['port'].decodeSimpleInt(context: r'Resource.port'),
            callback: values['callback'].decodeSimpleNullableUri(
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
          ).toSimple(explode: explode, allowEmpty: allowEmpty);
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
          ).toSimple(explode: explode, allowEmpty: allowEmpty);
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
          ).toSimple(explode: explode, allowEmpty: allowEmpty);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
