import 'package:tonik_core/tonik_core.dart';

bool isCollectionModel(Model model) {
  final resolved = model.resolved;
  return resolved is ListModel || resolved is MapModel;
}
