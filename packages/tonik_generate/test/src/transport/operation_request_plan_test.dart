import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_planner.dart';

void main() {
  group('OperationRequestPlan', () {
    test('retains every HTTP method without backend-specific values', () {
      for (final method in HttpMethod.values) {
        final plan = OperationRequestPlan(
          method: method,
          uri: refer(r'_$uri'),
          pathParameters: const [],
          queryParameters: const [],
          headers: const [],
          cookies: const [],
          contentType: null,
          followRedirects: true,
          maxRedirects: 5,
          cancellation: refer('cancelToken'),
          response: ResponseRequirements(
            expectsBytes: true,
            statuses: const [],
            contentTypes: const [],
          ),
          body: const AbsentBodyPlan(),
        );

        expect(plan.methodName, _methodNames[method]);
        expect(plan.body, isA<AbsentBodyPlan>());
      }
    });

    test('retains ordered query, header, and cookie semantics', () {
      final query = RequestValuePlan(
        rawName: 'tag',
        normalizedName: 'tag',
        value: refer('tag'),
        isRequired: false,
        allowEmpty: true,
        allowsMultiple: true,
      );
      final header = RequestValuePlan(
        rawName: 'X-Trace',
        normalizedName: 'xTrace',
        value: refer('xTrace'),
        isRequired: true,
        allowEmpty: false,
        allowsMultiple: false,
      );
      final cookie = RequestValuePlan(
        rawName: 'session',
        normalizedName: 'session',
        value: refer('session'),
        isRequired: true,
        allowEmpty: false,
        allowsMultiple: false,
      );

      final plan = OperationRequestPlan(
        method: HttpMethod.get,
        uri: refer(r'_$uri'),
        pathParameters: const [],
        queryParameters: [query, query],
        headers: [header],
        cookies: [cookie],
        contentType: literalString('application/json'),
        followRedirects: false,
        maxRedirects: 2,
        cancellation: refer('cancelToken'),
        response: ResponseRequirements(
          expectsBytes: true,
          statuses: const [ExplicitResponseStatus(statusCode: 200)],
          contentTypes: const ['application/json'],
        ),
        body: JsonBodyPlan(
          value: refer('body'),
          rawContentType: 'application/json',
          isRequired: false,
        ),
      );

      expect(plan.queryParameters, [same(query), same(query)]);
      expect(plan.headers.single, same(header));
      expect(plan.cookies.single, same(cookie));
      expect(plan.followRedirects, isFalse);
      expect(plan.maxRedirects, 2);
      expect(plan.body, isA<JsonBodyPlan>());
    });

    test('freezes request and response collections at construction', () {
      final queryParameters = <RequestValuePlan>[];
      final statuses = <ResponseStatus>[
        const ExplicitResponseStatus(statusCode: 200),
      ];
      final contentTypes = <String>['application/json'];
      final response = ResponseRequirements(
        expectsBytes: true,
        statuses: statuses,
        contentTypes: contentTypes,
      );
      final plan = OperationRequestPlan(
        method: HttpMethod.get,
        uri: refer(r'_$uri'),
        pathParameters: const [],
        queryParameters: queryParameters,
        headers: const [],
        cookies: const [],
        contentType: null,
        followRedirects: true,
        maxRedirects: 5,
        cancellation: refer('cancelToken'),
        response: response,
        body: const AbsentBodyPlan(),
      );

      queryParameters.add(
        RequestValuePlan(
          rawName: 'late',
          normalizedName: 'late',
          value: refer('late'),
          isRequired: false,
          allowEmpty: false,
          allowsMultiple: false,
        ),
      );
      statuses.add(const ExplicitResponseStatus(statusCode: 201));
      contentTypes.add('text/plain');

      expect(plan.queryParameters, isEmpty);
      expect(response.statuses, [
        const ExplicitResponseStatus(statusCode: 200),
      ]);
      expect(response.contentTypes, ['application/json']);
      expect(
        () => response.contentTypes.add('image/png'),
        throwsUnsupportedError,
      );
    });

    test('retains every body meaning as a distinct plan', () {
      final value = refer('body');
      final plans = <RequestBodyPlan>[
        const AbsentBodyPlan(),
        JsonBodyPlan(
          value: value,
          rawContentType: 'application/json',
          isRequired: true,
        ),
        TextBodyPlan(
          value: value,
          rawContentType: 'text/plain; charset=utf-8',
          encoding: 'utf-8',
          isRequired: true,
        ),
        BytesBodyPlan(
          value: value,
          rawContentType: 'application/octet-stream',
          isRequired: true,
        ),
        FormBodyPlan(
          value: value,
          rawContentType: 'application/x-www-form-urlencoded',
          entries: const [],
          isRequired: true,
        ),
        MultipartBodyPlan(
          value: value,
          rawContentType: 'multipart/form-data',
          parts: [
            MultipartPartPlan(
              name: 'item',
              value: refer('first'),
              source: MultipartPartSource.scalar,
              isNullable: false,
              filename: null,
              contentType: 'text/plain',
            ),
            MultipartPartPlan(
              name: 'item',
              value: refer('second'),
              source: MultipartPartSource.fileBytesOrPath,
              isNullable: true,
              filename: 'item.bin',
              contentType: 'application/octet-stream',
            ),
          ],
          isRequired: true,
        ),
      ];

      expect(plans.map((plan) => plan.runtimeType).toList(), [
        AbsentBodyPlan,
        JsonBodyPlan,
        TextBodyPlan,
        BytesBodyPlan,
        FormBodyPlan,
        MultipartBodyPlan,
      ]);

      final multipart = plans.last as MultipartBodyPlan;
      expect(multipart.parts.map((part) => part.name).toList(), [
        'item',
        'item',
      ]);
      expect(multipart.parts.last.source, MultipartPartSource.fileBytesOrPath);
      expect(multipart.parts.last.isNullable, isTrue);
      expect(multipart.parts.last.filename, 'item.bin');
      expect(multipart.parts.last.contentType, 'application/octet-stream');
    });
  });

  group('OperationRequestPlanner', () {
    const planner = OperationRequestPlanner();
    const parameters = NormalizedRequestParameters(
      pathParameters: [],
      queryParameters: [],
      headers: [],
      cookieParameters: [],
    );

    test('produces a complete plan for every HTTP method', () {
      final context = Context.initial();

      for (final method in HttpMethod.values) {
        final plan = planner.plan(
          _operation(context, method: method),
          parameters,
        );

        expect(plan.method, method);
        expect(plan.methodName, _methodNames[method]);
        expect(plan.body, isA<AbsentBodyPlan>());
        expect(plan.response.expectsBytes, isTrue);
        expect(
          plan.cancellation.accept(DartEmitter()).toString(),
          'cancellation',
        );
      }
    });

    test('creates one concrete plan for every request content kind', () {
      final context = Context.initial();
      final cases = <(ContentType, Type)>[
        (ContentType.json, JsonBodyPlan),
        (ContentType.text, TextBodyPlan),
        (ContentType.bytes, BytesBodyPlan),
        (ContentType.form, FormBodyPlan),
        (ContentType.multipart, MultipartBodyPlan),
      ];

      for (final (contentType, expectedType) in cases) {
        final operation = _operation(
          context,
          requestBody: RequestBodyObject(
            name: 'body',
            context: context,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: context),
                contentType: contentType,
                rawContentType: _rawContentTypes[contentType]!,
                examples: const [],
              ),
            },
          ),
        );

        expect(
          planner.plan(operation, parameters).body.runtimeType,
          expectedType,
        );
      }
    });

    test('retains multipart property order, duplicates, and file metadata', () {
      final context = Context.initial();
      final scalar = Property(
        name: 'item',
        model: StringModel(context: context),
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final file = Property(
        name: 'item',
        model: BinaryModel(context: context),
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
      final content = RequestContent(
        model: ClassModel(
          name: 'Upload',
          properties: [scalar, file],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data',
        examples: const [],
        multipartEncoding: {
          scalar: const PartEncoding(
            contentType: ContentType.text,
            rawContentType: 'text/plain',
            headers: null,
            style: null,
            explode: null,
            allowReserved: null,
          ),
          file: const PartEncoding(
            contentType: ContentType.bytes,
            rawContentType: 'application/octet-stream',
            headers: null,
            style: null,
            explode: null,
            allowReserved: null,
          ),
        },
      );
      final operation = _operation(
        context,
        requestBody: RequestBodyObject(
          name: 'upload',
          context: context,
          description: null,
          isRequired: true,
          content: {content},
        ),
      );

      final plan = planner.plan(operation, parameters);
      final body = plan.body as MultipartBodyPlan;

      expect(body.parts.map((part) => part.name).toList(), ['item', 'item']);
      expect(body.parts.first.source, MultipartPartSource.scalar);
      expect(body.parts.first.contentType, 'text/plain');
      expect(body.parts.last.source, MultipartPartSource.fileBytesOrPath);
      expect(body.parts.last.isNullable, isTrue);
      expect(body.parts.last.contentType, 'application/octet-stream');
    });

    test('retains response selectors and creates a variant body plan', () {
      final context = Context.initial();
      final operation = _operation(
        context,
        requestBody: RequestBodyObject(
          name: 'body',
          context: context,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              examples: const [],
            ),
          },
        ),
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            description: '',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
            },
          ),
          const DefaultResponseStatus(): ResponseObject(
            name: null,
            context: context,
            description: '',
            headers: const {},
            bodies: const {},
          ),
        },
      );

      final plan = planner.plan(operation, parameters);

      expect(plan.body, isA<BodySelectionPlan>());
      expect(
        (plan.body as BodySelectionPlan).variants.map(
          (body) => body.runtimeType,
        ),
        [JsonBodyPlan, TextBodyPlan],
      );
      expect(plan.response.statuses, [
        const ExplicitResponseStatus(statusCode: 200),
        const DefaultResponseStatus(),
      ]);
      expect(plan.response.contentTypes, ['application/json']);
    });
  });
}

const Map<HttpMethod, String> _methodNames = {
  HttpMethod.get: 'GET',
  HttpMethod.post: 'POST',
  HttpMethod.put: 'PUT',
  HttpMethod.delete: 'DELETE',
  HttpMethod.patch: 'PATCH',
  HttpMethod.head: 'HEAD',
  HttpMethod.options: 'OPTIONS',
  HttpMethod.trace: 'TRACE',
};

const Map<ContentType, String> _rawContentTypes = {
  ContentType.json: 'application/json',
  ContentType.text: 'text/plain; charset=utf-8',
  ContentType.bytes: 'application/octet-stream',
  ContentType.form: 'application/x-www-form-urlencoded',
  ContentType.multipart: 'multipart/form-data',
};

Operation _operation(
  Context context, {
  HttpMethod method = HttpMethod.post,
  RequestBody? requestBody,
  Map<ResponseStatus, Response> responses = const {},
}) => Operation(
  operationId: 'operation',
  context: context,
  path: '/resource',
  method: method,
  tags: const {},
  isDeprecated: false,
  headers: const {},
  queryParameters: const {},
  pathParameters: const {},
  cookieParameters: const {},
  requestBody: requestBody,
  responses: responses,
  securitySchemes: const {},
);
