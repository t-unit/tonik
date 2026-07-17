import 'package:tonik_generate/src/naming/name_manager.dart';

/// Computes the targeted import URL for a generated source file.
///
/// Given a [packageName] (e.g. `'my_api'`), a [category] subdirectory
/// (e.g. `'model'`, `'operation'`), and the PascalCase [className],
/// returns a package URL like
/// `'package:my_api/src/model/my_class.dart'`.
String sourceFileUrl(
  String packageName,
  String category,
  String className,
  NameManager nameManager,
) {
  return 'package:$packageName/src/$category/'
      '${nameManager.fileNameForClass(className)}';
}
