import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/typedef_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

void main() {
  group('TypedefGenerator', () {
    late TypedefGenerator generator;
    late NameManger nameManager;
    late PropertyNameNormalizer propertyNameNormalizer;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;
    const package = 'test_package';

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManger(generator: nameGenerator);
      propertyNameNormalizer = PropertyNameNormalizer();
      generator = TypedefGenerator(
        nameManger: nameManager,
        propertyNameNormalizer: propertyNameNormalizer,
        package: package,
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('generates typedef for primitive types', () {
      final model = AliasModel(
        name: 'UserId',
        model: StringModel(context: context),
        context: context,
      );

      final result = generator.generateAlias(model);
      final typedef = generator.generateAliasTypedef(model);

      expect(result.filename, 'user_id.dart');
      expect(
        typedef.accept(emitter).toString().trim(),
        'typedef UserId = String;',
      );
    });

    test('generates typedef for list types', () {
      final model = AliasModel(
        name: 'UserIds',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        context: context,
      );

      final result = generator.generateAlias(model);
      final typedef = generator.generateAliasTypedef(model);

      expect(result.filename, 'user_ids.dart');
      expect(
        typedef.accept(emitter).toString().trim(),
        'typedef UserIds = List<String>;',
      );
    });

    test('generates typedef for named models', () {
      final userModel = ClassModel(
        name: 'User',
        properties: const {},
        context: context,
      );

      final model = AliasModel(
        name: 'UserReference',
        model: userModel,
        context: context,
      );

      final result = generator.generateAlias(model);
      final typedef = generator.generateAliasTypedef(model);

      expect(result.filename, 'user_reference.dart');
      expect(
        typedef.accept(emitter).toString().trim(),
        'typedef UserReference = User;',
      );
    });

    test('generates typedef for nested list types', () {
      final model = AliasModel(
        name: 'Matrix',
        model: ListModel(
          content: ListModel(
            content: IntegerModel(context: context),
            context: context,
          ),
          context: context,
        ),
        context: context,
      );

      final result = generator.generateAlias(model);
      final typedef = generator.generateAliasTypedef(model);

      expect(result.filename, 'matrix.dart');
      expect(
        typedef.accept(emitter).toString().trim(),
        'typedef Matrix = List<List<int>>;',
      );
    });

    test('generates typedef for all primitive types', () {
      final primitiveTypes = [
        (model: StringModel(context: context), expectedType: 'String'),
        (model: IntegerModel(context: context), expectedType: 'int'),
        (model: DoubleModel(context: context), expectedType: 'double'),
        (model: NumberModel(context: context), expectedType: 'num'),
        (model: BooleanModel(context: context), expectedType: 'bool'),
        (model: DateTimeModel(context: context), expectedType: 'DateTime'),
        (model: DateModel(context: context), expectedType: 'DateTime'),
        (model: DecimalModel(context: context), expectedType: 'BigDecimal'),
      ];

      for (final (index, type) in primitiveTypes.indexed) {
        final model = AliasModel(
          name: 'TestType$index',
          model: type.model,
          context: context,
        );

        final typedef = generator.generateAliasTypedef(model);
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef TestType$index = ${type.expectedType};',
        );
      }
    });

    group('generateFromList', () {
      test('generates typedef for list of primitive types', () {
        final model = ListModel(
          name: 'StringList',
          content: StringModel(context: context),
          context: context,
        );

        final result = generator.generateList(model);
        final typedef = generator.generateListTypedef(model);

        expect(result.filename, 'string_list.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef StringList = List<String>;',
        );
      });

      test('generates typedef for list of lists', () {
        final model = ListModel(
          name: 'Matrix',
          content: ListModel(
            content: IntegerModel(context: context),
            context: context,
          ),
          context: context,
        );

        final result = generator.generateList(model);
        final typedef = generator.generateListTypedef(model);

        expect(result.filename, 'matrix.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef Matrix = List<List<int>>;',
        );
      });

      test('generates typedef for list of named models', () {
        final userModel = ClassModel(
          name: 'User',
          properties: const {},
          context: context,
        );

        final model = ListModel(
          name: 'UserList',
          content: userModel,
          context: context,
        );

        final result = generator.generateList(model);
        final typedef = generator.generateListTypedef(model);

        expect(result.filename, 'user_list.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef UserList = List<User>;',
        );
      });

      test('uses Anonymous when no name is provided', () {
        final model = ListModel(
          content: StringModel(context: context),
          context: context,
        );

        final result = generator.generateList(model);
        final typedef = generator.generateListTypedef(model);

        expect(result.filename, 'anonymous.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef Anonymous = List<String>;',
        );
      });
    });
  });
}
