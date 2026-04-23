import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Creates a Dart expression that correctly deserializes a JSON value
/// to its Dart representation.
///
/// When [useImmutableCollections] is `true`, decoded lists and maps are
/// wrapped in `IList()` / `IMap()` constructors at every nesting level so
/// the result is `IList` / `IMap` throughout.
Expression buildFromJsonValueExpression(
  String value, {
  required Model model,
  required NameManager nameManager,
  required String package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);
  final nullable = isNullable || model.isEffectivelyNullable;

  switch (model) {
    case IntegerModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableInt' : 'decodeJsonInt',
          )
          .call([], contextParam);
    case NumberModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableNum' : 'decodeJsonNum',
          )
          .call([], contextParam);
    case DoubleModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableDouble' : 'decodeJsonDouble',
          )
          .call([], contextParam);
    case DecimalModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableBigDecimal' : 'decodeJsonBigDecimal',
          )
          .call([], contextParam);
    case StringModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableString' : 'decodeJsonString',
          )
          .call([], contextParam);
    case BooleanModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableBool' : 'decodeJsonBool',
          )
          .call([], contextParam);
    case DateTimeModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableDateTime' : 'decodeJsonDateTime',
          )
          .call([], contextParam);
    case DateModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableDate' : 'decodeJsonDate',
          )
          .call([], contextParam);
    case UriModel():
      return refer(value)
          .property(
            nullable ? 'decodeJsonNullableUri' : 'decodeJsonUri',
          )
          .call([], contextParam);
    case BinaryModel():
      final decodeExpr = refer(
        value,
      ).property('decodeJsonBinary').call([], contextParam);
      final wrapExpr = refer(
        'TonikFileBytes',
        'package:tonik_util/tonik_util.dart',
      ).call([decodeExpr]);
      return nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, wrapExpr)
          : wrapExpr;
    case Base64Model():
      final decodeExpr = refer(
        value,
      ).property('decodeJsonBase64').call([], contextParam);
      final wrapExpr = refer(
        'TonikFileBytes',
        'package:tonik_util/tonik_util.dart',
      ).call([decodeExpr]);
      return nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, wrapExpr)
          : wrapExpr;
    case ListModel():
      return _buildListFromJsonExpression(
        value,
        model,
        nameManager,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: isNullable,
        useImmutableCollections: useImmutableCollections,
      );
    case MapModel():
      return _buildMapFromJsonExpression(
        value,
        model,
        nameManager,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: nullable,
        useImmutableCollections: useImmutableCollections,
      );
    case ClassModel() || AllOfModel() || OneOfModel() || AnyOfModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        sourceFileUrl(package, 'model', className),
      ).property('fromJson').call([refer(value)]);
      return nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, expr)
          : expr;
    case EnumModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        sourceFileUrl(package, 'model', className),
      ).property('fromJson').call([refer(value)]);
      return nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, expr)
          : expr;
    case AliasModel():
      return buildFromJsonValueExpression(
        value,
        model: model.resolved,
        nameManager: nameManager,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: nullable,
        useImmutableCollections: useImmutableCollections,
      );
    case NeverModel():
      final throwExpr = generateJsonDecodingExceptionExpression(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
      return nullable
          ? refer(
              value,
            ).equalTo(literalNull).conditional(literalNull, throwExpr)
          : throwExpr;
    case AnyModel():
      return refer(value);
    case NamedModel() || CompositeModel():
      return generateJsonDecodingExceptionExpression(
        'Unsupported model type for JSON decoding.',
      );
  }
}

Expression _buildListFromJsonExpression(
  String value,
  ListModel model,
  NameManager nameManager, {
  String? package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final content = model.content;
  final contextParam = _buildContextParam(contextClass, contextProperty);

  // isNullable already accounts for model.isEffectivelyNullable via the
  // caller (buildFromJsonValueExpression), so no need to recompute here.
  //
  // When using immutable collections, always use the non-nullable decoder
  // internally. We handle null ourselves via a ternary wrapping IList(), so
  // that refer('IList', ficUrl) properly tracks the import.
  final effectiveNullable = !useImmutableCollections && isNullable;
  final listDecoder =
      effectiveNullable ? 'decodeJsonNullableList' : 'decodeJsonList';

  // Unwrap alias to get the underlying model
  final unwrappedContent = content is AliasModel ? content.model : content;

  Expression result;

  switch (unwrappedContent) {
    case final ListModel nestedList:
      final mapFunction = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = _buildListFromJsonExpression(
            'e',
            nestedList,
            nameManager,
            package: package,
            contextClass: contextClass,
            contextProperty: contextProperty,
            useImmutableCollections: useImmutableCollections,
          ).code,
      ).closure;
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      result = effectiveNullable
          ? listExpr
                .nullSafeProperty('map')
                .call([mapFunction])
                .property('toList')
                .call([])
          : listExpr
                .property('map')
                .call([mapFunction])
                .property('toList')
                .call([]);

    case ClassModel() ||
        AllOfModel() ||
        OneOfModel() ||
        AnyOfModel() ||
        EnumModel():
      final className = nameManager.modelName(unwrappedContent);
      // Use tear-off for fromJson
      final mapFunction = refer(
        className,
        package != null ? sourceFileUrl(package, 'model', className) : null,
      ).property('fromJson');
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      result = effectiveNullable
          ? listExpr
                .nullSafeProperty('map')
                .call([mapFunction])
                .property('toList')
                .call([])
          : listExpr
                .property('map')
                .call([mapFunction])
                .property('toList')
                .call([]);

    case final MapModel mapModel:
      final mapDecoderClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = _buildMapFromJsonExpression(
            'e',
            mapModel,
            nameManager,
            package: package,
            contextClass: contextClass,
            contextProperty: contextProperty,
            useImmutableCollections: useImmutableCollections,
          ).code,
      ).closure;
      final mapListExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      result = effectiveNullable
          ? mapListExpr
                .nullSafeProperty('map')
                .call([mapDecoderClosure])
                .property('toList')
                .call([])
          : mapListExpr
                .property('map')
                .call([mapDecoderClosure])
                .property('toList')
                .call([]);

    case DateTimeModel() || DateModel() || DecimalModel() || UriModel():
      final jsonType = _jsonTypeForPrimitive(unwrappedContent);
      final decodeMethod = _decodeMethodForPrimitive(unwrappedContent)!;
      final mapFunction = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = refer(
            'e',
          ).property(decodeMethod).call([], contextParam).code,
      ).closure;
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer(jsonType, 'dart:core')],
      );
      result = effectiveNullable
          ? listExpr
                .nullSafeProperty('map')
                .call([mapFunction])
                .property('toList')
                .call([])
          : listExpr
                .property('map')
                .call([mapFunction])
                .property('toList')
                .call([]);

    case BinaryModel():
      final mapFunction = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body =
              refer(
                'TonikFileBytes',
                'package:tonik_util/tonik_util.dart',
              ).call([
                refer('e').property('decodeJsonBinary').call([], contextParam),
              ]).code,
      ).closure;
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('String', 'dart:core')],
      );
      result = effectiveNullable
          ? listExpr
                .nullSafeProperty('map')
                .call([mapFunction])
                .property('toList')
                .call([])
          : listExpr
                .property('map')
                .call([mapFunction])
                .property('toList')
                .call([]);

    case Base64Model():
      final mapFunction = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body =
              refer(
                'TonikFileBytes',
                'package:tonik_util/tonik_util.dart',
              ).call([
                refer('e').property('decodeJsonBase64').call([], contextParam),
              ]).code,
      ).closure;
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('String', 'dart:core')],
      );
      result = effectiveNullable
          ? listExpr
                .nullSafeProperty('map')
                .call([mapFunction])
                .property('toList')
                .call([])
          : listExpr
                .property('map')
                .call([mapFunction])
                .property('toList')
                .call([]);

    case NeverModel():
      return generateJsonDecodingExceptionExpression(
        'Cannot decode List<NeverModel> - this type does not permit any value.',
      );

    default:
      final typeArg = typeReference(content, nameManager, package ?? '');
      result = refer(
        value,
      ).property(listDecoder).call([], contextParam, [typeArg]);
  }

  // When using immutable collections, wrap with IList() constructor to convert.
  // Using refer() ensures the fast_immutable_collections import is tracked.
  if (useImmutableCollections) {
    result = _wrapImmutable(
      'IList',
      result,
      isNullable: isNullable,
      value: value,
    );
  }

  return result;
}

Expression _buildMapFromJsonExpression(
  String value,
  MapModel model,
  NameManager nameManager, {
  String? package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);
  final valueModel = model.valueModel;

  // Build a decoder closure for map values.
  final decoderClosure = Method(
    (b) => b
      ..requiredParameters.add(Parameter((p) => p..name = 'v'))
      ..body = buildFromJsonValueExpression(
        'v',
        model: valueModel,
        nameManager: nameManager,
        package: package ?? '',
        contextClass: contextClass,
        contextProperty: contextProperty,
        useImmutableCollections: useImmutableCollections,
      ).code,
  ).closure;

  // When using immutable collections, always use non-nullable decoder and
  // handle null ourselves so that refer('IMap', ficUrl) tracks the import.
  final effectiveNullable = !useImmutableCollections && isNullable;
  final mapDecoder =
      effectiveNullable ? 'decodeJsonNullableMap' : 'decodeJsonMap';

  var result = refer(value).property(mapDecoder).call(
    [decoderClosure],
    contextParam,
  );

  // When using immutable collections, wrap with IMap() constructor to convert.
  // Using refer() ensures the fast_immutable_collections import is tracked.
  if (useImmutableCollections) {
    result = _wrapImmutable(
      'IMap',
      result,
      isNullable: isNullable,
      value: value,
    );
  }

  return result;
}

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Wraps [result] in an immutable collection constructor (`IList` or `IMap`).
///
/// For non-nullable results, generates `IList(result)` / `IMap(result)`.
/// For nullable results, generates `value == null ? null : IList(result)`.
/// The [result] expression must use a non-nullable decoder (guaranteed by
/// the caller setting `effectiveNullable = false`), and [value] is the
/// original JSON variable name for the null guard.
///
/// Using `refer(symbol, ficUrl)` ensures the `fast_immutable_collections`
/// import is automatically tracked by code_builder.
Expression _wrapImmutable(
  String symbol,
  Expression result, {
  required bool isNullable,
  required String value,
}) {
  final immutableRef = refer(symbol, _ficUrl);
  final wrapped = immutableRef.call([result]);
  if (!isNullable) {
    return wrapped;
  }
  return refer(value).equalTo(literalNull).conditional(literalNull, wrapped);
}

String? _decodeMethodForPrimitive(Model model) {
  if (model is IntegerModel) return 'decodeJsonInt';
  if (model is NumberModel) return 'decodeJsonNum';
  if (model is DoubleModel) return 'decodeJsonDouble';
  if (model is DecimalModel) return 'decodeJsonBigDecimal';
  if (model is StringModel) return 'decodeJsonString';
  if (model is BooleanModel) return 'decodeJsonBool';
  if (model is DateTimeModel) return 'decodeJsonDateTime';
  if (model is DateModel) return 'decodeJsonDate';
  if (model is UriModel) return 'decodeJsonUri';
  if (model is BinaryModel) return 'decodeJsonBinary';
  if (model is Base64Model) return 'decodeJsonBase64';
  return null;
}

String _jsonTypeForPrimitive(Model model) {
  if (model is DateTimeModel || model is DateModel || model is UriModel) {
    return 'String';
  }
  if (model is IntegerModel) return 'int';
  if (model is NumberModel || model is DoubleModel) return 'num';
  if (model is DecimalModel) return 'String';
  if (model is StringModel) return 'String';
  if (model is BooleanModel) return 'bool';
  if (model is BinaryModel) return 'String';
  if (model is Base64Model) return 'String';
  return 'Object?';
}

Map<String, Expression> _buildContextParam(
  String? contextClass,
  String? contextProperty,
) {
  if (contextClass != null || contextProperty != null) {
    return {
      'context': specLiteralString(
        (contextClass != null && contextProperty != null)
            ? '$contextClass.$contextProperty'
            : contextClass ?? contextProperty!,
      ),
    };
  }
  return <String, Expression>{};
}
