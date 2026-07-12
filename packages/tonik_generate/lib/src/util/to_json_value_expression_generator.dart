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
/// [NameManager] via the `testNameManager()` helper in
/// `packages/tonik_generate/test/src/util/name_manager_test_helper.dart`.
///
/// [contextClass] and [contextProperty] are threaded into emitted
/// recursive encode helpers so the runtime `EncodingException` message
/// identifies the failing class+property when a typedef cast fails.
BuiltExpression buildToJsonPropertyExpression(
  String propertyName,
  Property property, {
  required NameManager nameManager,
  String? package,
  InlineHelperContext? helperContext,
  String? contextClass,
  String? contextProperty,
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
    contextClass: contextClass,
    contextProperty: contextProperty,
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
  String? contextClass,
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
    contextClass: contextClass,
    contextProperty: 'additionalProperties',
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
  String? contextClass,
  String? contextProperty,
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
        contextClass: contextClass,
        contextProperty: contextProperty,
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
        contextClass: contextClass,
        contextProperty: contextProperty,
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
        contextClass: contextClass,
        contextProperty: contextProperty,
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
  String? contextClass,
  String? contextProperty,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  if (_shouldUseHelper(model, helperContext)) {
    return _buildNamedTypedefEncodeHelperCall(
      receiver: receiver,
      model: model,
      nameManager: nameManager,
      helperContext: helperContext,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
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
    contextClass: contextClass,
    contextProperty: contextProperty,
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
  String? contextClass,
  String? contextProperty,
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
      model.isContentNullable || contentModel.isEffectivelyNullable;

  final innerBuilt = _buildSerializationExpression(
    refer('e'),
    contentModel,
    isContentNullable,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    contextClass: contextClass,
    contextProperty: contextProperty,
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
  String? contextClass,
  String? contextProperty,
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  if (_shouldUseHelper(model, helperContext)) {
    return _buildNamedTypedefEncodeHelperCall(
      receiver: receiver,
      model: model,
      nameManager: nameManager,
      helperContext: helperContext,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
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
    contextClass: contextClass,
    contextProperty: contextProperty,
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
  String? contextClass,
  String? contextProperty,
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
      model.isValueNullable || valueModel.isEffectivelyNullable;

  final innerBuilt = _buildSerializationExpression(
    refer('v'),
    valueModel,
    isValueNullable,
    nameManager: nameManager,
    package: package,
    helperContext: helperContext,
    contextClass: contextClass,
    contextProperty: contextProperty,
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
      isRecursive(model);
}

BuiltExpression _buildNamedTypedefEncodeHelperCall({
  required Expression receiver,
  required Model model,
  required NameManager nameManager,
  required InlineHelperContext helperContext,
  required String? package,
  required String? contextClass,
  required String? contextProperty,
  required bool isNullable,
  required bool forceNonNullReceiver,
  required bool useImmutableCollections,
}) {
  assert(
    package != null,
    'Recursive typedef encode helpers require a non-null package URL to '
    'resolve the typedef Dart type. Public callers that emit helpers '
    '(parse_generator, data_generator, class/oneOf/anyOf/allOf generators) '
    'always pass package.',
  );
  final resolvedPackage = package!;
  final named = model as NamedModel;
  final typedefName = nameManager.modelName(named);
  final helperName = helperContext.helperName(named, _encodePrefix);

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
            package: resolvedPackage,
            helperContext: helperContext,
            contextClass: contextClass,
            contextProperty: contextProperty,
            useImmutableCollections: useImmutableCollections,
          ),
          ListModel() => _handleListExpressionBody(
            paramRef,
            model,
            false,
            nameManager: nameManager,
            package: resolvedPackage,
            helperContext: helperContext,
            contextClass: contextClass,
            contextProperty: contextProperty,
            useImmutableCollections: useImmutableCollections,
          ),
          _ => throw ArgumentError(
            'Encode helper only valid for named MapModel/ListModel; '
            'got ${model.runtimeType} for typedef "$typedefName"',
          ),
        };

        // Dart forbids self-referential typedefs, so the typedef RHS is
        // type-erased to Object? at recursion points; the helper accepts
        // the erased type and casts internally.
        final typedefType = typeReference(
          model,
          nameManager,
          resolvedPackage,
          useImmutableCollections: useImmutableCollections,
        );
        final returnType = refer('Object?', 'dart:core');
        final paramType = refer('Object?', 'dart:core');

        final contextSuffix = _encodeContextSuffix(
          contextClass,
          contextProperty,
        );
        final castFailureMessage = literalString(
          'Cannot encode value as $typedefName$contextSuffix; got: ',
        );

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
                const Code(' raw) { if (raw is! '),
                typedefType.code,
                const Code(') { throw '),
                refer(
                  'EncodingException',
                  'package:tonik_util/tonik_util.dart',
                ).code,
                const Code('('),
                castFailureMessage.code,
                const Code(r" '${raw.runtimeType}'"),
                const Code('); } final v = raw; return '),
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

String _encodeContextSuffix(String? contextClass, String? contextProperty) {
  final location = [?contextClass, ?contextProperty].join('.');
  if (location.isEmpty) return '';
  return " (at '$location')";
}

const _encodePrefix = r'_$encode';

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
    // A recursive named typedef has been seen on the current descent; we
    // must treat it as transformation-required so the recursive helper
    // path emits a .map() call (and a self-referencing local function)
    // rather than identity-returning the receiver.
    return true;
  }
  return switch (model) {
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() => false,
    // Any values need the recursive unknown-value JSON conversion; passing
    // the collection through would leak DateTime and JsonEncodable
    // instances into the JSON structure.
    AnyModel() => true,
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
