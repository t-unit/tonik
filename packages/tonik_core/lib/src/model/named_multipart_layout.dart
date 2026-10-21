part of 'request_body.dart';

/// One schema occurrence of a named multipart field. Members identify the
/// enclosing allOf branches; Dart member names are assigned by generation.
final class MultipartPartSource({
  required final List<({Model model, int index})> members,
  required final Property property,
  required final bool receiverNullable,
});

enum MultipartMergePolicy() {
  single,
  objectProperties,
  objects,
  maps,
  lists,
  dynamicValues,
}

final class NamedMultipartPart({
  required final String wireName,
  required final List<MultipartPartSource> sources,
  required final Model model,
  required final bool isRequired,
  required final bool isNullable,
  required final PartEncoding encoding,
  required final MultipartMergePolicy mergePolicy,
});

final class MultipartAdditionalFields({
  required final Model valueModel,
  required final bool isValueNullable,
  required final bool receiverNullable,
  required final Set<String> declaredWireNames,
  required final PartEncoding encoding,
});

final class NamedMultipartLayout._({
  required final Model model,
  required final List<NamedMultipartPart> fields,
  required final MultipartAdditionalFields? additionalFields,
  required final String? runtimeEncodingError,
  required final Map<String, PartEncoding> _declaredEncodings,
});

NamedMultipartLayout _resolveNamedMultipartLayout(
  Model model, {
  required Map<String, PartEncoding> encoding,
  Iterable<String> preferredWireNames = const [],
}) {
  final declaredEncodings = Map<String, PartEncoding>.unmodifiable(encoding);
  final occurrences = <MultipartPartSource>[];
  final collection = _collect(
    model,
    const [],
    _isNullable(model),
    <Model>{},
    occurrences,
  );
  if (collection.error case final error?) {
    return NamedMultipartLayout._(
      model: model,
      fields: const [],
      additionalFields: null,
      runtimeEncodingError: error,
      declaredEncodings: declaredEncodings,
    );
  }
  final grouped = <String, List<MultipartPartSource>>{};
  for (final source in occurrences) {
    if (source.property.isReadOnly ||
        _isReadOnly(source.property.model, <Model>{})) {
      continue;
    }
    (grouped[source.property.name] ??= []).add(source);
  }
  final unmatched = encoding.keys.where((key) => !grouped.containsKey(key));
  if (unmatched.isNotEmpty) {
    return NamedMultipartLayout._(
      model: model,
      fields: const [],
      additionalFields: null,
      runtimeEncodingError: _unmatchedEncodingError(unmatched),
      declaredEncodings: declaredEncodings,
    );
  }
  final previousNames = preferredWireNames.toSet();
  final orderedNames = [
    for (final name in preferredWireNames)
      if (grouped.containsKey(name)) name,
    for (final name in grouped.keys)
      if (!previousNames.contains(name)) name,
  ];
  String? incompatibleError;
  for (final name in orderedNames) {
    incompatibleError ??= _incompatibleDefinitionsError(name, grouped[name]!);
  }
  return NamedMultipartLayout._(
    model: model,
    fields: List.unmodifiable([
      for (final name in orderedNames)
        _part(name, grouped[name]!, encoding[name]),
    ]),
    additionalFields: collection.additionalFields,
    runtimeEncodingError: incompatibleError,
    declaredEncodings: declaredEncodings,
  );
}

String _unmatchedEncodingError(Iterable<String> unmatched) =>
    'Multipart encoding references properties that are not writable or '
    'do not exist in the body model: ${unmatched.join(', ')}.';

NamedMultipartPart _part(
  String wireName,
  List<MultipartPartSource> sources,
  PartEncoding? declaredEncoding,
) {
  final model = sources.first.property.model;
  final effective = resolveMultipartEncoding(declaredEncoding, model);
  final resolved = sources
      .map((source) => source.property.model.resolved)
      .toList();
  final objects = resolved.every(
    (model) => model is ClassModel || model is AllOfModel,
  );
  final maps = resolved.every((model) => model is MapModel);
  final lists = resolved.every((model) => model is ListModel);
  final mergePolicy = sources.length == 1
      ? MultipartMergePolicy.single
      : objects &&
            (effective.isStyleBased ||
                effective.contentType == ContentType.form)
      ? MultipartMergePolicy.objectProperties
      : objects
      ? MultipartMergePolicy.objects
      : maps
      ? MultipartMergePolicy.maps
      : lists
      ? MultipartMergePolicy.lists
      : MultipartMergePolicy.dynamicValues;
  return NamedMultipartPart(
    wireName: wireName,
    sources: List.unmodifiable(sources),
    model: model,
    isRequired: sources.any((source) => source.property.isRequired),
    isNullable: sources.every(
      (source) =>
          source.property.isNullable ||
          _isNullable(source.property.model) ||
          !source.property.isRequired ||
          source.property.isWriteOnly ||
          source.receiverNullable,
    ),
    encoding: effective,
    mergePolicy: mergePolicy,
  );
}

PartEncoding resolveMultipartEncoding(PartEncoding? encoding, Model model) {
  if (encoding?.isStyleBased ?? false) return encoding!;
  final contentType =
      encoding?.contentType ?? _defaultContentType(model, <Model>{});
  final rawContentType =
      encoding?.rawContentType ??
      switch (contentType) {
        ContentType.json => 'application/json',
        ContentType.bytes => 'application/octet-stream',
        _ => 'text/plain',
      };
  return PartEncoding(
    contentType: contentType,
    rawContentType: rawContentType,
    wireContentType: encoding?.wireContentType ?? rawContentType,
    textEncoding: encoding?.textEncoding ?? TextEncoding.utf8,
    headers: encoding?.headers,
    style: null,
    explode: null,
    allowReserved: null,
  );
}

ContentType _defaultContentType(Model model, Set<Model> active) {
  if (!active.add(model)) return ContentType.json;
  try {
    return switch (model) {
      AliasModel(:final model) => _defaultContentType(model, active),
      ListModel(:final content) => _defaultContentType(content, active),
      BinaryModel() || Base64Model() => ContentType.bytes,
      ClassModel() ||
      AllOfModel() ||
      OneOfModel() ||
      AnyOfModel() ||
      AnyModel() ||
      MapModel() => ContentType.json,
      _ => ContentType.text,
    };
  } finally {
    active.remove(model);
  }
}

typedef _Collection = ({
  String? error,
  MultipartAdditionalFields? additionalFields,
});

_Collection _collect(
  Model model,
  List<({Model model, int index})> members,
  bool receiverNullable,
  Set<Model> active,
  List<MultipartPartSource> result,
) {
  if (_isReadOnly(model, <Model>{})) {
    return members.isEmpty
        ? (
            error:
                'Multipart body root ${model.runtimeType} at ${model.context} '
                'is read-only and cannot be used as a request body.',
            additionalFields: null,
          )
        : (error: null, additionalFields: null);
  }
  if (!active.add(model)) {
    return (
      error:
          'Multipart body model contains a cycle while resolving '
          '${model.context}.',
      additionalFields: null,
    );
  }
  try {
    switch (model) {
      case AliasModel(:final model, :final isNullable):
        return _collect(
          model,
          members,
          receiverNullable || isNullable,
          active,
          result,
        );
      case MapModel():
        if (members.isNotEmpty) {
          return (error: _dynamicAllOfError(model), additionalFields: null);
        }
        final error = _dynamicValueError(model.valueModel);
        if (error != null) return (error: error, additionalFields: null);
        return (
          error: null,
          additionalFields: MultipartAdditionalFields(
            valueModel: model.valueModel,
            isValueNullable:
                model.isValueNullable || _isNullable(model.valueModel),
            receiverNullable: receiverNullable,
            declaredWireNames: const {},
            encoding: resolveMultipartEncoding(
              null,
              model.valueModel.resolved is ListModel
                  ? (model.valueModel.resolved as ListModel).content.resolved
                  : model.valueModel,
            ),
          ),
        );
      case ClassModel():
        MultipartAdditionalFields? additionalFields;
        if (model.additionalPropertiesPolicy case AllowedAdditionalProperties(
          origin: AdditionalPropertiesOrigin.explicit,
          :final valueModel,
        )) {
          if (members.isNotEmpty) {
            return (error: _dynamicAllOfError(model), additionalFields: null);
          }
          final error = _dynamicValueError(valueModel);
          if (error != null) return (error: error, additionalFields: null);
          additionalFields = MultipartAdditionalFields(
            valueModel: valueModel,
            isValueNullable: _isNullable(valueModel),
            receiverNullable: receiverNullable,
            declaredWireNames: Set.unmodifiable(
              model.properties.map((property) => property.name),
            ),
            encoding: resolveMultipartEncoding(
              null,
              valueModel.resolved is ListModel
                  ? (valueModel.resolved as ListModel).content.resolved
                  : valueModel,
            ),
          );
        }
        for (final property in model.properties) {
          result.add(
            MultipartPartSource(
              members: List.unmodifiable(members),
              property: property,
              receiverNullable: receiverNullable,
            ),
          );
        }
        return (error: null, additionalFields: additionalFields);
      case AllOfModel():
        if (model.additionalPropertiesPolicy case AllowedAdditionalProperties(
          origin: AdditionalPropertiesOrigin.explicit,
        )) {
          return (error: _dynamicAllOfError(model), additionalFields: null);
        }
        for (var index = 0; index < model.models.length; index++) {
          final member = model.models[index];
          final collected = _collect(
            member,
            [...members, (model: member, index: index)],
            receiverNullable || _isNullable(member),
            active,
            result,
          );
          if (collected.error != null) return collected;
        }
        return (error: null, additionalFields: null);
      default:
        return (
          error:
              'Unsupported multipart body root/member ${model.runtimeType} at '
              '${model.context}. Multipart bodies require a class, an alias to '
              'a supported model, or an allOf containing supported members.',
          additionalFields: null,
        );
    }
  } finally {
    active.remove(model);
  }
}

bool _isReadOnly(Model model, Set<Model> active) {
  if (!active.add(model)) return false;
  try {
    return switch (model) {
      AliasModel(:final isReadOnly, :final model) =>
        isReadOnly || _isReadOnly(model, active),
      ClassModel(:final isReadOnly) ||
      ListModel(:final isReadOnly) ||
      MapModel(:final isReadOnly) ||
      EnumModel(:final isReadOnly) ||
      AllOfModel(:final isReadOnly) ||
      OneOfModel(:final isReadOnly) ||
      AnyOfModel(:final isReadOnly) => isReadOnly,
      _ => false,
    };
  } finally {
    active.remove(model);
  }
}

String _dynamicAllOfError(Model model) =>
    'Dynamic multipart sources inside allOf are not supported '
    '(${model.runtimeType} at ${model.context}).';

String? _dynamicValueError(Model model) {
  if (_containsRecursiveCollection(model)) {
    return 'Recursive collection types are not supported for dynamic '
        'multipart values.';
  }
  var valueModel = model;
  var resolved = model.resolved;
  if (resolved is ListModel) {
    valueModel = resolved.content;
    resolved = valueModel.resolved;
    if (resolved is ListModel) {
      return 'Arrays of arrays are not supported for dynamic multipart values '
          '(${model.context}).';
    }
  }
  if (resolved is AnyModel) {
    return 'Untyped dynamic multipart values are not supported '
        '(${valueModel.context}).';
  }
  if (resolved is AliasModel || resolved is NeverModel) {
    return 'Unsupported dynamic multipart value ${resolved.runtimeType} '
        '(${valueModel.context}).';
  }
  return null;
}

bool _containsRecursiveCollection(Model model) {
  final visited = <Model>{};
  bool walk(Model current) {
    if (!visited.add(current)) return false;
    return switch (current) {
      AliasModel(:final model) => walk(model),
      MapModel(:final valueModel) => _isRecursive(current) || walk(valueModel),
      ListModel(:final content) => _isRecursive(current) || walk(content),
      _ => false,
    };
  }

  return walk(model);
}

bool _isRecursive(Model start) {
  if (start is! MapModel && start is! ListModel) return false;
  if (start is MapModel && start.name == null ||
      start is ListModel && start.name == null) {
    return false;
  }
  final stack = <Model>{start};
  final visited = <Model>{start};
  bool reaches(Model current) {
    final resolved = current.resolved;
    if (resolved is MapModel || resolved is ListModel) {
      if (stack.contains(resolved)) return true;
      if (!visited.add(resolved)) return false;
      if (resolved is MapModel && resolved.name != null ||
          resolved is ListModel && resolved.name != null) {
        stack.add(resolved);
      }
      final found = reaches(
        resolved is MapModel
            ? resolved.valueModel
            : (resolved as ListModel).content,
      );
      stack.remove(resolved);
      return found;
    }
    return false;
  }

  return reaches(
    start is MapModel ? start.valueModel : (start as ListModel).content,
  );
}

bool _isNullable(Model model, [Set<Model>? active]) {
  final visited = active ?? <Model>{};
  if (!visited.add(model)) return false;
  try {
    return switch (model) {
      AliasModel(:final isNullable, :final model) =>
        isNullable || _isNullable(model, visited),
      _ => model.isEffectivelyNullable,
    };
  } finally {
    visited.remove(model);
  }
}

String? _incompatibleDefinitionsError(
  String wireName,
  List<MultipartPartSource> sources,
) {
  final first = sources.first.property.model;
  for (final source in sources.skip(1)) {
    if (!_compatibleModels(first, source.property.model, <(Model, Model)>{})) {
      return 'Multipart property "$wireName" has incompatible '
          'definitions (${first.runtimeType} and '
          '${source.property.model.runtimeType}).';
    }
  }
  return null;
}

bool _compatibleModels(Model left, Model right, Set<(Model, Model)> active) {
  if (identical(left, right)) return true;
  final pair = (left, right);
  if (!active.add(pair)) return true;
  try {
    if (left is AliasModel) {
      return _compatibleModels(left.model, right, active);
    }
    if (right is AliasModel) {
      return _compatibleModels(left, right.model, active);
    }
    if (left is ListModel && right is ListModel) {
      return left.isContentNullable == right.isContentNullable &&
          _compatibleModels(left.content, right.content, active);
    }
    if (left is MapModel && right is MapModel) {
      return left.isValueNullable == right.isValueNullable &&
          _compatibleModels(left.valueModel, right.valueModel, active);
    }
    final leftObject = left is ClassModel || left is AllOfModel;
    final rightObject = right is ClassModel || right is AllOfModel;
    if (leftObject && rightObject) {
      if (!_compatibleAdditionalProperties(left, right, active)) {
        return false;
      }
      final leftProperties = _objectProperties(left, <Model>{});
      final rightProperties = _objectProperties(right, <Model>{});
      final overlapping = leftProperties.keys.toSet().intersection(
        rightProperties.keys.toSet(),
      );
      for (final name in overlapping) {
        for (final leftProperty in leftProperties[name]!) {
          for (final rightProperty in rightProperties[name]!) {
            final leftNullable =
                leftProperty.isNullable || _isNullable(leftProperty.model);
            final rightNullable =
                rightProperty.isNullable || _isNullable(rightProperty.model);
            if (leftNullable != rightNullable ||
                !_compatibleModels(
                  leftProperty.model,
                  rightProperty.model,
                  active,
                )) {
              return false;
            }
          }
        }
      }
      return true;
    }
    if (left is EnumModel && right is EnumModel) {
      // Distinct named enums generate distinct Dart types. Comparing their
      // instances dynamically would therefore reject even equal wire values.
      return false;
    }
    return left.runtimeType == right.runtimeType;
  } finally {
    active.remove(pair);
  }
}

bool _compatibleAdditionalProperties(
  Model left,
  Model right,
  Set<(Model, Model)> active,
) {
  final leftPolicy = _effectiveExplicitAdditionalProperties(left);
  final rightPolicy = _effectiveExplicitAdditionalProperties(right);
  if (leftPolicy == null || rightPolicy == null) return true;
  if (leftPolicy is ForbiddenAdditionalProperties ||
      rightPolicy is ForbiddenAdditionalProperties) {
    return leftPolicy is ForbiddenAdditionalProperties &&
        rightPolicy is ForbiddenAdditionalProperties;
  }
  final leftAllowed = leftPolicy as AllowedAdditionalProperties;
  final rightAllowed = rightPolicy as AllowedAdditionalProperties;
  return _isNullable(leftAllowed.valueModel) ==
          _isNullable(rightAllowed.valueModel) &&
      _compatibleModels(
        leftAllowed.valueModel,
        rightAllowed.valueModel,
        active,
      );
}

AdditionalPropertiesPolicy? _effectiveExplicitAdditionalProperties(
  Model model,
) {
  final policy = switch (model) {
    ClassModel(:final additionalPropertiesPolicy) => additionalPropertiesPolicy,
    AllOfModel(:final additionalPropertiesPolicy) => additionalPropertiesPolicy,
    _ => null,
  };
  return switch (policy) {
    AllowedAdditionalProperties(
      origin: AdditionalPropertiesOrigin.implicitDefault,
    ) =>
      null,
    _ => policy,
  };
}

Map<String, List<Property>> _objectProperties(Model model, Set<Model> active) {
  if (!active.add(model)) return const {};
  try {
    switch (model) {
      case AliasModel():
        return _objectProperties(model.model, active);
      case ClassModel():
        final result = <String, List<Property>>{};
        for (final property in model.properties) {
          (result[property.name] ??= []).add(property);
        }
        return result;
      case AllOfModel():
        final result = <String, List<Property>>{};
        for (final member in model.models) {
          for (final entry in _objectProperties(member, active).entries) {
            (result[entry.key] ??= []).addAll(entry.value);
          }
        }
        return result;
      default:
        return const {};
    }
  } finally {
    active.remove(model);
  }
}
