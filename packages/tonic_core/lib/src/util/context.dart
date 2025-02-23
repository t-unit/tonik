import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class Context {
  Context.initial() : path = List.unmodifiable([]);

  const Context._(this.path);

  final List<String> path;

  Context push(String name) {
    final newPath = List.of(path)..add(name);
    return Context._(List.unmodifiable(newPath));
  }

  Context pushAll(Iterable<String> names) {
    final newPath = List.of(path)..addAll(names);
    return Context._(List.unmodifiable(newPath));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Context) return false;
    return const ListEquality<String>().equals(path, other.path);
  }

  @override
  int get hashCode => const ListEquality<String>().hash(path);

  @override
  String toString() => path.join('/');
}
