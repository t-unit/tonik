import 'package:tonik_core/tonik_core.dart';

/// Returns `true` when [start] is a named [MapModel]/[ListModel] whose
/// value/content graph reaches a typedef cycle. Detects direct cycles
/// (`Tree -> Map<String, Tree>`), nested (`Tree -> Map<String, List<Tree>>`),
/// and indirect (`A -> Map<String, B>` ↔ `B -> Map<String, A>`).
///
/// Cycles reachable from [start] do not need to pass through [start]
/// itself — the recovery (emit a local helper) is identical either way.
///
/// Returns `false` for anonymous maps/lists or non-collection models.
bool isRecursive(Model start) {
  final namedStart = _asNamedTypedef(start);
  if (namedStart == null) return false;

  final stack = <NamedModel>[namedStart];
  final visited = <Model>{start};

  return _reachesAny(_innerOf(start), stack, visited);
}

NamedModel? _asNamedTypedef(Model model) {
  if (model is MapModel && model.name != null) return model;
  if (model is ListModel && model.name != null) return model;
  return null;
}

bool _reachesAny(
  Model model,
  List<NamedModel> stack,
  Set<Model> visited,
) {
  final unwrapped = model.resolved;

  final named = _asNamedTypedef(unwrapped);
  if (named != null) {
    if (stack.any((entry) => identical(entry, unwrapped))) return true;
    if (!visited.add(unwrapped)) return false;
    stack.add(named);
    final found = _reachesAny(_innerOf(unwrapped), stack, visited);
    stack.removeLast();
    return found;
  }

  if (unwrapped is MapModel) {
    if (!visited.add(unwrapped)) return false;
    return _reachesAny(unwrapped.valueModel, stack, visited);
  }
  if (unwrapped is ListModel) {
    if (!visited.add(unwrapped)) return false;
    return _reachesAny(unwrapped.content, stack, visited);
  }
  return false;
}

Model _innerOf(Model model) {
  if (model is MapModel) return model.valueModel;
  if (model is ListModel) return model.content;
  return model;
}
