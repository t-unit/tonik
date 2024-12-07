import 'package:meta/meta.dart';

@immutable
class Server {
  const Server({required this.url, required this.description});

  final String url;
  final String? description;

  @override
  String toString() => 'Server{url: $url, description: $description}';
}
