import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';

@immutable
class ResponseWrapperGenerator {
  const ResponseWrapperGenerator({
    required this.nameManager,
    required this.package,
  });

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(Operation operation) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final (baseName, _) = nameManager.responseWrapperNames(operation);
    final classes = generateClasses(operation);

    final library = Library((b) {
      b.body.addAll(classes);
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());
    final filename = '${baseName.toSnakeCase()}.dart';
    return (code: code, filename: filename);
  }

  @visibleForTesting
  List<Class> generateClasses(Operation operation) {
    if (operation.responses.isEmpty) {
      throw ArgumentError('At least one response is required');
    }

    final (baseName, subclassNames) = nameManager.responseWrapperNames(
      operation,
    );

    final baseClass = Class(
      (b) =>
          b
            ..name = baseName
            ..sealed = true
            ..constructors.add(Constructor((b) => b..constant = true)),
    );

    final classes = <Class>[baseClass];

    for (final subclassName in subclassNames.values) {
      classes.add(
        Class(
          (b) =>
              b
                ..name = subclassName
                ..extend = refer(baseName)
                ..constructors.add(Constructor((b) => b..constant = true)),
        ),
      );
    }
    return classes;
  }
}
