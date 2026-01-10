import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart typedef files from
/// alias and list model definitions.
@immutable
class TypedefGenerator {
  const TypedefGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generateAlias(AliasModel model) =>
      _generateFile(generateAliasTypedef(model));

  ({String code, String filename}) generateList(ListModel model) =>
      _generateFile(generateListTypedef(model));

  @visibleForTesting
  TypeDef generateAliasTypedef(AliasModel model) {
    final isNullable = model.isNullable;

    final baseType = typeReference(
      model.model,
      nameManager,
      package,
      isNullableOverride: isNullable,
    );

    return TypeDef(
      (b) {
        b
          ..name = nameManager.modelName(model)
          ..definition = baseType
          ..docs.addAll(formatDocComment(model.description));

        if (model.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This typedef is deprecated.'),
            ]),
          );
        }
      },
    );
  }

  @visibleForTesting
  TypeDef generateListTypedef(ListModel model) {
    final isNullable = model.isNullable;

    final baseType = typeReference(
      model,
      nameManager,
      package,
      isNullableOverride: isNullable,
    );

    return TypeDef(
      (b) => b
        ..name = nameManager.modelName(model)
        ..definition = baseType,
    );
  }

  ({String code, String filename}) _generateFile(TypeDef typedef) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final snakeCaseName = typedef.name.toSnakeCase();
    final library = Library((b) => b.body.add(typedef));

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }
}
