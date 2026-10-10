import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';
import 'package:tonik_generate/src/operation/parse_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';

void main() {
  late NameManager names;
  late Operation operation;
  final emitter = DartEmitter(useNullSafetySyntax: true);

  setUp(() {
    names = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    final context = Context.initial();
    operation = Operation(
      operationId: 'getItems',
      context: context,
      summary: '',
      description: '',
      tags: const {},
      isDeprecated: false,
      path: '/items',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      securitySchemes: const {},
      responses: {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'Items',
          context: context,
          headers: const {},
          description: '',
          bodies: {
            ResponseBody(
              model: IntegerModel(context: context),
              rawContentType: 'application/x-ndjson',
              contentType: ContentType.bytes,
              examples: const [],
              delivery: ResponseDelivery.ndjson,
            ),
          },
        ),
      },
    );
  });

  test('Dio generates a typed stream with native Response metadata', () {
    final generator = OperationGenerator(
      nameManager: names,
      package: 'api',
      defaultsCache: OperationDefaultsCache(nameManager: names, package: 'api'),
      backendGenerator: const DioBackendGenerator(),
      operationBaseFilename: 'dio_operation.dart',
    );
    final generated = generator.generateClass(operation, 'GetItems');
    expect(
      generated.extend!.accept(emitter).toString(),
      'DioStreamingOperation<Stream<TonikResult<int,Response<Object?>>>>',
    );
    final call = generated.methods.singleWhere(
      (method) => method.name == 'call',
    );
    expect(
      call.returns!.accept(emitter).toString(),
      'Future<TonikResult<Stream<TonikResult<int,Response<Object?>>>,'
      'Response<Object?>>>',
    );
    final parse = generated.methods.singleWhere(
      (method) => method.name == '_parseResponse',
    );
    expect(
      parse.returns!.accept(emitter).toString(),
      'Stream<TonikResult<int,Response<Object?>>>',
    );
    expect(
      parse.requiredParameters.first.type!.accept(emitter).toString(),
      'Response<Object?>',
    );
    expect(parse.requiredParameters.last.type!.symbol, 'TonikCancellation');
  });

  test('HTTP generates a typed stream with BaseResponse metadata', () {
    final generator = OperationGenerator(
      nameManager: names,
      package: 'api',
      defaultsCache: OperationDefaultsCache(nameManager: names, package: 'api'),
      backendGenerator: const HttpBackendGenerator(),
      operationBaseFilename: 'http_operation.dart',
    );
    final generated = generator.generateClass(operation, 'GetItems');
    expect(
      generated.extend!.accept(emitter).toString(),
      'HttpStreamingOperation<Stream<TonikResult<int,BaseResponse>>>',
    );
    final call = generated.methods.singleWhere(
      (method) => method.name == 'call',
    );
    expect(
      call.returns!.accept(emitter).toString(),
      'Future<TonikResult<Stream<TonikResult<int,BaseResponse>>,BaseResponse>>',
    );
    final parse = generated.methods.singleWhere(
      (method) => method.name == '_parseResponse',
    );
    expect(
      parse.returns!.accept(emitter).toString(),
      'Stream<TonikResult<int,BaseResponse>>',
    );
    expect(parse.requiredParameters.first.type!.symbol, 'BaseResponse');
    expect(parse.requiredParameters.last.type!.symbol, 'TonikCancellation');
    final selection = generated.methods.singleWhere(
      (method) => method.name == '_isStreamingResponse',
    );
    expect(selection.returns!.symbol, 'bool?');
    expect(selection.requiredParameters.single.type!.symbol, 'BaseResponse');
  });

  test(
    'explicit streaming takes precedence over multipart content mapping',
    () {
      operation.responses.values.single.resolved.bodies.single.contentType =
          ContentType.multipart;
      final parse = ParseGenerator(
        nameManager: names,
        package: 'api',
        backendGenerator: const DioBackendGenerator(),
      ).generateParseResponseMethod(operation);
      final format = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      expect(
        collapseWhitespace(format(parse.accept(emitter).toString())),
        collapseWhitespace(
          format(r'''
        Stream<TonikResult<int, Response<Object?>>> _parseResponse(Response<Object?> response, TonikCancellation cancellation) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/x-ndjson'):
              final _$body = decodeResponseStream<int, Response<Object?>>(
                ((response.data as ResponseBody)).stream, decodeNdjson,
                (_$json) { return _$json.decodeJsonInt(); },
                cancellation: cancellation, response: response,
                sourceErrorType: (error) => error is DioException && error.type == DioExceptionType.cancel ? TonikErrorType.cancelled : TonikErrorType.network);
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
          }
        }
      '''),
        ),
      );
    },
  );

  test('Dio SSE frames events before existing JSON item conversion', () {
    final context = Context.initial();
    operation.responses[const ExplicitResponseStatus(
      statusCode: 200,
    )] = ResponseObject(
      name: 'Events',
      context: context,
      description: '',
      headers: const {},
      bodies: {
        ResponseBody(
          model: AnyModel(context: context),
          rawContentType: 'text/event-stream',
          contentType: ContentType.bytes,
          examples: const [],
          delivery: ResponseDelivery.sse,
        ),
      },
    );
    final parse = ParseGenerator(
      nameManager: names,
      package: 'api',
      backendGenerator: const DioBackendGenerator(),
    ).generateParseResponseMethod(operation);
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    expect(
      collapseWhitespace(format(parse.accept(emitter).toString())),
      collapseWhitespace(
        format(r'''
        Stream<TonikResult<Object?, Response<Object?>>> _parseResponse(Response<Object?> response, TonikCancellation cancellation) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'text/event-stream'):
              final _$body = decodeResponseStream<Object?, Response<Object?>>(
                ((response.data as ResponseBody)).stream, decodeSse,
                (_$json) { return _$json; },
                cancellation: cancellation, response: response,
                sourceErrorType: (error) => error is DioException && error.type == DioExceptionType.cancel ? TonikErrorType.cancelled : TonikErrorType.network);
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
          }
        }
      '''),
      ),
    );
  });

  test('HTTP SSE uses the shared streaming response and item converter', () {
    final context = Context.initial();
    operation.responses[const ExplicitResponseStatus(
      statusCode: 200,
    )] = ResponseObject(
      name: 'Events',
      context: context,
      description: '',
      headers: const {},
      bodies: {
        ResponseBody(
          model: AnyModel(context: context),
          rawContentType: 'text/event-stream',
          contentType: ContentType.bytes,
          examples: const [],
          delivery: ResponseDelivery.sse,
        ),
      },
    );
    final parse = ParseGenerator(
      nameManager: names,
      package: 'api',
      backendGenerator: const HttpBackendGenerator(),
    ).generateParseResponseMethod(operation);
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    expect(
      collapseWhitespace(format(parse.accept(emitter).toString())),
      collapseWhitespace(
        format(r'''
        Stream<TonikResult<Object?, BaseResponse>> _parseResponse(BaseResponse response, TonikCancellation cancellation) {
          final _$mediaType = extractMediaType(response.headers['content-type']);
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'text/event-stream'):
              final _$body = decodeResponseStream<Object?, BaseResponse>(
                ((response as StreamedResponse)).stream, decodeSse,
                (_$json) { return _$json; },
                cancellation: cancellation, response: response,
                sourceErrorType: (error) => error is RequestAbortedException && cancellation.isCancelled ? TonikErrorType.cancelled : TonikErrorType.network);
              return _$body;
            default:
              final _$content = response.headers['content-type'] ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
          }
        }
      '''),
      ),
    );
  });
}
