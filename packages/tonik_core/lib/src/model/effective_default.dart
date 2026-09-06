import 'package:tonik_core/src/model/model.dart';

/// Returns [localDefault] when set; otherwise falls back to [model]'s
/// enclosing schema default, following alias chains with cycle protection.
/// Defaults on individual composition members are not inherited.
Object? effectiveDefault(Object? localDefault, Model model) {
  if (localDefault != null) return localDefault;
  return switch (model) {
    AliasModel(:final defaultValue) ||
    CompositeModel(:final defaultValue) => defaultValue,
    _ => null,
  };
}
