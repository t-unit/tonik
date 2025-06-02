import 'package:code_builder/code_builder.dart';

/// Generates a hash code method for a class with the given properties.
///
/// [properties] is a list of tuples containing the normalized property name
/// and whether it's a collection.
Method generateHashCodeMethod({
  required List<({String normalizedName, bool hasCollectionValue})> properties,
}) {
  final methodBuilder =
      MethodBuilder()
        ..name = 'hashCode'
        ..type = MethodType.getter
        ..returns = refer('int', 'dart:core')
        ..annotations.add(refer('override', 'dart:core'));

  final hasCollections = properties.any((p) => p.hasCollectionValue);
  final codeLines = <Code>[];

  if (properties.isEmpty) {
    methodBuilder
      ..lambda = true
      ..body = refer('runtimeType').property('hashCode').code;
    return methodBuilder.build();
  }

  if (properties.length == 1) {
    final prop = properties.first;
    if (prop.hasCollectionValue) {
      codeLines
        ..add(
          declareConst('deepEquals')
              .assign(
                refer(
                  'DeepCollectionEquality',
                  'package:collection/collection.dart',
                ).call([]),
              )
              .statement,
        )
        ..add(
          refer('deepEquals')
              .property('hash')
              .call([refer(prop.normalizedName)])
              .returned
              .statement,
        );
    } else {
      methodBuilder
        ..lambda = true
        ..body = refer(prop.normalizedName).property('hashCode').code;
      return methodBuilder.build();
    }
  } else {
    if (hasCollections) {
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

    final hashArgs =
        properties.map((prop) {
          if (prop.hasCollectionValue) {
            return refer(
              'deepEquals',
            ).property('hash').call([refer(prop.normalizedName)]);
          } else {
            return refer(prop.normalizedName);
          }
        }).toList();

    codeLines.add(
      refer(
        'Object',
        'dart:core',
      ).property('hashAll').call([literalList(hashArgs)]).returned.statement,
    );
  }

  methodBuilder.body = Block.of(codeLines);
  return methodBuilder.build();
}
