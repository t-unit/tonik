import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

class Operation {
  Operation({
    required this.context,
    required this.path,
    required this.method,
    required this.tags,
    required this.isDeprecated,
    required this.headers,
    required this.queryParameters,
    required this.pathParameters,
    required this.responses,
    required this.securitySchemes,
    this.operationId,
    this.nameOverride,
    this.summary,
    this.description,
    this.requestBody,
  });

  final String? operationId;
  final Context context;
  final String path;
  final HttpMethod method;

  String? nameOverride;
  String? summary;
  String? description;
  bool isDeprecated;
  Set<Tag> tags;
  Set<RequestHeader> headers;
  Set<QueryParameter> queryParameters;
  Set<PathParameter> pathParameters;
  RequestBody? requestBody;
  Map<ResponseStatus, Response> responses;
  Set<SecurityScheme> securitySchemes;
}

sealed class ResponseStatus {
  const ResponseStatus();
}

@immutable
class DefaultResponseStatus extends ResponseStatus {
  const DefaultResponseStatus();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DefaultResponseStatus) return false;
    return true;
  }

  @override
  int get hashCode => 0;
}

@immutable
class ExplicitResponseStatus extends ResponseStatus {
  const ExplicitResponseStatus({required this.statusCode});

  final int statusCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExplicitResponseStatus) return false;
    return statusCode == other.statusCode;
  }

  @override
  int get hashCode => statusCode.hashCode;

  @override
  String toString() => 'ExplicitResponseStatus(statusCode: $statusCode)';
}

@immutable
class RangeResponseStatus extends ResponseStatus {
  const RangeResponseStatus({required this.min, required this.max});

  final int min;
  final int max;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RangeResponseStatus) return false;
    return min == other.min && max == other.max;
  }

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'RangeResponseStatus(min: $min, max: $max)';
}

enum HttpMethod { get, post, put, delete, patch, head, options, trace }
