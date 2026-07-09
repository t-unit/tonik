import 'package:code_builder/code_builder.dart';
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

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = ClassGenerator(
      nameManager: nameManager,
      package: 'example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ClassGenerator copyWith generation', () {
    test('does not generate copyWith for empty class', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Empty',
        properties: const [],
        context: context,
        examples: const [],
      );

      final generatedSpecs = generator.generateClasses(model);
      expect(generatedSpecs.length, 1);
      final mainClass = generatedSpecs[0] as Class;
      final hasCopyWith = mainClass.methods.any((m) => m.name == 'copyWith');
      expect(hasCopyWith, isFalse);
    });

    test('generates freezed-like copyWith for simple properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedSpecs = generator.generateClasses(model);
      expect(generatedSpecs.length, 3);
      final mainClass = generatedSpecs[0] as Class;
      final copyWithGetter = mainClass.methods.firstWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWithGetter.type, MethodType.getter);
      expect(
        copyWithGetter.returns?.accept(emitter).toString(),
        r'$$UserCopyWith<User>',
      );
      expect(copyWithGetter.lambda, isTrue);
      expect(
        copyWithGetter.body?.accept(emitter).toString(),
        '_UserCopyWith(this)',
      );
      final interfaceClass = generatedSpecs[1] as Class;
      expect(interfaceClass.name, r'$$UserCopyWith');
      expect(interfaceClass.abstract, isTrue);
      expect(interfaceClass.types.length, 1);
      expect(interfaceClass.types.first.symbol, r'$Res');
      final interfaceFactory = interfaceClass.constructors.firstWhere(
        (c) => c.factory,
      );
      expect(interfaceFactory.requiredParameters.length, 1);
      expect(interfaceFactory.requiredParameters.first.name, 'value');
      expect(
        interfaceFactory.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'User',
      );
      final callMethod = interfaceClass.methods.firstWhere(
        (m) => m.name == 'call',
      );
      expect(callMethod.optionalParameters.length, 2);
      expect(callMethod.optionalParameters[0].name, 'name');
      expect(
        callMethod.optionalParameters[0].type?.accept(emitter).toString(),
        'String?',
      );
      expect(callMethod.optionalParameters[1].name, 'age');
      expect(
        callMethod.optionalParameters[1].type?.accept(emitter).toString(),
        'int?',
      );
      final nameGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'name',
      );
      expect(nameGetter.type, MethodType.getter);
      expect(nameGetter.returns?.accept(emitter).toString(), 'String');

      final ageGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'age',
      );
      expect(ageGetter.type, MethodType.getter);
      expect(ageGetter.returns?.accept(emitter).toString(), 'int');
      final implClass = generatedSpecs[2] as Class;
      expect(implClass.name, '_UserCopyWith');
      expect(implClass.implements.length, 1);
      expect(
        implClass.implements.first.accept(emitter).toString(),
        r'$$UserCopyWith<$Res>',
      );
      final sentinelField = implClass.fields.firstWhere(
        (f) => f.name == '_sentinel',
      );
      expect(sentinelField.static, isTrue);
      expect(sentinelField.modifier, FieldModifier.constant);
      final valueField = implClass.fields.firstWhere(
        (f) => f.name == '_value',
      );
      expect(valueField.modifier, FieldModifier.final$);
      expect(valueField.type?.accept(emitter).toString(), 'User');
      final implCallMethod = implClass.methods.firstWhere(
        (m) => m.name == 'call',
      );
      const expectedCallMethod = r'''
        @override
        $Res call({Object? name = _sentinel, Object? age = _sentinel, }) {
          return (User(name: identical(name, _sentinel, ) ? this.name : (name as String),
            age: identical(age, _sentinel, ) ? this.age : (age as int),
          ) as $Res);
        }
      ''';
      expect(
        collapseWhitespace(implCallMethod.accept(emitter).toString()),
        collapseWhitespace(expectedCallMethod),
      );
    });

    test('generates copyWith with nullable properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'bio',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedSpecs = generator.generateClasses(model);
      final interfaceClass = generatedSpecs[1] as Class;
      final bioGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'bio',
      );
      expect(bioGetter.type, MethodType.getter);
      expect(bioGetter.returns?.accept(emitter).toString(), 'String?');
      final implClass = generatedSpecs[2] as Class;
      final implCallMethod = implClass.methods.firstWhere(
        (m) => m.name == 'call',
      );
      const expectedCallMethod = r'''
        @override
        $Res call({Object? name = _sentinel, Object? bio = _sentinel, }) {
          return (User(name: identical(name, _sentinel, ) ? this.name : (name as String),
            bio: identical(bio, _sentinel, ) ? this.bio : (bio as String?),
          ) as $Res);
        }
      ''';
      expect(
        collapseWhitespace(implCallMethod.accept(emitter).toString()),
        collapseWhitespace(expectedCallMethod),
      );
    });

    test('generates copyWith with complex types', () {
      final addressModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: [
          Property(
            name: 'street',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'homeAddress',
            model: addressModel,
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'workAddress',
            model: addressModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedSpecs = generator.generateClasses(model);
      final interfaceClass = generatedSpecs[1] as Class;
      final homeAddressGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'homeAddress',
      );
      expect(homeAddressGetter.returns?.accept(emitter).toString(), 'Address?');

      final workAddressGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'workAddress',
      );
      expect(workAddressGetter.returns?.accept(emitter).toString(), 'Address');
      final implClass = generatedSpecs[2] as Class;
      final implCallMethod = implClass.methods.firstWhere(
        (m) => m.name == 'call',
      );
      const expectedCallMethod = r'''
        @override
        $Res call({Object? name = _sentinel,
          Object? homeAddress = _sentinel,
          Object? workAddress = _sentinel,
        }) {
          return (User(name: identical(name, _sentinel, ) ? this.name : (name as String),
            homeAddress: identical(homeAddress, _sentinel, ) ? this.homeAddress : (homeAddress as Address?),
            workAddress: identical(workAddress, _sentinel, ) ? this.workAddress : (workAddress as Address),
          ) as $Res);
        }
      ''';
      expect(
        collapseWhitespace(implCallMethod.accept(emitter).toString()),
        collapseWhitespace(expectedCallMethod),
      );
    });

    test('generates copyWith with list types', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'optionalTags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedSpecs = generator.generateClasses(model);
      final interfaceClass = generatedSpecs[1] as Class;
      final tagsGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'tags',
      );
      expect(tagsGetter.returns?.accept(emitter).toString(), 'List<String>');

      final optionalTagsGetter = interfaceClass.methods.firstWhere(
        (m) => m.name == 'optionalTags',
      );
      expect(
        optionalTagsGetter.returns?.accept(emitter).toString(),
        'List<String>?',
      );
      final implClass = generatedSpecs[2] as Class;
      final implCallMethod = implClass.methods.firstWhere(
        (m) => m.name == 'call',
      );
      const expectedCallMethod = r'''
        @override
        $Res call({Object? tags = _sentinel,
          Object? optionalTags = _sentinel,
        }) {
          return (User(tags: identical(tags, _sentinel, ) ? this.tags : (tags as List<String>),
            optionalTags: identical(optionalTags, _sentinel, ) ? this.optionalTags : (optionalTags as List<String>?),
          ) as $Res);
        }
      ''';
      expect(
        collapseWhitespace(implCallMethod.accept(emitter).toString()),
        collapseWhitespace(expectedCallMethod),
      );
    });

    test('generates copyWith with normalized property names', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'first-name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'last_name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: '_id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedSpecs = generator.generateClasses(model);
      final interfaceClass = generatedSpecs[1] as Class;
      final getterNames = interfaceClass.methods
          .where((m) => m.type == MethodType.getter)
          .map((m) => m.name)
          .toList();
      expect(getterNames, containsAll(['firstName', 'lastName', 'id']));
      final implClass = generatedSpecs[2] as Class;
      final implCallMethod = implClass.methods.firstWhere(
        (m) => m.name == 'call',
      );
      const expectedCallMethod = r'''
        @override
        $Res call({Object? firstName = _sentinel,
          Object? lastName = _sentinel,
          Object? id = _sentinel,
        }) {
          return (User(firstName: identical(firstName, _sentinel, ) ? this.firstName : (firstName as String),
            lastName: identical(lastName, _sentinel, ) ? this.lastName : (lastName as String),
            id: identical(id, _sentinel, ) ? this.id : (id as String),
          ) as $Res);
        }
      ''';
      expect(
        collapseWhitespace(implCallMethod.accept(emitter).toString()),
        collapseWhitespace(expectedCallMethod),
      );
    });
  });
}
