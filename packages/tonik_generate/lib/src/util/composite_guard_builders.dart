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
      ..returns = buildMapStringPropertyValueType()
      ..optionalParameters.addAll(buildParameterPropertiesParameters())
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
      ..optionalParameters.addAll(buildUriEncodeParameters())
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
      ..optionalParameters.addAll(buildSimpleEncodingParameters())
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
      ..returns = buildParameterEntryListType()
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
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
      ..optionalParameters.addAll(buildDeepObjectEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only delimited method ([methodName]) that throws.
Method _buildReadOnlyToDelimitedMethod(String methodName, Code exceptionBody) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = methodName
      ..returns = buildParameterEntryListType()
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildDelimitedEncodingParameters())
      ..lambda = true
      ..body = exceptionBody,
  );
}

/// Builds a read-only `toPipeDelimited` method that throws.
Method buildReadOnlyToPipeDelimitedMethod(Code exceptionBody) =>
    _buildReadOnlyToDelimitedMethod('toPipeDelimited', exceptionBody);

/// Builds a read-only `toSpaceDelimited` method that throws.
Method buildReadOnlyToSpaceDelimitedMethod(Code exceptionBody) =>
    _buildReadOnlyToDelimitedMethod('toSpaceDelimited', exceptionBody);

/// Builds a delimited method ([methodName]) delegating to
/// `parameterProperties`.
Method _buildToDelimitedMethod(String methodName) {
  return Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = methodName
      ..returns = buildParameterEntryListType()
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildDelimitedEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property(methodName)
            .call(
              [refer('paramName')],
              {
                'allowEmpty': refer('allowEmpty'),
                'allowReserved': refer('allowReserved'),
              },
            )
            .returned
            .statement,
      ]),
  );
}

/// Builds the `toPipeDelimited` method that delegates to `parameterProperties`.
Method buildToPipeDelimitedMethod() =>
    _buildToDelimitedMethod('toPipeDelimited');

/// Builds the `toSpaceDelimited` method that delegates to
/// `parameterProperties`.
Method buildToSpaceDelimitedMethod() =>
    _buildToDelimitedMethod('toSpaceDelimited');

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
      ..optionalParameters.addAll(buildDeepObjectEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property('toDeepObject')
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
                'allowReserved': refer('allowReserved'),
              },
            )
            .returned
            .statement,
      ]),
  );
}
