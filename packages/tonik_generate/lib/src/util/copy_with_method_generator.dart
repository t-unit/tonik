import 'package:code_builder/code_builder.dart';

/// Generates a copyWith method for a class with the given properties.
///
/// [className] is the name of the class to generate the copyWith method for.
/// [properties] is a list of tuples containing the normalized property name
/// and its type reference.
Method generateCopyWithMethod({
  required String className,
  required List<({String normalizedName, TypeReference typeRef})> properties,
}) {
  final parameters = <Parameter>[];
  final assignments = <Code>[];

  for (final prop in properties) {
    final name = prop.normalizedName;
    final typeRef = prop.typeRef;

    parameters.add(
      Parameter(
        (b) => b
          ..name = name
          ..named = true
          ..type = typeRef.rebuild((b) => b..isNullable = true),
      ),
    );

    assignments.add(Code('$name: $name ?? this.$name,'));
  }

  return Method(
    (b) => b
      ..name = 'copyWith'
      ..returns = refer(className)
      ..optionalParameters.addAll(parameters)
      ..body = Code(
        'return $className(\n  ${assignments.join('\n  ')}\n);',
      ),
  );
}
