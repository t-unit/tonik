import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Normalizes models based on HTTP content type.
///
/// Ensures response/request body models match their HTTP content type,
/// regardless of what the schema says. This transformer is applied after
/// parsing completes.
@immutable
class ContentTypeNormalizer {
  const ContentTypeNormalizer();

  static final log = Logger('ContentTypeNormalizer');

  /// Applies content type normalization to an API document.
  ///
  /// Walks through all ResponseBody and RequestContent objects and normalizes
  /// their models based on content type.
  ///
  /// Returns a new document with normalized responses and request bodies.
  ApiDocument apply(ApiDocument document) {
    // Build a map from original to normalized request bodies
    final requestBodyMap = <RequestBody, RequestBody>{};
    for (final original in document.requestBodies) {
      final normalized = _normalizeRequestBody(original);
      requestBodyMap[original] = normalized;
    }

    // Build a map from original to normalized responses
    final responseMap = <Response, Response>{};
    for (final original in document.responses) {
      final normalized = _normalizeResponse(original);
      responseMap[original] = normalized;
    }

    final normalizedResponses = responseMap.values.toSet();
    final normalizedRequestBodies = requestBodyMap.values.toSet();

    // Update operations to point to normalized request bodies and responses
    final normalizedOperations = document.operations.map((operation) {
      final normalizedRequestBody = operation.requestBody != null
          ? requestBodyMap[operation.requestBody]
          : null;

      final normalizedOperationResponses = <ResponseStatus, Response>{};
      var responsesChanged = false;
      for (final entry in operation.responses.entries) {
        final normalized = responseMap[entry.value];
        if (normalized != null && !identical(normalized, entry.value)) {
          normalizedOperationResponses[entry.key] = normalized;
          responsesChanged = true;
        } else {
          normalizedOperationResponses[entry.key] = entry.value;
        }
      }

      // Only create new operation if something changed
      if ((normalizedRequestBody != null &&
              !identical(normalizedRequestBody, operation.requestBody)) ||
          responsesChanged) {
        return Operation(
          operationId: operation.operationId,
          context: operation.context,
          path: operation.path,
          method: operation.method,
          tags: operation.tags,
          isDeprecated: operation.isDeprecated,
          headers: operation.headers,
          queryParameters: operation.queryParameters,
          pathParameters: operation.pathParameters,
          cookieParameters: operation.cookieParameters,
          responses: normalizedOperationResponses,
          securitySchemes: operation.securitySchemes,
          nameOverride: operation.nameOverride,
          summary: operation.summary,
          description: operation.description,
          requestBody: normalizedRequestBody,
        );
      }
      return operation;
    }).toSet();

    return ApiDocument(
      title: document.title,
      version: document.version,
      models: document.models,
      responseHeaders: document.responseHeaders,
      requestHeaders: document.requestHeaders,
      servers: document.servers,
      operations: normalizedOperations,
      responses: normalizedResponses,
      queryParameters: document.queryParameters,
      pathParameters: document.pathParameters,
      cookieParameters: document.cookieParameters,
      requestBodies: normalizedRequestBodies,
    );
  }

  Response _normalizeResponse(Response response) {
    switch (response) {
      case ResponseAlias(:final response):
        final normalized = _normalizeResponse(response);
        if (identical(normalized, response)) {
          return response;
        }
        return ResponseAlias(
          name: response.name,
          context: response.context,
          response: normalized,
        );
      case ResponseObject(:final bodies):
        final normalizedBodies = <ResponseBody>{};
        var hasChanges = false;
        for (final body in bodies) {
          final normalized = _normalizeResponseBody(body, response.context);
          normalizedBodies.add(normalized);
          if (!identical(normalized, body)) {
            hasChanges = true;
          }
        }
        // Return original if nothing changed
        if (!hasChanges) {
          return response;
        }
        return ResponseObject(
          name: response.name,
          context: response.context,
          description: response.description,
          headers: response.headers,
          bodies: normalizedBodies,
        );
    }
  }

  ResponseBody _normalizeResponseBody(ResponseBody body, Context context) {
    final normalizedModel = _normalizeModel(
      body.model,
      body.contentType,
      context,
    );

    if (identical(normalizedModel, body.model)) {
      return body;
    }

    return ResponseBody(
      model: normalizedModel,
      rawContentType: body.rawContentType,
      contentType: body.contentType,
    );
  }

  RequestBody _normalizeRequestBody(RequestBody requestBody) {
    switch (requestBody) {
      case RequestBodyAlias(:final requestBody):
        final normalized = _normalizeRequestBody(requestBody);
        if (identical(normalized, requestBody)) {
          return requestBody;
        }
        return RequestBodyAlias(
          name: requestBody.name,
          context: requestBody.context,
          requestBody: normalized,
        );
      case RequestBodyObject(:final content):
        final normalizedContent = <RequestContent>{};
        var hasChanges = false;
        for (final contentItem in content) {
          final normalized = _normalizeRequestContent(
            contentItem,
            requestBody.context,
          );
          normalizedContent.add(normalized);
          if (!identical(normalized, contentItem)) {
            hasChanges = true;
          }
        }
        // Return original if nothing changed
        if (!hasChanges) {
          return requestBody;
        }
        return RequestBodyObject(
          name: requestBody.name,
          context: requestBody.context,
          description: requestBody.description,
          isRequired: requestBody.isRequired,
          content: normalizedContent,
        );
    }
  }

  RequestContent _normalizeRequestContent(
    RequestContent content,
    Context context,
  ) {
    final normalizedModel = _normalizeModel(
      content.model,
      content.contentType,
      context,
    );

    if (identical(normalizedModel, content.model)) {
      return content;
    }

    return RequestContent(
      model: normalizedModel,
      contentType: content.contentType,
      rawContentType: content.rawContentType,
    );
  }

  Model _normalizeModel(Model model, ContentType contentType, Context context) {
    return switch (contentType) {
      ContentType.bytes when model is! BinaryModel => _replaceToBinary(
        model,
        context,
      ),
      ContentType.text when model is! StringModel => _replaceToString(
        model,
        context,
      ),
      ContentType.json => model,
      _ => model,
    };
  }

  Model _replaceToBinary(Model originalModel, Context context) {
    log.warning(
      'Replacing ${originalModel.runtimeType} with BinaryModel '
      'for ContentType.bytes at $context',
    );
    return BinaryModel(context: context);
  }

  Model _replaceToString(Model originalModel, Context context) {
    log.warning(
      'Replacing ${originalModel.runtimeType} with StringModel '
      'for ContentType.text at $context',
    );
    return StringModel(context: context);
  }
}
