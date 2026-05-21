import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/recursion_detector.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Creates a [BuiltExpression] that correctly serializes a property to its
/// JSON representation.
///
/// [nameManager] is required because recursive named typedefs ([MapModel]
/// or [ListModel] cycles) emit local helper functions whose identifiers
/// derive from [NameManager.modelName]. Test callers should construct a
/// [NameManager] via `NameManager(generator: NameGenerator(), ...)` — see
/// the test helpers in `packages/tonik_generate/test/src/util/`.
BuiltExpression buildToJsonPropertyExpression(
  String propertyName,
  Property property, {
  required NameManager nameManager,
  String? package,
  InlineHelperContext? helperContext,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;
  return _buildSerializationExpression(
    refer(propertyName),
    model,
    isNullable,
    nameManager: nameManager,
    package: package,
    helperContext:
        helperContext ?? InlineHelperContext(nameManager: nameManager),
    forceNonNullReceiver: forceNonNullReceiver,
    useImmutableCollections: useImmutableCollections,
  );
}

/// Creates a [BuiltExpression] that correctly serializes a path parameter
/// to its JSON representation.
BuiltExpression buildToJsonPathParameterExpression(
  String parameterName,
  PathParameterObject parameter, {
  required NameManager nameManager,
  String? package,
  InlineHelperContext? helperContext,
}) {
  final model = parameter.model;
  return _buildSerializationExpression(
    refer(parameterName),
    model,
    false,
    nameManager: nameManager,
    package: package,
    helperContext:
        helperContext ?? InlineHelperContext(nameManager: nameManager),
  );
}

/// Creates a [BuiltExpression] that correctly serializes a query parameter
/// to its JSON representation.
BuiltExpression buildToJsonQueryParameterExpression(
  String parameterName,
  QueryParameterObject parameter, {
  required NameManager nameManager,
  String? package,
  InlineHelperContext? helperContext,
}) {
  final model = parameter.model;
  return _buildSerializationExpression(
    refer(parameterName),
    model,
    false,
    nameManager: nameManager,
    package: package,
    helperContext:
        helperContext ?? InlineHelperContext(nameManager: nameManager),
  );
}

/// Builds the serialization expression for typed additional properties.
///
/// Returns a [BuiltExpression] suitable for spreading into a map literal
/// (class generator) or passing to `addAll` (allOf generator). Handles
/// unlock for immutable collections internally.
BuiltExpression buildToJsonAdditionalPropertiesExpression(
  String fieldName,
  Model valueModel, {
  required NameManager nameManager,
  String? package,
  InlineHelperContext? helperContext,
  bool useImmutableCollections = false,
}) {
  final ctx = helperContext ?? InlineHelperContext(nameManager: nameManager);
  final receiver = useImmutableCollections
      ? refer(fieldName).property('unlock')
      : refer(fieldName);

  if (!_needsTransformation(
    valueModel,
    useImmutableCollections: useImmutableCollections,
  )) {
    return BuiltExpression.simple(receiver);
  }

  final inner = _buildSerializationExpression(
    refer('v'),
    valueModel,
    false,
    nameManager: nameManager,
    package: package,
    helperContext: ctx,
    useImmutableCollections: useImmutableCollections,
  );

  final mapClosure = Method(
    (b) => b
      ..requiredParameters.addAll([
        Parameter((p) => p..name = 'k'),
        Parameter((p) => p..name = 'v'),
      ])
      ..body = refer(
        'MapEntry',
        'dart:core',
      ).call([refer('k'), inner.unsafeRawBody]).code,
  ).closure;

  return BuiltExpression(
    body: receiver.property('map').call([mapClosure]),
    inlineFunctions: inner.inlineFunctions,
  );
}

BuiltExpression _buildSerializationExpression(
  Expression receiver,
  Model model,
  bool isNullable, {
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  String? package,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  final directReceiver = forceNonNullReceiver ? receiver.nullChecked : receiver;
  final useNullAware =
      !forceNonNullReceiver &&
      (isNullable ||
          (model is EnumModel && model.isNullable) ||
          model.isEffectivelyNullable);

  Expression callMethod(String methodName) {
    if (forceNonNullReceiver) {
      return receiver.nullChecked.property(methodName).call([]);
    } else if (useNullAware) {
      return receiver.nullSafeProperty(methodName).call([]);
    } else {
      return receiver.property(methodName).call([]);
    }
  }

  switch (model) {
    case NeverModel():
      return BuiltExpression.simple(
        generateEncodingExceptionExpression(
          'Cannot encode NeverModel - this type does not permit any value.',
        ),
      );
    case DateTimeModel():
      return BuiltExpression.simple(callMethod('toTimeZonedIso8601String'));
    case DecimalModel():
    case UriModel():
      return BuiltExpression.simple(callMethod('toString'));
    case BinaryModel():
      return BuiltExpression.simple(
        _callToBytesMethod(
          receiver,
          'decodeToString',
          useNullAware: useNullAware,
          forceNonNull: forceNonNullReceiver,
        ),
      );
    case Base64Model():
      return BuiltExpression.simple(
        _callToBytesMethod(
          receiver,
          'encodeToBase64String',
          useNullAware: useNullAware,
          forceNonNull: forceNonNullReceiver,
        ),
      );
    case DateModel():
    case EnumModel():
    case ClassModel():
    case AllOfModel():
    case OneOfModel():
    case AnyOfModel():
      return BuiltExpression.simple(callMethod('toJson'));
    case ListModel():
      return _handleListExpression(
        receiver,
        model,
        isNullable,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        forceNonNullReceiver: forceNonNullReceiver,
        useImmutableCollections: useImmutableCollections,
      );
    case MapModel():
      return _handleMapExpression(
        receiver,
        model,
        isNullable || model.isNullable,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        forceNonNullReceiver: forceNonNullReceiver,
        useImmutableCollections: useImmutableCollections,
      );
    case AliasModel():
      return _buildSerializationExpression(
        receiver,
        model.model,
        isNullable || model.isNullable,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        forceNonNullReceiver: forceNonNullReceiver,
        useImmutableCollections: useImmutableCollections,
      );
    case PrimitiveModel():
      return BuiltExpression.simple(directReceiver);
    case AnyModel():
      return BuiltExpression.simple(
        refer(
          'encodeAnyToJson',
          'package:tonik_util/tonik_util.dart',
        ).call([directReceiver]),
      );
    default:
      return BuiltExpression.simple(
        generateEncodingExceptionExpression(
          'Unsupported model type for JSON encoding.',
        ),
      );
  }
}

BuiltExpression _handleListExpression(
  Expression receiver,
  ListModel model,
  bool isNullable, {
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  String? package,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  if (_shouldUseHelper(model, helperContext)) {
    return _buildNamedTypedefEncodeHelperCall(
      receiver: receiver,
      model: model,
      nameManager: nameManager,
      helperContext: helperContext,
      package: package ?? '',
      forceNonNullReceiver: forceNonNullReceiver,
      isNullable: isNullable,
      useImmutableCollections: useImmutableCollections,
    );
  }

  return _handleListExpressionBody(
    receiver,
    model,
    isNullable,
    helperContext: helperContext,
    nameManager: nameManager,
    package: package,
    forceNonNullReceiver: forceNonNullReceiver,
    useImmutableCollections: useImmutableCollections,
  );
}

BuiltExpression _handleListExpressionBody(
  Expression receiver,
  ListModel model,
  bool isNullable, {
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  String? package,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  final contentModel = model.content;
  if (!_needsTransformation(
    contentModel,
    useImmutableCollections: useImmutableCollections,
  )) {
    if (useImmutableCollections) {
      if (forceNonNullReceiver) {
        return BuiltExpression.simple(
          receiver.nullChecked.property('unlock'),
        );
      } else if (isNullable) {
        return BuiltExpression.simple(
          receiver.nullSafeProperty('unlock'),
        );
      } else {
        return BuiltExpression.simple(receiver.property('unlock'));
      }
    }
    return BuiltExpression.simple(
      forceNonNullReceiver ? receiver.nullChecked : receiver,
    );
  }

  final isContentNullable =
      contentModel.isEffectivelyNullable ||
      (contentModel is AliasModel && contentModel.isNullable);

  final innerBuilt = _buildSerializationExpression(
    refer('e'),
    contentModel,
    isContentNullable,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    useImmutableCollections: useImmutableCollections,
  );

  final mapClosure = Method(
    (b) => b
      ..requiredParameters.add(Parameter((p) => p..name = 'e'))
      ..body = innerBuilt.unsafeRawBody.code,
  ).closure;

  Expression result;
  if (useImmutableCollections) {
    if (forceNonNullReceiver) {
      result = receiver.nullChecked
          .property('unlock')
          .property('map')
          .call([mapClosure])
          .property('toList')
          .call([]);
    } else if (isNullable) {
      result = receiver
          .nullSafeProperty('unlock')
          .property('map')
          .call([mapClosure])
          .property('toList')
          .call([]);
    } else {
      result = receiver
          .property('unlock')
          .property('map')
          .call([mapClosure])
          .property('toList')
          .call([]);
    }
  } else if (forceNonNullReceiver) {
    result = receiver.nullChecked
        .property('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  } else if (isNullable) {
    result = receiver
        .nullSafeProperty('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  } else {
    result = receiver
        .property('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  }

  return BuiltExpression(
    body: result,
    inlineFunctions: innerBuilt.inlineFunctions,
  );
}

BuiltExpression _handleMapExpression(
  Expression receiver,
  MapModel model,
  bool isNullable, {
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  String? package,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  if (_shouldUseHelper(model, helperContext)) {
    return _buildNamedTypedefEncodeHelperCall(
      receiver: receiver,
      model: model,
      nameManager: nameManager,
      helperContext: helperContext,
      package: package ?? '',
      forceNonNullReceiver: forceNonNullReceiver,
      isNullable: isNullable,
      useImmutableCollections: useImmutableCollections,
    );
  }

  return _handleMapExpressionBody(
    receiver,
    model,
    isNullable,
    helperContext: helperContext,
    nameManager: nameManager,
    package: package,
    forceNonNullReceiver: forceNonNullReceiver,
    useImmutableCollections: useImmutableCollections,
  );
}

BuiltExpression _handleMapExpressionBody(
  Expression receiver,
  MapModel model,
  bool isNullable, {
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  String? package,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  final valueModel = model.valueModel;
  if (!_needsTransformation(
    valueModel,
    useImmutableCollections: useImmutableCollections,
  )) {
    if (useImmutableCollections) {
      if (forceNonNullReceiver) {
        return BuiltExpression.simple(
          receiver.nullChecked.property('unlock'),
        );
      } else if (isNullable) {
        return BuiltExpression.simple(
          receiver.nullSafeProperty('unlock'),
        );
      } else {
        return BuiltExpression.simple(receiver.property('unlock'));
      }
    }
    return BuiltExpression.simple(
      forceNonNullReceiver ? receiver.nullChecked : receiver,
    );
  }

  final isValueNullable =
      valueModel.isEffectivelyNullable ||
      (valueModel is AliasModel && valueModel.isNullable);

  final innerBuilt = _buildSerializationExpression(
    refer('v'),
    valueModel,
    isValueNullable,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    useImmutableCollections: useImmutableCollections,
  );

  final mapClosure = Method(
    (b) => b
      ..requiredParameters.addAll([
        Parameter((p) => p..name = 'k'),
        Parameter((p) => p..name = 'v'),
      ])
      ..body = refer(
        'MapEntry',
        'dart:core',
      ).call([refer('k'), innerBuilt.unsafeRawBody]).code,
  ).closure;

  Expression result;
  if (useImmutableCollections) {
    if (forceNonNullReceiver) {
      result = receiver.nullChecked.property('unlock').property('map').call([
        mapClosure,
      ]);
    } else if (isNullable) {
      result = receiver.nullSafeProperty('unlock').property('map').call([
        mapClosure,
      ]);
    } else {
      result = receiver.property('unlock').property('map').call([mapClosure]);
    }
  } else if (forceNonNullReceiver) {
    result = receiver.nullChecked.property('map').call([mapClosure]);
  } else if (isNullable) {
    result = receiver.nullSafeProperty('map').call([mapClosure]);
  } else {
    result = receiver.property('map').call([mapClosure]);
  }

  return BuiltExpression(
    body: result,
    inlineFunctions: innerBuilt.inlineFunctions,
  );
}

bool _shouldUseHelper(Model model, InlineHelperContext helperContext) {
  if (model is! NamedModel) return false;
  if (model.name == null) return false;
  return helperContext.isHelperEmitted(model, _encodePrefix) ||
      helperContext.isOnStack(model) ||
      findRecursionTarget(model) != null;
}

BuiltExpression _buildNamedTypedefEncodeHelperCall({
  required Expression receiver,
  required Model model,
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  required String package,
  required bool isNullable,
  required bool forceNonNullReceiver,
  required bool useImmutableCollections,
}) {
  final named = model as NamedModel;
  final helperName = helperContext.reserveHelperName(named, _encodePrefix);

  final helpers = <InlineHelper>[];
  if (!helperContext.isHelperEmitted(named, _encodePrefix)) {
    helperContext
      ..markHelperEmitted(named, _encodePrefix)
      ..withRecursion(named, () {
        final paramRef = refer('v');
        final inner = switch (model) {
          MapModel() => _handleMapExpressionBody(
            paramRef,
            model,
            false,
            nameManager: nameManager,
            package: package,
            helperContext: helperContext,
            useImmutableCollections: useImmutableCollections,
          ),
          ListModel() => _handleListExpressionBody(
            paramRef,
            model,
            false,
            nameManager: nameManager,
            package: package,
            helperContext: helperContext,
            useImmutableCollections: useImmutableCollections,
          ),
          _ => throw ArgumentError(
            'Encode helper only valid for named MapModel/ListModel; '
            'got ${model.runtimeType} for typedef '
            '"${nameManager.modelName(named)}"',
          ),
        };

        // Dart forbids self-referential typedefs, so the typedef RHS is
        // type-erased to Object? at recursion points; the helper accepts
        // the erased type and casts internally.
        final typedefType = typeReference(
          model,
          nameManager,
          package,
          useImmutableCollections: useImmutableCollections,
        );
        final returnType = refer('Object?', 'dart:core');
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
                const Code(' raw) { final v = raw as '),
                typedefType.code,
                const Code('; return '),
                inner.unsafeRawBody.code,
                const Code('; };'),
              ]),
            ),
          );
      });
  }

  Expression call;
  if (forceNonNullReceiver) {
    call = refer(helperName).call([receiver.nullChecked]);
  } else if (isNullable) {
    call = receiver
        .equalTo(literalNull)
        .conditional(literalNull, refer(helperName).call([receiver]));
  } else {
    call = refer(helperName).call([receiver]);
  }

  return BuiltExpression(body: call, inlineFunctions: helpers);
}

const _encodePrefix = '_encode';

/// Calls `.toBytes().methodName()` on a `TonikFile` receiver.
Expression _callToBytesMethod(
  Expression receiver,
  String methodName, {
  required bool useNullAware,
  required bool forceNonNull,
}) {
  if (forceNonNull) {
    return receiver.nullChecked
        .property('toBytes')
        .call([])
        .property(methodName)
        .call([]);
  } else if (useNullAware) {
    return receiver
        .nullSafeProperty('toBytes')
        .call([])
        .property(methodName)
        .call([]);
  } else {
    return receiver.property('toBytes').call([]).property(methodName).call([]);
  }
}

bool _needsTransformation(
  Model model, {
  bool useImmutableCollections = false,
}) {
  return _needsTransformationImpl(
    model,
    useImmutableCollections: useImmutableCollections,
    visited: <Model>{},
  );
}

bool _needsTransformationImpl(
  Model model, {
  required bool useImmutableCollections,
  required Set<Model> visited,
}) {
  if (!visited.add(model)) {
    // Cycle detected — the value type is a recursive named typedef. Treat
    // it as transformation-required so the recursive helper path emits a
    // .map() call (and a self-referencing local function) rather than
    // identity-returning the receiver.
    return true;
  }
  return switch (model) {
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    AnyModel() => false,
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    BinaryModel() ||
    Base64Model() ||
    DateModel() => true,
    AliasModel() => _needsTransformationImpl(
      model.model,
      useImmutableCollections: useImmutableCollections,
      visited: visited,
    ),
    ListModel() when useImmutableCollections => true,
    MapModel() when useImmutableCollections => true,
    ListModel() => _needsTransformationImpl(
      model.content,
      useImmutableCollections: useImmutableCollections,
      visited: visited,
    ),
    MapModel() => _needsTransformationImpl(
      model.valueModel,
      useImmutableCollections: useImmutableCollections,
      visited: visited,
    ),
    _ => true,
  };
}
