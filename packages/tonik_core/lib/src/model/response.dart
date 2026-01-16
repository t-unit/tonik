import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

sealed class Response {
  const Response({required this.name, required this.context});

  final String? name;
  final Context context;

  /// The description of the response.
  /// For aliases, this may override the referenced response's description.
  String? get description;

  /// Returns true if the response has no body and no headers.
  bool get isEmpty;

  /// Returns true if the response has any headers.
  bool get hasHeaders;

  /// Returns the number of bodies in the response.
  int get bodyCount;

  /// Returns the resolved response object.
  ResponseObject get resolved;
}

@immutable
class ResponseAlias extends Response {
  const ResponseAlias({
    required super.name,
    required this.response,
    required super.context,
    this.description,
  });

  final Response response;

  @override
  final String? description;

  @override
  bool get isEmpty => response.isEmpty;

  @override
  bool get hasHeaders => response.hasHeaders;

  @override
  int get bodyCount => response.bodyCount;

  @override
  ResponseObject get resolved => response.resolved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          response == other.response &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, response, description, context);

  @override
  String toString() =>
      'ResponseAlias(name: $name, response: $response, '
      'description: $description)';
}

@immutable
class ResponseObject extends Response {
  const ResponseObject({
    required super.name,
    required super.context,
    required this.headers,
    required this.description,
    required this.bodies,
  });

  final Map<String, ResponseHeader> headers;
  final Set<ResponseBody> bodies;

  @override
  final String description;

  @override
  bool get isEmpty => bodies.isEmpty && headers.isEmpty;

  @override
  bool get hasHeaders => headers.isNotEmpty;

  @override
  int get bodyCount => bodies.length;

  @override
  ResponseObject get resolved => this;

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
        bodies == other.bodies &&
        description == other.description;
  }

  @override
  int get hashCode => Object.hash(
    name,
    context,
    const MapEquality<String, ResponseHeader>().hash(headers),
    bodies,
    description,
  );

  @override
  String toString() =>
      'ResponseObject(name: $name, context: $context, headers: $headers, '
      'description: $description, bodies: $bodies)';
}

class ResponseBody {
  ResponseBody({
    required this.model,
    required this.rawContentType,
    required this.contentType,
  });

  Model model;
  String rawContentType;
  ContentType contentType;

  @override
  String toString() => 'ResponseBody(model: $model, contentType: $contentType)';
}
