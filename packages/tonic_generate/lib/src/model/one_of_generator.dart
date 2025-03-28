import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

/// A generator for creating sealed Dart classes from OneOf model definitions.
@immutable
class OneOfGenerator {
  const OneOfGenerator({required this.nameManger, required this.package});

  final NameManger nameManger;
  final String package;

  ({String code, String filename}) generate(OneOfModel model) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final className = nameManger.modelName(model);
    final snakeCaseName = className.toSnakeCase();

    final library = Library((b) {
      b.directives.add(Directive.part('$snakeCaseName.freezed.dart'));
      b.body.add(generateClass(model));
    });

    final buffer =
        StringBuffer()
          ..writeln('// Generated code - do not modify by hand\n')
          ..write(library.accept(emitter));

    return (code: buffer.toString(), filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  Class generateClass(OneOfModel model) {
    final className = nameManger.modelName(model);

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(
              refer(
                'freezed',
                'package:freezed_annotation/freezed_annotation.dart',
              ),
            )
            ..mixins.add(refer('_\$$className'))
            ..sealed = true
            ..constructors.addAll(
              model.models.map(
                (discriminatedModel) => _generateConstructor(
                  className,
                  discriminatedModel,
                  model.discriminator,
                ),
              ),
            ),
    );
  }

  Constructor _generateConstructor(
    String parentClassName,
    DiscriminatedModel discriminatedModel,
    String? discriminator,
  ) {
    final rawName =
        discriminatedModel.discriminatorValue ??
        nameManger.modelName(discriminatedModel.model);

    final factoryName = rawName.toCamelCase();

    return Constructor(
      (b) =>
          b
            ..constant = true
            ..factory = true
            ..name = factoryName
            ..redirect = Reference(
              '$parentClassName${factoryName.toPascalCase()}',
            )
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'value'
                      ..type = getTypeReference(
                        discriminatedModel.model,
                        nameManger,
                        package,
                      ),
              ),
            ),
    );
  }
}
