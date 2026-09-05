import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class const Context._(final List<String> path) {
  new initial() : this._(List.unmodifiable([]));

  Context push(String name) {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty, got: $name');
    }

    final newPath = List.of(path)..add(name.normalize());
    return Context._(List.unmodifiable(newPath));
  }

  Context pushAll(Iterable<String> names) {
    if (names.isEmpty || names.any((n) => n.isEmpty)) {
      throw ArgumentError('Names cannot be empty, got: $names');
    }

    final newPath = List.of(path)..addAll(names.map((n) => n.normalize()));
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

extension on String {
  String normalize() {
    return replaceAll(RegExp('^/*'), '').replaceAll('/', '-');
  }
}
