import 'package:meta/meta.dart';

@immutable
class Server {
  const Server({required this.url, required this.description});

  final String url;
  final String? description;

  @override
  String toString() => 'Server{url: $url, description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Server &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          description == other.description;

  @override
  int get hashCode => Object.hash(url, description);
}
