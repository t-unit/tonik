import 'package:tonik_core/src/model/model.dart';

/// Walks one step through an [AliasModel] only when [localDefault] is null;
/// the alias default never overrides a property/parameter's own default.
Object? effectiveDefault(Object? localDefault, Model model) {
  if (localDefault != null) return localDefault;
  return model is AliasModel ? model.defaultValue : null;
}
