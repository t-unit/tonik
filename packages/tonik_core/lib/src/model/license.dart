import 'package:meta/meta.dart';

@immutable
class const License({
  required final String? name,
  required final String? identifier,
  required final String? url,
}) {
  @override
  String toString() =>
      'License{name: $name, identifier: $identifier, url: $url}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is License &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          identifier == other.identifier &&
          url == other.url;

  @override
  int get hashCode => Object.hash(name, identifier, url);
}
