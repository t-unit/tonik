import 'package:code_builder/code_builder.dart';

/// Generates freezed-like copyWith infrastructure for a class.
///
/// This generates:
/// - A getter that returns the copyWith interface
/// - An abstract class (`$$<ClassName>CopyWith`)
/// - An implementation class (`_<ClassName>CopyWith`)
CopyWithResult? generateCopyWith({
  required String className,
  required List<({String normalizedName, TypeReference typeRef})> properties,
}) {
  if (properties.isEmpty) {
    return null;
  }

  final interfaceClassName = '\$\$${className}CopyWith';
  final implClassName = '_${className}CopyWith';

  return CopyWithResult(
    getter: _generateCopyWithGetter(
      className,
      interfaceClassName,
      implClassName,
    ),
    interfaceClass: _generateCopyWithInterface(
      className,
      interfaceClassName,
      implClassName,
      properties,
    ),
    implClass: _generateCopyWithImpl(
      className,
      interfaceClassName,
      implClassName,
      properties,
    ),
  );
}

/// Result of generating copyWith infrastructure.
class CopyWithResult {
  const CopyWithResult({
    required this.getter,
    required this.interfaceClass,
    required this.implClass,
  });

  /// The getter method to add to the main class.
  final Method getter;

  /// The abstract interface class.
  final Class interfaceClass;

  /// The implementation class.
  final Class implClass;
}

Method _generateCopyWithGetter(
  String className,
  String interfaceClassName,
  String implClassName,
) {
  return Method(
    (b) => b
      ..name = 'copyWith'
      ..type = MethodType.getter
      ..returns = TypeReference(
        (b) => b
          ..symbol = interfaceClassName
          ..types.add(refer(className)),
      )
      ..lambda = true
      ..body = Code('$implClassName(this)'),
  );
}

Class _generateCopyWithInterface(
  String className,
  String interfaceClassName,
  String implClassName,
  List<({String normalizedName, TypeReference typeRef})> properties,
) {
  // Generate call method parameters
  final callParams = properties.map(
    (prop) => Parameter(
      (b) => b
        ..name = prop.normalizedName
        ..named = true
        ..type = prop.typeRef.rebuild((b) => b..isNullable = true),
    ),
  );

  // Generate property getters
  final getters = properties.map(
    (prop) => Method(
      (b) => b
        ..name = prop.normalizedName
        ..type = MethodType.getter
        ..returns = prop.typeRef,
    ),
  );

  return Class(
    (b) => b
      ..name = interfaceClassName
      ..abstract = true
      ..types.add(refer(r'$Res'))
      ..constructors.add(
        Constructor(
          (b) => b
            ..factory = true
            ..requiredParameters.add(
              Parameter(
                (b) => b
                  ..name = 'value'
                  ..type = refer(className),
              ),
            )
            ..redirect = TypeReference(
              (b) => b
                ..symbol = implClassName
                ..types.add(refer(r'$Res')),
            ),
        ),
      )
      ..methods.add(
        Method(
          (b) => b
            ..name = 'call'
            ..returns = refer(r'$Res')
            ..optionalParameters.addAll(callParams),
        ),
      )
      ..methods.addAll(getters),
  );
}

Class _generateCopyWithImpl(
  String className,
  String interfaceClassName,
  String implClassName,
  List<({String normalizedName, TypeReference typeRef})> properties,
) {
  // Generate call method parameters using Object? with sentinel default
  final callParams = properties.map(
    (prop) => Parameter(
      (b) => b
        ..name = prop.normalizedName
        ..named = true
        ..type = refer('Object?', 'dart:core')
        ..defaultTo = const Code('_sentinel'),
    ),
  );

  // Generate property getters that delegate to _value
  final getters = properties.map(
    (prop) => Method(
      (b) => b
        ..name = prop.normalizedName
        ..type = MethodType.getter
        ..annotations.add(refer('override', 'dart:core'))
        ..returns = prop.typeRef
        ..lambda = true
        ..body = Code('_value.${prop.normalizedName}'),
    ),
  );

  // Build call method body using Code.scope to properly emit type references
  final callBody = _buildCallMethodBody(className, properties);

  return Class(
    (b) => b
      ..name = implClassName
      ..types.add(refer(r'$Res'))
      ..implements.add(
        TypeReference(
          (b) => b
            ..symbol = interfaceClassName
            ..types.add(refer(r'$Res')),
        ),
      )
      ..constructors.add(
        Constructor(
          (b) => b
            ..requiredParameters.add(
              Parameter(
                (b) => b..name = '_value',
              ).rebuild((b) => b..toThis = true),
            ),
        ),
      )
      ..fields.addAll([
        Field(
          (b) => b
            ..name = '_sentinel'
            ..static = true
            ..modifier = FieldModifier.constant
            ..assignment = refer('Object', 'dart:core').newInstance([]).code,
        ),
        Field(
          (b) => b
            ..name = '_value'
            ..modifier = FieldModifier.final$
            ..type = refer(className),
        ),
      ])
      ..methods.addAll(getters)
      ..methods.add(
        Method(
          (b) => b
            ..name = 'call'
            ..annotations.add(refer('override', 'dart:core'))
            ..returns = refer(r'$Res')
            ..optionalParameters.addAll(callParams)
            ..body = callBody,
        ),
      ),
  );
}

Code _buildCallMethodBody(
  String className,
  List<({String normalizedName, TypeReference typeRef})> properties,
) {
  if (properties.isEmpty) {
    return refer(className).call([]).asA(refer(r'$Res')).returned.statement;
  }

  final namedArgs = <String, Expression>{};
  for (final prop in properties) {
    final name = prop.normalizedName;
    // Use the original type for casting, not nullable.
    // The parameter is Object? with sentinel, but when we use it,
    // we cast back to the original type to pass to the constructor.
    final originalType = prop.typeRef;

    namedArgs[name] = refer('identical', 'dart:core')
        .call([refer(name), refer('_sentinel')])
        .conditional(
          refer('this').property(name),
          refer(name).asA(originalType),
        );
  }

  return refer(
    className,
  ).call([], namedArgs).asA(refer(r'$Res')).returned.statement;
}
