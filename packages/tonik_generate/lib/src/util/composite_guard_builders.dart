import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Shared builders for read-only and write-only guard methods used by
/// composite model generators (anyOf, allOf, oneOf).

/// Builds a read-only `currentEncodingShape` getter that throws.
Method buildReadOnlyCurrentEncodingShapeGetter(Code exceptionBody) {
  return Method(
    (b) => b
      ..name = 'currentEncodingShape'
      ..type = MethodType.getter
      ..returns = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      )
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `parameterProperties` method that throws.
Method buildReadOnlyParameterPropertiesMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..name = 'parameterProperties'
      ..returns = buildMapStringStringType()
      ..optionalParameters.addAll([
        buildBoolParameter('allowEmpty', defaultValue: true),
        buildBoolParameter('allowLists', defaultValue: true),
      ])
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `uriEncode` method that throws.
Method buildReadOnlyUriEncodeMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'uriEncode'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll([
        Parameter(
          (b) => b
            ..name = 'allowEmpty'
            ..type = refer('bool', 'dart:core')
            ..named = true
            ..required = true,
        ),
        Parameter(
          (b) => b
            ..name = 'useQueryComponent'
            ..type = refer('bool', 'dart:core')
            ..named = true
            ..defaultTo = literalBool(false).code,
        ),
      ])
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toJson` method that throws.
Method buildReadOnlyToJsonMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toJson'
      ..returns = refer('Object?', 'dart:core')
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toSimple` method that throws.
Method buildReadOnlyToSimpleMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toSimple'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toForm` method that throws.
Method buildReadOnlyToFormMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toForm'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildFormEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toLabel` method that throws.
Method buildReadOnlyToLabelMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toLabel'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toMatrix` method that throws.
Method buildReadOnlyToMatrixMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toMatrix'
      ..returns = refer('String', 'dart:core')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toDeepObject` method that throws.
Method buildReadOnlyToDeepObjectMethod(Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toDeepObject'
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(
            refer(
              'ParameterEntry',
              'package:tonik_util/tonik_util.dart',
            ),
          ),
      )
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a write-only `fromJson` factory constructor that throws.
Constructor buildWriteOnlyFromJsonConstructor(String className) {
  return Constructor(
    (b) => b
      ..factory = true
      ..name = 'fromJson'
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'json'
            ..type = refer('Object?', 'dart:core'),
        ),
      )
      ..lambda = true
      ..body = generateJsonDecodingExceptionExpression(
        '$className is write-only and cannot be decoded.',
        raw: true,
      ).code,
  );
}

/// Builds a write-only `fromSimple` factory constructor that throws.
Constructor buildWriteOnlyFromSimpleConstructor(String className) {
  return Constructor(
    (b) => b
      ..factory = true
      ..name = 'fromSimple'
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'value'
            ..type = refer('String?', 'dart:core'),
        ),
      )
      ..optionalParameters.add(
        buildBoolParameter('explode', required: true),
      )
      ..lambda = true
      ..body = generateSimpleDecodingExceptionExpression(
        '$className is write-only and cannot be decoded.',
        raw: true,
      ).code,
  );
}

/// Builds a write-only `fromForm` factory constructor that throws.
Constructor buildWriteOnlyFromFormConstructor(String className) {
  return Constructor(
    (b) => b
      ..factory = true
      ..name = 'fromForm'
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'value'
            ..type = refer('String?', 'dart:core'),
        ),
      )
      ..optionalParameters.add(
        buildBoolParameter('explode', required: true),
      )
      ..lambda = true
      ..body = generateFormDecodingExceptionExpression(
        '$className is write-only and cannot be decoded.',
        raw: true,
      ).code,
  );
}

/// Builds the `toDeepObject` method that delegates to `parameterProperties`.
Method buildToDeepObjectMethod() {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toDeepObject'
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(
            refer(
              'ParameterEntry',
              'package:tonik_util/tonik_util.dart',
            ),
          ),
      )
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {
              'allowEmpty': refer('allowEmpty'),
              'allowLists': literalBool(false),
            })
            .property('toDeepObject')
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
                'alreadyEncoded': literalBool(true),
              },
            )
            .returned
            .statement,
      ]),
  );
}
