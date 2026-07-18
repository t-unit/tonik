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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = OptionsGenerator(
      nameManager: nameManager,
      package: 'api',
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options() {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';
      final method = generator.generateOptionsMethod(operation, [], []);

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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options() {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          return Options(
            method: 'POST',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';
      final method = generator.generateOptionsMethod(operation, [], []);

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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options() {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          return Options(
            method: 'PUT',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';
      final method = generator.generateOptionsMethod(operation, [], []);

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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options() {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          return Options(
            method: 'DELETE',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';
      final method = generator.generateOptionsMethod(operation, [], []);

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
        examples: const [],
        defaultValue: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
          Options _options({required String xMyHeader}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            _$headers[r'X-My-Header'] = xMyHeader.toSimple(
              explode: false,
              allowEmpty: false,
              literal: true,
            );
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMyHeader', parameter: requestHeader),
          ];
      final method = generator.generateOptionsMethod(operation, headers, []);

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
        examples: const [],
        defaultValue: null,
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
        examples: const [],
        defaultValue: null,
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
        examples: const [],
        defaultValue: null,
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
          examples: const [],
        ),
        encoding: HeaderParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
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

      const expectedMethod = r'''
          Options _options({
            required String xRequiredString,
            required DateTime xRequiredDate,
            bool? xOptionalBool,
            List<String>? xOptionalList,
          }) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            _$headers[r'X-Required-String'] = xRequiredString.toSimple(
              explode: false,
              allowEmpty: false,
              literal: true,
            );
            _$headers[r'X-Required-Date'] = xRequiredDate.toSimple(
              explode: false,
              allowEmpty: true,
              literal: true,
            );
            if (xOptionalBool != null) {
              _$headers[r'X-Optional-Bool'] = xOptionalBool.toSimple(
                explode: false,
                allowEmpty: false,
                literal: true,
              );
            }
            if (xOptionalList != null) {
              _$headers[r'X-Optional-List'] = xOptionalList.toSimple(
                explode: true,
                allowEmpty: false,
                literal: true,
              );
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

      final method = generator.generateOptionsMethod(operation, headers, []);

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

    test(
      'optional header with nullable model uses non-null access '
      'inside null-check block',
      () {
        final optionalNullableHeader = RequestHeaderObject(
          name: 'X-Nullable-Object',
          rawName: 'X-Nullable-Object',
          description: 'An optional header with a nullable model',
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: ClassModel(
            name: 'NullableObj',
            properties: const [],
            context: context,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
          ),
          encoding: HeaderParameterEncoding.simple,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'operationWithNullableHeader',
          context: context,
          summary: 'Operation with nullable header',
          description: 'An operation with an optional nullable header',
          tags: const {},
          isDeprecated: false,
          path: '/with-nullable-header',
          method: HttpMethod.get,
          headers: {optionalNullableHeader},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final headers =
            <({String normalizedName, RequestHeaderObject parameter})>[
              (
                normalizedName: 'xNullableObject',
                parameter: optionalNullableHeader,
              ),
            ];

        const expectedMethod = r'''
            Options _options({NullableObj? xNullableObject}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              if (xNullableObject != null) {
                _$headers[r'X-Nullable-Object'] = xNullableObject.toSimple(
                  explode: false,
                  allowEmpty: false,
                  literal: true,
                );
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

        final method = generator.generateOptionsMethod(operation, headers, []);

        expect(method, isA<Method>());
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

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
        examples: const [],
        defaultValue: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options({required String xMyHeader}) {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          _$headers[r'X-My-Header'] = xMyHeader.toSimple(
            explode: true,
            allowEmpty: true,
            literal: true,
          );
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMyHeader', parameter: requestHeader),
          ];
      final method = generator.generateOptionsMethod(operation, headers, []);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles simple list of enums', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        context: context,
        values: {
          const EnumEntry(value: 'RED'),
          const EnumEntry(value: 'GREEN'),
          const EnumEntry(value: 'BLUE'),
        },
        isNullable: false,
        examples: const [],
      );

      final listModel = ListModel(
        context: context,
        content: enumModel,
        examples: const [],
      );

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
        examples: const [],
        defaultValue: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
          Options _options({required List<AnonymousModel> xColors}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            _$headers[r'X-Colors'] = xColors
                .map(
                  (e) => e.toSimple(
                    explode: true,
                    allowEmpty: false,
                    literal: true,
                  ),
                )
                .toList()
                .toSimple(explode: true, allowEmpty: false, literal: true);
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xColors', parameter: headerParam),
          ];

      final method = generator.generateOptionsMethod(operation, headers, []);

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles nested list of class models', () {
      final innerModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
        examples: const [],
      );
      final innerListModel = ListModel(
        context: context,
        content: innerModel,
        examples: const [],
      );
      final outerListModel = ListModel(
        context: context,
        content: innerListModel,
        examples: const [],
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
        examples: const [],
        defaultValue: null,
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
          Options _options({required List<List<AnonymousModel>> xMatrix}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            throw EncodingException('Simple encoding does not support list with complex elements for header X-Matrix');
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

      final headers =
          <({String normalizedName, RequestHeaderObject parameter})>[
            (normalizedName: 'xMatrix', parameter: headerParam),
          ];

      final method = generator.generateOptionsMethod(operation, headers, []);

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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
          Options _options() {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            return Options(
              method: 'POST',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

      final method = generator.generateOptionsMethod(operation, [], []);
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
              examples: const [],
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
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Options _options() {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            return Options(
              method: 'POST',
              headers: _$headers,
              contentType: r'application/json',
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final method = generator.generateOptionsMethod(operation, [], []);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test('omits contentType when optional single-content body is null', () {
      final requestBody = RequestBodyObject(
        name: 'optionalContent',
        context: context,
        description: 'Optional request body with single content type',
        isRequired: false,
        content: {
          RequestContent(
            model: StringModel(context: context),
            contentType: ContentType.json,
            rawContentType: 'application/json',
            examples: const [],
          ),
        },
      );

      final operation = Operation(
        operationId: 'operationWithOptionalContent',
        context: context,
        summary: 'Operation with optional single content',
        description: 'An operation with an optional single content type body',
        tags: const {},
        isDeprecated: false,
        path: '/optional-content',
        method: HttpMethod.post,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        requestBody: requestBody,
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options({String? body}) {
          final _$contentType = body == null ? null : r'application/json';
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          return Options(
            method: 'POST',
            headers: _$headers,
            contentType: _$contentType,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, [], []);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(expectedMethod),
      );
    });

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
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'multipart/form-data',
              examples: const [],
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
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Options _options({required MultiContent body}) {
            final _$contentType = switch (body) {
              MultiContentJson _ => r'application/json',
              MultiContentFormData _ => r'multipart/form-data',
            };
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            return Options(
              method: 'POST',
              headers: _$headers,
              contentType: _$contentType,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final method = generator.generateOptionsMethod(operation, [], []);
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
        cookieParameters: const {},
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
                examples: const [],
              ),
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options() {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'application/json,application/xml';
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, [], []);
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
        cookieParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: 'OK',
            bodies: const {},
          ),
        },
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options() {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, [], []);
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
        examples: const [],
        defaultValue: null,
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        Options _options({required String accept}) {
          final _$headers = <String, dynamic>{};
          _$headers[r'Accept'] = accept.toSimple(
            explode: false,
            allowEmpty: false,
            literal: true,
          );
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final method = generator.generateOptionsMethod(operation, [
        (normalizedName: 'accept', parameter: requestHeader),
      ], []);
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
          examples: const [],
          defaultValue: null,
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
          cookieParameters: const {},
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
                  examples: const [],
                ),
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/xml',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );

        const expectedMethod = r'''
        Options _options({String? accept}) {
          final _$headers = <String, dynamic>{};
          if (accept != null) {
            _$headers[r'Accept'] = accept.toSimple(
              explode: false,
              allowEmpty: false,
              literal: true,
            );
          } else {
            _$headers['Accept'] = r'application/json,application/xml';
          }
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

        final method = generator.generateOptionsMethod(operation, [
          (normalizedName: 'accept', parameter: requestHeader),
        ], []);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });

  group('cookie header generation', () {
    test('generates Cookie header for required cookie parameter', () {
      final cookieParam = CookieParameterObject(
        name: 'sessionId',
        rawName: 'session_id',
        description: 'Session identifier',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withCookie',
        context: context,
        summary: 'With cookie',
        description: 'Operation with cookie',
        tags: const {},
        isDeprecated: false,
        path: '/cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'sessionId', parameter: cookieParam),
      ]);
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'sessionId',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'String');
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace(r'''
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
  sessionId
.toForm(r'session_id', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
          '''),
        ),
      );
    });

    test('generates Cookie header for optional cookie parameter', () {
      final cookieParam = CookieParameterObject(
        name: 'trackingId',
        rawName: 'tracking_id',
        description: 'Tracking identifier',
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withOptionalCookie',
        context: context,
        summary: 'With optional cookie',
        description: 'Operation with optional cookie',
        tags: const {},
        isDeprecated: false,
        path: '/cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'trackingId', parameter: cookieParam),
      ]);
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'trackingId',
      );
      expect(param.required, isFalse);
      expect(param.type?.accept(emitter).toString(), 'String?');
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace(r'''
            final _$cookieParts = <String>[];
            if (trackingId != null) {
              _$cookieParts.addAll(
  trackingId
.toForm(r'tracking_id', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
          '''),
        ),
      );
    });

    test('generates Cookie header for multiple cookies', () {
      final cookie1 = CookieParameterObject(
        name: 'sessionId',
        rawName: 'session_id',
        description: 'Session',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final cookie2 = CookieParameterObject(
        name: 'userId',
        rawName: 'user_id',
        description: 'User',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withMultipleCookies',
        context: context,
        summary: 'With multiple cookies',
        description: 'Operation with multiple cookies',
        tags: const {},
        isDeprecated: false,
        path: '/cookies',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookie1, cookie2},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'sessionId', parameter: cookie1),
        (normalizedName: 'userId', parameter: cookie2),
      ]);
      expect(method.optionalParameters, hasLength(2));

      final sessionParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'sessionId',
      );
      expect(sessionParam.required, isTrue);
      expect(sessionParam.type?.accept(emitter).toString(), 'String');

      final userParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'userId',
      );
      expect(userParam.required, isTrue);
      expect(userParam.type?.accept(emitter).toString(), 'String');
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace(r'''
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
  sessionId
.toForm(r'session_id', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            _$cookieParts.addAll(
  userId
.toForm(r'user_id', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
          '''),
        ),
      );
    });

    test('generates Cookie header with integer cookie parameter', () {
      final cookieParam = CookieParameterObject(
        name: 'pageNum',
        rawName: 'page_num',
        description: 'Page number',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: IntegerModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withIntCookie',
        context: context,
        summary: 'With int cookie',
        description: 'Operation with int cookie',
        tags: const {},
        isDeprecated: false,
        path: '/int-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'pageNum', parameter: cookieParam),
      ]);
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'pageNum',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'int');
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace(r'''
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
  pageNum
.toForm(r'page_num', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
          '''),
        ),
      );
    });

    test('generates Cookie header for map cookie with string values', () {
      final cookieParam = CookieParameterObject(
        name: 'labels',
        rawName: 'labels',
        description: 'Labels map',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withMapStringCookie',
        context: context,
        summary: 'With map string cookie',
        description: 'Operation with map string cookie',
        tags: const {},
        isDeprecated: false,
        path: '/map-string-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'labels', parameter: cookieParam),
      ]);
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'labels',
      );
      expect(param.required, isTrue);
      expect(
        param.type?.accept(emitter).toString(),
        'Map<String,String>',
      );

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(r'''
          Options _options({required Map<String, String> labels}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
              labels
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toForm(r'labels', explode: false, allowEmpty: true)
                  .map(
                    (e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}',
                  ),
            );
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''')),
      );
    });

    test('generates Cookie header for map cookie with integer values', () {
      final cookieParam = CookieParameterObject(
        name: 'prefs',
        rawName: 'prefs',
        description: 'Preferences map',
        isRequired: true,
        isDeprecated: false,
        explode: true,
        model: MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withMapIntCookie',
        context: context,
        summary: 'With map int cookie',
        description: 'Operation with map int cookie',
        tags: const {},
        isDeprecated: false,
        path: '/map-int-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'prefs', parameter: cookieParam),
      ]);
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'prefs',
      );
      expect(param.required, isTrue);
      expect(
        param.type?.accept(emitter).toString(),
        'Map<String,int>',
      );

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(r'''
          Options _options({required Map<String, int> prefs}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
              prefs
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toString())),
                  )
                  .toForm(r'prefs', explode: true, allowEmpty: true)
                  .map(
                    (e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}',
                  ),
            );
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''')),
      );
    });

    test('generates Cookie header for optional map cookie', () {
      final cookieParam = CookieParameterObject(
        name: 'settings',
        rawName: 'settings',
        description: 'Settings map',
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withOptionalMapCookie',
        context: context,
        summary: 'With optional map cookie',
        description: 'Operation with optional map cookie',
        tags: const {},
        isDeprecated: false,
        path: '/optional-map-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'settings', parameter: cookieParam),
      ]);
      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'settings',
      );
      expect(param.required, isFalse);
      expect(
        param.type?.accept(emitter).toString(),
        'Map<String,int>?',
      );

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(r'''
          Options _options({Map<String, int>? settings}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (settings != null) {
              _$cookieParts.addAll(
                settings
                    .map(
                      (k, v) =>
                          MapEntry(k, PropertyValue.scalar(v.toString())),
                    )
                    .toForm(r'settings', explode: false, allowEmpty: true)
                    .map(
                      (e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}',
                    ),
              );
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''')),
      );
    });

    test('generates throw for map cookie with unsupported value type', () {
      final cookieParam = CookieParameterObject(
        name: 'data',
        rawName: 'data',
        description: 'Data map',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: MapModel(
          valueModel: ClassModel(
            name: 'Nested',
            properties: const [],
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withUnsupportedMapCookie',
        context: context,
        summary: 'With unsupported map cookie',
        description: 'Operation with unsupported map cookie',
        tags: const {},
        isDeprecated: false,
        path: '/unsupported-map-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'data', parameter: cookieParam),
      ]);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(r'''
          Options _options({required Map<String, Nested> data}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            throw EncodingException(
              r'Map with complex value types cannot be form-encoded for cookie data',
            );
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''')),
      );
    });

    test('generates throw for NeverModel cookie', () {
      final cookieParam = CookieParameterObject(
        name: 'data',
        rawName: 'data',
        description: 'Never data',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: NeverModel(context: context, isNullable: false),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withNeverCookie',
        context: context,
        summary: 'With never cookie',
        description: 'Operation with NeverModel cookie',
        tags: const {},
        isDeprecated: false,
        path: '/never-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'data', parameter: cookieParam),
      ]);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            throw EncodingException(
              'Cannot encode NeverModel - this type does not permit any value for cookie data',
            );
          '''),
        ),
      );
    });

    test('generates throw for cookie with list of complex content', () {
      final cookieParam = CookieParameterObject(
        name: 'data',
        rawName: 'data',
        description: 'List of objects',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: ListModel(
          content: ClassModel(
            name: 'Item',
            properties: const [],
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withComplexListCookie',
        context: context,
        summary: 'With complex list cookie',
        description: 'Operation with complex list cookie',
        tags: const {},
        isDeprecated: false,
        path: '/complex-list-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'data', parameter: cookieParam),
      ]);

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        contains(
          collapseWhitespace('''
            throw EncodingException(
              'Unsupported model type for form-encoded cookie data',
            );
          '''),
        ),
      );
    });

    test(
      'generates Cookie header for required AnyModel cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'data',
          rawName: 'data',
          description: 'Any data',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: AnyModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withAnyCookie',
          context: context,
          summary: 'With any cookie',
          description: 'Operation with AnyModel cookie',
          tags: const {},
          isDeprecated: false,
          path: '/any-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'data', parameter: cookieParam),
        ]);
        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'data',
        );
        expect(param.required, isTrue);
        expect(param.type?.accept(emitter).toString(), 'Object?');

        const expectedMethod = r'''
          Options _options({required Object? data}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.add(
  [r'data=', encodeAnyToForm(data, explode: false, allowEmpty: true)].join(),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates Cookie header for list of AnyModel cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'items',
          rawName: 'items',
          description: 'List of any items',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: ListModel(
            content: AnyModel(context: context),
            context: context,
            examples: const [],
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withArrayAnyCookie',
          context: context,
          summary: 'With array any cookie',
          description: 'Operation with list of AnyModel cookie',
          tags: const {},
          isDeprecated: false,
          path: '/array-any-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'items', parameter: cookieParam),
        ]);
        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'items',
        );
        expect(param.required, isTrue);
        expect(param.type?.accept(emitter).toString(), 'List<Object?>');

        const expectedMethod = r'''
          Options _options({required List<Object?> items}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
  items
                    .map(
                      (e) =>
                          encodeAnyToUri(e, allowEmpty: true),
                    )
                    .toList()
                    .toForm(r'items', 
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates Cookie header for optional AnyModel cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'metadata',
          rawName: 'metadata',
          description: 'Optional any data',
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: AnyModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withOptionalAnyCookie',
          context: context,
          summary: 'With optional any cookie',
          description: 'Operation with optional AnyModel cookie',
          tags: const {},
          isDeprecated: false,
          path: '/optional-any-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'metadata', parameter: cookieParam),
        ]);
        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'metadata',
        );
        expect(param.required, isFalse);
        expect(param.type?.accept(emitter).toString(), 'Object?');

        const expectedMethod = r'''
          Options _options({Object? metadata}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (metadata != null) {
              _$cookieParts.add(
  [r'metadata=', encodeAnyToForm(metadata, explode: false, allowEmpty: true)].join(),
);
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test('generates Cookie header for required Base64 cookie parameter', () {
      final cookieParam = CookieParameterObject(
        name: 'token',
        rawName: 'token',
        description: 'Base64 token',
        isRequired: true,
        isDeprecated: false,
        explode: true,
        model: Base64Model(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withBase64Cookie',
        context: context,
        summary: 'With base64 cookie',
        description: 'Operation with Base64 cookie',
        tags: const {},
        isDeprecated: false,
        path: '/base64-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'token', parameter: cookieParam),
      ]);

      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'token',
      );
      expect(param.required, isTrue);
      expect(param.type?.accept(emitter).toString(), 'TonikFile');

      const expectedMethod = r'''
        Options _options({required TonikFile token}) {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          final _$cookieParts = <String>[];
          _$cookieParts.addAll(
  token.toBase64String().toForm(r'token', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
          if (_$cookieParts.isNotEmpty) {
            _$headers[r'Cookie'] = _$cookieParts.join('; ');
          }
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test(
      'generates EncodingException for required Binary cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'token',
          rawName: 'token',
          description: 'Binary token',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: BinaryModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withBinaryCookie',
          context: context,
          summary: 'With binary cookie',
          description: 'Operation with Binary cookie',
          tags: const {},
          isDeprecated: false,
          path: '/binary-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'token', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'token',
        );
        expect(param.required, isTrue);
        expect(param.type?.accept(emitter).toString(), 'TonikFile');

        const expectedMethod = r'''
          Options _options({required TonikFile token}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            throw EncodingException(
              'Binary data cannot be form-encoded for cookie token',
            );
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates Cookie header for required list of Base64 cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'tokens',
          rawName: 'tokens',
          description: 'List of Base64 tokens',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: ListModel(
            content: Base64Model(context: context),
            context: context,
            examples: const [],
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withListBase64Cookie',
          context: context,
          summary: 'With list base64 cookie',
          description: 'Operation with list of Base64 cookies',
          tags: const {},
          isDeprecated: false,
          path: '/list-base64-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'tokens', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'tokens',
        );
        expect(param.required, isTrue);
        expect(param.type?.accept(emitter).toString(), 'List<TonikFile>');

        const expectedMethod = r'''
          Options _options({required List<TonikFile> tokens}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
  tokens
                    .map((e) => e.toBase64String())
                    .toList()
                    .toForm(r'tokens', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates EncodingException for required list of '
      'Binary cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'files',
          rawName: 'files',
          description: 'List of binary files',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: ListModel(
            content: BinaryModel(context: context),
            context: context,
            examples: const [],
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withListBinaryCookie',
          context: context,
          summary: 'With list binary cookie',
          description: 'Operation with list of Binary cookies',
          tags: const {},
          isDeprecated: false,
          path: '/list-binary-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'files', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'files',
        );
        expect(param.required, isTrue);
        expect(param.type?.accept(emitter).toString(), 'List<TonikFile>');

        const expectedMethod = r'''
          Options _options({required List<TonikFile> files}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            throw EncodingException(
              'Binary data cannot be form-encoded for cookie files',
            );
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test('generates Cookie header for optional Base64 cookie parameter', () {
      final cookieParam = CookieParameterObject(
        name: 'token',
        rawName: 'token',
        description: 'Optional Base64 token',
        isRequired: false,
        isDeprecated: false,
        explode: true,
        model: Base64Model(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'withOptionalBase64Cookie',
        context: context,
        summary: 'With optional base64 cookie',
        description: 'Operation with optional Base64 cookie',
        tags: const {},
        isDeprecated: false,
        path: '/optional-base64-cookie',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final method = generator.generateOptionsMethod(operation, [], [
        (normalizedName: 'token', parameter: cookieParam),
      ]);

      final param = method.optionalParameters.firstWhere(
        (p) => p.name == 'token',
      );
      expect(param.required, isFalse);
      expect(param.type?.accept(emitter).toString(), 'TonikFile?');

      const expectedMethod = r'''
        Options _options({TonikFile? token}) {
          final _$headers = <String, dynamic>{};
          _$headers['Accept'] = r'*/*';
          final _$cookieParts = <String>[];
          if (token != null) {
            _$cookieParts.addAll(
  token.toBase64String().toForm(r'token', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
          }
          if (_$cookieParts.isNotEmpty) {
            _$headers[r'Cookie'] = _$cookieParts.join('; ');
          }
          return Options(
            method: 'GET',
            headers: _$headers,
            responseType: ResponseType.bytes,
            validateStatus: (_) => true,
          );
        }
      ''';

      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test(
      'generates EncodingException for optional Binary cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'token',
          rawName: 'token',
          description: 'Optional Binary token',
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: BinaryModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withOptionalBinaryCookie',
          context: context,
          summary: 'With optional binary cookie',
          description: 'Operation with optional Binary cookie',
          tags: const {},
          isDeprecated: false,
          path: '/optional-binary-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'token', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'token',
        );
        expect(param.required, isFalse);
        expect(param.type?.accept(emitter).toString(), 'TonikFile?');

        const expectedMethod = r'''
          Options _options({TonikFile? token}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (token != null) {
              throw EncodingException(
                'Binary data cannot be form-encoded for cookie token',
              );
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates Cookie header for optional list of Base64 cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'tokens',
          rawName: 'tokens',
          description: 'Optional list of Base64 tokens',
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: ListModel(
            content: Base64Model(context: context),
            context: context,
            examples: const [],
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withOptionalListBase64Cookie',
          context: context,
          summary: 'With optional list base64 cookie',
          description: 'Operation with optional list of Base64 cookies',
          tags: const {},
          isDeprecated: false,
          path: '/optional-list-base64-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'tokens', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'tokens',
        );
        expect(param.required, isFalse);
        expect(param.type?.accept(emitter).toString(), 'List<TonikFile>?');

        const expectedMethod = r'''
          Options _options({List<TonikFile>? tokens}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (tokens != null) {
              _$cookieParts.addAll(
  tokens
                      .map((e) => e.toBase64String())
                      .toList()
                      .toForm(r'tokens', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates EncodingException for optional list of '
      'Binary cookie parameter',
      () {
        final cookieParam = CookieParameterObject(
          name: 'files',
          rawName: 'files',
          description: 'Optional list of binary files',
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: ListModel(
            content: BinaryModel(context: context),
            context: context,
            examples: const [],
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withOptionalListBinaryCookie',
          context: context,
          summary: 'With optional list binary cookie',
          description: 'Operation with optional list of Binary cookies',
          tags: const {},
          isDeprecated: false,
          path: '/optional-list-binary-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'files', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'files',
        );
        expect(param.required, isFalse);
        expect(param.type?.accept(emitter).toString(), 'List<TonikFile>?');

        const expectedMethod = r'''
          Options _options({List<TonikFile>? files}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (files != null) {
              throw EncodingException(
                'Binary data cannot be form-encoded for cookie files',
              );
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'generates throw plus adjacent cookie code for operation with '
      'mixed Binary and String cookies',
      () {
        final binaryCookie = CookieParameterObject(
          name: 'binaryData',
          rawName: 'binaryData',
          description: 'Binary cookie',
          isRequired: true,
          isDeprecated: false,
          explode: true,
          model: BinaryModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final stringCookie = CookieParameterObject(
          name: 'tracker',
          rawName: 'tracker',
          description: 'Tracker cookie',
          isRequired: true,
          isDeprecated: false,
          explode: true,
          model: StringModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withMixedBinaryStringCookies',
          context: context,
          summary: 'With mixed binary and string cookies',
          description: 'Operation with mixed Binary and String cookies',
          tags: const {},
          isDeprecated: false,
          path: '/mixed-binary-string-cookies',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {binaryCookie, stringCookie},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'binaryData', parameter: binaryCookie),
          (normalizedName: 'tracker', parameter: stringCookie),
        ]);

        const expectedMethod = r'''
          Options _options({
            required TonikFile binaryData,
            required String tracker,
          }) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            throw EncodingException(
              'Binary data cannot be form-encoded for cookie binaryData',
            );
            _$cookieParts.addAll(
  tracker
.toForm(r'tracker', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    group('alias-wrapped cookie parameters', () {
      test(
        'alias to list of strings routes through list path',
        () {
          final cookieParam = CookieParameterObject(
            name: 'tags',
            rawName: 'tags',
            description: 'Alias to list of strings',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'TagList',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasStringListCookie',
            context: context,
            summary: 'With alias string list cookie',
            description: 'Operation with alias-to-list-of-string cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-string-list-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'tags', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'tags',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'TagList');

          const expectedMethod = r'''
            Options _options({required TagList tags}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  tags
.toForm(r'tags', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'alias to list of integers uses list-form encoding (not binary)',
        () {
          final cookieParam = CookieParameterObject(
            name: 'numbers',
            rawName: 'numbers',
            description: 'Alias to list of integers',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'IntList',
              model: ListModel(
                content: IntegerModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasIntListCookie',
            context: context,
            summary: 'With alias int list cookie',
            description: 'Operation with alias-to-list-of-int cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-int-list-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'numbers', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'numbers',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'IntList');

          const expectedMethod = r'''
            Options _options({required IntList numbers}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  numbers
                      .map((e) => e.uriEncode(allowEmpty: true))
                      .toList()
                      .toForm(r'numbers', 
                        explode: false,
                        allowEmpty: true,
                        alreadyEncoded: true,
                      )
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'nested alias chain to list of booleans routes through list path',
        () {
          final boolArray = AliasModel(
            name: 'BoolArray',
            model: ListModel(
              content: BooleanModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
          );
          final flagList = AliasModel(
            name: 'FlagList',
            model: boolArray,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final cookieParam = CookieParameterObject(
            name: 'flags',
            rawName: 'flags',
            description: 'Nested alias chain to list of booleans',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: flagList,
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withNestedAliasBoolListCookie',
            context: context,
            summary: 'With nested alias bool list cookie',
            description: 'Operation with nested-alias-to-list-of-bool cookie',
            tags: const {},
            isDeprecated: false,
            path: '/nested-alias-bool-list-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'flags', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'flags',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'FlagList');

          const expectedMethod = r'''
            Options _options({required FlagList flags}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  flags
                      .map((e) => e.uriEncode(allowEmpty: true))
                      .toList()
                      .toForm(r'flags', 
                        explode: false,
                        allowEmpty: true,
                        alreadyEncoded: true,
                      )
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'optional alias to list of integers routes through list path',
        () {
          final cookieParam = CookieParameterObject(
            name: 'numbers',
            rawName: 'numbers',
            description: 'Optional alias to list of integers',
            isRequired: false,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'IntList',
              model: ListModel(
                content: IntegerModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withOptionalAliasIntListCookie',
            context: context,
            summary: 'With optional alias int list cookie',
            description: 'Operation with optional alias-to-list-of-int cookie',
            tags: const {},
            isDeprecated: false,
            path: '/optional-alias-int-list-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'numbers', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'numbers',
          );
          expect(param.required, isFalse);
          expect(param.type?.accept(emitter).toString(), 'IntList?');

          const expectedMethod = r'''
            Options _options({IntList? numbers}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              if (numbers != null) {
                _$cookieParts.addAll(
  numbers
                        .map((e) => e.uriEncode(allowEmpty: true))
                        .toList()
                        .toForm(r'numbers', 
                          explode: false,
                          allowEmpty: true,
                          alreadyEncoded: true,
                        )
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              }
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test('alias to map routes through map path', () {
        final cookieParam = CookieParameterObject(
          name: 'prefs',
          rawName: 'prefs',
          description: 'Alias to map of integers',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: AliasModel(
            name: 'PrefsMap',
            model: MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withAliasMapCookie',
          context: context,
          summary: 'With alias map cookie',
          description: 'Operation with alias-to-map cookie',
          tags: const {},
          isDeprecated: false,
          path: '/alias-map-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'prefs', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'prefs',
        );
        expect(param.required, isTrue);
        expect(param.type?.symbol, 'PrefsMap');

        const expectedMethod = r'''
          Options _options({required PrefsMap prefs}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.addAll(
  prefs
                    .map(
                      (k, v) =>
                          MapEntry(k, PropertyValue.scalar(v.toString())),
                    )
                    .toForm(r'prefs', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('alias to AnyModel scalar routes through any path', () {
        final cookieParam = CookieParameterObject(
          name: 'data',
          rawName: 'data',
          description: 'Alias to AnyModel scalar',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: AliasModel(
            name: 'AnyData',
            model: AnyModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withAliasAnyCookie',
          context: context,
          summary: 'With alias any cookie',
          description: 'Operation with alias-to-AnyModel cookie',
          tags: const {},
          isDeprecated: false,
          path: '/alias-any-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'data', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'data',
        );
        expect(param.required, isTrue);
        expect(param.type?.symbol, 'AnyData');

        const expectedMethod = r'''
          Options _options({required AnyData data}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            _$cookieParts.add(
  [r'data=', encodeAnyToForm(data, explode: false, allowEmpty: true)].join(),
);
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'alias to list of AnyModel routes through list-of-any path',
        () {
          final cookieParam = CookieParameterObject(
            name: 'items',
            rawName: 'items',
            description: 'Alias to list of AnyModel',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'AnyList',
              model: ListModel(
                content: AnyModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasAnyListCookie',
            context: context,
            summary: 'With alias any list cookie',
            description: 'Operation with alias-to-list-of-AnyModel cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-any-list-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'items', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'items',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'AnyList');

          const expectedMethod = r'''
            Options _options({required AnyList items}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  items
                      .map(
                        (e) =>
                            encodeAnyToUri(e, allowEmpty: true),
                      )
                      .toList()
                      .toForm(r'items', 
                        explode: false,
                        allowEmpty: true,
                        alreadyEncoded: true,
                      )
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'alias to list of strings with explode true threads explode through',
        () {
          final cookieParam = CookieParameterObject(
            name: 'names',
            rawName: 'names',
            description: 'Alias to list of strings, explode true',
            isRequired: true,
            isDeprecated: false,
            explode: true,
            model: AliasModel(
              name: 'NameList',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasStringListCookieExplodeTrue',
            context: context,
            summary: 'With alias string list cookie explode true',
            description:
                'Operation with alias-to-list-of-string cookie '
                'using explode true',
            tags: const {},
            isDeprecated: false,
            path: '/alias-string-list-cookie-explode-true',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'names', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'names',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'NameList');

          const expectedMethod = r'''
            Options _options({required NameList names}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  names
.toForm(r'names', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'alias to map with unsupported value type throws EncodingException',
        () {
          final cookieParam = CookieParameterObject(
            name: 'data',
            rawName: 'data',
            description: 'Alias to map of complex values',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'NestedMap',
              model: MapModel(
                valueModel: ClassModel(
                  name: 'Nested',
                  properties: const [],
                  context: context,
                  isDeprecated: false,
                  examples: const [],
                ),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasUnsupportedMapCookie',
            context: context,
            summary: 'With alias unsupported map cookie',
            description:
                'Operation with alias-to-map cookie of complex '
                'values',
            tags: const {},
            isDeprecated: false,
            path: '/alias-unsupported-map-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'data', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'data',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'NestedMap');

          const expectedMethod = r'''
            Options _options({required NestedMap data}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              throw EncodingException(
                r'Map with complex value types cannot be form-encoded for cookie data',
              );
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test('optional alias to map', () {
        final cookieParam = CookieParameterObject(
          name: 'prefs',
          rawName: 'prefs',
          description: 'Optional alias to map of integers',
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: AliasModel(
            name: 'PrefsMap',
            model: MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withOptionalAliasMapCookie',
          context: context,
          summary: 'With optional alias map cookie',
          description: 'Operation with optional alias-to-map cookie',
          tags: const {},
          isDeprecated: false,
          path: '/optional-alias-map-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'prefs', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'prefs',
        );
        expect(param.required, isFalse);
        expect(param.type?.accept(emitter).toString(), 'PrefsMap?');

        const expectedMethod = r'''
          Options _options({PrefsMap? prefs}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (prefs != null) {
              _$cookieParts.addAll(
  prefs
                      .map(
                        (k, v) =>
                            MapEntry(k, PropertyValue.scalar(v.toString())),
                      )
                      .toForm(r'prefs', explode: false, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('optional alias to AnyModel scalar', () {
        final cookieParam = CookieParameterObject(
          name: 'data',
          rawName: 'data',
          description: 'Optional alias to AnyModel scalar',
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: AliasModel(
            name: 'AnyData',
            model: AnyModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'withOptionalAliasAnyCookie',
          context: context,
          summary: 'With optional alias any cookie',
          description: 'Operation with optional alias-to-AnyModel cookie',
          tags: const {},
          isDeprecated: false,
          path: '/optional-alias-any-cookie',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          securitySchemes: const {},
        );

        final method = generator.generateOptionsMethod(operation, [], [
          (normalizedName: 'data', parameter: cookieParam),
        ]);

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'data',
        );
        expect(param.required, isFalse);
        expect(param.type?.accept(emitter).toString(), 'AnyData?');

        const expectedMethod = r'''
          Options _options({AnyData? data}) {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            final _$cookieParts = <String>[];
            if (data != null) {
              _$cookieParts.add(
  [r'data=', encodeAnyToForm(data, explode: false, allowEmpty: true)].join(),
);
            }
            if (_$cookieParts.isNotEmpty) {
              _$headers[r'Cookie'] = _$cookieParts.join('; ');
            }
            return Options(
              method: 'GET',
              headers: _$headers,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'generates Cookie header for alias-wrapped Base64 cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'token',
            rawName: 'token',
            description: 'Alias to Base64',
            isRequired: true,
            isDeprecated: false,
            explode: true,
            model: AliasModel(
              name: 'BinaryToken',
              model: Base64Model(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasBase64Cookie',
            context: context,
            summary: 'With alias base64 cookie',
            description: 'Operation with alias-to-Base64 cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-base64-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'token', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'token',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'BinaryToken');

          const expectedMethod = r'''
            Options _options({required BinaryToken token}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  token.toBase64String().toForm(r'token', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates EncodingException for alias-wrapped Binary cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'blob',
            rawName: 'blob',
            description: 'Alias to Binary',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'BinaryBlob',
              model: BinaryModel(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasBinaryCookie',
            context: context,
            summary: 'With alias binary cookie',
            description: 'Operation with alias-to-Binary cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-binary-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'blob', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'blob',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'BinaryBlob');

          const expectedMethod = r'''
            Options _options({required BinaryBlob blob}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              throw EncodingException(
                'Binary data cannot be form-encoded for cookie blob',
              );
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates Cookie header for alias-wrapped list of '
        'Base64 cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'tokens',
            rawName: 'tokens',
            description: 'Alias to list of Base64',
            isRequired: true,
            isDeprecated: false,
            explode: true,
            model: AliasModel(
              name: 'TokenList',
              model: ListModel(
                content: Base64Model(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasListBase64Cookie',
            context: context,
            summary: 'With alias list base64 cookie',
            description: 'Operation with alias-to-list-of-Base64 cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-list-base64-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'tokens', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'tokens',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'TokenList');

          const expectedMethod = r'''
            Options _options({required TokenList tokens}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              _$cookieParts.addAll(
  tokens
                      .map((e) => e.toBase64String())
                      .toList()
                      .toForm(r'tokens', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates EncodingException for alias-wrapped list of '
        'Binary cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'blobs',
            rawName: 'blobs',
            description: 'Alias to list of Binary',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'BlobList',
              model: ListModel(
                content: BinaryModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withAliasListBinaryCookie',
            context: context,
            summary: 'With alias list binary cookie',
            description: 'Operation with alias-to-list-of-Binary cookie',
            tags: const {},
            isDeprecated: false,
            path: '/alias-list-binary-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'blobs', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'blobs',
          );
          expect(param.required, isTrue);
          expect(param.type?.symbol, 'BlobList');

          const expectedMethod = r'''
            Options _options({required BlobList blobs}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              throw EncodingException(
                'Binary data cannot be form-encoded for cookie blobs',
              );
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates Cookie header for optional alias-wrapped '
        'Base64 cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'token',
            rawName: 'token',
            description: 'Optional alias to Base64',
            isRequired: false,
            isDeprecated: false,
            explode: true,
            model: AliasModel(
              name: 'BinaryToken',
              model: Base64Model(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withOptionalAliasBase64Cookie',
            context: context,
            summary: 'With optional alias base64 cookie',
            description: 'Operation with optional alias-to-Base64 cookie',
            tags: const {},
            isDeprecated: false,
            path: '/optional-alias-base64-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'token', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'token',
          );
          expect(param.required, isFalse);
          expect(param.type?.symbol, 'BinaryToken');
          expect((param.type! as TypeReference).isNullable, isTrue);

          const expectedMethod = r'''
            Options _options({BinaryToken? token}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              if (token != null) {
                _$cookieParts.addAll(
  token.toBase64String().toForm(r'token', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              }
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates EncodingException for optional alias-wrapped '
        'Binary cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'blob',
            rawName: 'blob',
            description: 'Optional alias to Binary',
            isRequired: false,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'BinaryBlob',
              model: BinaryModel(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withOptionalAliasBinaryCookie',
            context: context,
            summary: 'With optional alias binary cookie',
            description: 'Operation with optional alias-to-Binary cookie',
            tags: const {},
            isDeprecated: false,
            path: '/optional-alias-binary-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'blob', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'blob',
          );
          expect(param.required, isFalse);
          expect(param.type?.symbol, 'BinaryBlob');
          expect((param.type! as TypeReference).isNullable, isTrue);

          const expectedMethod = r'''
            Options _options({BinaryBlob? blob}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              if (blob != null) {
                throw EncodingException(
                  'Binary data cannot be form-encoded for cookie blob',
                );
              }
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates Cookie header for optional alias-wrapped list of '
        'Base64 cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'tokens',
            rawName: 'tokens',
            description: 'Optional alias to list of Base64',
            isRequired: false,
            isDeprecated: false,
            explode: true,
            model: AliasModel(
              name: 'TokenList',
              model: ListModel(
                content: Base64Model(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withOptionalAliasListBase64Cookie',
            context: context,
            summary: 'With optional alias list base64 cookie',
            description:
                'Operation with optional alias-to-list-of-Base64 cookie',
            tags: const {},
            isDeprecated: false,
            path: '/optional-alias-list-base64-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'tokens', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'tokens',
          );
          expect(param.required, isFalse);
          expect(param.type?.symbol, 'TokenList');
          expect((param.type! as TypeReference).isNullable, isTrue);

          const expectedMethod = r'''
            Options _options({TokenList? tokens}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              if (tokens != null) {
                _$cookieParts.addAll(
  tokens
                        .map((e) => e.toBase64String())
                        .toList()
                        .toForm(r'tokens', explode: true, allowEmpty: true)
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}'),
);
              }
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates EncodingException for optional alias-wrapped list of '
        'Binary cookie parameter',
        () {
          final cookieParam = CookieParameterObject(
            name: 'blobs',
            rawName: 'blobs',
            description: 'Optional alias to list of Binary',
            isRequired: false,
            isDeprecated: false,
            explode: false,
            model: AliasModel(
              name: 'BlobList',
              model: ListModel(
                content: BinaryModel(context: context),
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'withOptionalAliasListBinaryCookie',
            context: context,
            summary: 'With optional alias list binary cookie',
            description:
                'Operation with optional alias-to-list-of-Binary cookie',
            tags: const {},
            isDeprecated: false,
            path: '/optional-alias-list-binary-cookie',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookieParam},
            responses: const {},
            securitySchemes: const {},
          );

          final method = generator.generateOptionsMethod(operation, [], [
            (normalizedName: 'blobs', parameter: cookieParam),
          ]);

          final param = method.optionalParameters.firstWhere(
            (p) => p.name == 'blobs',
          );
          expect(param.required, isFalse);
          expect(param.type?.symbol, 'BlobList');
          expect((param.type! as TypeReference).isNullable, isTrue);

          const expectedMethod = r'''
            Options _options({BlobList? blobs}) {
              final _$headers = <String, dynamic>{};
              _$headers['Accept'] = r'*/*';
              final _$cookieParts = <String>[];
              if (blobs != null) {
                throw EncodingException(
                  'Binary data cannot be form-encoded for cookie blobs',
                );
              }
              if (_$cookieParts.isNotEmpty) {
                _$headers[r'Cookie'] = _$cookieParts.join('; ');
              }
              return Options(
                method: 'GET',
                headers: _$headers,
                responseType: ResponseType.bytes,
                validateStatus: (_) => true,
              );
            }
          ''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });

    group('multipart content type', () {
      test('sets contentType to null for single multipart content type', () {
        final requestBody = RequestBodyObject(
          name: 'uploadBody',
          context: context,
          description: 'Multipart body',
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'UploadForm',
                isDeprecated: false,
                properties: const [],
                context: context,
                examples: const [],
              ),
              contentType: ContentType.multipart,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
          },
        );

        final operation = Operation(
          operationId: 'uploadFile',
          context: context,
          summary: 'Upload file',
          description: 'Upload a file',
          tags: const {},
          isDeprecated: false,
          path: '/upload',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Options _options() {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            return Options(
              method: 'POST',
              headers: _$headers,
              contentType: null,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final method = generator.generateOptionsMethod(operation, [], []);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('sets contentType to null for optional single multipart body', () {
        final requestBody = RequestBodyObject(
          name: 'optionalUploadBody',
          context: context,
          description: 'Optional multipart body',
          isRequired: false,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'UploadForm',
                isDeprecated: false,
                properties: const [],
                context: context,
                examples: const [],
              ),
              contentType: ContentType.multipart,
              rawContentType: 'multipart/form-data',
              examples: const [],
            ),
          },
        );

        final operation = Operation(
          operationId: 'uploadOptionalFile',
          context: context,
          summary: 'Upload optional file',
          description: 'Upload an optional file',
          tags: const {},
          isDeprecated: false,
          path: '/upload-optional',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Options _options() {
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            return Options(
              method: 'POST',
              headers: _$headers,
              contentType: null,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

        final method = generator.generateOptionsMethod(operation, [], []);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'sets contentType to null for multipart arm in multi-content body',
        () {
          final requestBody = RequestBodyObject(
            name: 'mixedBody',
            context: context,
            description: 'Mixed content body',
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
              RequestContent(
                model: ClassModel(
                  name: 'FormModel',
                  isDeprecated: false,
                  properties: const [],
                  context: context,
                  examples: const [],
                ),
                contentType: ContentType.multipart,
                rawContentType: 'multipart/form-data',
                examples: const [],
              ),
            },
          );

          final operation = Operation(
            operationId: 'createMixed',
            context: context,
            summary: 'Create mixed',
            description: 'Create with mixed content types',
            tags: const {},
            isDeprecated: false,
            path: '/mixed',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
          Options _options({required MixedBody body}) {
            final _$contentType = switch (body) {
              MixedBodyJson _ => r'application/json',
              MixedBodyFormData _ => null,
            };
            final _$headers = <String, dynamic>{};
            _$headers['Accept'] = r'*/*';
            return Options(
              method: 'POST',
              headers: _$headers,
              contentType: _$contentType,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
            );
          }
        ''';

          final method = generator.generateOptionsMethod(operation, [], []);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });
  });
}
