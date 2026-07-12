import 'package:tonik_core/tonik_core.dart';

/// Whether the given [model] resolves to a collection type (list or map).
bool isCollectionModel(Model model) {
  final resolved = model.resolved;
  return resolved is ListModel || resolved is MapModel;
}
