import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/operation/operation_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/parameter_name_normalizer.dart';

void main() {
  group('OperationGenerator', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    group('generatePathMethod', () {
      test('returns path for operation without parameters', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          String _path() {
            return '/users';
          }
        ''';

        final method = generator.generatePathMethod(operation, []);

        expect(method, isA<Method>());
        expect(method.returns?.symbol, 'String');
        expect(method.requiredParameters, isEmpty);
        expect(method.optionalParameters, isEmpty);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });
    });

    group('generateDataMethod', () {
      test('returns null for operation without request body', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Object? _data() {
            return null;
          }
        ''';

        final method = generator.generateDataMethod(operation);

        expect(method, isA<Method>());
        expect(method.returns?.symbol, 'Object?');
        expect(method.requiredParameters, isEmpty);
        expect(method.optionalParameters, isEmpty);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });
    });

    group('generateQueryParametersMethod', () {
      test('returns empty map for operation without query parameters', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Map<String, dynamic> _queryParameters() {
            return {};
          }
        ''';

        final method = generator.generateQueryParametersMethod(operation, []);

        expect(method, isA<Method>());

        final returnTypeString = method.returns?.accept(emitter).toString();
        expect(returnTypeString, contains('Map<String,dynamic>'));

        expect(method.requiredParameters, isEmpty);
        expect(method.optionalParameters, isEmpty);

        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      });
    });

    group('generateCallMethod', () {
      test('generates call method for operation without parameters', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Future<void> call() async {
            await _dio.request<dynamic>(
              _path(),
              data: _data(),
              queryParameters: _queryParameters(),
              options: _options(),
            );
          }
        ''';

        const normalizedParams = NormalizedRequestParameters(
          pathParameters: [],
          queryParameters: [],
          headers: [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());

        final returnTypeString = method.returns?.accept(emitter).toString();
        expect(returnTypeString, 'Future<void>');
        expect(method.modifier, MethodModifier.async);

        expect(method.name, 'call');
        expect(method.requiredParameters, isEmpty);
        expect(method.optionalParameters, isEmpty);

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test('generates call method with header parameters', () {
        final requestHeader = RequestHeaderObject(
          name: 'X-My-Header',
          rawName: 'X-My-Header',
          description: 'A custom header',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: StringModel(context: context),
          encoding: HeaderParameterEncoding.simple,
          context: context,
        );

        final operation = Operation(
          operationId: 'operationWithHeader',
          context: context,
          summary: 'Operation with header',
          description: 'An operation that requires a header',
          tags: const {},
          isDeprecated: false,
          path: '/with-header',
          method: HttpMethod.get,
          headers: {requestHeader},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        const expectedMethod = '''
          Future<void> call({required String xMyHeader}) async {
            await _dio.request<dynamic>(
              _path(),
              data: _data(),
              queryParameters: _queryParameters(),
              options: _options(xMyHeader: xMyHeader),
            );
          }
        ''';

        final normalizedParams = NormalizedRequestParameters(
          pathParameters: const [],
          queryParameters: const [],
          headers: [(normalizedName: 'xMyHeader', parameter: requestHeader)],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());
        expect(method.returns?.accept(emitter).toString(), 'Future<void>');
        expect(method.modifier, MethodModifier.async);
        expect(method.name, 'call');

        expect(method.optionalParameters, hasLength(1));
        final param = method.optionalParameters.first;
        expect(param.name, 'xMyHeader');
        expect(param.type?.accept(emitter).toString(), 'String');
        expect(param.named, isTrue);
        expect(param.required, isTrue);

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });
    });

    group('generateCallableOperation', () {
      test('generates snake_case filename from operation name', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
        );

        final result = generator.generateCallableOperation(operation);
        expect(result.filename, 'get_users.dart');
      });
    });
  });
}
