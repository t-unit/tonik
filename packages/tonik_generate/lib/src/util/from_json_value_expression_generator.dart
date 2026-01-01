import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Creates a Dart expression that correctly deserializes a JSON value
/// to its Dart representation.
Expression buildFromJsonValueExpression(
  String value, {
  required Model model,
  required NameManager nameManager,
  required String package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);

  switch (model) {
    case IntegerModel():
      return refer(value)
          .property(isNullable ? 'decodeJsonNullableInt' : 'decodeJsonInt')
          .call([], contextParam);
    case NumberModel():
      return refer(value)
          .property(isNullable ? 'decodeJsonNullableNum' : 'decodeJsonNum')
          .call([], contextParam);
    case DoubleModel():
      return refer(value)
          .property(
            isNullable ? 'decodeJsonNullableDouble' : 'decodeJsonDouble',
          )
          .call([], contextParam);
    case DecimalModel():
      return refer(value)
          .property(
            isNullable
                ? 'decodeJsonNullableBigDecimal'
                : 'decodeJsonBigDecimal',
          )
          .call([], contextParam);
    case StringModel():
      return refer(value)
          .property(
            isNullable ? 'decodeJsonNullableString' : 'decodeJsonString',
          )
          .call([], contextParam);
    case BooleanModel():
      return refer(value)
          .property(isNullable ? 'decodeJsonNullableBool' : 'decodeJsonBool')
          .call([], contextParam);
    case DateTimeModel():
      return refer(value)
          .property(
            isNullable ? 'decodeJsonNullableDateTime' : 'decodeJsonDateTime',
          )
          .call([], contextParam);
    case DateModel():
      return refer(value)
          .property(isNullable ? 'decodeJsonNullableDate' : 'decodeJsonDate')
          .call([], contextParam);
    case UriModel():
      return refer(value)
          .property(isNullable ? 'decodeJsonNullableUri' : 'decodeJsonUri')
          .call([], contextParam);
    case BinaryModel():
      return refer(value)
          .property(
            isNullable ? 'decodeJsonNullableBinary' : 'decodeJsonBinary',
          )
          .call([], contextParam);
    case ListModel():
      return _buildListFromJsonExpression(
        value,
        model,
        nameManager,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: isNullable,
      );
    case ClassModel() || AllOfModel() || OneOfModel() || AnyOfModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        package,
      ).property('fromJson').call([refer(value)]);
      return isNullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, expr)
          : expr;
    case EnumModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        package,
      ).property('fromJson').call([refer(value)]);
      return isNullable
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
        isNullable: isNullable,
      );
    case NeverModel():
      return generateJsonDecodingExceptionExpression(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    case AnyModel():
      return refer(value);
    case NamedModel() || CompositeModel():
      throw UnimplementedError('$model is not supported');
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
}) {
  final content = model.content;
  final contextParam = _buildContextParam(contextClass, contextProperty);

  // Use nullable list decoder if isNullable
  final listDecoder = isNullable ? 'decodeJsonNullableList' : 'decodeJsonList';

  // Unwrap alias to get the underlying model
  final unwrappedContent = content is AliasModel ? content.model : content;

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
          ).code,
      ).closure;
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      return isNullable
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
      final mapFunction = refer(className, package).property('fromJson');
      final listExpr = refer(value).property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      return isNullable
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

    case DateTimeModel() || DateModel() || DecimalModel() || BinaryModel():
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
      return isNullable
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
      return refer(
        value,
      ).property(listDecoder).call([], contextParam, [typeArg]);
  }
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
  if (model is BinaryModel) return 'decodeJsonBinary';
  return null;
}

String _jsonTypeForPrimitive(Model model) {
  if (model is DateTimeModel || model is DateModel) return 'String';
  if (model is IntegerModel) return 'int';
  if (model is NumberModel || model is DoubleModel) return 'num';
  if (model is DecimalModel) return 'String';
  if (model is StringModel) return 'String';
  if (model is BooleanModel) return 'bool';
  if (model is BinaryModel) return 'String';
  return 'Object?';
}

Map<String, Expression> _buildContextParam(
  String? contextClass,
  String? contextProperty,
) {
  if (contextClass != null || contextProperty != null) {
    return {
      'context': literalString(
        (contextClass != null && contextProperty != null)
            ? '$contextClass.$contextProperty'
            : contextClass ?? contextProperty!,
        raw: true,
      ),
    };
  }
  return <String, Expression>{};
}
