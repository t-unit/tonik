import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart typedef files from 
/// alias and list model definitions.
@immutable
class TypedefGenerator {
  const TypedefGenerator({
    required this.nameManager,
    required this.package,
  });

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generateAlias(AliasModel model) =>
      _generateFile(generateAliasTypedef(model));

  ({String code, String filename}) generateList(ListModel model) =>
      _generateFile(generateListTypedef(model));

  @visibleForTesting
  TypeDef generateAliasTypedef(AliasModel model) =>
      _generateTypedefFromModel(model, model.model);

  @visibleForTesting
  TypeDef generateListTypedef(ListModel model) =>
      _generateTypedefFromModel(model, model);

  TypeDef _generateTypedefFromModel(Model model, Model definition) {
    final baseType = getTypeReference(definition, nameManager, package);

    return TypeDef(
      (b) =>
          b
            ..name = nameManager.modelName(model)
            ..definition = baseType,
    );
  }

  ({String code, String filename}) _generateFile(TypeDef typedef) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final snakeCaseName = typedef.name.toSnakeCase();
    final library = Library((b) => b.body.add(typedef));

    final buffer =
        StringBuffer()
          ..writeln('// Generated code - do not modify by hand\n')
          ..write(library.accept(emitter));

    return (code: buffer.toString(), filename: '$snakeCaseName.dart');
  }
}
