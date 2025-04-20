import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/operation.dart';
import 'package:tonik_parse/src/model/path_item.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/tag.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/src/request_parameter_importer.dart';
import 'package:tonik_parse/src/response_importer.dart';

class OperationImporter {
  OperationImporter({
    required this.openApiObject,
    required this.parameterImporter,
    required this.responseImporter,
    required this.requestBodyImporter,
  });

  final RequestParameterImporter parameterImporter;
  final ResponseImporter responseImporter;
  final RequestBodyImporter requestBodyImporter;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['paths']);

  final OpenApiObject openApiObject;
  final log = Logger('OperationImporter');

  late Set<core.Operation> operations;
  late Set<core.Tag> validTags;

  void import() {
    validTags = {
      for (final tag in openApiObject.tags ?? <Tag>[])
        core.Tag(name: tag.name, description: tag.description),
    };

    operations = <core.Operation>{};

    for (final pathEntry in openApiObject.paths.entries) {
      final path = pathEntry.key;
      final pathItem = pathEntry.value;
      final context = rootContext.push(pathEntry.key);

      _addOperation(pathItem.get, context, core.HttpMethod.get, pathItem, path);
      _addOperation(pathItem.put, context, core.HttpMethod.put, pathItem, path);
      _addOperation(
        pathItem.post,
        context,
        core.HttpMethod.post,
        pathItem,
        path,
      );
      _addOperation(
        pathItem.delete,
        context,
        core.HttpMethod.delete,
        pathItem,
        path,
      );
      _addOperation(
        pathItem.patch,
        context,
        core.HttpMethod.patch,
        pathItem,
        path,
      );
      _addOperation(
        pathItem.head,
        context,
        core.HttpMethod.head,
        pathItem,
        path,
      );
      _addOperation(
        pathItem.options,
        context,
        core.HttpMethod.options,
        pathItem,
        path,
      );
      _addOperation(
        pathItem.trace,
        context,
        core.HttpMethod.trace,
        pathItem,
        path,
      );
    }
  }

  Map<core.ResponseStatus, core.Response> _importResponses(
    Map<String, ReferenceWrapper<Response>> responses,
    core.Context context,
  ) {
    final result = <core.ResponseStatus, core.Response>{};

    for (final entry in responses.entries) {
      final statusCode = entry.key;
      final response = entry.value;

      log.finer('Importing response $statusCode at ${context.path.join('.')}');

      final importedResponse = responseImporter.importResponse(
        name: null,
        wrapper: response,
        context: context.push(statusCode),
      );

      final status = _parseResponseStatus(statusCode);
      result[status] = importedResponse;
    }

    return result;
  }

  core.ResponseStatus _parseResponseStatus(String status) {
    if (status == 'default') {
      return const core.DefaultResponseStatus();
    }

    // Check for range pattern (e.g., '4XX', '5XX')
    final rangeMatch = RegExp(r'^([1-5])XX$').firstMatch(status);
    if (rangeMatch != null) {
      final rangeStart = int.parse('${rangeMatch.group(1)}00');
      return core.RangeResponseStatus(min: rangeStart, max: rangeStart + 99);
    }

    // Parse as explicit status code
    return core.ExplicitResponseStatus(statusCode: int.parse(status));
  }

  void _addOperation(
    Operation? operation,
    core.Context context,
    core.HttpMethod httpMethod,
    PathItem pathItem,
    String path,
  ) {
    if (operation == null) return;

    final methodContext = context.push(httpMethod.name);

    final tags =
        operation.tags
            ?.map(
              (name) => validTags.firstWhereOrNull((tag) => tag.name == name),
            )
            .nonNulls
            .toSet();

    final pathParameters = pathItem.parameters ?? [];
    final operationParameters = operation.parameters ?? [];
    final allParameters = [...pathParameters, ...operationParameters];

    final (headers, queryParams, pathParams) = parameterImporter
        .importOperationParameters(allParameters, context.push('parameters'));

    final responses = _importResponses(operation.responses, methodContext);

    core.RequestBody? requestBody;
    if (operation.requestBody != null) {
      requestBody = requestBodyImporter.importRequestBody(
        name: null,
        wrapper: operation.requestBody!,
        context: methodContext.push('body'),
      );
    }

    operations.add(
      core.Operation(
        method: httpMethod,
        operationId: operation.operationId,
        context: methodContext,
        path: path,
        tags: tags ?? {},
        isDeprecated: operation.isDeprecated ?? false,
        summary: operation.summary,
        description: operation.description,
        headers: headers,
        queryParameters: queryParams,
        pathParameters: pathParams,
        responses: responses,
        requestBody: requestBody,
      ),
    );
  }
}
