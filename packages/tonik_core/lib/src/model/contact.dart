import 'package:meta/meta.dart';

@immutable
class Contact {
  const Contact({this.name, this.url, this.email});

  final String? name;
  final String? url;
  final String? email;

  @override
  String toString() => 'Contact{name: $name, url: $url, email: $email}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          url == other.url &&
          email == other.email;

  @override
  int get hashCode => Object.hash(name, url, email);
}
