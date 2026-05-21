import 'package:tonik_core/tonik_core.dart';

/// Returns `true` when [start] is a named [MapModel] or [ListModel] that
/// reaches itself, directly or indirectly, through its value/content models.
///
/// A typedef'd [MapModel]/[ListModel] decoded inline cannot break the cycle
/// through a generated factory the way a class can (typedefs have no
/// constructor). When this predicate returns `true`, the expression builder
/// emits a local recursive helper instead of inlining.
///
/// Direct cycles (`Tree -> Map<String, Tree>`), nested cycles
/// (`Tree -> List<Tree>`, `Tree -> Map<String, List<Tree>>`), and indirect
/// cycles (`A -> Map<String, B>` <-> `B -> Map<String, A>`) are all detected.
///
/// Only typedef'd collections — [MapModel] and [ListModel] with a non-null
/// [NamedModel.name] — are considered. Inline (anonymous) maps/lists return
/// `false` because callers can still recurse through their content models
/// without re-entering the same builder shape; the `_buildXFromY` recursion
/// only blows the stack on a NAMED typedef whose value/content reaches itself.
///
/// Returns `false` unless [start] is a named [MapModel] or [ListModel].
///
/// Only the named typedef passed in as [start] is reported on; the function
/// never identifies a different model as the recursion target. The
/// `bool` return reflects that callers only need the yes/no answer.
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
