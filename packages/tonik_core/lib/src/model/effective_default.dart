import 'package:tonik_core/src/model/model.dart';

/// Returns [localDefault] when set; otherwise falls back to [model]'s
/// default if [model] is an [AliasModel] (which itself walks the alias
/// chain with cycle protection). The alias default never overrides a
/// property/parameter's own local default.
Object? effectiveDefault(Object? localDefault, Model model) {
  if (localDefault != null) return localDefault;
  return model is AliasModel ? model.defaultValue : null;
}
