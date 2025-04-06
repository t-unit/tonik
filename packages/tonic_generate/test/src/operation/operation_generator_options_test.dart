import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/operation/operation_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
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

  group('generateOptionsMethod', () {
    test('returns Options with GET method for GET operation', () {
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
          Options _options() {
            return Options(method: 'GET');
          }
        ''';

      final method = generator.generateOptionsMethod(operation);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(methodString, contains("method: 'GET'"));

      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('returns Options with POST method for POST operation', () {
      final operation = Operation(
        operationId: 'createUser',
        context: context,
        summary: 'Create user',
        description: 'Creates a new user',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.post,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options() {
            return Options(method: 'POST');
          }
        ''';

      final method = generator.generateOptionsMethod(operation);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(methodString, contains("method: 'POST'"));

      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('includes headers when operation has headers', () {
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
          Options _options({required String xMyHeader}) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            
            if (xMyHeader.isNotEmpty) {
              headers['X-My-Header'] = headerEncoder.encode(xMyHeader);
            }

            return Options(method: 'GET', headers: headers);
          }
        ''';

      final method = generator.generateOptionsMethod(operation);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), 'Options');

      expect(method.optionalParameters, hasLength(1));
      expect(method.optionalParameters.first.name, 'xMyHeader');

      expect(method.optionalParameters.first.type?.symbol, 'String');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles headers with different types and requirements', () {
      // Required string header that doesn't allow empty values
      final requiredStringHeader = RequestHeaderObject(
        name: 'X-Required-String',
        rawName: 'X-Required-String',
        description: 'A required string header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Required date header that allows empty values
      final requiredDateHeader = RequestHeaderObject(
        name: 'X-Required-Date',
        rawName: 'X-Required-Date',
        description: 'A required date header that allows empty values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        model: DateTimeModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Optional boolean header
      final optionalBoolHeader = RequestHeaderObject(
        name: 'X-Optional-Bool',
        rawName: 'X-Optional-Bool',
        description: 'An optional boolean header',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: BooleanModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Optional list header
      final optionalListHeader = RequestHeaderObject(
        name: 'X-Optional-List',
        rawName: 'X-Optional-List',
        description: 'An optional list of strings header',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: true,
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'operationWithComplexHeaders',
        context: context,
        summary: 'Operation with complex headers',
        description:
            'An operation that has headers of different '
            'types and requirements',
        tags: const {},
        isDeprecated: false,
        path: '/with-complex-headers',
        method: HttpMethod.get,
        headers: {
          requiredStringHeader,
          requiredDateHeader,
          optionalBoolHeader,
          optionalListHeader,
        },
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options({
            required String xRequiredString,
            required DateTime xRequiredDate,
            bool? xOptionalBool,
            List<String>? xOptionalList,
          }) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            
            if (xRequiredString.isNotEmpty) {
              headers['X-Required-String'] = headerEncoder.encode(xRequiredString);
            }
            
            headers['X-Required-Date'] = headerEncoder.encode(xRequiredDate);
            
            if (xOptionalBool != null) {
              headers['X-Optional-Bool'] = headerEncoder.encode(xOptionalBool);
            }
            
            if (xOptionalList != null) {
              headers['X-Optional-List'] = headerEncoder.encode(
                xOptionalList,
                explode: true,
              );
            }

            return Options(method: 'GET', headers: headers);
          }
        ''';

      final method = generator.generateOptionsMethod(operation);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), 'Options');

      // Verify parameters
      expect(method.optionalParameters, hasLength(4));

      // Check required string parameter
      final stringParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'xRequiredString',
      );
      expect(stringParam.type?.accept(emitter).toString(), 'String');
      expect(stringParam.named, isTrue);
      expect(stringParam.required, isTrue);

      // Check required date parameter
      final dateParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'xRequiredDate',
      );
      expect(dateParam.type?.accept(emitter).toString(), 'DateTime');
      expect(dateParam.named, isTrue);
      expect(dateParam.required, isTrue);

      // Check optional bool parameter
      final boolParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'xOptionalBool',
      );
      expect(boolParam.type?.accept(emitter).toString(), 'bool?');
      expect(boolParam.named, isTrue);
      expect(boolParam.required, isFalse);

      // Check optional list parameter
      final listParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'xOptionalList',
      );
      expect(listParam.type?.accept(emitter).toString(), 'List<String>?');
      expect(listParam.named, isTrue);
      expect(listParam.required, isFalse);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles header aliases', () {
      // Create a base header
      final baseHeader = RequestHeaderObject(
        name: 'X-Base-Header',
        rawName: 'X-Base-Header',
        description: 'A base header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Create an alias for the base header
      final aliasHeader = RequestHeaderAlias(
        name: 'X-Alias-Header',
        header: baseHeader,
        context: context,
      );

      final operation = Operation(
        operationId: 'operationWithHeaderAlias',
        context: context,
        summary: 'Operation with header alias',
        description: 'An operation that uses a header alias',
        tags: const {},
        isDeprecated: false,
        path: '/with-alias-header',
        method: HttpMethod.get,
        headers: {aliasHeader},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options({required String xAliasHeader}) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            
            if (xAliasHeader.isNotEmpty) {
              headers['X-Base-Header'] = headerEncoder.encode(xAliasHeader);
            }

            return Options(method: 'GET', headers: headers);
          }
        ''';

      final method = generator.generateOptionsMethod(operation);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), 'Options');

      // Verify parameters - should use the alias name, not the base name
      expect(method.optionalParameters, hasLength(1));
      final param = method.optionalParameters.first;
      expect(param.name, 'xAliasHeader');
      expect(param.type?.accept(emitter).toString(), 'String');
      expect(param.named, isTrue);
      expect(param.required, isTrue);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles deeply nested header aliases', () {
      // Create a base header
      final baseHeader = RequestHeaderObject(
        name: 'X-Base-Header',
        rawName: 'X-Base-Header',
        description: 'A base header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      // Create nested aliases (three levels deep)
      final firstLevelAlias = RequestHeaderAlias(
        name: 'X-First-Level',
        header: baseHeader,
        context: context,
      );

      final secondLevelAlias = RequestHeaderAlias(
        name: 'X-Second-Level',
        header: firstLevelAlias,
        context: context,
      );

      final thirdLevelAlias = RequestHeaderAlias(
        name: 'X-Third-Level',
        header: secondLevelAlias,
        context: context,
      );

      final operation = Operation(
        operationId: 'operationWithNestedHeaderAlias',
        context: context,
        summary: 'Operation with nested header alias',
        description: 'An operation that uses a deeply nested header alias',
        tags: const {},
        isDeprecated: false,
        path: '/with-nested-alias',
        method: HttpMethod.get,
        headers: {thirdLevelAlias},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
          Options _options({required String xThirdLevel}) {
            final headers = <String, dynamic>{};
            const headerEncoder = SimpleEncoder();
            
            if (xThirdLevel.isNotEmpty) {
              headers['X-Base-Header'] = headerEncoder.encode(xThirdLevel);
            }

            return Options(method: 'GET', headers: headers);
          }
        ''';

      final method = generator.generateOptionsMethod(operation);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), 'Options');

      // Verify parameters - should use the top-level alias name
      expect(method.optionalParameters, hasLength(1));
      final param = method.optionalParameters.first;
      expect(param.name, 'xThirdLevel');
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
}
