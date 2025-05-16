import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ApiClientGenerator generator;
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;

  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ApiClientGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ApiClientGenerator', () {
    group('class generation', () {
      test('generates API client class for a tag', () {
        final operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {const Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          requestBody: null,
        );

        final generatedClass = generator.generateClass({
          operation,
        }, const Tag(name: 'users'),);

        // Test class definition
        expect(generatedClass.name, 'UsersApi');
        expect(generatedClass.fields.length, 1);
        expect(generatedClass.fields.first.name, '_dio');
        expect(
          generatedClass.fields.first.type?.accept(emitter).toString(),
          'Dio',
        );

        // Test constructor
        final constructor = generatedClass.constructors.first;
        expect(constructor.requiredParameters.length, 1);
        expect(constructor.requiredParameters.first.name, '_dio');
        expect(constructor.requiredParameters.first.toThis, isTrue);
      });
    });

    group('method generation', () {
      late Class generatedClass;
      late Operation operation;

      setUp(() {
        operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {const Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          requestBody: null,
        );

        generatedClass = generator.generateClass({
          operation,
        }, const Tag(name: 'users'),);
      });

      test('generates method with correct signature', () {
        final method = generatedClass.methods.first;
        expect(method.name, 'getUser');
        expect(method.modifier, MethodModifier.async);
        expect(
          method.returns?.accept(emitter).toString(),
          'Future<TonikResult<void>>',
        );
      });

      test('generates method body with operation call', () {
        final generatedCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
          Future<TonikResult<void>> getUser() async => GetUser(_dio).call();
        ''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    test('generates ready-to-use code and filename', () {
      final operation = Operation(
        operationId: 'getUser',
        context: testContext,
        summary: 'Get user',
        description: 'Get user by ID',
        tags: {const Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final result = generator.generate({operation}, const Tag(name: 'users'));

      expect(result.filename, 'users_api.dart');
      expect(result.code, contains('class UsersApi'));
      expect(result.code, contains('final _i1.Dio _dio;'));
      expect(
        result.code,
        contains('_i2.Future<_i3.TonikResult<void>> getUser()'),
      );
    });
  });
}
