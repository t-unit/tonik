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
/// [receiverOverride], when provided, replaces `refer(value)` at the
/// top-level receiver position only — nested element closures (`e` / `v`)
/// keep their identifiers.
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
  Expression? receiverOverride,
}) {
  final ctx = helperContext ?? InlineHelperContext(nameManager: nameManager);
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
    receiverOverride: receiverOverride,
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
  Expression? receiverOverride,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);
  // The override is always a const literal, so the `receiver == null ? ...`
  // guards below would be dead.
  final nullable =
      receiverOverride == null && (isNullable || model.isEffectivelyNullable);
  final receiver = receiverOverride ?? refer(value);

  switch (model) {
    case IntegerModel():
      return BuiltExpression.simple(
        receiver
            .property(nullable ? 'decodeJsonNullableInt' : 'decodeJsonInt')
            .call([], contextParam),
      );
    case NumberModel():
      return BuiltExpression.simple(
        receiver
            .property(nullable ? 'decodeJsonNullableNum' : 'decodeJsonNum')
            .call([], contextParam),
      );
    case DoubleModel():
      return BuiltExpression.simple(
        receiver
            .property(
              nullable ? 'decodeJsonNullableDouble' : 'decodeJsonDouble',
            )
            .call([], contextParam),
      );
    case DecimalModel():
      return BuiltExpression.simple(
        receiver
            .property(
              nullable
                  ? 'decodeJsonNullableBigDecimal'
                  : 'decodeJsonBigDecimal',
            )
            .call([], contextParam),
      );
    case StringModel():
      return BuiltExpression.simple(
        receiver
            .property(
              nullable ? 'decodeJsonNullableString' : 'decodeJsonString',
            )
            .call([], contextParam),
      );
    case BooleanModel():
      return BuiltExpression.simple(
        receiver
            .property(nullable ? 'decodeJsonNullableBool' : 'decodeJsonBool')
            .call([], contextParam),
      );
    case DateTimeModel():
      return BuiltExpression.simple(
        receiver
            .property(
              nullable ? 'decodeJsonNullableDateTime' : 'decodeJsonDateTime',
            )
            .call([], contextParam),
      );
    case DateModel():
      return BuiltExpression.simple(
        receiver
            .property(nullable ? 'decodeJsonNullableDate' : 'decodeJsonDate')
            .call([], contextParam),
      );
    case UriModel():
      return BuiltExpression.simple(
        receiver
            .property(nullable ? 'decodeJsonNullableUri' : 'decodeJsonUri')
            .call([], contextParam),
      );
    case BinaryModel():
      final decodeExpr = receiver
          .property('decodeJsonBinary')
          .call([], contextParam);
      final wrapExpr = refer(
        'TonikFileBytes',
        'package:tonik_util/tonik_util.dart',
      ).call([decodeExpr]);
      final body = nullable
          ? receiver.equalTo(literalNull).conditional(literalNull, wrapExpr)
          : wrapExpr;
      return BuiltExpression.simple(body);
    case Base64Model():
      final decodeExpr = receiver
          .property('decodeJsonBase64')
          .call([], contextParam);
      final wrapExpr = refer(
        'TonikFileBytes',
        'package:tonik_util/tonik_util.dart',
      ).call([decodeExpr]);
      final body = nullable
          ? receiver.equalTo(literalNull).conditional(literalNull, wrapExpr)
          : wrapExpr;
      return BuiltExpression.simple(body);
    case ListModel():
      // Forward the combined `nullable` (caller flag OR
      // model.isEffectivelyNullable) — _buildListFromJsonExpression doesn't
      // re-derive intrinsic nullability, so dropping this would make nullable
      // list-of-Never emit a bare throw and reintroduce the unused `_$json`
      // local.
      return _buildListFromJsonExpression(
        value,
        model,
        nameManager,
        helperContext,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: nullable,
        useImmutableCollections: useImmutableCollections,
        receiverOverride: receiverOverride,
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
        receiverOverride: receiverOverride,
      );
    case ClassModel() || AllOfModel() || OneOfModel() || AnyOfModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        sourceFileUrl(package, 'model', className),
      ).property('fromJson').call([receiver]);
      final body = nullable
          ? receiver.equalTo(literalNull).conditional(literalNull, expr)
          : expr;
      return BuiltExpression.simple(body);
    case EnumModel():
      final className = nameManager.modelName(model);
      final expr = refer(
        className,
        sourceFileUrl(package, 'model', className),
      ).property('fromJson').call([receiver]);
      final body = nullable
          ? receiver.equalTo(literalNull).conditional(literalNull, expr)
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
        receiverOverride: receiverOverride,
      );
    case NeverModel():
      final throwExpr = generateJsonDecodingExceptionExpression(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
      final body = nullable
          ? receiver.equalTo(literalNull).conditional(literalNull, throwExpr)
          : throwExpr;
      return BuiltExpression.simple(body);
    case AnyModel():
      return BuiltExpression.simple(receiver);
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
  Expression? receiverOverride,
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
      receiverOverride: receiverOverride,
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
    receiverOverride: receiverOverride,
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
  Expression? receiverOverride,
}) {
  final content = model.content;
  final contextParam = _buildContextParam(contextClass, contextProperty);
  final receiver = receiverOverride ?? refer(value);

  // When useImmutableCollections is true we keep the non-nullable decoder
  // internally and handle null via a ternary wrapping IList(), so the
  // refer('IList', ficUrl) call inside _wrapImmutable still tracks the
  // import for the allocator.
  final effectiveNullable = !useImmutableCollections && isNullable;
  final listDecoder = effectiveNullable
      ? 'decodeJsonNullableList'
      : 'decodeJsonList';

  final unwrappedContent = content is AliasModel ? content.model : content;
  final isItemNullable =
      model.isContentNullable || content.isEffectivelyNullable;
  final inlineFunctions = <InlineHelper>[];

  // When items are nullable, the element decoder can't represent null itself,
  // so the list is decoded as Object? and each element short-circuits null
  // before decoding.
  Expression elementClosure(Expression decodeOfE) {
    if (!isItemNullable) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = decodeOfE.code,
      ).closure;
    }
    return Method(
      (b) => b
        ..requiredParameters.add(Parameter((b) => b..name = 'e'))
        ..body = refer('e')
            .equalTo(literalNull)
            .conditional(literalNull, decodeOfE)
            .code,
    ).closure;
  }

  // Decoders invoked directly on the element collapse to a null-aware call
  // when items are nullable; `?.` expresses the short-circuit without the
  // ternary the analyzer would flag.
  Expression methodOnElementClosure(String method) {
    final receiver = refer('e');
    final body = isItemNullable
        ? receiver.nullSafeProperty(method).call([], contextParam)
        : receiver.property(method).call([], contextParam);
    return Method(
      (b) => b
        ..requiredParameters.add(Parameter((b) => b..name = 'e'))
        ..body = body.code,
    ).closure;
  }

  Expression mapList(Expression listExpr, Expression closure) =>
      effectiveNullable
      ? listExpr
            .nullSafeProperty('map')
            .call([closure])
            .property('toList')
            .call([])
      : listExpr.property('map').call([closure]).property('toList').call([]);

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
      final mapFunction = elementClosure(inner.unsafeRawBody);
      final listExpr = receiver.property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      result = mapList(listExpr, mapFunction);

    case ClassModel() ||
        AllOfModel() ||
        OneOfModel() ||
        AnyOfModel() ||
        EnumModel():
      final className = nameManager.modelName(unwrappedContent);
      final fromJson = refer(
        className,
        sourceFileUrl(package, 'model', className),
      ).property('fromJson');
      final mapFunction = isItemNullable
          ? elementClosure(fromJson.call([refer('e')]))
          : fromJson;
      final listExpr = receiver.property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      result = mapList(listExpr, mapFunction);

    case final MapModel mapModel:
      // The map decoder owns element nullability.
      final inner = _buildMapFromJsonExpression(
        'e',
        mapModel,
        nameManager,
        helperContext,
        package: package,
        contextClass: contextClass,
        contextProperty: contextProperty,
        isNullable: isItemNullable,
        useImmutableCollections: useImmutableCollections,
      );
      inlineFunctions.addAll(inner.inlineFunctions);
      final mapDecoderClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = inner.unsafeRawBody.code,
      ).closure;
      final mapListExpr = receiver.property(listDecoder).call(
        [],
        contextParam,
        [refer('Object?', 'dart:core')],
      );
      result = mapList(mapListExpr, mapDecoderClosure);

    case DateTimeModel() || DateModel() || DecimalModel() || UriModel():
      final jsonType = _jsonTypeForPrimitive(unwrappedContent);
      final decodeMethod = _decodeMethodForPrimitive(unwrappedContent)!;
      final mapFunction = methodOnElementClosure(decodeMethod);
      final typeArg = isItemNullable
          ? refer('Object?', 'dart:core')
          : refer(jsonType, 'dart:core');
      final listExpr = receiver.property(listDecoder).call(
        [],
        contextParam,
        [typeArg],
      );
      result = mapList(listExpr, mapFunction);

    case BinaryModel():
      final mapFunction = elementClosure(
        refer('TonikFileBytes', 'package:tonik_util/tonik_util.dart').call([
          refer('e').property('decodeJsonBinary').call([], contextParam),
        ]),
      );
      final typeArg = isItemNullable
          ? refer('Object?', 'dart:core')
          : refer('String', 'dart:core');
      final listExpr = receiver.property(listDecoder).call(
        [],
        contextParam,
        [typeArg],
      );
      result = mapList(listExpr, mapFunction);

    case Base64Model():
      final mapFunction = elementClosure(
        refer('TonikFileBytes', 'package:tonik_util/tonik_util.dart').call([
          refer('e').property('decodeJsonBase64').call([], contextParam),
        ]),
      );
      final typeArg = isItemNullable
          ? refer('Object?', 'dart:core')
          : refer('String', 'dart:core');
      final listExpr = receiver.property(listDecoder).call(
        [],
        contextParam,
        [typeArg],
      );
      result = mapList(listExpr, mapFunction);

    case NeverModel():
      final throwExpr = generateJsonDecodingExceptionExpression(
        'Cannot decode List<NeverModel> - this type does not permit any '
        'value.',
      );
      // Gate on isNullable, not effectiveNullable: useImmutableCollections
      // must not erase nullable semantics (a `null` payload yields `null`,
      // not a throw). The non-nullable case stays a bare throw so
      // _isJsonBodyPureThrow can drop the surrounding _$json / _$body locals.
      if (isNullable) {
        return BuiltExpression.simple(
          receiver.equalTo(literalNull).conditional(literalNull, throwExpr),
        );
      }
      return BuiltExpression.simple(throwExpr);

    default:
      final typeArg = typeReference(
        content,
        nameManager,
        package,
        isNullableOverride: isItemNullable,
      );
      result = receiver
          .property(listDecoder)
          .call([], contextParam, [typeArg]);
  }

  if (useImmutableCollections) {
    result = _wrapImmutable(
      'IList',
      result,
      isNullable: isNullable,
      receiver: receiver,
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
  Expression? receiverOverride,
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
      receiverOverride: receiverOverride,
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
    receiverOverride: receiverOverride,
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
  Expression? receiverOverride,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);
  final valueModel = model.valueModel;
  final receiver = receiverOverride ?? refer(value);

  final innerBuilt = _buildFromJson(
    'v',
    model: valueModel,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    contextClass: contextClass,
    contextProperty: contextProperty,
    isNullable: model.isValueNullable,
    useImmutableCollections: useImmutableCollections,
  );

  final decoderClosure = Method(
    (b) => b
      ..requiredParameters.add(Parameter((p) => p..name = 'v'))
      ..body = innerBuilt.unsafeRawBody.code,
  ).closure;

  final effectiveNullable = !useImmutableCollections && isNullable;
  final mapDecoder = effectiveNullable
      ? 'decodeJsonNullableMap'
      : 'decodeJsonMap';

  var result = receiver.property(mapDecoder).call(
    [decoderClosure],
    contextParam,
  );

  if (useImmutableCollections) {
    result = _wrapImmutable(
      'IMap',
      result,
      isNullable: isNullable,
      receiver: receiver,
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
  Expression? receiverOverride,
}) {
  final named = model as NamedModel;
  final typedefName = nameManager.modelName(model);
  final typedefUrl = sourceFileUrl(package, 'model', typedefName);
  final helperName = helperContext.helperName(named, _decodePrefix);
  final receiver = receiverOverride ?? refer(value);

  final helpers = <InlineHelper>[];
  if (!helperContext.isHelperEmitted(named, _decodePrefix)) {
    helperContext
      ..markHelperEmitted(named, _decodePrefix)
      ..withRecursion(named, () {
        final helperContextClass = _helperBodyContextClass(
          typedefName,
          contextClass,
          contextProperty,
        );
        final inner = _buildTypedefHelperBody(
          model: model,
          nameManager: nameManager,
          helperContext: helperContext,
          package: package,
          helperContextClass: helperContextClass,
          useImmutableCollections: useImmutableCollections,
        );

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

  final call = refer(helperName).call([receiver]);
  final body = isNullable
      ? receiver.equalTo(literalNull).conditional(literalNull, call)
      : call;

  return BuiltExpression(body: body, inlineFunctions: helpers);
}

const _decodePrefix = r'_$decode';

String _helperBodyContextClass(
  String typedefName,
  String? contextClass,
  String? contextProperty,
) {
  final location = [?contextClass, ?contextProperty].join('.');
  if (location.isEmpty) return typedefName;
  return "$typedefName (at '$location')";
}

/// Builds the body of a typedef decode helper (the right-hand side of
/// `_decodeX = (Object? v) => <body>`). The immediate decodeJsonMap/
/// decodeJsonList call uses [helperContextClass] for its `context:`
/// argument so a runtime type-mismatch on the helper input is reported
/// against the typedef's logical name. The value decoder is built with
/// no inherited context so any nested typedef helpers it triggers stay
/// standalone — each helper carries only its own type identity.
BuiltExpression _buildTypedefHelperBody({
  required Model model,
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  required String package,
  required String helperContextClass,
  required bool useImmutableCollections,
}) {
  final contextParam = _buildContextParam(helperContextClass, null);
  switch (model) {
    case final MapModel mapModel:
      final innerBuilt = _buildFromJson(
        'v',
        model: mapModel.valueModel,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        isNullable: mapModel.isValueNullable,
        useImmutableCollections: useImmutableCollections,
      );
      final decoderClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((p) => p..name = 'v'))
          ..body = innerBuilt.unsafeRawBody.code,
      ).closure;
      var result = refer('v').property('decodeJsonMap').call(
        [decoderClosure],
        contextParam,
      );
      if (useImmutableCollections) {
        result = _wrapImmutable(
          'IMap',
          result,
          isNullable: false,
          receiver: refer('v'),
        );
      }
      return BuiltExpression(
        body: result,
        inlineFunctions: innerBuilt.inlineFunctions,
      );
    case final ListModel listModel:
      final inlineFunctions = <InlineHelper>[];
      final content = listModel.content;
      final unwrappedContent = content is AliasModel ? content.model : content;
      final inner = _buildFromJson(
        'e',
        model: unwrappedContent,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        useImmutableCollections: useImmutableCollections,
      );
      inlineFunctions.addAll(inner.inlineFunctions);
      final mapFunction = Method(
        (b) => b
          ..requiredParameters.add(Parameter((p) => p..name = 'e'))
          ..body = inner.unsafeRawBody.code,
      ).closure;
      var result = refer('v')
          .property('decodeJsonList')
          .call(
            [],
            contextParam,
            [refer('Object?', 'dart:core')],
          )
          .property('map')
          .call([mapFunction])
          .property('toList')
          .call([]);
      if (useImmutableCollections) {
        result = _wrapImmutable(
          'IList',
          result,
          isNullable: false,
          receiver: refer('v'),
        );
      }
      return BuiltExpression(
        body: result,
        inlineFunctions: inlineFunctions,
      );
    default:
      throw ArgumentError(
        'Decode helper only valid for named MapModel/ListModel; '
        'got ${model.runtimeType}',
      );
  }
}

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

Expression _wrapImmutable(
  String symbol,
  Expression result, {
  required bool isNullable,
  required Expression receiver,
}) {
  final immutableRef = refer(symbol, _ficUrl);
  final wrapped = immutableRef.call([result]);
  if (!isNullable) {
    return wrapped;
  }
  return receiver.equalTo(literalNull).conditional(literalNull, wrapped);
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
