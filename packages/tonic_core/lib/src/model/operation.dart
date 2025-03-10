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
