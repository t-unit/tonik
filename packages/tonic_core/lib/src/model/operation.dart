import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

@immutable
class Operation {
  const Operation({
    required this.operationId,
    required this.context,
    required this.summary,
    required this.description,
    required this.tags,
    required this.isDeprecated,
    required this.method,
    required this.headers,
    required this.queryParameters,
    required this.pathParameters,
    required this.responses,
  });

  final Set<Tag> tags;

  final String? operationId;
  final Context context;
  final bool isDeprecated;
  final String? summary;
  final String? description;

  final HttpMethod method;

  final Set<RequestHeader> headers;
  final Set<QueryParameter> queryParameters;
  final Set<PathParameter> pathParameters;

  final Map<ResponseStatus, ResponseBody> responses;
}

@immutable
sealed class ResponseStatus {
  const ResponseStatus();
}

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

enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
  trace;
}
