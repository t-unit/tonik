class Context {
  Context.initial() : path = List.unmodifiable([]);

  Context._(this.path);

  List<String> path;

  Context push(String name) {
    final newPath = List.of(path)..add(name);
    return Context._(List.unmodifiable(newPath));
  }

  Context pushAll(Iterable<String> names) {
    final newPath = List.of(path)..addAll(names);
    return Context._(List.unmodifiable(newPath));
  }
}
