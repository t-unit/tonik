import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';

/// Shared entry-point logic for composite model generators (anyOf, allOf,
/// oneOf).
({String code, String filename}) generateCompositeLibrary({
  required Model model,
  required bool isNullable,
  required NameManager nameManager,
  required List<Spec> Function(String actualClassName) generateClasses,
}) {
  final emitter = DartEmitter(
    allocator: CorePrefixedAllocator(
      additionalImports: ['package:tonik_util/tonik_util.dart'],
    ),
    orderDirectives: true,
    useNullSafetySyntax: true,
  );

  final publicClassName = nameManager.modelName(model);
  final snakeCaseName = publicClassName.toSnakeCase();

  final actualClassName = isNullable
      ? nameManager.modelName(
          AliasModel(
            name: '\$Raw$publicClassName',
            model: model,
            context: model.context,
          ),
        )
      : publicClassName;

  final generatedClasses = generateClasses(actualClassName);

  final library = Library((b) {
    b.body.addAll(generatedClasses);

    if (isNullable) {
      b.body.add(
        TypeDef(
          (b) => b
            ..name = publicClassName
            ..definition = refer('$actualClassName?'),
        ),
      );
    }
  });

  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  final code = formatter.formatWithHeader(library.accept(emitter).toString());

  return (code: code, filename: '$snakeCaseName.dart');
}
