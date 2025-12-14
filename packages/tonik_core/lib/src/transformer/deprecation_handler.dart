import 'package:tonik_core/tonik_core.dart';

class DeprecationHandler {
  const DeprecationHandler();

  Set<Operation> handleOperations({
    required Set<Operation> operations,
    required DeprecatedHandling mode,
  }) {
    return switch (mode) {
      DeprecatedHandling.annotate => operations,
      DeprecatedHandling.exclude =>
        operations.where((op) => !op.isDeprecated).toSet(),
      DeprecatedHandling.ignore =>
        operations..forEach((op) => op.isDeprecated = false),
    };
  }

  Set<Model> handleSchemas({
    required Set<Model> models,
    required DeprecatedHandling mode,
  }) {
    return switch (mode) {
      DeprecatedHandling.annotate => models,
      DeprecatedHandling.exclude =>
        models.where((model) {
          return switch (model) {
            final ClassModel m => !m.isDeprecated,
            final EnumModel<Object?> m => !m.isDeprecated,
            final AllOfModel m => !m.isDeprecated,
            final OneOfModel m => !m.isDeprecated,
            final AnyOfModel m => !m.isDeprecated,
            _ => true,
          };
        }).toSet(),
      DeprecatedHandling.ignore =>
        models..forEach((model) {
          switch (model) {
            case final ClassModel m:
              m.isDeprecated = false;
            case final EnumModel<Object?> m:
              m.isDeprecated = false;
            case final AllOfModel m:
              m.isDeprecated = false;
            case final OneOfModel m:
              m.isDeprecated = false;
            case final AnyOfModel m:
              m.isDeprecated = false;
            default:
          }
        }),
    };
  }

  Set<QueryParameter> handleQueryParameters({
    required Set<QueryParameter> parameters,
    required DeprecatedHandling mode,
  }) {
    return switch (mode) {
      DeprecatedHandling.annotate => parameters,
      DeprecatedHandling.exclude =>
        parameters.where((param) {
          return switch (param) {
            final QueryParameterObject obj => !obj.isDeprecated,
            final QueryParameterAlias alias =>
              !alias.parameter.resolve().isDeprecated,
          };
        }).toSet(),
      DeprecatedHandling.ignore =>
        parameters..forEach((param) {
          if (param case final QueryParameterObject obj) {
            obj.isDeprecated = false;
          }
        }),
    };
  }

  Set<PathParameter> handlePathParameters({
    required Set<PathParameter> parameters,
    required DeprecatedHandling mode,
  }) {
    return switch (mode) {
      DeprecatedHandling.annotate => parameters,
      DeprecatedHandling.exclude =>
        parameters.where((param) {
          return switch (param) {
            final PathParameterObject obj => !obj.isDeprecated,
            final PathParameterAlias alias =>
              !alias.parameter.resolve().isDeprecated,
          };
        }).toSet(),
      DeprecatedHandling.ignore =>
        parameters..forEach((param) {
          if (param case final PathParameterObject obj) {
            obj.isDeprecated = false;
          }
        }),
    };
  }

  Set<RequestHeader> handleRequestHeaders({
    required Set<RequestHeader> headers,
    required DeprecatedHandling mode,
  }) {
    return switch (mode) {
      DeprecatedHandling.annotate => headers,
      DeprecatedHandling.exclude =>
        headers.where((header) {
          return switch (header) {
            final RequestHeaderObject obj => !obj.isDeprecated,
            final RequestHeaderAlias alias =>
              !alias.header.resolve().isDeprecated,
          };
        }).toSet(),
      DeprecatedHandling.ignore =>
        headers..forEach((header) {
          if (header case final RequestHeaderObject obj) {
            obj.isDeprecated = false;
          }
        }),
    };
  }

  List<Property> handleProperties({
    required List<Property> properties,
    required DeprecatedHandling mode,
  }) {
    return switch (mode) {
      DeprecatedHandling.annotate => properties,
      DeprecatedHandling.exclude =>
        properties.where((prop) => !prop.isDeprecated).toList(),
      DeprecatedHandling.ignore =>
        properties..forEach((prop) => prop.isDeprecated = false),
    };
  }
}
