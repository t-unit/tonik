import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// Creates a Dart expression that correctly serializes a property
/// to its JSON representation.
Expression buildToJsonPropertyExpression(
  String propertyName,
  Property property, {
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;
  return _buildSerializationExpression(
    refer(propertyName),
    model,
    isNullable,
    forceNonNullReceiver: forceNonNullReceiver,
    useImmutableCollections: useImmutableCollections,
  );
}

/// Creates a Dart expression that correctly serializes a path parameter
/// to its JSON representation.
Expression buildToJsonPathParameterExpression(
  String parameterName,
  PathParameterObject parameter,
) {
  final model = parameter.model;
  return _buildSerializationExpression(
    refer(parameterName),
    model,
    false,
  );
}

/// Creates a Dart expression that correctly serializes a query parameter
/// to its JSON representation.
Expression buildToJsonQueryParameterExpression(
  String parameterName,
  QueryParameterObject parameter,
) {
  final model = parameter.model;
  return _buildSerializationExpression(
    refer(parameterName),
    model,
    false,
  );
}

Expression _buildSerializationExpression(
  Expression receiver,
  Model model,
  bool isNullable, {
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

  return switch (model) {
    NeverModel() => generateEncodingExceptionExpression(
      'Cannot encode NeverModel - this type does not permit any value.',
    ),
    DateTimeModel() => callMethod('toTimeZonedIso8601String'),
    DecimalModel() || UriModel() => callMethod('toString'),
    BinaryModel() => _callToBytesMethod(
      receiver,
      'decodeToString',
      useNullAware: useNullAware,
      forceNonNull: forceNonNullReceiver,
    ),
    Base64Model() => _callToBytesMethod(
      receiver,
      'encodeToBase64String',
      useNullAware: useNullAware,
      forceNonNull: forceNonNullReceiver,
    ),
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => callMethod('toJson'),
    ListModel() => _handleListExpression(
      receiver,
      model.content,
      isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
      useImmutableCollections: useImmutableCollections,
    ),
    MapModel() => _handleMapExpression(
      receiver,
      model.valueModel,
      isNullable || model.isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
      useImmutableCollections: useImmutableCollections,
    ),
    AliasModel() => _buildSerializationExpression(
      receiver,
      model.model,
      isNullable || model.isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
      useImmutableCollections: useImmutableCollections,
    ),
    PrimitiveModel() => directReceiver,
    AnyModel() => refer(
      'encodeAnyToJson',
      'package:tonik_util/tonik_util.dart',
    ).call([directReceiver]),
    // coverage:ignore-start
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for JSON encoding.',
    ),
    // coverage:ignore-end
  };
}

Expression _handleListExpression(
  Expression receiver,
  Model contentModel,
  bool isNullable, {
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  if (!_needsTransformation(
    contentModel,
    useImmutableCollections: useImmutableCollections,
  )) {
    if (useImmutableCollections) {
      // IList must be converted to List for JSON serialization.
      if (forceNonNullReceiver) {
        return receiver.nullChecked.property('unlock');
      } else if (isNullable) {
        return receiver.nullSafeProperty('unlock');
      } else {
        return receiver.property('unlock');
      }
    }
    return forceNonNullReceiver ? receiver.nullChecked : receiver;
  }

  final isContentNullable = contentModel.isEffectivelyNullable ||
      (contentModel is AliasModel && contentModel.isNullable);

  final innerExpr = _buildSerializationExpression(
    refer('e'),
    contentModel,
    isContentNullable,
    useImmutableCollections: useImmutableCollections,
  );

  final mapClosure = Method(
    (b) => b
      ..requiredParameters.add(Parameter((p) => p..name = 'e'))
      ..body = innerExpr.code,
  ).closure;

  if (useImmutableCollections) {
    // Unlock the outer IList to a regular List before mapping, so the
    // result is a standard List for JSON serialization.
    if (forceNonNullReceiver) {
      return receiver.nullChecked
          .property('unlock')
          .property('map')
          .call([mapClosure])
          .property('toList')
          .call([]);
    } else if (isNullable) {
      return receiver
          .nullSafeProperty('unlock')
          .property('map')
          .call([mapClosure])
          .property('toList')
          .call([]);
    } else {
      return receiver
          .property('unlock')
          .property('map')
          .call([mapClosure])
          .property('toList')
          .call([]);
    }
  }

  if (forceNonNullReceiver) {
    return receiver.nullChecked
        .property('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  } else if (isNullable) {
    return receiver
        .nullSafeProperty('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  } else {
    return receiver
        .property('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  }
}

Expression _handleMapExpression(
  Expression receiver,
  Model valueModel,
  bool isNullable, {
  bool forceNonNullReceiver = false,
  bool useImmutableCollections = false,
}) {
  if (!_needsTransformation(
    valueModel,
    useImmutableCollections: useImmutableCollections,
  )) {
    if (useImmutableCollections) {
      // IMap must be converted to Map for JSON serialization.
      if (forceNonNullReceiver) {
        return receiver.nullChecked.property('unlock');
      } else if (isNullable) {
        return receiver.nullSafeProperty('unlock');
      } else {
        return receiver.property('unlock');
      }
    }
    return forceNonNullReceiver ? receiver.nullChecked : receiver;
  }

  final isValueNullable = valueModel.isEffectivelyNullable ||
      (valueModel is AliasModel && valueModel.isNullable);

  final innerExpr = _buildSerializationExpression(
    refer('v'),
    valueModel,
    isValueNullable,
    useImmutableCollections: useImmutableCollections,
  );

  final mapClosure = Method(
    (b) => b
      ..requiredParameters.addAll([
        Parameter((p) => p..name = 'k'),
        Parameter((p) => p..name = 'v'),
      ])
      ..body = refer('MapEntry', 'dart:core')
          .call([refer('k'), innerExpr])
          .code,
  ).closure;

  // When using immutable collections, unlock to regular Map first
  // so that Map.map() returns a Map (not IMap).
  if (useImmutableCollections) {
    if (forceNonNullReceiver) {
      return receiver.nullChecked
          .property('unlock')
          .property('map')
          .call([mapClosure]);
    } else if (isNullable) {
      return receiver
          .nullSafeProperty('unlock')
          .property('map')
          .call([mapClosure]);
    } else {
      return receiver
          .property('unlock')
          .property('map')
          .call([mapClosure]);
    }
  }

  if (forceNonNullReceiver) {
    return receiver.nullChecked.property('map').call([mapClosure]);
  } else if (isNullable) {
    return receiver.nullSafeProperty('map').call([mapClosure]);
  } else {
    return receiver.property('map').call([mapClosure]);
  }
}

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
  return switch (model) {
    // These primitive types serialize as-is
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    AnyModel() => false,
    // All other primitives need transformation
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    BinaryModel() ||
    Base64Model() ||
    DateModel() => true,
    // Aliases delegate to their underlying model
    AliasModel() => _needsTransformation(
      model.model,
      useImmutableCollections: useImmutableCollections,
    ),
    // When using immutable collections, lists and maps always need
    // transformation to convert IList/IMap back to List/Map for JSON serialization.
    ListModel() when useImmutableCollections => true,
    MapModel() when useImmutableCollections => true,
    // Lists delegate to their content model
    ListModel() => _needsTransformation(model.content),
    // Maps delegate to their value model
    MapModel() => _needsTransformation(model.valueModel),
    // Complex types always need transformation
    _ => true,
  };
}
