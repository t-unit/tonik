import 'package:code_builder/code_builder.dart';

typedef CopyWithProperty = ({
  String normalizedName,
  TypeReference typeRef,
  bool isNullable,
  bool skipCast,
});

Method? generateCopyWith({
  required String className,
  required List<CopyWithProperty> properties,
}) {
  if (properties.isEmpty) return null;

  final namedArgs = <String, Expression>{};
  for (final prop in properties) {
    if (!prop.isNullable) {
      namedArgs[prop.normalizedName] = refer(prop.normalizedName)
          .ifNullThen(refer('this').property(prop.normalizedName));
      continue;
    }

    final originalType = prop.typeRef;
    final isDartCoreObjectNullable =
        originalType.symbol == 'Object' &&
        originalType.url == 'dart:core' &&
        (originalType.isNullable ?? false);
    final value = prop.skipCast || isDartCoreObjectNullable
        ? refer(prop.normalizedName)
        : refer(prop.normalizedName).asA(originalType);
    namedArgs[prop.normalizedName] = refer('identical', 'dart:core')
        .call([refer(prop.normalizedName), refer('_sentinel')])
        .conditional(refer('this').property(prop.normalizedName), value);
  }

  final closure = Method(
    (b) => b
      ..optionalParameters.addAll(
        properties.map(
          (prop) => Parameter(
            (b) => b
              ..name = prop.normalizedName
              ..named = true
              ..type = prop.isNullable
                  ? refer('Object?', 'dart:core')
                  : prop.typeRef.rebuild((b) => b..isNullable = true)
              ..defaultTo = prop.isNullable ? refer('_sentinel').code : null,
          ),
        ),
      )
      ..lambda = true
      ..body = refer(className).call([], namedArgs).code,
  );

  return Method(
    (b) => b
      ..name = 'copyWith'
      ..type = MethodType.getter
      ..returns = FunctionType(
        (b) => b
          ..returnType = refer(className)
          ..namedParameters.addEntries(
            properties.map(
              (prop) => MapEntry(
                prop.normalizedName,
                prop.typeRef.rebuild((b) => b..isNullable = true),
              ),
            ),
          ),
      )
      ..body = Block.of([
        if (properties.any((prop) => prop.isNullable))
          declareConst(
            '_sentinel',
            type: refer('Object', 'dart:core'),
          ).assign(refer('Object', 'dart:core').constInstance([])).statement,
        closure.closure.returned.statement,
      ]),
  );
}
