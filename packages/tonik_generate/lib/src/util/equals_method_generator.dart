import 'package:code_builder/code_builder.dart';

/// Generates an equals method for a class with the given properties.
///
/// [className] is the name of the class to generate the equals method for.
/// [properties] is a list of tuples containing the normalized property name
/// and whether it's a collection.
Method generateEqualsMethod({
  required String className,
  required List<({String normalizedName, bool hasCollectionValue})> properties,
}) {
  var hasCollectionProperties = false;
  final comparisons = <String>[];

  for (final prop in properties) {
    final name = prop.normalizedName;

    if (prop.hasCollectionValue) {
      hasCollectionProperties = true;
      comparisons.add('deepEquals.equals(other.$name, $name)');
    } else {
      comparisons.add('other.$name == $name');
    }
  }

  final methodBuilder =
      MethodBuilder()
        ..name = 'operator =='
        ..returns = refer('bool', 'dart:core')
        ..annotations.add(refer('override', 'dart:core'))
        ..requiredParameters.add(
          Parameter(
            (b) =>
                b
                  ..name = 'other'
                  ..type = refer('Object', 'dart:core'),
          ),
        );

  final codeLines = <Code>[
    Code.scope((allocate) {
      final identical = allocate(refer('identical', 'dart:core'));
      return 'if ($identical(this, other)) return true;';
    }),
  ];

  if (hasCollectionProperties) {
    codeLines.add(
      declareConst('deepEquals')
          .assign(
            refer(
              'DeepCollectionEquality',
              'package:collection/collection.dart',
            ).call([]),
          )
          .statement,
    );
  }

  if (properties.isEmpty) {
    codeLines.add(Code('return other is $className;'));
  } else {
    codeLines
      ..add(Code('return other is $className && '))
      ..add(Code('  ${comparisons.join(' && ')};'));
  }

  methodBuilder.body = Block.of(codeLines);

  return methodBuilder.build();
}
