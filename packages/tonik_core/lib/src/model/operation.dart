import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

class Operation({
  required final Context context,
  required final String path,
  required final HttpMethod method,
  required var Set<Tag> tags,
  required var bool isDeprecated,
  required var Set<RequestHeader> headers,
  required var Set<QueryParameter> queryParameters,
  required var Set<PathParameter> pathParameters,
  required var Set<CookieParameter> cookieParameters,
  required var Map<ResponseStatus, Response> responses,
  required var Set<SecurityScheme> securitySchemes,
  final String? operationId,
  var String? nameOverride,
  var String? summary,
  var String? description,
  var RequestBody? requestBody,
});

sealed class const ResponseStatus() implements Comparable<ResponseStatus> {
  int get _specificityRank => switch (this) {
    ExplicitResponseStatus() => 0,
    RangeResponseStatus() => 1,
    DefaultResponseStatus() => 2,
  };

  // Explicit codes take precedence over ranges, ranges over `default`; within a
  // class, order by status value so this is a total order and the standard
  // List.sort suffices.
  @override
  int compareTo(ResponseStatus other) {
    final byRank = _specificityRank.compareTo(other._specificityRank);
    if (byRank != 0) return byRank;
    return switch ((this, other)) {
      (
        ExplicitResponseStatus(statusCode: final a),
        ExplicitResponseStatus(statusCode: final b),
      ) =>
        a.compareTo(b),
      (
        RangeResponseStatus(min: final aMin, max: final aMax),
        RangeResponseStatus(min: final bMin, max: final bMax),
      ) =>
        aMin != bMin ? aMin.compareTo(bMin) : aMax.compareTo(bMax),
      _ => 0,
    };
  }
}

@immutable
class const DefaultResponseStatus() extends ResponseStatus {
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
class const ExplicitResponseStatus({required final int statusCode})
    extends ResponseStatus {
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
class const RangeResponseStatus({
  required final int min,
  required final int max,
}) extends ResponseStatus {
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

enum HttpMethod() {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
  trace,
}
