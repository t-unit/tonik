import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

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
    generator = ClassGenerator(nameManager: nameManager, package: 'example');
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

    test('generates typed copyWith for simple properties', () {
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
      expect(generatedSpecs, hasLength(1));
      final mainClass = generatedSpecs.single as Class;
      final copyWith = mainClass.methods.singleWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'User');
      const expectedCopyWith = '''
        User Function({String? name, int? age}) get copyWith {
          return ({String? name, int? age, }) => User(name: name ?? this.name,
            age: age ?? this.age,
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expectedCopyWith)),
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
      expect(generatedSpecs, hasLength(1));
      final mainClass = generatedSpecs.single as Class;
      final copyWith = mainClass.methods.singleWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'User');
      const expectedCopyWith = '''
        User Function({String? name, String? bio}) get copyWith {
          const Object _sentinel = Object();
          return ({String? name, Object? bio = _sentinel, }) => User(name: name ?? this.name,
            bio: identical(bio, _sentinel, ) ? this.bio : (bio as String?),
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expectedCopyWith)),
      );
    });

    test('preserves nullable typedef semantics for required properties', () {
      final nullableName = AliasModel(
        name: 'NullableName',
        model: StringModel(context: context),
        isNullable: true,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final anyValue = AliasModel(
        name: 'AnyValue',
        model: AnyModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: nullableName,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'data',
            model: anyValue,
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

      final generated = generator.generateClasses(model).single as Class;
      final copyWith = generated.methods.singleWhere(
        (method) => method.name == 'copyWith',
      );
      const expected = '''
        User Function({NullableName? name, AnyValue? data}) get copyWith {
          const Object _sentinel = Object();
          return ({Object? name = _sentinel, Object? data = _sentinel}) =>
            User(
              name: identical(name, _sentinel) ? this.name : (name as NullableName),
              data: identical(data, _sentinel) ? this.data : data,
            );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
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
      expect(generatedSpecs, hasLength(1));
      final mainClass = generatedSpecs.single as Class;
      final copyWith = mainClass.methods.singleWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'User');
      const expectedCopyWith = '''
        User Function({String? name, Address? homeAddress, Address? workAddress}) get copyWith {
          const Object _sentinel = Object();
          return ({String? name,
          Object? homeAddress = _sentinel,
          Address? workAddress,
        }) => User(name: name ?? this.name,
            homeAddress: identical(homeAddress, _sentinel, ) ? this.homeAddress : (homeAddress as Address?),
            workAddress: workAddress ?? this.workAddress,
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expectedCopyWith)),
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
      expect(generatedSpecs, hasLength(1));
      final mainClass = generatedSpecs.single as Class;
      final copyWith = mainClass.methods.singleWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'User');
      const expectedCopyWith = '''
        User Function({List<String>? tags, List<String>? optionalTags}) get copyWith {
          const Object _sentinel = Object();
          return ({List<String>? tags,
          Object? optionalTags = _sentinel,
        }) => User(tags: tags ?? this.tags,
            optionalTags: identical(optionalTags, _sentinel, ) ? this.optionalTags : (optionalTags as List<String>?),
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expectedCopyWith)),
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
      expect(generatedSpecs, hasLength(1));
      final mainClass = generatedSpecs.single as Class;
      final copyWith = mainClass.methods.singleWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'User');
      const expectedCopyWith = '''
        User Function({String? firstName, String? lastName, String? id}) get copyWith {
          return ({String? firstName,
          String? lastName,
          String? id,
        }) => User(firstName: firstName ?? this.firstName,
            lastName: lastName ?? this.lastName,
            id: id ?? this.id,
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expectedCopyWith)),
      );
    });

    test('escapes call property in copyWith', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Widget',
        properties: [
          Property(
            name: 'call',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'name',
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
      expect(generatedSpecs, hasLength(1));
      final mainClass = generatedSpecs.single as Class;
      final copyWith = mainClass.methods.singleWhere(
        (m) => m.name == 'copyWith',
      );
      expect(copyWith.type, MethodType.getter);
      final functionType = copyWith.returns! as FunctionType;
      expect(functionType.returnType?.symbol, 'Widget');
      const expectedCopyWith = r'''
        Widget Function({String? $call, String? name}) get copyWith {
          return ({String? $call, String? name, }) => Widget($call: $call ?? this.$call,
            name: name ?? this.name,
          );
        }
      ''';
      expect(
        collapseWhitespace(format(copyWith.accept(emitter).toString())),
        collapseWhitespace(format(expectedCopyWith)),
      );
    });
  });
}
