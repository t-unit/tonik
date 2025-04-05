import 'package:collection/collection.dart';
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
    required this.path,
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

  final String path;
  final HttpMethod method;

  final Set<RequestHeader> headers;
  final Set<QueryParameter> queryParameters;
  final Set<PathParameter> pathParameters;

  final Map<ResponseStatus, Response> responses;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Operation) return false;

    final deepEquals = const DeepCollectionEquality().equals;

    return operationId == other.operationId &&
        context == other.context &&
        summary == other.summary &&
        description == other.description &&
        deepEquals(tags, other.tags) &&
        isDeprecated == other.isDeprecated &&
        path == other.path &&
        method == other.method &&
        deepEquals(headers, other.headers) &&
        deepEquals(queryParameters, other.queryParameters) &&
        deepEquals(pathParameters, other.pathParameters) &&
        deepEquals(responses, other.responses);
  }

  @override
  int get hashCode {
    final deepHash = const DeepCollectionEquality().hash;

    return Object.hash(
      operationId,
      context,
      summary,
      description,
      deepHash(tags),
      isDeprecated,
      path,
      method,
      deepHash(headers),
      deepHash(queryParameters),
      deepHash(pathParameters),
      deepHash(responses),
    );
  }
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

enum HttpMethod { get, post, put, delete, patch, head, options, trace }
