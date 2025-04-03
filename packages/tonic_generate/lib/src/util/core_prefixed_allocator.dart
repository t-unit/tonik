import 'package:code_builder/code_builder.dart';

/// A custom allocator that prefixes all imports, including 'dart:core'.
///
/// This implementation is based on code_builder's _PrefixedAllocator but
/// doesn't exclude any packages from prefixing.
class CorePrefixedAllocator implements Allocator {
  final _imports = <String, int>{};
  var _keys = 1;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    final url = reference.url;

    // Apply prefix to all imports, including dart:core
    if (url == null) {
      return symbol!;
    }

    return '_i${_imports.putIfAbsent(url, _nextKey)}.$symbol';
  }

  int _nextKey() => _keys++;

  @override
  Iterable<Directive> get imports =>
      _imports.keys.map((u) => Directive.import(u, as: '_i${_imports[u]}'));
}
