import 'package:meta/meta.dart';

@immutable
class ExternalDocumentation {
  const ExternalDocumentation({required this.url, required this.description});

  final String? description;
  final String url;

  @override
  String toString() =>
      'ExternalDocumentation{description: $description, url: $url}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalDocumentation &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          url == other.url;

  @override
  int get hashCode => Object.hash(description, url);
}
