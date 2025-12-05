import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('TypedefGenerator', () {
    late TypedefGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;
    const package = 'test_package';

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = TypedefGenerator(nameManager: nameManager, package: package);
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
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
        description: null,
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
        (model: DateModel(context: context), expectedType: 'Date'),
        (model: DecimalModel(context: context), expectedType: 'BigDecimal'),
        (model: UriModel(context: context), expectedType: 'Uri'),
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

    group('Uri typedef generation', () {
      test('generates typedef for Uri type', () {
        final model = AliasModel(
          name: 'ApiEndpoint',
          model: UriModel(context: context),
          context: context,
        );

        final result = generator.generateAlias(model);
        final typedef = generator.generateAliasTypedef(model);

        expect(result.filename, 'api_endpoint.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef ApiEndpoint = Uri;',
        );
      });

      test('generates typedef for required Uri type', () {
        final model = AliasModel(
          name: 'RequiredEndpoint',
          model: UriModel(context: context),
          context: context,
        );

        final typedef = generator.generateAliasTypedef(model);

        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef RequiredEndpoint = Uri;',
        );
      });

      test('generates typedef for list of URIs', () {
        final model = AliasModel(
          name: 'EndpointList',
          model: ListModel(
            content: UriModel(context: context),
            context: context,
          ),
          context: context,
        );

        final result = generator.generateAlias(model);
        final typedef = generator.generateAliasTypedef(model);

        expect(result.filename, 'endpoint_list.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef EndpointList = List<Uri>;',
        );
      });

      test('generates typedef for nested list of URIs', () {
        final model = AliasModel(
          name: 'EndpointMatrix',
          model: ListModel(
            content: ListModel(
              content: UriModel(context: context),
              context: context,
            ),
            context: context,
          ),
          context: context,
        );

        final result = generator.generateAlias(model);
        final typedef = generator.generateAliasTypedef(model);

        expect(result.filename, 'endpoint_matrix.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef EndpointMatrix = List<List<Uri>>;',
        );
      });
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
          properties: const [],
          context: context,
          description: null,
          isDeprecated: false,
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

        expect(result.filename, 'anonymous_model.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef AnonymousModel = List<String>;',
        );
      });

      test('generates typedef for list of URIs', () {
        final model = ListModel(
          name: 'UriList',
          content: UriModel(context: context),
          context: context,
        );

        final result = generator.generateList(model);
        final typedef = generator.generateListTypedef(model);

        expect(result.filename, 'uri_list.dart');
        expect(
          typedef.accept(emitter).toString().trim(),
          'typedef UriList = List<Uri>;',
        );
      });
    });
  });
}
