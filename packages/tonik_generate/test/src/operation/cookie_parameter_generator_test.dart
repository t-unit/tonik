import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/options_generator.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';

void main() {
  late OptionsGenerator optionsGenerator;
  late Context context;
  late DartEmitter emitter;
  late NameManager nameManager;
  late NameGenerator nameGenerator;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    optionsGenerator = OptionsGenerator(
      nameManager: nameManager,
      package: 'package:api/api.dart',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('Cookie parameter normalization', () {
    test('normalizes cookie parameter names', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {
          createCookieParameter('session_id'),
          createCookieParameter('user-token'),
        },
      );

      expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
        'sessionId',
        'userToken',
      ]);
    });

    test(
      'makes duplicates unique across parameter types including cookies',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {createPathParameter('id')},
          queryParameters: {createQueryParameter('id')},
          headers: {createHeader('id')},
          cookieParameters: {createCookieParameter('id')},
        );

        expect(result.pathParameters.map((r) => r.normalizedName).toList(), [
          'idPath',
        ]);
        expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
          'idQuery',
        ]);
        expect(result.headers.map((r) => r.normalizedName).toList(), [
          'idHeader',
        ]);
        expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
          'idCookie',
        ]);
      },
    );

    test('uses nameOverride for cookie parameters', () {
      final param = createCookieParameter('session_id')
        ..nameOverride = 'mySession';

      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {param},
      );

      expect(result.cookieParameters.first.normalizedName, 'mySession');
      expect(
        result.cookieParameters.first.parameter.rawName,
        'session_id',
        reason: 'Original raw name should be preserved for Cookie header',
      );
    });

    test('handles Dart keywords in cookie names', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {createCookieParameter('class')},
      );

      expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
        r'$class',
      ]);
    });

    test('preserves cookie parameter metadata', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {
          createCookieParameter(
            'session',
            isRequired: true,
            isDeprecated: true,
          ),
        },
      );

      expect(result.cookieParameters.first.parameter.isRequired, isTrue);
      expect(result.cookieParameters.first.parameter.isDeprecated, isTrue);
    });
  });

  group('Cookie parameter operation generation', () {
    test('generates method parameters for cookie parameters', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'sessionId',
            rawName: 'session_id',
            description: 'Session identifier',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
          CookieParameterObject(
            name: 'optionalCookie',
            rawName: 'optional_cookie',
            description: 'Optional cookie',
            isRequired: false,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 2);

      final requiredParam = parameters.firstWhere(
        (p) => p.name == 'sessionId',
      );
      expect(requiredParam.required, isTrue);
      expect(requiredParam.named, isTrue);

      final optionalParam = parameters.firstWhere(
        (p) => p.name == 'optionalCookie',
      );
      expect(optionalParam.required, isFalse);
      expect(optionalParam.named, isTrue);
    });

    test('generates deprecated annotation for deprecated cookie parameter', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'deprecatedCookie',
            rawName: 'deprecated_cookie',
            description: 'A deprecated cookie',
            isRequired: false,
            isDeprecated: true,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 1);
      expect(parameters.first.annotations.length, 1);

      // Use object introspection for annotation.
      final annotation = parameters.first.annotations.first;
      expect(annotation, isA<InvokeExpression>());
      final invoke = annotation as InvokeExpression;
      expect(invoke.target, isA<Reference>());
      final ref = invoke.target as Reference;
      expect(ref.symbol, 'Deprecated');
      expect(ref.url, 'dart:core');
    });
  });

  group('Cookie header generation in options', () {
    test('generates Cookie header for single required cookie', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'sessionId',
            rawName: 'session_id',
            description: 'Session identifier',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'sessionId', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has required parameter.
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'sessionId',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'String');

      // Check method body generates cookie header.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
              final cookieParts = <String>[];
              cookieParts.add(
                r'session_id=' + sessionId.toForm(explode: false, allowEmpty: true),
              );
              if (cookieParts.isNotEmpty) {
                headers[r'Cookie'] = cookieParts.join('; ');
              }
            '''),
        ),
      );
    });

    test('generates Cookie header for multiple cookies', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'sessionId',
            rawName: 'session_id',
            description: 'Session identifier',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
          CookieParameterObject(
            name: 'userId',
            rawName: 'user_id',
            description: 'User identifier',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map(
            (p) => (
              normalizedName: p.rawName == 'session_id'
                  ? 'sessionId'
                  : 'userId',
              parameter: p,
            ),
          )
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has both required parameters.
      expect(method.optionalParameters, hasLength(2));

      final sessionParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'sessionId',
      );
      expect(sessionParam.required, isTrue);

      final userParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'userId',
      );
      expect(userParam.required, isTrue);

      // Check method body generates multiple cookie parts.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
              final cookieParts = <String>[];
              cookieParts.add(
                r'session_id=' + sessionId.toForm(explode: false, allowEmpty: true),
              );
              cookieParts.add(
                r'user_id=' + userId.toForm(explode: false, allowEmpty: true),
              );
              if (cookieParts.isNotEmpty) {
                headers[r'Cookie'] = cookieParts.join('; ');
              }
            '''),
        ),
      );
    });

    test('generates conditional Cookie header for optional cookies', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'optionalSession',
            rawName: 'optional_session',
            description: 'Optional session',
            isRequired: false,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'optionalSession', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has optional parameter.
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'optionalSession',
      );
      expect(param.required, isFalse);
      expect(param.type?.accept(emitter).toString(), 'String?');

      // Check method body has null check for optional cookie.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            final cookieParts = <String>[];
            if (optionalSession != null) {
              cookieParts.add(
                r'optional_session=' +
                    optionalSession.toForm(explode: false, allowEmpty: true),
              );
            }
            if (cookieParts.isNotEmpty) {
              headers[r'Cookie'] = cookieParts.join('; ');
            }
          '''),
        ),
      );
    });

    test('generates integer cookie parameter correctly', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'pageNum',
            rawName: 'page',
            description: 'Page number',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: IntegerModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'pageNum', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has required int parameter.
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'pageNum',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'int');

      // Check method body generates cookie with int encoding.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            final cookieParts = <String>[];
            cookieParts.add(r'page=' + pageNum.toForm(explode: false, allowEmpty: true));
            if (cookieParts.isNotEmpty) {
              headers[r'Cookie'] = cookieParts.join('; ');
            }
          '''),
        ),
      );
    });

    test('generates Cookie header for array cookie parameter', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'tags',
            rawName: 'tags',
            description: 'Tags list',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: ListModel(
              context: context,
              content: StringModel(context: context),
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'tags', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has required List<String> parameter.
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'tags',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'List<String>');

      // Check method body generates cookie with list encoding.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            final cookieParts = <String>[];
            cookieParts.add(r'tags=' + tags.toForm(explode: false, allowEmpty: true));
          '''),
        ),
      );
    });

    test('generates Cookie header for object cookie parameter', () {
      final classModel = ClassModel(
        name: 'UserObject',
        context: context,
        isDeprecated: false,
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'user',
            rawName: 'user',
            description: 'User object',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: classModel,
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'user', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has required UserObject parameter.
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'user',
      );
      expect(param.required, isTrue);

      // Check method body generates cookie with object encoding.
      final methodString = method.accept(emitter).toString();
      expect(
        collapseWhitespace(methodString),
        contains("cookieParts.add(r'user=' + user.toForm("),
      );
    });

    test('generates Cookie header for oneOf cookie parameter', () {
      final oneOfModel = OneOfModel(
        name: 'OneOfIdentifier',
        context: context,
        isDeprecated: false,
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'identifier',
            rawName: 'identifier',
            description: 'OneOf identifier',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: oneOfModel,
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'identifier', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method body generates cookie with oneOf encoding.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            cookieParts.add(
              r'identifier=' + identifier.toForm(explode: false, allowEmpty: true),
            );
          '''),
        ),
      );
    });

    test('generates Cookie header for anyOf cookie parameter', () {
      final anyOfModel = AnyOfModel(
        name: 'AnyOfValue',
        context: context,
        isDeprecated: false,
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'value',
            rawName: 'value',
            description: 'AnyOf value',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: anyOfModel,
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'value', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method body generates cookie with anyOf encoding.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            cookieParts.add(r'value=' + value.toForm(explode: false, allowEmpty: true));
          '''),
        ),
      );
    });

    test('generates Cookie header for allOf cookie parameter', () {
      final allOfModel = AllOfModel(
        name: 'AllOfEntity',
        context: context,
        isDeprecated: false,
        models: {
          ClassModel(
            name: 'EntityId',
            context: context,
            isDeprecated: false,
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
          ),
          ClassModel(
            name: 'EntityName',
            context: context,
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
          ),
        },
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'entity',
            rawName: 'entity',
            description: 'AllOf entity',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: allOfModel,
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'entity', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method body generates cookie with allOf encoding.
      final methodString = method.accept(emitter).toString();
      expect(
        collapseWhitespace(methodString),
        contains("cookieParts.add(r'entity=' + entity.toForm("),
      );
    });

    test('generates encoding exception for nested object cookie parameter', () {
      final nestedClassModel = ClassModel(
        name: 'NestedProfile',
        context: context,
        isDeprecated: false,
        properties: [
          Property(
            name: 'user',
            model: ClassModel(
              name: 'UserObject',
              context: context,
              isDeprecated: false,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'profile',
            rawName: 'profile',
            description: 'Nested profile',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: nestedClassModel,
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'profile', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Nested object cookie still generates toForm - error is thrown
      // at runtime.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains('profile.toForm(explode: false, allowEmpty: true)'),
      );
    });

    test('generates Cookie header for array of integers cookie parameter', () {
      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {
          CookieParameterObject(
            name: 'ids',
            rawName: 'ids',
            description: 'Integer IDs list',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: ListModel(
              context: context,
              content: IntegerModel(context: context),
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
          ),
        },
        responses: const {},
        securitySchemes: const {},
      );

      final cookies = operation.cookieParameters
          .map((p) => p.resolve())
          .map((p) => (normalizedName: 'ids', parameter: p))
          .toList();

      final method = optionsGenerator.generateOptionsMethod(
        operation,
        [],
        cookies,
      );

      // Check method has required List<int> parameter.
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'ids',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'List<int>');

      // Check method body generates cookie with list encoding using mapping.
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            cookieParts.add(
              r'ids=' +
                  ids
                      .map((e) => e.toForm(explode: false, allowEmpty: true))
                      .toList()
                      .toForm(explode: false, allowEmpty: true, alreadyEncoded: true),
            );
          '''),
        ),
      );
    });
  });
}

// Helper functions to create test parameters
CookieParameterObject createCookieParameter(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return CookieParameterObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    explode: false,
    model: StringModel(context: context),
    encoding: CookieParameterEncoding.form,
    context: context,
  );
}

PathParameterObject createPathParameter(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return PathParameterObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    allowEmptyValue: false,
    explode: false,
    model: StringModel(context: context),
    encoding: PathParameterEncoding.simple,
    context: context,
  );
}

QueryParameterObject createQueryParameter(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return QueryParameterObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    allowEmptyValue: false,
    allowReserved: false,
    explode: false,
    model: StringModel(context: context),
    encoding: QueryParameterEncoding.form,
    context: context,
  );
}

RequestHeaderObject createHeader(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return RequestHeaderObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    allowEmptyValue: false,
    explode: false,
    model: StringModel(context: context),
    encoding: HeaderParameterEncoding.simple,
    context: context,
  );
}
