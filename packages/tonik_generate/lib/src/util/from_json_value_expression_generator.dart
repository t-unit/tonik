import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/recursion_detector.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Creates a [BuiltExpression] that correctly deserializes a JSON value
/// to its Dart representation.
///
/// When [useImmutableCollections] is `true`, decoded lists and maps are
/// wrapped in `IList()` / `IMap()` constructors at every nesting level so
/// the result is `IList` / `IMap` throughout.
///
/// When [helperContext] is provided, self-referential `MapModel`/`ListModel`
/// typedefs are broken via local recursive functions returned in
/// [BuiltExpression.inlineFunctions]. If [helperContext] is omitted, a
/// fresh context is created and helpers cannot be shared with sibling
/// builders — every builder pass independently emits its own helpers.
BuiltExpression buildFromJsonValueExpression(
  String value, {
  required Model model,
  required NameManager nameManager,
  required String package,
  InlineHelperContext? helperContext,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final ctx =
      helperContext ?? InlineHelperContext(nameManager: nameManager);
  return _buildFromJson(
    value,
    model: model,
    nameManager: nameManager,
    package: package,
    helperContext: ctx,
    contextClass: contextClass,
    contextProperty: contextProperty,
    isNullable: isNullable,
    useImmutableCollections: useImmutableCollections,
  );
}

BuiltExpression _buildFromJson(
  String value, {
  required Model model,
  required NameManager nameManager,
  required String package,
  required InlineHelperContext helperContext,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);
  final nullable = isNullable || model.isEffectivelyNullable;

  switch (model) {
    case IntegerModel():
      return BuiltExpression.simple(
        refer(value)
            .property(nullable ? 'decodeJsonNullableInt' : 'decodeJsonInt')
            .call([], contextParam),
      );
    case NumberModel():
      return BuiltExpression.simple(
        refer(value)
            .property(nullable ? 'decodeJsonNullableNum' : 'decodeJsonNum')
            .call([], contextParam),
      );
    case DoubleModel():
      return BuiltExpression.simple(
        refer(value)
            .property(
              nullable ? 'decodeJsonNullableDouble' : 'decodeJsonDouble',
            )
            .call([], contextParam),
      );
    case DecimalModel():
      return BuiltExpression.simple(
        refer(value)
            .property(
              nullable
                  ? 'decodeJsonNullableBigDecimal'
                  : 'decodeJsonBigDecimal',
            )
            .call([], contextParam),
      );
    case StringModel():
      return BuiltExpression.simple(
        refer(value)
            .property(
              nullable ? 'decodeJsonNullableString' : 'decodeJsonString',
            )
            .call([], contextParam),
      );
    case BooleanModel():
      return BuiltExpression.simple(
        refer(value)
            .property(nullable ? 'decodeJsonNullableBool' : 'decodeJsonBool')
            .call([], contextParam),
      );
    case DateTimeModel():
      return BuiltExpression.simple(
        refer(value)
            .property(
              nullable ? 'decodeJsonNullableDateTime' : 'decodeJsonDateTime',
            )
            .call([], contextParam),
      );
    case DateModel():
      return BuiltExpression.simple(
        refer(value)
            .property(nullable ? 'decodeJsonNullableDate' : 'decodeJsonDate')
            .call([], contextParam),
      );
    case UriModel():
      return BuiltExpression.simple(
        refer(value)
            .property(nullable ? 'decodeJsonNullableUri' : 'decodeJsonUri')
            .call([], contextParam),
      );
    case BinaryModel():
      final decodeExpr = refer(
        value,
      ).property('decodeJsonBinary').call([], contextParam);
      final wrapExpr = refer(
        'TonikFileBytes',
        'package:tonik_util/tonik_util.dart',
      ).call([decodeExpr]);
      final body = nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, wrapExpr)
          : wrapExpr;
      return BuiltExpression.simple(body);
    case Base64Model():
      final decodeExpr = refer(
        value,
      ).property('decodeJsonBase64').call([], contextParam);
      final wrapExpr = refer(
        'TonikFileBytes',
        'package:tonik_util/tonik_util.dart',
      ).call([decodeExpr]);
      final body = nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, wrapExpr)
          : wrapExpr;
      return BuiltExpression.simple(body);
    case ListModel():
      return _buildListFromJsonExpression(
        value,
        model,
        nameManager,
        helperContext,
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
        helperContext,
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
      final body = nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, expr)
          : expr;
      return BuiltExpression.simple(body);
    case EnumModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        sourceFileUrl(package, 'model', className),
      ).property('fromJson').call([refer(value)]);
      final body = nullable
          ? refer(value).equalTo(literalNull).conditional(literalNull, expr)
          : expr;
      return BuiltExpression.simple(body);
    case AliasModel():
      return _buildFromJson(
        value,
        model: model.model,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: nullable,
        useImmutableCollections: useImmutableCollections,
      );
    case NeverModel():
      final throwExpr = generateJsonDecodingExceptionExpression(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
      final body = nullable
          ? refer(value)
                .equalTo(literalNull)
                .conditional(literalNull, throwExpr)
          : throwExpr;
      return BuiltExpression.simple(body);
    case AnyModel():
      return BuiltExpression.simple(refer(value));
    case NamedModel() || CompositeModel():
      return BuiltExpression.simple(
        generateJsonDecodingExceptionExpression(
          'Unsupported model type for JSON decoding.',
        ),
      );
  }
}

BuiltExpression _buildListFromJsonExpression(
  String value,
  ListModel model,
  NameManager nameManager,
  InlineHelperContext helperContext, {
  required String package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  if (_shouldUseHelper(model, helperContext)) {
    return _buildNamedTypedefHelperCall(
      value: value,
      model: model,
      nameManager: nameManager,
      helperContext: helperContext,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      isNullable: isNullable,
      useImmutableCollections: useImmutableCollections,
    );
  }

  return _buildListFromJsonBody(
    value,
    model,
    nameManager,
    helperContext,
    package: package,
    contextClass: contextClass,
    contextProperty: contextProperty,
    isNullable: isNullable,
    useImmutableCollections: useImmutableCollections,
  );
}

bool _shouldUseHelper(Model model, InlineHelperContext helperContext) {
  if (model is! NamedModel) return false;
  if (model.name == null) return false;
  return helperContext.isHelperEmitted(model, _decodePrefix) ||
      helperContext.isOnStack(model) ||
      isRecursive(model);
}

BuiltExpression _buildListFromJsonBody(
  String value,
  ListModel model,
  NameManager nameManager,
  InlineHelperContext helperContext, {
  required String package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final content = model.content;
  final contextParam = _buildContextParam(contextClass, contextProperty);

  // When useImmutableCollections is true we keep the non-nullable decoder
  // internally and handle null via a ternary wrapping IList(), so the
  // refer('IList', ficUrl) call inside _wrapImmutable still tracks the
  // import for the allocator.
  final effectiveNullable = !useImmutableCollections && isNullable;
  final listDecoder =
      effectiveNullable ? 'decodeJsonNullableList' : 'decodeJsonList';

  final unwrappedContent = content is AliasModel ? content.model : content;
  final inlineFunctions = <InlineHelper>[];

  Expression result;

  switch (unwrappedContent) {
    case final ListModel nestedList:
      final inner = _buildListFromJsonExpression(
        'e',
        nestedList,
        nameManager,
        helperContext,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        useImmutableCollections: useImmutableCollections,
      );
      inlineFunctions.addAll(inner.inlineFunctions);
      final mapFunction = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = inner.unsafeRawBody.code,
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
      final mapFunction = refer(
        className,
        sourceFileUrl(package, 'model', className),
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
      final inner = _buildMapFromJsonExpression(
        'e',
        mapModel,
        nameManager,
        helperContext,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        useImmutableCollections: useImmutableCollections,
      );
      inlineFunctions.addAll(inner.inlineFunctions);
      final mapDecoderClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = inner.unsafeRawBody.code,
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
      return BuiltExpression.simple(
        generateJsonDecodingExceptionExpression(
          'Cannot decode List<NeverModel> - this type does not permit any '
          'value.',
        ),
      );

    default:
      final typeArg = typeReference(content, nameManager, package);
      result = refer(
        value,
      ).property(listDecoder).call([], contextParam, [typeArg]);
  }

  if (useImmutableCollections) {
    result = _wrapImmutable(
      'IList',
      result,
      isNullable: isNullable,
      value: value,
    );
  }

  return BuiltExpression(body: result, inlineFunctions: inlineFunctions);
}

BuiltExpression _buildMapFromJsonExpression(
  String value,
  MapModel model,
  NameManager nameManager,
  InlineHelperContext helperContext, {
  required String package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  if (_shouldUseHelper(model, helperContext)) {
    return _buildNamedTypedefHelperCall(
      value: value,
      model: model,
      nameManager: nameManager,
      helperContext: helperContext,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      isNullable: isNullable,
      useImmutableCollections: useImmutableCollections,
    );
  }

  return _buildMapFromJsonBody(
    value,
    model,
    nameManager,
    helperContext,
    package: package,
    contextClass: contextClass,
    contextProperty: contextProperty,
    isNullable: isNullable,
    useImmutableCollections: useImmutableCollections,
  );
}

BuiltExpression _buildMapFromJsonBody(
  String value,
  MapModel model,
  NameManager nameManager,
  InlineHelperContext helperContext, {
  required String package,
  String? contextClass,
  String? contextProperty,
  bool isNullable = false,
  bool useImmutableCollections = false,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);
  final valueModel = model.valueModel;

  final innerBuilt = _buildFromJson(
    'v',
    model: valueModel,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    contextClass: contextClass,
    contextProperty: contextProperty,
    useImmutableCollections: useImmutableCollections,
  );

  final decoderClosure = Method(
    (b) => b
      ..requiredParameters.add(Parameter((p) => p..name = 'v'))
      ..body = innerBuilt.unsafeRawBody.code,
  ).closure;

  final effectiveNullable = !useImmutableCollections && isNullable;
  final mapDecoder =
      effectiveNullable ? 'decodeJsonNullableMap' : 'decodeJsonMap';

  var result = refer(value).property(mapDecoder).call(
    [decoderClosure],
    contextParam,
  );

  if (useImmutableCollections) {
    result = _wrapImmutable(
      'IMap',
      result,
      isNullable: isNullable,
      value: value,
    );
  }

  return BuiltExpression(
    body: result,
    inlineFunctions: innerBuilt.inlineFunctions,
  );
}

/// Emits a call to a local recursive `_decode<TypeName>(value)` helper and
/// declares the helper itself the first time the typedef is encountered.
///
/// [model] must be a [MapModel] or [ListModel] with a non-null `name` —
/// the only models emitted as typedefs.
BuiltExpression _buildNamedTypedefHelperCall({
  required String value,
  required Model model,
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  required String package,
  required String? contextClass,
  required String? contextProperty,
  required bool isNullable,
  required bool useImmutableCollections,
}) {
  final named = model as NamedModel;
  final typedefName = nameManager.modelName(model);
  final typedefUrl = sourceFileUrl(package, 'model', typedefName);
  final helperName = helperContext.reserveHelperName(named, _decodePrefix);

  final helpers = <InlineHelper>[];
  if (!helperContext.isHelperEmitted(named, _decodePrefix)) {
    helperContext
      ..markHelperEmitted(named, _decodePrefix)
      ..withRecursion(named, () {
        final inner = switch (model) {
          MapModel() => _buildMapFromJsonBody(
            'v',
            model,
            nameManager,
            helperContext,
            package: package,
            contextClass: contextClass,
            contextProperty: contextProperty,
            useImmutableCollections: useImmutableCollections,
          ),
          ListModel() => _buildListFromJsonBody(
            'v',
            model,
            nameManager,
            helperContext,
            package: package,
            contextClass: contextClass,
            contextProperty: contextProperty,
            useImmutableCollections: useImmutableCollections,
          ),
          _ => throw ArgumentError(
            'Decode helper only valid for named MapModel/ListModel; '
            'got ${model.runtimeType} for typedef "$typedefName"',
          ),
        };

        final returnType = refer(typedefName, typedefUrl);
        final paramType = refer('Object?', 'dart:core');
        helpers
          ..addAll(inner.inlineFunctions)
          ..add(
            InlineHelper(
              name: helperName,
              forwardDeclaration: Block.of([
                const Code('late final '),
                returnType.code,
                const Code(' Function('),
                paramType.code,
                Code(') $helperName;'),
              ]),
              assignment: Block.of([
                Code('$helperName = ('),
                paramType.code,
                const Code(' v) => '),
                inner.unsafeRawBody.code,
                const Code(';'),
              ]),
            ),
          );
      });
  }

  final call = refer(helperName).call([refer(value)]);
  final body = isNullable
      ? refer(value).equalTo(literalNull).conditional(literalNull, call)
      : call;

  return BuiltExpression(body: body, inlineFunctions: helpers);
}

const _decodePrefix = '_decode';

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

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
  final location = [?contextClass, ?contextProperty].join('.');
  if (location.isEmpty) return const <String, Expression>{};
  return {'context': specLiteralString(location)};
}
