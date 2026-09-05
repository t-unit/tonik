import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

/// Builds backend-neutral request meaning from a normalized operation.
class OperationRequestPlanner {
  const OperationRequestPlanner({
    required this.backend,
    this.nameManager,
    this.package,
    this.useImmutableCollections = false,
  });

  final TransportBackend backend;
  final NameManager? nameManager;
  final String? package;
  final bool useImmutableCollections;

  OperationRequestPlan plan(
    Operation operation,
    NormalizedRequestParameters parameters,
  ) {
    final requestBody = operation.requestBody;
    final content = requestBody?.resolvedContent.toList() ?? const [];

    return OperationRequestPlan(
      method: operation.method,
      uri: refer(r'_$uri'),
      pathParameters: [
        for (final (:normalizedName, :parameter) in parameters.pathParameters)
          _pathValue(normalizedName, parameter),
      ],
      queryParameters: [
        for (final (:normalizedName, :parameter) in parameters.queryParameters)
          _queryValue(normalizedName, parameter),
      ],
      headers: [
        for (final (:normalizedName, :parameter) in parameters.headers)
          _headerValue(normalizedName, parameter),
      ],
      cookies: [
        for (final (:normalizedName, :parameter) in parameters.cookieParameters)
          _cookieValue(normalizedName, parameter),
      ],
      contentType: _contentTypeExpression(requestBody, content),
      cancellation: refer('cancellation'),
      response: _responseRequirements(operation),
      body: planBody(operation),
    );
  }

  RequestValuePlan _pathValue(
    String normalizedName,
    PathParameterObject parameter,
  ) => RequestValuePlan(
    rawName: parameter.rawName,
    normalizedName: normalizedName,
    value: refer(normalizedName),
    isRequired: parameter.isRequired,
    allowEmpty: parameter.allowEmptyValue,
    allowsMultiple: parameter.model.resolved is ListModel,
  );

  RequestValuePlan _queryValue(
    String normalizedName,
    QueryParameterObject parameter,
  ) => RequestValuePlan(
    rawName: parameter.rawName,
    normalizedName: normalizedName,
    value: refer(normalizedName),
    isRequired: parameter.isRequired,
    allowEmpty: parameter.allowEmptyValue,
    allowsMultiple: parameter.model.resolved is ListModel,
  );

  RequestValuePlan _headerValue(
    String normalizedName,
    RequestHeaderObject parameter,
  ) => RequestValuePlan(
    rawName: parameter.rawName,
    normalizedName: normalizedName,
    value: refer(normalizedName),
    isRequired: parameter.isRequired,
    allowEmpty: parameter.allowEmptyValue,
    allowsMultiple: parameter.model.resolved is ListModel,
  );

  RequestValuePlan _cookieValue(
    String normalizedName,
    CookieParameterObject parameter,
  ) => RequestValuePlan(
    rawName: parameter.rawName,
    normalizedName: normalizedName,
    value: refer(normalizedName),
    isRequired: parameter.isRequired,
    allowEmpty: false,
    allowsMultiple: parameter.model.resolved is ListModel,
  );

  Expression? _contentTypeExpression(
    RequestBody? requestBody,
    List<RequestContent> content,
  ) {
    if (content.length != 1 ||
        content.single.contentType == ContentType.multipart ||
        requestBody?.isRequired == false) {
      return null;
    }
    return literalString(content.single.wireContentType);
  }

  ResponseRequirements _responseRequirements(Operation operation) {
    final statuses = operation.responses.keys.toList()..sort();
    final contentTypes = <String>[];
    for (final response in operation.responses.values) {
      for (final body in response.resolved.bodies) {
        if (!contentTypes.contains(body.rawContentType)) {
          contentTypes.add(body.rawContentType);
        }
      }
    }

    return ResponseRequirements(
      expectsBytes: true,
      statuses: List.unmodifiable(statuses),
      contentTypes: List.unmodifiable(contentTypes),
    );
  }

  RequestBodyPlan planBody(Operation operation) {
    final requestBody = operation.requestBody;
    final content = requestBody?.resolvedContent.toList() ?? const [];
    if (requestBody == null || content.isEmpty) {
      return const AbsentBodyPlan();
    }

    final headers = extractOperationMultipartHeaderParamInfo(
      operation,
      nameManager: nameManager,
      package: package,
    );
    final variants = [
      for (final item in content)
        _contentPlan(
          item,
          isRequired: requestBody.isRequired,
          bodyAccessor: content.length > 1 ? 'value.value' : 'body',
          headerParameters: headers,
        ),
    ];
    if (variants.length == 1) return variants.single;

    return BodySelectionPlan(
      value: refer('body'),
      variants: variants,
      isRequired: requestBody.isRequired,
    );
  }

  PresentBodyPlan _contentPlan(
    RequestContent content, {
    required bool isRequired,
    required String bodyAccessor,
    required List<MultipartHeaderParamInfo> headerParameters,
  }) {
    if (content is MultipartRequestContent) {
      return MultipartBodyPlanner(
        backend: backend,
        nameManager: nameManager,
        package: package,
        useImmutableCollections: useImmutableCollections,
      ).plan(
        content,
        bodyAccessor: bodyAccessor,
        isRequired: isRequired,
        headerParameters: headerParameters,
      );
    }
    content as ModelRequestContent;
    final value = refer('body');
    return switch (content.contentType) {
      ContentType.json => JsonBodyPlan(
        value: value,
        rawContentType: content.rawContentType,
        isRequired: isRequired,
      ),
      ContentType.text => TextBodyPlan(
        value: value,
        rawContentType: content.rawContentType,
        encoding: content.textEncoding,
        isRequired: isRequired,
      ),
      ContentType.bytes => BytesBodyPlan(
        value: value,
        rawContentType: content.rawContentType,
        isRequired: isRequired,
      ),
      ContentType.form => FormBodyPlan(
        value: value,
        rawContentType: content.rawContentType,
        entries: _formEntries(content.model),
        isRequired: isRequired,
      ),
      ContentType.multipart => throw StateError(
        'Multipart content must own parts.',
      ),
    };
  }

  List<FormEntryPlan> _formEntries(Model model) {
    final resolved = model.resolved;
    if (resolved is! ClassModel) return const [];

    return [
      for (final (:normalizedName, :property) in normalizeProperties(
        resolved.properties.where((property) => !property.isReadOnly).toList(),
      ))
        FormEntryPlan(
          name: property.name,
          value: refer('body').property(normalizedName),
          isNullable: property.isNullable || !property.isRequired,
          allowsMultiple: property.model.resolved is ListModel,
        ),
    ];
  }
}
