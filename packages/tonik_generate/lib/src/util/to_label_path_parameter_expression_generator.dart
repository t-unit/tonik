import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

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
  final valueRef = refer(parameterName);

  final model = parameter.model;

  if (model is AnyModel) {
    return refer('encodeAnyToLabel', 'package:tonik_util/tonik_util.dart').call(
      [valueRef],
      {'explode': explode, 'allowEmpty': allowEmpty},
    );
  }

  if (model is ListModel) {
    final content = model.content;
    final contentModel = content is AliasModel ? content.resolved : content;

    if (contentModel is StringModel) {
      return valueRef.property('toLabel').call([], {
        'explode': explode,
        'allowEmpty': allowEmpty,
      });
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

  return valueRef.property('toLabel').call([], {
    'explode': explode,
    'allowEmpty': allowEmpty,
  });
}
