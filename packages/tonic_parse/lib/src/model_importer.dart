import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/schema.dart';

class ModelImporter {
  ModelImporter(OpenApiObject openApiObject)
      : _schemas = openApiObject.components?.schemas ?? {};

  final Map<String, ReferenceWrapper<Schema>> _schemas;
  late Set<Model> models;
  final log = Logger('ModelImporter');

  static Context get rootContext =>
      Context.initial().pushAll(['components', 'schemas']);

  void import() {
    models = <Model>{};

    final context = rootContext;

    for (final MapEntry(key: name, value: schema) in _schemas.entries) {
      var model = _parseSchemaWrapper(name, schema, context);

      if (model is PrimitiveModel) {
        model = AliasModel(name: name, model: model, context: context);
      }

      if (models.none((m) => m is NamedModel && m.name == name)) {
        models.add(model);
      }
    }
  }

  Model importSchema(ReferenceWrapper<Schema> schema, Context context) {
    final model = _parseSchemaWrapper(null, schema, context);

    if (model is! PrimitiveModel && model is! AliasModel) {
      models.add(model);
    }

    return model;
  }

  Model _parseSchemaWrapper(
    String? name,
    ReferenceWrapper<Schema> schema,
    Context context,
  ) {
    switch (schema) {
      case Reference():
        if (!schema.ref.startsWith('#/components/schemas/')) {
          throw UnimplementedError(
            'Only local schema references are supported, '
            'found ${schema.ref} for $name',
          );
        }

        final refName = schema.ref.split('/').last;
        final ref = _schemas[refName];

        if (ref == null) {
          throw ArgumentError('Schema $ref not found for $name');
        }

        var model = models.firstWhereOrNull(
              (model) => model is NamedModel && model.name == refName,
            ) ??
            _parseSchemaWrapper(refName, ref, rootContext);

        if (name != null) {
          model = AliasModel(name: name, model: model, context: context);
        }

        return model;

      case InlinedObject<Schema>():
        return _parseSchema(name, schema.object, context);
    }
  }

  Model _parseSchema(String? name, Schema schema, Context context) {
    final existing = models.firstWhereOrNull(
      (model) => name != null && model is NamedModel && model.name == name,
    );
    if (existing != null) {
      return existing;
    }

    var model = switch (schema.type) {
      'string' when schema.format == 'date-time' =>
        DateTimeModel(context: context),
      'string' when schema.format == 'date' => DateModel(context: context),
      'string' when schema.format == 'decimal' || schema.format == 'currency' =>
        DecimalModel(context: context),
      'string' when schema.enumerated != null =>
        _parseEnum<String>(name, schema.enumerated!, context: context),
      'string' => StringModel(context: context),
      'number' when schema.format == 'float' || schema.format == 'double' =>
        DoubleModel(context: context),
      'number' => NumberModel(context: context),
      'integer' when schema.enumerated != null =>
        _parseEnum<int>(name, schema.enumerated!, context: context),
      'integer' => IntegerModel(context: context),
      'boolean' => BooleanModel(context: context),
      _ => _parseClassModel(name, schema, context),
    };

    if (model is PrimitiveModel && name != null) {
      model = AliasModel(name: name, model: model, context: context);
      models.add(model);
    }

    return model;
  }

  ClassModel _parseClassModel(String? name, Schema schema, Context context) {
    final schemaProperties = schema.properties ?? {};
    final properties = <Property>{};

    final model = ClassModel(
      name: name,
      properties: properties,
      context: context,
    );

    if (schema.not != null) {
      log.warning('Found not schema for $name. The not keyword is not '
          'supported and will be ignored.');
    }

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      // Add model to the list of models before parsing properties,
      // only so we can support recursive models.
      models.add(model);
    }

    for (final MapEntry(key: propertyName, value: propertySchema)
        in schemaProperties.entries) {
      bool isNullable;
      bool isDeprecated;
      if (propertySchema is InlinedObject<Schema>) {
        isNullable = propertySchema.object.isNullable ?? false;
        isDeprecated = propertySchema.object.isDeprecated ?? false;
      } else {
        isNullable = false;
        isDeprecated = false;
      }

      properties.add(
        Property(
          name: propertyName,
          model: _parseSchemaWrapper(
            null,
            propertySchema,
            context.pushAll([name, propertyName].whereType<String>()),
          ),
          isRequired: schema.required?.contains(propertyName) ?? false,
          isNullable: isNullable,
          isDeprecated: isDeprecated,
        ),
      );
    }

    return model;
  }

  EnumModel<T> _parseEnum<T>(
    String? name,
    List<dynamic> values, {
    required Context context,
  }) {
    final typedValues = values.whereType<T>().toSet();
    final hasNull = values.any((value) => value == null);

    // Warn if there are non-matching values in the enum.
    // Ignore [null] values, as we indicate nullability with [isNullable].
    if (!hasNull && typedValues.length != values.length ||
        hasNull && (typedValues.length + 1) != values.length) {
      log.warning(
        'Found non-matching values in enum for $context. '
        'Ignoring non-matching values.',
      );
    }

    return EnumModel(
      context: context,
      values: typedValues,
      isNullable: hasNull,
      name: name,
    );
  }
}
