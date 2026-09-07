import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Removes unconstrained allOf members and normalizes redundant intersections.
///
/// This transformer performs in-place replacement throughout the entire
/// document, ensuring referential consistency by memoizing transformations.
@immutable
class const AllOfNormalizer({final bool normalizeSingleMembers = true}) {
  /// Normalizes allOf schemas, optionally reducing single models to aliases.
  ///
  /// This simplifies patterns like `allOf: [$ref, {description: ...}]` used
  /// by Spotify and others to add descriptions to referenced schemas.
  ApiDocument apply(ApiDocument document) {
    final cache = <Model, Model>{};

    final transformedModels = <Model>{};
    for (final model in document.models) {
      transformedModels.add(_transformModel(model, cache));
    }
    document.models = transformedModels;

    for (final model in document.models) {
      if (model is ClassModel) {
        for (final prop in model.properties) {
          final transformed = cache[prop.model];
          if (transformed != null && transformed != prop.model) {
            prop.model = transformed;
          }
        }
      }
    }

    for (final response in document.responses) {
      _updateResponseModels(response, cache);
    }

    for (final operation in document.operations) {
      for (final response in operation.responses.values) {
        _updateResponseModels(response, cache);
      }

      final requestBody = operation.requestBody;
      if (requestBody != null) {
        _updateRequestBodyModels(requestBody, cache);
      }

      for (final header in operation.headers) {
        _updateRequestHeaderModel(header, cache);
      }

      for (final param in operation.queryParameters) {
        _updateQueryParameterModel(param, cache);
      }

      for (final param in operation.pathParameters) {
        _updatePathParameterModel(param, cache);
      }
      for (final param in operation.cookieParameters) {
        _updateCookieParameterModel(param, cache);
      }
    }

    for (final requestBody in document.requestBodies) {
      _updateRequestBodyModels(requestBody, cache);
    }

    for (final header in document.responseHeaders) {
      _updateResponseHeaderModel(header, cache);
    }

    for (final header in document.requestHeaders) {
      _updateRequestHeaderModel(header, cache);
    }

    for (final param in document.queryParameters) {
      _updateQueryParameterModel(param, cache);
    }
    for (final param in document.pathParameters) {
      _updatePathParameterModel(param, cache);
    }
    for (final param in document.cookieParameters) {
      _updateCookieParameterModel(param, cache);
    }

    return document;
  }

  /// Transforms a model, normalizing single-model AllOfModels to AliasModels.
  Model _transformModel(Model model, Map<Model, Model> cache) {
    if (cache.containsKey(model)) {
      return cache[model]!;
    }

    // Placeholder to handle cycles
    cache[model] = model;

    final Model result;

    if (model is AllOfModel) {
      final newModels = <Model>[];
      var hasUnconstrainedMember = false;
      for (final m in model.models) {
        final transformed = _transformModel(m, cache);
        if (transformed.resolved is AnyModel) {
          // An unconstrained schema is the identity of an intersection.
          hasUnconstrainedMember = true;
        } else {
          newModels.add(transformed);
        }
      }
      model.additionalPropertiesPolicy = _transformAdditionalProperties(
        model.additionalPropertiesPolicy,
        cache,
      );
      final hasExplicitAdditionalProperties =
          switch (model.additionalPropertiesPolicy) {
            AllowedAdditionalProperties(:final origin) =>
              origin == AdditionalPropertiesOrigin.explicit,
            ForbiddenAdditionalProperties() => true,
          };
      final isUnconstrained = hasUnconstrainedMember && newModels.isEmpty;
      final additionalProperties = model.additionalPropertiesPolicy;
      final hasRecursiveAdditionalProperties =
          isUnconstrained &&
          additionalProperties is AllowedAdditionalProperties &&
          _referencesModel(additionalProperties.valueModel, model, {});
      if (hasRecursiveAdditionalProperties) {
        // Keep the concrete shell that recursive references already target.
        // A recursive alias of an anonymous map is not a valid Dart typedef.
        model.models = [_additionalPropertiesModel(model)];
        result = model;
      } else if (isUnconstrained ||
          (!hasExplicitAdditionalProperties &&
              normalizeSingleMembers &&
              newModels.length == 1)) {
        result = AliasModel(
          name: model.name,
          model: isUnconstrained
              ? _additionalPropertiesModel(model)
              : newModels.single,
          context: model.context,
          description: model.description,
          isDeprecated: model.isDeprecated,
          isNullable: model.isNullable,
          isReadOnly: model.isReadOnly,
          isWriteOnly: model.isWriteOnly,
          nameOverride: model.nameOverride,
          defaultValue: model.defaultValue,
          examples: model.examples,
        );
      } else {
        model.models = newModels;
        result = model;
      }
    } else if (model is ClassModel) {
      for (final prop in model.properties) {
        prop.model = _transformModel(prop.model, cache);
      }
      model.additionalPropertiesPolicy = _transformAdditionalProperties(
        model.additionalPropertiesPolicy,
        cache,
      );
      result = model;
    } else if (model is OneOfModel) {
      final newModels = <({String? discriminatorValue, Model model})>[];
      for (final m in model.models) {
        newModels.add((
          discriminatorValue: m.discriminatorValue,
          model: _transformModel(m.model, cache),
        ));
      }
      model.models = newModels;
      result = model;
    } else if (model is AnyOfModel) {
      final newModels = <({String? discriminatorValue, Model model})>[];
      for (final m in model.models) {
        newModels.add((
          discriminatorValue: m.discriminatorValue,
          model: _transformModel(m.model, cache),
        ));
      }
      model.models = newModels;
      result = model;
    } else if (model is ListModel) {
      model.content = _transformModel(model.content, cache);
      result = model;
    } else if (model is MapModel) {
      model.valueModel = _transformModel(model.valueModel, cache);
      result = model;
    } else if (model is AliasModel) {
      model.model = _transformModel(model.model, cache);
      result = model;
    } else {
      result = model;
    }

    cache[model] = result;
    return result;
  }

  AdditionalPropertiesPolicy _transformAdditionalProperties(
    AdditionalPropertiesPolicy policy,
    Map<Model, Model> cache,
  ) {
    if (policy is! AllowedAdditionalProperties) return policy;
    final valueModel = _transformModel(policy.valueModel, cache);
    if (identical(valueModel, policy.valueModel)) return policy;
    return AllowedAdditionalProperties(
      valueModel: valueModel,
      origin: policy.origin,
    );
  }

  Model _additionalPropertiesModel(AllOfModel model) {
    final policy = model.additionalPropertiesPolicy;
    if (policy is AllowedAdditionalProperties &&
        policy.valueModel.resolved is AnyModel) {
      return AnyModel(context: model.context);
    }
    return MapModel(
      valueModel: policy is AllowedAdditionalProperties
          ? policy.valueModel
          : NeverModel(context: model.context, isNullable: false),
      context: model.context,
      examples: const [],
    );
  }

  bool _referencesModel(Model model, Model target, Set<Model> visited) {
    if (identical(model, target)) return true;
    if (!visited.add(model)) return false;
    final children = switch (model) {
      AliasModel() => [model.model],
      MapModel() => [model.valueModel],
      ListModel() => [model.content],
      ClassModel() => [
        ...model.properties.map((property) => property.model),
        if (model.additionalPropertiesPolicy case AllowedAdditionalProperties(
          :final valueModel,
        ))
          valueModel,
      ],
      AllOfModel() => [
        ...model.models,
        if (model.additionalPropertiesPolicy case AllowedAdditionalProperties(
          :final valueModel,
        ))
          valueModel,
      ],
      CompositeModel() => model.containedModels,
      _ => const <Model>[],
    };
    return children.any((child) => _referencesModel(child, target, visited));
  }

  void _updateResponseModels(Response response, Map<Model, Model> cache) {
    switch (response) {
      case ResponseAlias():
        _updateResponseModels(response.response, cache);
      case ResponseObject():
        for (final body in response.bodies) {
          body.model = _transformModel(body.model, cache);
        }
        for (final header in response.headers.values) {
          _updateResponseHeaderModel(header, cache);
        }
    }
  }

  void _updateRequestBodyModels(
    RequestBody requestBody,
    Map<Model, Model> cache,
  ) {
    switch (requestBody) {
      case RequestBodyAlias():
        _updateRequestBodyModels(requestBody.requestBody, cache);
      case RequestBodyObject():
        for (final content in requestBody.content) {
          switch (content) {
            case ModelRequestContent():
              content.model = _transformModel(content.model, cache);
            case MultipartRequestContent():
              content.model = _transformModel(content.model, cache);
          }
        }
    }
  }

  void _updateResponseHeaderModel(
    ResponseHeader header,
    Map<Model, Model> cache,
  ) {
    switch (header) {
      case ResponseHeaderAlias():
        _updateResponseHeaderModel(header.header, cache);
      case ResponseHeaderObject():
        header.model = _transformModel(header.model, cache);
    }
  }

  void _updateRequestHeaderModel(
    RequestHeader header,
    Map<Model, Model> cache,
  ) {
    switch (header) {
      case RequestHeaderAlias():
        _updateRequestHeaderModel(header.header, cache);
      case RequestHeaderObject():
        header.model = _transformModel(header.model, cache);
    }
  }

  void _updateQueryParameterModel(
    QueryParameter param,
    Map<Model, Model> cache,
  ) {
    switch (param) {
      case QueryParameterAlias():
        _updateQueryParameterModel(param.parameter, cache);
      case QueryParameterObject():
        param.model = _transformModel(param.model, cache);
    }
  }

  void _updatePathParameterModel(PathParameter param, Map<Model, Model> cache) {
    switch (param) {
      case PathParameterAlias():
        _updatePathParameterModel(param.parameter, cache);
      case PathParameterObject():
        param.model = _transformModel(param.model, cache);
    }
  }

  void _updateCookieParameterModel(
    CookieParameter param,
    Map<Model, Model> cache,
  ) {
    switch (param) {
      case CookieParameterAlias():
        _updateCookieParameterModel(param.parameter, cache);
      case CookieParameterObject():
        param.model = _transformModel(param.model, cache);
    }
  }
}
