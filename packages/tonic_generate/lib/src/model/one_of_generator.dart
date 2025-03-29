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
            )
            ..methods.addAll([
              Method(
                (b) =>
                    b
                      ..name = 'toJson'
                      ..returns = refer('dynamic')
                      ..body = _generateToJsonBody(className, model)
                      ..lambda = false,
              ),
            ]),
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

  Code _generateToJsonBody(String className, OneOfModel model) {
    final cases = model.models
        .map((discriminatedModel) {
          final factoryName =
              discriminatedModel.discriminatorValue ??
              nameManger.modelName(discriminatedModel.model);
          final variantName = '$className${factoryName.toPascalCase()}';

          final isPrimitive = discriminatedModel.model is PrimitiveModel;
          final jsonValue = isPrimitive ? 'value' : 'value.toJson()';
          final discriminatorValue =
              discriminatedModel.discriminatorValue != null
                  ? "'${discriminatedModel.discriminatorValue}'"
                  : 'null';

          return '$variantName(:final value) => '
              '($jsonValue, $discriminatorValue)';
        })
        .join(',\n');

    final blocks = [
      Code(
        'final (dynamic json, String? discriminator) = switch (this) {\n'
        '$cases\n'
        '};\n',
      ),
    ];

    if (model.discriminator != null) {
      blocks.add(
        Code(
          'if (discriminator != null && json is Map<String, dynamic>) {\n'
          "  json.putIfAbsent('${model.discriminator}', () => discriminator);\n"
          '}\n\n',
        ),
      );
    }

    blocks.add(const Code('return json;'));

    return Block.of(blocks);
  }
}
