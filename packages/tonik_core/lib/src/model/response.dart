import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

@immutable
sealed class Response {
  const Response({
    required this.name,
    required this.context,
  });

  final String? name;
  final Context context;
}

@immutable
class ResponseAlias extends Response {
  const ResponseAlias({
    required super.name,
    required this.response,
    required super.context,
  });

  final Response response;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          response == other.response &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, response, context);

  @override
  String toString() => 'ResponseAlias(name: $name, response: $response)';
}

@immutable
class ResponseObject extends Response {
  const ResponseObject({
    required super.name,
    required super.context,
    required this.headers,
    required this.description,
    required this.body,
  });

  final Map<String, ResponseHeader> headers;
  final ResponseBody? body;
  final String description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResponseObject) return false;
    return name == other.name &&
        context == other.context &&
        const MapEquality<String, ResponseHeader>().equals(
          headers,
          other.headers,
        ) &&
        body == other.body &&
        description == other.description;
  }

  @override
  int get hashCode => Object.hash(
        name,
        context,
        const MapEquality<String, ResponseHeader>().hash(headers),
        body,
        description,
      );

  @override
  String toString() =>
      'ResponseObject(name: $name, context: $context, headers: $headers, '
      'description: $description, body: $body)';
}

@immutable
class ResponseBody {
  const ResponseBody({
    required this.model,
    required this.rawContentType,
    required this.contentType,
  });

  final Model model;
  final String rawContentType;
  final ContentType contentType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResponseBody) return false;
    return model == other.model &&
        rawContentType == other.rawContentType &&
        contentType == other.contentType;
  }

  @override
  int get hashCode => Object.hash(model, rawContentType);

  @override
  String toString() => 'ResponseBody(model: $model, contentType: $contentType)';
}
