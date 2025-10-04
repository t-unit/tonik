import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';

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
      log.fine('Importing schema $name');
      var model = _parseSchemaWrapper(name, schema, context);

      if (model is PrimitiveModel) {
        model = AliasModel(name: name, model: model, context: context);
      }

      if (models.none((m) => m is NamedModel && m.name == name)) {
        log.fine('Adding model $name');
        models.add(model);
      }
    }
  }

  Model importSchema(ReferenceWrapper<Schema> schema, Context context) {
    final model = _parseSchemaWrapper(null, schema, context);
    log.fine('Importing schema $model@$context');

    if (model is! PrimitiveModel && model is! AliasModel) {
      _logModelAdded(model);
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

        var model =
            models.firstWhereOrNull(
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

    if (schema.allOf != null) {
      return _parseAllOf(name, schema, context);
    }

    if (schema.oneOf != null) {
      return _parseOneOf(name, schema, context);
    }

    if (schema.anyOf != null) {
      return _parseAnyOf(name, schema, context);
    }

    // Check if the type array includes 'null'
    final hasNullType = schema.type.contains('null');
    final types = schema.type.where((t) => t != 'null').toList();

    if (types.length > 1) {
      return _parseMultiType(types, schema, hasNullType, context, name);
    }

    var model = switch (types.firstOrNull) {
      'string' when schema.format == 'date-time' => DateTimeModel(
        context: context,
      ),
      'string' when schema.format == 'date' => DateModel(context: context),
      'string'
          when [
            'decimal',
            'currency',
            'money',
            'number',
          ].contains(schema.format) =>
        DecimalModel(context: context),
      'string' when schema.format == 'uri' || schema.format == 'url' =>
        UriModel(context: context),
      'string' when schema.enumerated != null => _parseEnum<String>(
        name,
        schema.enumerated!,
        schema.isNullable ?? hasNullType,
        context,
      ),
      'string' => StringModel(context: context),
      'number' when schema.format == 'float' || schema.format == 'double' =>
        DoubleModel(context: context),
      'number' => NumberModel(context: context),
      'integer' when schema.enumerated != null => _parseEnum<int>(
        name,
        schema.enumerated!,
        schema.isNullable ?? hasNullType,
        context,
      ),
      'integer' => IntegerModel(context: context),
      'boolean' => BooleanModel(context: context),
      'array' => _parseArray(name, schema, context),
      _ => _parseClassModel(name, schema, context),
    };

    if (model is PrimitiveModel && name != null) {
      model = AliasModel(name: name, model: model, context: context);
      _logModelAdded(model);
      models.add(model);
    }

    return model;
  }

  OneOfModel _parseMultiType(
    List<String> types,
    Schema schema,
    bool hasNullType,
    Context context,
    String? name,
  ) {
    final models = types.map((type) {
      final singleTypeSchema = Schema(
        type: [type],
        format: schema.format,
        required: schema.required,
        enumerated: schema.enumerated,
        allOf: schema.allOf,
        anyOf: schema.anyOf,
        oneOf: schema.oneOf,
        not: schema.not,
        items: schema.items,
        properties: schema.properties,
        description: schema.description,
        isNullable: schema.isNullable ?? hasNullType,
        discriminator: schema.discriminator,
        isDeprecated: schema.isDeprecated,
        uniqueItems: schema.uniqueItems,
      );
      return (
        discriminatorValue: null,
        model: _parseSchema(null, singleTypeSchema, context),
      );
    });

    return OneOfModel(
      models: models.toSet(),
      name: name,
      discriminator: null,
      context: context,
    );
  }

  ListModel _parseArray(String? name, Schema schema, Context context) {
    final items = schema.items;
    if (items == null) {
      throw ArgumentError('Array schema $schema has no items');
    }

    final modelContext = context.push('array');
    final content = _parseSchemaWrapper(null, items, modelContext);
    return ListModel(content: content, context: context, name: name);
  }

  AllOfModel _parseAllOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'allOf');
    final models = schema.allOf!.map(
      (allOfSchema) => _parseSchemaWrapper(null, allOfSchema, modelContext),
    ).toList();
    
    final allOfModel = AllOfModel(
      models: models.toSet(),
      context: modelContext,
      name: name,
    );

    _addModelToSet(allOfModel);
    return allOfModel;
  }

  void _addModelToSet(Model model) {
    if (model is! PrimitiveModel) {
      _logModelAdded(model);
      models.add(model);

      if (model is OneOfModel) {
        for (final nestedModel in model.models) {
          _addModelToSet(nestedModel.model);
        }
      }
    }
  }

  OneOfModel _parseOneOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'oneOf');
    final models = schema.oneOf!.map(
      (oneOfSchema) => (
        discriminatorValue: _getDiscriminatorValue(
          schema: schema,
          innerSchema: oneOfSchema,
        ),
        model: _parseSchemaWrapper(null, oneOfSchema, modelContext),
      ),
    );

    final oneOfModel = OneOfModel(
      models: models.toSet(),
      context: context,
      name: name,
      discriminator: schema.discriminator?.propertyName,
    );

    _addModelToSet(oneOfModel);
    return oneOfModel;
  }

  AnyOfModel _parseAnyOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'anyOf');
    final models = schema.anyOf!.map(
      (anyOfSchema) => (
        discriminatorValue: _getDiscriminatorValue(
          schema: schema,
          innerSchema: anyOfSchema,
        ),
        model: _parseSchemaWrapper(null, anyOfSchema, modelContext),
      ),
    );
    final anyOfModel = AnyOfModel(
      models: models.toSet(),
      context: context,
      name: name,
      discriminator: schema.discriminator?.propertyName,
    );

    _addModelToSet(anyOfModel);
    return anyOfModel;
  }

  String? _getDiscriminatorValue({
    required Schema schema,
    required ReferenceWrapper<Schema> innerSchema,
  }) {
    if (innerSchema is Reference &&
        schema.discriminator?.propertyName != null) {
      final ref = (innerSchema as Reference).ref;
      final discriminatorEntry = schema.discriminator?.mapping?.entries
          .firstWhereOrNull((entry) => entry.value == ref);
      return discriminatorEntry?.key ?? ref.split('/').last;
    }
    return null;
  }

  ClassModel _parseClassModel(String? name, Schema schema, Context context) {
    final schemaProperties = schema.properties ?? {};
    final properties = <Property>[];

    final model = ClassModel(
      name: name,
      properties: properties,
      context: context,
    );

    if (schema.not != null) {
      log.warning(
        'Found not schema for $name. The not keyword is not '
        'supported and will be ignored.',
      );
    }

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      // Add model to the list of models before parsing properties,
      // only so we can support recursive models.
      _logModelAdded(model);
      models.add(model);
    }

    for (final MapEntry(key: propertyName, value: propertySchema)
        in schemaProperties.entries) {
      bool isNullable;
      bool isDeprecated;
      if (propertySchema is InlinedObject<Schema>) {
        final schema = propertySchema.object;
        isNullable = schema.isNullable ?? schema.type.contains('null');
        isDeprecated = schema.isDeprecated ?? false;
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
    List<dynamic> values,
    bool isNullable,
    Context context,
  ) {
    log.fine('Parsing enum $name<$T> for $context with values $values');

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

    final model = EnumModel<T>(
      values: typedValues,
      isNullable: isNullable || hasNull,
      context: context,
      name: name,
    );

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      _logModelAdded(model);
      models.add(model);
    }

    return model;
  }

  void _logModelAdded(Model model) {
    final name =
        model is NamedModel && model.name != null
            ? model.name
            : '${model.context}->${model.runtimeType}';
    log.fine('Adding model $name');
  }
}
