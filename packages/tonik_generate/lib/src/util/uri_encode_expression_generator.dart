import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

BuiltExpression buildUriEncodeExpression(
  Expression valueExpression,
  Model model, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
  bool useImmutableCollections = false,
  bool allowReserved = false,
}) {
  return BuiltExpression.simple(
    _buildUriEncodeExpression(
      valueExpression,
      model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
      allowReserved: allowReserved,
    ),
  );
}

/// A `format: byte` ([Base64Model]) value is percent-encoded from its base64
/// text, not its raw bytes, so [receiver] is converted with `.toBase64String()`
/// before `.uriEncode()`.
String uriEncodeReceiver(Model model, String receiver) =>
    model.resolved is Base64Model ? '$receiver.toBase64String()' : receiver;

/// A `format: byte` ([Base64Model]) value is percent-encoded from its base64
/// text, not its raw bytes, so [receiver] is converted with `.toBase64String()`
/// before `.uriEncode()`.
Expression uriEncodeReceiverExpression(Model model, Expression receiver) =>
    model.resolved is Base64Model
    ? receiver.property('toBase64String').call([])
    : receiver;

Expression _buildUriEncodeExpression(
  Expression valueExpression,
  Model model, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
  bool useImmutableCollections = false,
  bool allowReserved = false,
}) {
  return switch (model) {
    StringModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel() =>
      uriEncodeReceiverExpression(
        model,
        valueExpression,
      ).property('uriEncode').call(
        [],
        {
          'allowEmpty': allowEmpty,
          'useQueryComponent': ?useQueryComponent,
          // Generated enums override uriEncode without an allowReserved
          // parameter, so the flag only applies to the built-in encoders.
          if (allowReserved && model is! EnumModel)
            'allowReserved': literalBool(true),
        },
      ),
    AnyModel() || AnyOfModel() || OneOfModel() || AllOfModel() =>
      refer(
        'encodeAnyToUri',
        'package:tonik_util/tonik_util.dart',
      ).call(
        [valueExpression],
        {
          'allowEmpty': allowEmpty,
          'useQueryComponent': ?useQueryComponent,
        },
      ),
    MapModel() => _buildMapUriEncodeExpression(
      valueExpression,
      model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    ),
    final ListModel m => _buildListUriEncodeExpression(
      valueExpression,
      m.content,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
      isContentNullable: m.isContentNullable || m.content.isEffectivelyNullable,
    ),
    AliasModel() => _buildUriEncodeExpression(
      valueExpression,
      model.model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
      allowReserved: allowReserved,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for URI encoding.',
    ),
  };
}

Expression _buildListUriEncodeExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression allowEmpty,
  required bool isContentNullable,
  Expression? useQueryComponent,
  bool useImmutableCollections = false,
}) {
  // When using immutable collections, the value is an IList. The .uriEncode()
  // extension is defined on List, not IList, so unlock to a regular List first.
  final listExpr = useImmutableCollections
      ? valueExpression.property('unlock')
      : valueExpression;

  // A null array element encodes to the empty string, coercing the element type
  // back to non-null `String` so the whole-list `uriEncode` extension matches.
  Expression nullGuard(Expression encoded) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), encoded)
      : encoded;

  return switch (contentModel) {
    StringModel() when isContentNullable =>
      listExpr
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(Parameter((b) => b..name = 'e'))
                ..body = refer('e').ifNullThen(literalString('')).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('uriEncode')
          .call(
            [],
            {
              'allowEmpty': allowEmpty,
              'useQueryComponent': ?useQueryComponent,
            },
          ),
    StringModel() => listExpr.property('uriEncode').call(
      [],
      {
        'allowEmpty': allowEmpty,
        'useQueryComponent': ?useQueryComponent,
      },
    ),
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel() =>
      listExpr
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = nullGuard(
                  _buildUriEncodeExpression(
                    refer('e'),
                    contentModel,
                    allowEmpty: allowEmpty,
                    useQueryComponent: useQueryComponent,
                  ),
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('uriEncode')
          .call(
            [],
            {
              'allowEmpty': allowEmpty,
              'useQueryComponent': ?useQueryComponent,
            },
          ),
    AnyModel() || AnyOfModel() || OneOfModel() || AllOfModel() =>
      listExpr
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body =
                    refer(
                          'encodeAnyToUri',
                          'package:tonik_util/tonik_util.dart',
                        )
                        .call(
                          [refer('e')],
                          {
                            'allowEmpty': allowEmpty,
                            'useQueryComponent': ?useQueryComponent,
                          },
                        )
                        .code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('uriEncode')
          .call(
            [],
            {
              'allowEmpty': allowEmpty,
              'useQueryComponent': ?useQueryComponent,
            },
          ),
    MapModel() => _buildListMapContentUriEncodeExpression(
      listExpr,
      contentModel,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    ),
    AliasModel() => _buildListUriEncodeExpression(
      valueExpression,
      contentModel.model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
      isContentNullable: isContentNullable,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for URI encoding.',
    ),
  };
}

Expression _buildMapUriEncodeExpression(
  Expression valueExpression,
  MapModel model, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) {
  final converted = buildMapToStringMapExpression(
    valueExpression,
    model,
    isNullable: false,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'Map with complex value types cannot be URI-encoded.',
    );
  }

  return converted.property('uriEncode').call(
    [],
    {
      'allowEmpty': allowEmpty,
      'useQueryComponent': ?useQueryComponent,
    },
  );
}

Expression _buildListMapContentUriEncodeExpression(
  Expression listExpression,
  MapModel contentModel, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) {
  final converted = buildMapToStringMapExpression(
    refer('e'),
    contentModel,
    isNullable: false,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'List of maps with complex value types cannot be URI-encoded.',
    );
  }

  return listExpression
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(
              Parameter((b) => b..name = 'e'),
            )
            ..body = converted.property('uriEncode').call(
              [],
              {
                'allowEmpty': allowEmpty,
                'useQueryComponent': ?useQueryComponent,
              },
            ).code,
        ).closure,
      ])
      .property('toList')
      .call([])
      .property('uriEncode')
      .call(
        [],
        {
          'allowEmpty': allowEmpty,
          'useQueryComponent': ?useQueryComponent,
        },
      );
}
