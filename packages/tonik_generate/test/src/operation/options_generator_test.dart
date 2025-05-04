import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/options_generator.dart';

void main() {
  late OptionsGenerator generator;
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
    generator = OptionsGenerator(
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
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options() {
          final headers = <String, dynamic>{};
          headers['Accept'] = '*/*';
          return Options(method: 'GET', headers: headers, validateStatus: (_) => true);
        }
      ''';
      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
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
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options() {
          final headers = <String, dynamic>{};
          headers['Accept'] = '*/*';
          return Options(method: 'POST', headers: headers, validateStatus: (_) => true);
        }
      ''';
      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('returns Options with PUT method for PUT operation', () {
      final operation = Operation(
        operationId: 'createUser',
        context: context,
        summary: 'Create user',
        description: 'Creates a new user',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.put,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options() {
          final headers = <String, dynamic>{};
          headers['Accept'] = '*/*';
          return Options(method: 'PUT', headers: headers, validateStatus: (_) => true);
        }
      ''';
      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test('returns Options with DELETE method for DELETE operation', () {
      final operation = Operation(
        operationId: 'createUser',
        context: context,
        summary: 'Create user',
        description: 'Creates a new user',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.delete,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options() {
          final headers = <String, dynamic>{};
          headers['Accept'] = '*/*';
          return Options(
            method: 'DELETE',
            headers: headers,
            validateStatus: (_) => true,
          );
        }
      ''';
      final method = generator.generateOptionsMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), contains('Options'));
      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      final methodString = format(method.accept(emitter).toString());
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
        requestBody: null,
      );

      const expectedMethod = '''
          Options _options({required String xMyHeader}) {
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            const headerEncoder = SimpleEncoder();
            headers[r'X-My-Header'] = headerEncoder.encode(
              xMyHeader,
              explode: false,
              allowEmpty: false,
            );
            return Options(
              method: 'GET',
              headers: headers,
              validateStatus: (_) => true,
            );
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMyHeader', parameter: requestHeader),
          ];
      final method = generator.generateOptionsMethod(operation, headers);

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
        collapseWhitespace(format(expectedMethod)),
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
        requestBody: null,
      );

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (
              normalizedName: 'xRequiredString',
              parameter: requiredStringHeader,
            ),
            (normalizedName: 'xRequiredDate', parameter: requiredDateHeader),
            (normalizedName: 'xOptionalBool', parameter: optionalBoolHeader),
            (normalizedName: 'xOptionalList', parameter: optionalListHeader),
          ];

      const expectedMethod = '''
          Options _options({
            required String xRequiredString,
            required DateTime xRequiredDate,
            bool? xOptionalBool,
            List<String>? xOptionalList,
          }) {
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            const headerEncoder = SimpleEncoder();
            headers[r'X-Required-String'] = headerEncoder.encode(
              xRequiredString,
              explode: false,
              allowEmpty: false,
            );
            headers[r'X-Required-Date'] = headerEncoder.encode(
              xRequiredDate.toIso8601String(),
              explode: false,
              allowEmpty: true,
            );
            if (xOptionalBool != null) {
              headers[r'X-Optional-Bool'] = headerEncoder.encode(
                xOptionalBool,
                explode: false,
                allowEmpty: false,
              );
            }
            if (xOptionalList != null) {
              headers[r'X-Optional-List'] = headerEncoder.encode(
                xOptionalList,
                explode: true,
                allowEmpty: false,
              );
            }
            return Options(
              method: 'GET',
              headers: headers,
              validateStatus: (_) => true,
            );
          }
        ''';

      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(method.optionalParameters, hasLength(4));

      final paramNames = method.optionalParameters.map((p) => p.name).toList();
      expect(paramNames.contains('xRequiredString'), isTrue);
      expect(paramNames.contains('xRequiredDate'), isTrue);
      expect(paramNames.contains('xOptionalBool'), isTrue);
      expect(paramNames.contains('xOptionalList'), isTrue);

      final methodString = format(method.accept(emitter).toString());

      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('encodes headers with allowEmpty and explode flags', () {
      final requestHeader = RequestHeaderObject(
        name: 'X-My-Header',
        rawName: 'X-My-Header',
        description: 'A custom header',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: true,
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
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options({required String xMyHeader}) {
          final headers = <String, dynamic>{};
          headers['Accept'] = '*/*';
          const headerEncoder = SimpleEncoder();
          headers[r'X-My-Header'] = headerEncoder.encode(
            xMyHeader,
            explode: true,
            allowEmpty: true,
          );
          return Options(
            method: 'GET',
            headers: headers,
            validateStatus: (_) => true,
          );
        }
      ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMyHeader', parameter: requestHeader),
          ];
      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles simple list of enums', () {
      final enumModel = EnumModel(
        context: context,
        values: const {'RED', 'GREEN', 'BLUE'},
        isNullable: false,
      );

      final listModel = ListModel(context: context, content: enumModel);

      final headerParam = RequestHeaderObject(
        name: 'X-Colors',
        rawName: 'X-Colors',
        description: 'List of colors',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: true,
        model: listModel,
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getWithColors',
        context: context,
        summary: 'Get with colors',
        description: 'Gets data with colors',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: {headerParam},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      const expectedMethod = '''
          Options _options({required List<Anonymous> xColors}) {
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            const headerEncoder = SimpleEncoder();
            headers[r'X-Colors'] = headerEncoder.encode(
              xColors.map((e) => e.toJson()).toList(),
              explode: true,
              allowEmpty: false,
            );
            return Options(
              method: 'GET',
              headers: headers,
              validateStatus: (_) => true,
            );
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xColors', parameter: headerParam),
          ];

      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles nested list of class models', () {
      final innerModel = ClassModel(context: context, properties: const []);
      final innerListModel = ListModel(context: context, content: innerModel);
      final outerListModel = ListModel(
        context: context,
        content: innerListModel,
      );

      final headerParam = RequestHeaderObject(
        name: 'X-Matrix',
        rawName: 'X-Matrix',
        description: 'Matrix of items',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: true,
        model: outerListModel,
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getWithMatrix',
        context: context,
        summary: 'Get with matrix',
        description: 'Gets data with matrix',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: {headerParam},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      const expectedMethod = '''
          Options _options({required List<List<Anonymous>> xMatrix}) {
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            const headerEncoder = SimpleEncoder();
            headers[r'X-Matrix'] = headerEncoder.encode(
              xMatrix.map((e) => e.map((e) => e.toJson()).toList()).toList(),
              explode: true,
              allowEmpty: false,
            );
            return Options(
              method: 'GET',
              headers: headers,
              validateStatus: (_) => true,
            );
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMatrix', parameter: headerParam),
          ];

      final method = generator.generateOptionsMethod(operation, headers);

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('sets contentType to null when requestBody is null', () {
      final operation = Operation(
        operationId: 'operationWithoutBody',
        context: context,
        summary: 'Operation without body',
        description: 'An operation without request body',
        tags: const {},
        isDeprecated: false,
        path: '/no-body',
        method: HttpMethod.post,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      const expectedMethod = '''
          Options _options() {
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            return Options(method: 'POST', headers: headers, validateStatus: (_) => true);
          }
        ''';

      final method = generator.generateOptionsMethod(operation, []);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

    test(
      'sets contentType from content type when requestBody has one content',
      () {
        final requestBody = RequestBodyObject(
          name: 'singleContent',
          context: context,
          description: 'Request body with single content type',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
        );

        final operation = Operation(
          operationId: 'operationWithSingleContent',
          context: context,
          summary: 'Operation with single content',
          description: 'An operation with single content type body',
          tags: const {},
          isDeprecated: false,
          path: '/single-content',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          requestBody: requestBody,
        );

        const expectedMethod = '''
          Options _options() {
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            return Options(
              method: 'POST',
              headers: headers,
              contentType: 'application/json',
              validateStatus: (_) => true,
            );
          }
        ''';

        final method = generator.generateOptionsMethod(operation, []);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test(
      'sets contentType based on body type when body has multiple contents',
      () {
        final requestBody = RequestBodyObject(
          name: 'multiContent',
          context: context,
          description: 'Request body with multiple content types',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'multipart/form-data',
            ),
          },
        );

        final operation = Operation(
          operationId: 'operationWithMultiContent',
          context: context,
          summary: 'Operation with multi content',
          description: 'An operation with multiple content type body',
          tags: const {},
          isDeprecated: false,
          path: '/multi-content',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          requestBody: requestBody,
        );

        const expectedMethod = '''
          Options _options({required MultiContent body}) {
            final contentType = switch (body) {
              MultiContentJson _ => 'application/json',
              MultiContentFormData _ => 'multipart/form-data',
            };
            final headers = <String, dynamic>{};
            headers['Accept'] = '*/*';
            return Options(
              method: 'POST',
              headers: headers,
              contentType: contentType,
              validateStatus: (_) => true,
            );
          }
        ''';

        final method = generator.generateOptionsMethod(operation, []);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test('adds Accept header with all response content types', () {
      final operation = Operation(
        operationId: 'getWithAccept',
        context: context,
        summary: 'Get with Accept',
        description: 'Test Accept header',
        tags: const {},
        isDeprecated: false,
        path: '/accept',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: 'OK',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options() {
          final headers = <String, dynamic>{};
          headers['Accept'] = 'application/json,application/xml';
          return Options(
            method: 'GET',
            headers: headers,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, []);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('adds Accept header as */* if no response content types', () {
      final operation = Operation(
        operationId: 'getWithWildcardAccept',
        context: context,
        summary: 'Get with Accept',
        description: 'Test Accept header',
        tags: const {},
        isDeprecated: false,
        path: '/accept',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: 'OK',
            bodies: const {},
          ),
        },
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options() {
          final headers = <String, dynamic>{};
          headers['Accept'] = '*/*';
          return Options(
            method: 'GET',
            headers: headers,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, []);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('does not override explicit Accept header', () {
      final requestHeader = RequestHeaderObject(
        name: 'Accept',
        rawName: 'Accept',
        description: 'Explicit Accept',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );
      final operation = Operation(
        operationId: 'explicitAccept',
        context: context,
        summary: 'Explicit Accept',
        description: 'Test explicit Accept header',
        tags: const {},
        isDeprecated: false,
        path: '/accept',
        method: HttpMethod.get,
        headers: {requestHeader},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: 'OK',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        requestBody: null,
      );

      const expectedMethod = '''
        Options _options({required String accept}) {
          final headers = <String, dynamic>{};
          const headerEncoder = SimpleEncoder();
          headers[r'Accept'] = headerEncoder.encode(
            accept,
            explode: false,
            allowEmpty: false,
          );
          return Options(
            method: 'GET',
            headers: headers,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, [
        (normalizedName: 'accept', parameter: requestHeader),
      ]);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test(
      'sets default Accept if explicit Accept header is optional and not set',
      () {
        final requestHeader = RequestHeaderObject(
          name: 'Accept',
          rawName: 'Accept',
          description: 'Optional Accept',
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: StringModel(context: context),
          encoding: HeaderParameterEncoding.simple,
          context: context,
        );
        final operation = Operation(
          operationId: 'optionalAccept',
          context: context,
          summary: 'Optional Accept',
          description: 'Test optional Accept header',
          tags: const {},
          isDeprecated: false,
          path: '/accept',
          method: HttpMethod.get,
          headers: {requestHeader},
          queryParameters: const {},
          pathParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: 'OK',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                ),
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/xml',
                  contentType: ContentType.json,
                ),
              },
            ),
          },
          requestBody: null,
        );

        const expectedMethod = '''
        Options _options({String? accept}) {
          final headers = <String, dynamic>{};
          const headerEncoder = SimpleEncoder();
          if (accept != null) {
            headers[r'Accept'] = headerEncoder.encode(
              accept,
              explode: false,
              allowEmpty: false,
            );
          } else {
            headers['Accept'] = 'application/json,application/xml';
          }
          return Options(
            method: 'GET',
            headers: headers,
            validateStatus: (_) => true,
          );
        }
      ''';

        final method = generator.generateOptionsMethod(operation, [
          (normalizedName: 'accept', parameter: requestHeader),
        ]);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });
}
