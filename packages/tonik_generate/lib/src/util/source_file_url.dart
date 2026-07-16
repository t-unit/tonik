import 'package:change_case/change_case.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Computes the targeted import URL for a generated source file.
///
/// Given a [packageName] (e.g. `'my_api'`), a [category] subdirectory
/// (e.g. `'model'`, `'operation'`), and the PascalCase [className],
/// returns a package URL like
/// `'package:my_api/src/model/my_class.dart'`.
String sourceFileUrl(String packageName, String category, String className) {
  return sourceFileUrlFromFileName(
    packageName,
    category,
    '${className.toSnakeCase()}.dart',
  );
}

/// Computes an import URL from an already generated source [fileName].
String sourceFileUrlFromFileName(
  String packageName,
  String category,
  String fileName,
) => 'package:$packageName/src/$category/$fileName';

/// Computes the import URL for a generated [model] file.
String modelSourceFileUrl(
  String packageName,
  NameManager nameManager,
  Model model,
) => sourceFileUrlFromFileName(
  packageName,
  'model',
  nameManager.modelFileName(model),
);
