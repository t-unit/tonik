import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Normalizes AllOfModel instances with a single contained model to AliasModel.
///
/// This transformer performs in-place replacement throughout the entire
/// document, ensuring referential consistency by memoizing transformations.
@immutable
class AllOfNormalizer {
  const AllOfNormalizer();

  /// Normalizes allOf schemas with a single model to type aliases.
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

    if (model is AllOfModel && model.models.length == 1) {
      final containedModel = _transformModel(model.models.first, cache);
      result = AliasModel(
        name: model.name,
        model: containedModel,
        context: model.context,
        description: model.description,
        isDeprecated: model.isDeprecated,
        isNullable: model.isNullable,
        nameOverride: model.nameOverride,
      );
    } else if (model is AllOfModel) {
      final newModels = <Model>{};
      for (final m in model.models) {
        newModels.add(_transformModel(m, cache));
      }
      model.models
        ..clear()
        ..addAll(newModels);
      result = model;
    } else if (model is ClassModel) {
      for (final prop in model.properties) {
        prop.model = _transformModel(prop.model, cache);
      }
      result = model;
    } else if (model is OneOfModel) {
      final newModels = <({String? discriminatorValue, Model model})>{};
      for (final m in model.models) {
        newModels.add((
          discriminatorValue: m.discriminatorValue,
          model: _transformModel(m.model, cache),
        ));
      }
      model.models
        ..clear()
        ..addAll(newModels);
      result = model;
    } else if (model is AnyOfModel) {
      final newModels = <({String? discriminatorValue, Model model})>{};
      for (final m in model.models) {
        newModels.add((
          discriminatorValue: m.discriminatorValue,
          model: _transformModel(m.model, cache),
        ));
      }
      model.models
        ..clear()
        ..addAll(newModels);
      result = model;
    } else if (model is ListModel) {
      model.content = _transformModel(model.content, cache);
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

  void _updateResponseModels(Response response, Map<Model, Model> cache) {
    switch (response) {
      case ResponseAlias():
        _updateResponseModels(response.response, cache);
      case ResponseObject():
        for (final body in response.bodies) {
          final transformed = cache[body.model];
          if (transformed != null && transformed != body.model) {
            body.model = transformed;
          }
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
          final transformed = cache[content.model];
          if (transformed != null && transformed != content.model) {
            content.model = transformed;
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
        final transformed = cache[header.model];
        if (transformed != null && transformed != header.model) {
          header.model = transformed;
        }
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
        final transformed = cache[header.model];
        if (transformed != null && transformed != header.model) {
          header.model = transformed;
        }
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
        final transformed = cache[param.model];
        if (transformed != null && transformed != param.model) {
          param.model = transformed;
        }
    }
  }

  void _updatePathParameterModel(
    PathParameter param,
    Map<Model, Model> cache,
  ) {
    switch (param) {
      case PathParameterAlias():
        _updatePathParameterModel(param.parameter, cache);
      case PathParameterObject():
        final transformed = cache[param.model];
        if (transformed != null && transformed != param.model) {
          param.model = transformed;
        }
    }
  }
}
