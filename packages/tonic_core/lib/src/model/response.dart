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

  final String name;
  final Context context;
  final Map<String, ResponseHeader> headers;
  final Model? body;
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
