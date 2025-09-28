import 'package:meta/meta.dart';

@immutable
class License {
  const License({this.name, this.url});

  final String? name;
  final String? url;

  @override
  String toString() => 'License{name: $name, url: $url}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is License &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          url == other.url;

  @override
  int get hashCode => Object.hash(name, url);
}
