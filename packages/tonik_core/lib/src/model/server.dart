import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/server_variable.dart';

@immutable
class const Server({
  required final String url,
  final String? description,
  final List<ServerVariable> variables = const [],
}) {
  @override
  String toString() =>
      'Server{url: $url, description: $description, '
      'variables: $variables}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Server &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          description == other.description &&
          const ListEquality<ServerVariable>().equals(
            variables,
            other.variables,
          );

  @override
  int get hashCode => Object.hash(
    url,
    description,
    const ListEquality<ServerVariable>().hash(variables),
  );
}
