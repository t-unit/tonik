import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

@immutable
class Response {
  const Response({
    required this.name,
    required this.context,
    required this.headers,
    required this.description,
    this.body,
  });

  final String? name;
  final Context context;
  final Map<String, ResponseHeader> headers;
  final ResponseBody? body;
  final String description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Response) return false;
    return name == other.name &&
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
        const MapEquality<String, ResponseHeader>().hash(headers),
        body,
        description,
      );

  @override
  String toString() =>
      'Response(name: $name, context: $context, headers: $headers, '
      'description: $description, body: $body)';
}

enum ContentType { json }

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
