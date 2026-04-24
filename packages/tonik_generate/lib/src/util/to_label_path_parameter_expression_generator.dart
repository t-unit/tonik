import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// Generates an expression for encoding a path parameter using label style.
///
/// Label encoding is used for path parameters in OpenAPI and follows the
/// simple encoding style with dot-prefixed values.
///
/// The generated expression calls the appropriate `toLabel` method on the
/// parameter value with the correct explode and allowEmpty settings.
///
/// For lists of non-string primitives, enums, or composite types (OneOf,
/// AnyOf), the items are first mapped to their URI-encoded string
/// representation before calling `toLabel` on the resulting `List<String>`.
Expression buildToLabelPathParameterExpression(
  String parameterName,
  PathParameterObject parameter,
) {
  final explode = literalBool(parameter.explode);
  final allowEmpty = literalBool(parameter.allowEmptyValue);
  final isNullable = parameter.model.isEffectivelyNullable;
  // Path parameters are always required; use ! assertion if type is nullable.
  final valueRef = isNullable
      ? refer(parameterName).nullChecked
      : refer(parameterName);

  final model = parameter.model;

  if (model is AnyModel) {
    return refer('encodeAnyToLabel', 'package:tonik_util/tonik_util.dart').call(
      [valueRef],
      {'explode': explode, 'allowEmpty': allowEmpty},
    );
  }

  if (model is ListModel) {
    final content = model.content;
    final contentModel = content.resolved;

    if (contentModel is StringModel) {
      return valueRef.property('toLabel').call([], {
        'explode': explode,
        'allowEmpty': allowEmpty,
      });
    }

    if (contentModel is BinaryModel) {
      return generateEncodingExceptionExpression(
        'Binary data cannot be label-encoded',
      );
    }

    // List<TonikFile> (base64): map each item through
    // toBase64String().uriEncode() then call toLabel().
    if (contentModel is Base64Model) {
      return valueRef
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer('e')
                    .property('toBase64String')
                    .call([])
                    .property('uriEncode')
                    .call([], {'allowEmpty': allowEmpty})
                    .code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toLabel')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalTrue,
            },
          );
    }

    // List<Map<String, V>>: map each item through
    // toParameterMap().uriEncode() then call toLabel().
    if (contentModel is MapModel) {
      return valueRef
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer('e')
                    .property('toParameterMap')
                    .call([])
                    .property('uriEncode')
                    .call([], {'allowEmpty': allowEmpty})
                    .code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toLabel')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalTrue,
            },
          );
    }

    if (contentModel is ClassModel) {
      return generateEncodingExceptionExpression(
        'Label encoding does not support arrays of complex types',
      );
    }

    // For AnyModel, AnyOfModel, OneOfModel, AllOfModel content,
    // use encodeAnyToUri since Object? doesn't have uriEncode method
    if (contentModel is AnyModel ||
        contentModel is AnyOfModel ||
        contentModel is OneOfModel ||
        contentModel is AllOfModel) {
      return valueRef
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer(
                  'encodeAnyToUri',
                  'package:tonik_util/tonik_util.dart',
                ).call([refer('e')], {'allowEmpty': allowEmpty}).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toLabel')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalTrue,
            },
          );
    }

    return valueRef
        .property('map')
        .call([
          Method(
            (b) => b
              ..requiredParameters.add(
                Parameter((b) => b..name = 'e'),
              )
              ..body = refer(
                'e',
              ).property('uriEncode').call([], {'allowEmpty': allowEmpty}).code,
          ).closure,
        ])
        .property('toList')
        .call([])
        .property('toLabel')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
            'alreadyEncoded': literalTrue,
          },
        );
  }

  if (model is BinaryModel) {
    return generateEncodingExceptionExpression(
      'Binary data cannot be label-encoded',
    );
  }

  // MapModel: convert to Map<String, String> via toParameterMap(), then
  // call toLabel() on the resulting map.
  if (model is MapModel) {
    return valueRef
        .property('toParameterMap')
        .call([])
        .property('toLabel')
        .call([], {
          'explode': explode,
          'allowEmpty': allowEmpty,
        });
  }

  // Base64Model: convert to base64 string via toBase64String(), then
  // call toLabel() on the resulting string.
  if (model is Base64Model) {
    return valueRef
        .property('toBase64String')
        .call([])
        .property('toLabel')
        .call([], {
          'explode': explode,
          'allowEmpty': allowEmpty,
        });
  }

  return valueRef.property('toLabel').call([], {
    'explode': explode,
    'allowEmpty': allowEmpty,
  });
}
