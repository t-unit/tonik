import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/discriminator.dart' as parse;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/schema.dart';

class ModelImporter {
  ModelImporter(
    OpenApiObject openApiObject, {
    Map<String, SchemaContentType> contentMediaTypes = const {},
  }) : _schemas = openApiObject.components?.schemas ?? {},
       _contentMediaTypes = contentMediaTypes;

  final Map<String, Schema> _schemas;
  final Map<String, SchemaContentType> _contentMediaTypes;
  final Map<String, Schema> _defs = {};
  final Set<String> _resolving = {};
  final Map<String, AliasModel> _placeholders = {};

  /// Set of named schemas whose composite shells have been populated.
  ///
  /// Used during pass 2 to determine whether a referenced model's composite
  /// sub-models have already been filled in (and thus can be checked for
  /// back-edges).
  final Set<String> _populatedComposites = {};

  late Set<Model> models;
  final log = Logger('ModelImporter');

  static Context get rootContext =>
      Context.initial().pushAll(['components', 'schemas']);

  /// Imports all schemas from components/schemas using a two-pass approach.
  ///
  /// **Pass 1 — Shell creation**: Creates empty model shells for all named
  /// schemas without following `$ref` links. This ensures every named model
  /// exists before any references are resolved, eliminating the need for
  /// placeholder-based cycle detection for named schemas.
  ///
  /// **Pass 2 — Reference population**: Populates each shell's references
  /// (sub-models, properties, list content) using the existing recursive
  /// resolution logic. For composite models (oneOf/allOf/anyOf), back-edges
  /// that would create cycles are skipped.
  void import() {
    models = <Model>{};
    _placeholders.clear();
    _populatedComposites.clear();
    _collectAllDefs();

    final context = rootContext;

    // --- Pass 1: Create empty shells for all named schemas ---
    for (final MapEntry(key: name, value: schema) in _schemas.entries) {
      log.fine('Pass 1: Creating shell for $name');
      _createShell(name, schema, context);
    }

    // --- Pass 2: Populate all shells ---
    for (final MapEntry(key: name, value: schema) in _schemas.entries) {
      log.fine('Pass 2: Populating $name');
      _populateShell(name, schema, context);
    }
  }

  /// Creates an empty model shell for a named schema without resolving refs.
  ///
  /// Determines the model type from the schema structure and creates the
  /// appropriate model with empty collections. The shell is registered in
  /// [models] so it can be found during pass 2.
  void _createShell(String name, Schema schema, Context context) {
    // Skip if already created (e.g. from a previous pass 1 iteration).
    if (models.any((m) => m is NamedModel && m.name == name)) {
      return;
    }

    // If it's a $ref, create an alias shell.
    if (schema.ref != null) {
      // Direct self-reference check.
      final ref = schema.ref!;
      if (ref.startsWith('#/components/schemas/')) {
        final refName = ref.split('/').last;
        if (name == refName) {
          // Will be caught during pass 2 with proper error.
          return;
        }
      }

      final aliasModel = AliasModel(
        name: name,
        model: AnyModel(context: context),
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.isNullable ?? schema.type.contains('null'),
      );
      _logModelAdded(aliasModel);
      models.add(aliasModel);
      return;
    }

    if (schema.isBooleanSchema != null) {
      final model = schema.isBooleanSchema!
          ? AnyModel(context: context)
          : NeverModel(context: context);
      final aliasModel = AliasModel(
        name: name,
        model: model,
        context: context,
      );
      _logModelAdded(aliasModel);
      models.add(aliasModel);
      return;
    }

    if (schema.allOf != null) {
      final modelContext = context.push(name);
      final allOfModel = AllOfModel(
        isDeprecated: schema.isDeprecated ?? false,
        models: <Model>{},
        context: modelContext,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(allOfModel);
      models.add(allOfModel);
      return;
    }

    if (schema.oneOf != null) {
      final oneOfModel = OneOfModel(
        isDeprecated: schema.isDeprecated ?? false,
        models: <DiscriminatedModel>{},
        context: context,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(oneOfModel);
      models.add(oneOfModel);
      return;
    }

    if (schema.anyOf != null) {
      final anyOfModel = AnyOfModel(
        isDeprecated: schema.isDeprecated ?? false,
        models: <DiscriminatedModel>{},
        context: context,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(anyOfModel);
      models.add(anyOfModel);
      return;
    }

    final hasNullType = schema.type.contains('null');
    final types = schema.type.where((t) => t != 'null').toList();

    if (types.length > 1) {
      // Multi-type becomes OneOfModel — create shell.
      final oneOfModel = OneOfModel(
        isDeprecated: schema.isDeprecated ?? false,
        models: <DiscriminatedModel>{},
        context: context,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(oneOfModel);
      models.add(oneOfModel);
      return;
    }

    // Pure map detection.
    if ((schema.properties == null || schema.properties!.isEmpty) &&
        schema.additionalProperties != null &&
        schema.additionalProperties != false) {
      final model = MapModel(
        valueModel: AnyModel(context: context),
        context: context,
        name: name,
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(model);
      models.add(model);
      return;
    }

    final firstType = types.firstOrNull;

    // Primitive types get wrapped in AliasModel.
    if (_isPrimitiveType(firstType, schema)) {
      final primitiveModel = _createPrimitiveModel(firstType, schema, context);
      if (primitiveModel != null) {
        final aliasModel = AliasModel(
          name: name,
          model: primitiveModel,
          context: context,
          isNullable: schema.isNullable ?? hasNullType,
          isReadOnly: schema.isReadOnly ?? false,
          isWriteOnly: schema.isWriteOnly ?? false,
        );
        _logModelAdded(aliasModel);
        models.add(aliasModel);
        return;
      }
    }

    // Enum types.
    if (firstType == 'string' && schema.enumerated != null) {
      // Will be fully created during pass 2 since enums are self-contained.
      return;
    }
    if (firstType == 'integer' && schema.enumerated != null) {
      return;
    }

    // Array type.
    if (firstType == 'array') {
      final listModel = ListModel(
        content: AnyModel(context: context.push('array')),
        context: context,
        name: name,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(listModel);
      models.add(listModel);
      return;
    }

    // Default: ClassModel (object type or untyped with properties).
    final model = ClassModel(
      isDeprecated: schema.isDeprecated ?? false,
      name: name,
      properties: <Property>[],
      context: context,
      description: schema.description,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );
    _logModelAdded(model);
    models.add(model);
  }

  /// Returns true if the type string represents a primitive type.
  bool _isPrimitiveType(String? type, Schema schema) {
    return switch (type) {
      'string' when schema.enumerated != null => false,
      'string' => true,
      'number' => true,
      'integer' when schema.enumerated != null => false,
      'integer' => true,
      'boolean' => true,
      _ => false,
    };
  }

  /// Creates a primitive model from the type string.
  Model? _createPrimitiveModel(
    String? type,
    Schema schema,
    Context context,
  ) {
    return switch (type) {
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
      'string' when schema.format == 'binary' => BinaryModel(context: context),
      'string' when schema.contentEncoding != null =>
        _resolveContentEncodedModel(schema, context),
      'string' when schema.format == 'byte' => Base64Model(context: context),
      'string' => StringModel(context: context),
      'number' when schema.format == 'float' || schema.format == 'double' =>
        DoubleModel(context: context),
      'number' => NumberModel(context: context),
      'integer' => IntegerModel(context: context),
      'boolean' => BooleanModel(context: context),
      _ => null,
    };
  }

  /// Populates a named schema shell created during pass 1.
  ///
  /// Re-reads the schema and resolves all references. The shell already
  /// exists in [models], so recursive references find it immediately.
  void _populateShell(String name, Schema schema, Context context) {
    final existingModel = models.firstWhereOrNull(
      (m) => m is NamedModel && m.name == name,
    );

    // For schemas that didn't get a shell in pass 1 (e.g. direct
    // self-references that were skipped, enums), run the full parse.
    if (existingModel == null) {
      var model = _resolveSchemaRef(name, schema, context);

      if (model is PrimitiveModel || model is AnyModel || model is NeverModel) {
        model = AliasModel(
          name: name,
          model: model,
          context: context,
        );
      }

      if (schema.xDartName != null) {
        if (model is NamedModel) {
          model.nameOverride = schema.xDartName;
        }
      }

      if (models.none((m) => m is NamedModel && m.name == name)) {
        log.fine('Adding model $name');
        models.add(model);
      }
      return;
    }

    // Apply x-dart-name vendor extension.
    if (schema.xDartName != null) {
      if (existingModel is NamedModel) {
        existingModel.nameOverride = schema.xDartName;
      }
    }

    // Populate based on model type.
    if (schema.ref != null) {
      _populateAliasShell(name, schema, context, existingModel as AliasModel);
      return;
    }

    if (schema.isBooleanSchema != null) {
      // Already fully populated in pass 1.
      return;
    }

    if (schema.allOf != null) {
      _populateAllOfShell(
        name,
        schema,
        context,
        existingModel as AllOfModel,
      );
      return;
    }

    if (schema.oneOf != null) {
      _populateOneOfShell(
        name,
        schema,
        context,
        existingModel as OneOfModel,
      );
      return;
    }

    if (schema.anyOf != null) {
      _populateAnyOfShell(
        name,
        schema,
        context,
        existingModel as AnyOfModel,
      );
      return;
    }

    final hasNullType = schema.type.contains('null');
    final types = schema.type.where((t) => t != 'null').toList();

    if (types.length > 1) {
      _populateMultiTypeShell(
        name,
        schema,
        hasNullType,
        context,
        existingModel as OneOfModel,
      );
      return;
    }

    // Pure map detection.
    if ((schema.properties == null || schema.properties!.isEmpty) &&
        schema.additionalProperties != null &&
        schema.additionalProperties != false) {
      _populateMapShell(name, schema, context, existingModel as MapModel);
      return;
    }

    final firstType = types.firstOrNull;

    // Primitives are already fully populated.
    if (_isPrimitiveType(firstType, schema)) {
      return;
    }

    // Array type.
    if (firstType == 'array') {
      _populateArrayShell(name, schema, context, existingModel as ListModel);
      return;
    }

    // Default: ClassModel.
    if (existingModel is ClassModel) {
      _populateClassShell(name, schema, context, existingModel);
    }
  }

  /// Populates an alias shell created for a `$ref` schema.
  ///
  /// The shell was already registered in pass 1 and may be referenced by
  /// other models (e.g. as an allOf member). We update it in place rather
  /// than replacing it, so existing references remain valid.
  void _populateAliasShell(
    String name,
    Schema schema,
    Context context,
    AliasModel shell,
  ) {
    final ref = schema.ref!;

    if (ref.contains(r'/$defs/')) {
      // For $defs references, delegate to the existing resolution logic.
      models.remove(shell);
      final model = _resolveDefsReference(name, schema, context);
      if (model is AliasModel && !identical(model, shell)) {
        shell
          ..model = model.model
          ..description = model.description
          ..isDeprecated = model.isDeprecated
          ..isNullable = model.isNullable
          ..isReadOnly = model.isReadOnly
          ..isWriteOnly = model.isWriteOnly;
      }
      if (models.none((m) => m is NamedModel && m.name == name)) {
        models.add(shell);
      }
      return;
    }

    if (!ref.startsWith('#/components/schemas/')) {
      throw UnimplementedError(
        'Only local schema references are supported, '
        'found $ref for $name',
      );
    }

    final refName = ref.split('/').last;

    if (name == refName) {
      throw ArgumentError(
        'Schema $name has a direct self-reference which is not supported',
      );
    }

    final refSchema = _schemas[refName];
    if (refSchema == null) {
      throw ArgumentError('Schema $ref not found for $name');
    }

    // Find the target model (shell from pass 1 or fully resolved).
    final refModel =
        models.firstWhereOrNull(
          (model) => model is NamedModel && model.name == refName,
        ) ??
        _resolveWithCycleCheck(refName, refSchema);

    // Handle structural siblings ($ref + properties/allOf/oneOf/anyOf).
    if (_hasStructuralSiblings(schema)) {
      // Need to replace shell with an AllOfModel.
      models.remove(shell);
      final allOfModel = _mergeRefWithStructuralSiblings(
        name,
        refModel,
        schema,
        context,
      );
      // Update shell to point to the allOf so existing references still work.
      shell.model = allOfModel;
      // The allOfModel is already registered by
      // _mergeRefWithStructuralSiblings.
      // We don't re-add the shell since the allOfModel replaces it.
      return;
    }

    // Check for bare $ref cycles before updating the shell.
    // If following the alias chain from refModel would lead back to this
    // shell, we'd create an infinite loop. Keep the AnyModel terminal.
    if (_wouldCreateAliasCycle(shell, refModel)) {
      // Keep the shell's AnyModel as the terminal to break the cycle.
      shell
        ..description = schema.description
        ..isDeprecated = (schema.isDeprecated ?? false)
        ..isNullable = (schema.isNullable ?? schema.type.contains('null'));
      return;
    }

    // Update the shell's inner model to point to the resolved target.
    shell
      ..model = refModel
      ..description = schema.description
      ..isDeprecated = (schema.isDeprecated ?? false)
      ..isNullable = (schema.isNullable ?? schema.type.contains('null'));
  }

  /// Returns true if setting the shell's model to [target] would create
  /// an alias cycle (e.g. AliasA -> AliasB -> AliasA).
  bool _wouldCreateAliasCycle(AliasModel shell, Model target) {
    var current = target;
    final visited = <Model>{shell};
    while (current is AliasModel) {
      if (visited.contains(current)) {
        return true;
      }
      visited.add(current);
      current = current.model;
    }
    return false;
  }

  /// Populates an allOf shell's models.
  void _populateAllOfShell(
    String name,
    Schema schema,
    Context context,
    AllOfModel shell,
  ) {
    final modelContext = context.push(name);

    shell.additionalProperties = _resolveAdditionalProperties(
      schema,
      modelContext,
    );

    final resolvedModels = <Model>{};
    for (final allOfSchema in schema.allOf!) {
      final model = _resolveCompositeSubModel(
        allOfSchema,
        modelContext,
        shell,
      );
      if (model != null) {
        resolvedModels.add(model);
      }
    }
    shell.models = resolvedModels;

    _populatedComposites.add(name);
  }

  /// Populates a oneOf shell's models.
  void _populateOneOfShell(
    String name,
    Schema schema,
    Context context,
    OneOfModel shell,
  ) {
    final modelContext = context.push(name);
    final alternatives = schema.oneOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    shell.discriminator = effectiveDiscriminator?.propertyName;

    final resolvedModels = <DiscriminatedModel>{};
    for (final oneOfSchema in alternatives) {
      final model = _resolveCompositeSubModel(
        oneOfSchema,
        modelContext,
        shell,
      );
      if (model != null) {
        resolvedModels.add((
          discriminatorValue: _getDiscriminatorValue(
            discriminator: effectiveDiscriminator,
            innerSchema: oneOfSchema,
          ),
          model: model,
        ));
      }
    }
    shell.models = resolvedModels;

    _populatedComposites.add(name);

    // Add nested models to the model set.
    for (final nestedModel in shell.models) {
      _addModelToSet(nestedModel.model);
    }
  }

  /// Populates an anyOf shell's models.
  void _populateAnyOfShell(
    String name,
    Schema schema,
    Context context,
    AnyOfModel shell,
  ) {
    final modelContext = context.push(name);
    final alternatives = schema.anyOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    shell.discriminator = effectiveDiscriminator?.propertyName;

    final resolvedModels = <DiscriminatedModel>{};
    for (final anyOfSchema in alternatives) {
      final model = _resolveCompositeSubModel(
        anyOfSchema,
        modelContext,
        shell,
      );
      if (model != null) {
        resolvedModels.add((
          discriminatorValue: _getDiscriminatorValue(
            discriminator: effectiveDiscriminator,
            innerSchema: anyOfSchema,
          ),
          model: model,
        ));
      }
    }
    shell.models = resolvedModels;

    _populatedComposites.add(name);
  }

  /// Resolves a sub-model for a composite (oneOf/allOf/anyOf) shell.
  ///
  /// If the sub-schema is a `$ref` to a named composite model that already
  /// (transitively) contains [currentShell] in its composite sub-models,
  /// returns `null` to skip the back-edge and prevent a cycle.
  Model? _resolveCompositeSubModel(
    Schema schema,
    Context context,
    Model currentShell,
  ) {
    if (schema.ref != null) {
      final ref = schema.ref!;
      if (ref.startsWith('#/components/schemas/')) {
        final refName = ref.split('/').last;
        final refModel = models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == refName,
        );
        if (refModel != null &&
            _compositeContains(refModel, currentShell, <Model>{})) {
          log.fine(
            'Skipping back-edge to $refName during composite population '
            'to prevent cycle.',
          );
          return null;
        }
      }
    }

    return _resolveSchemaRef(null, schema, context);
  }

  /// Returns true if [model] transitively contains [target] in its
  /// composite sub-models (oneOf/allOf/anyOf members).
  bool _compositeContains(Model model, Model target, Set<Model> visited) {
    if (identical(model, target)) {
      return true;
    }
    if (!visited.add(model)) {
      return false;
    }

    final subModels = switch (model) {
      OneOfModel(:final models) => models.map((m) => m.model),
      AllOfModel(:final models) => models,
      AnyOfModel(:final models) => models.map((m) => m.model),
      AliasModel(:final model) => [model],
      _ => <Model>[],
    };

    for (final sub in subModels) {
      if (_compositeContains(sub, target, visited)) {
        return true;
      }
    }

    return false;
  }

  /// Populates a multi-type OneOfModel shell.
  void _populateMultiTypeShell(
    String name,
    Schema schema,
    bool hasNullType,
    Context context,
    OneOfModel shell,
  ) {
    // Remove the shell so _parseMultiType can create the real model.
    models.remove(shell);
    final oneOfModel = _parseMultiType(
      schema.type.where((t) => t != 'null').toList(),
      schema,
      hasNullType,
      context,
      name,
    );

    // Transfer the resolved data into the shell and restore it.
    shell
      ..models = oneOfModel.models
      ..discriminator = oneOfModel.discriminator;

    // Remove the duplicate created by _parseMultiType.
    models.remove(oneOfModel);
    if (models.none((m) => m is NamedModel && m.name == name)) {
      models.add(shell);
    }
  }

  /// Populates a MapModel shell's valueModel.
  void _populateMapShell(
    String name,
    Schema schema,
    Context context,
    MapModel shell,
  ) {
    final ap = schema.additionalProperties;
    final mapContext = context.push(name);
    if (ap == true) {
      shell.valueModel = AnyModel(context: mapContext);
    } else if (ap is Schema) {
      var valueModel = _resolveSchemaRef(null, ap, mapContext);
      final apNullable = ap.isNullable ?? ap.type.contains('null');
      if (apNullable && !valueModel.isEffectivelyNullable) {
        valueModel = AliasModel(
          model: valueModel,
          context: mapContext,
          isNullable: true,
        );
      }
      shell.valueModel = valueModel;
    }
  }

  /// Populates a ListModel shell.
  void _populateArrayShell(
    String name,
    Schema schema,
    Context context,
    ListModel shell,
  ) {
    final items = schema.items;
    final modelContext = context.push('array');
    shell.content = items == null
        ? AnyModel(context: modelContext)
        : _resolveSchemaRef(null, items, modelContext);
  }

  /// Populates a ClassModel shell.
  void _populateClassShell(
    String name,
    Schema schema,
    Context context,
    ClassModel shell,
  ) {
    shell.additionalProperties = _resolveAdditionalProperties(schema, context);

    if (schema.not != null) {
      log.warning(
        'Found not schema for $name. The not keyword is not '
        'supported and will be ignored.',
      );
    }

    final schemaProperties = schema.properties ?? {};
    final properties = <Property>[];

    for (final MapEntry(key: propertyName, value: propertySchema)
        in schemaProperties.entries) {
      final isNullable =
          propertySchema.isNullable ?? propertySchema.type.contains('null');
      final isDeprecated = propertySchema.isDeprecated ?? false;
      final isReadOnly = propertySchema.isReadOnly ?? false;
      final isWriteOnly = propertySchema.isWriteOnly ?? false;
      final description = propertySchema.description;
      final nameOverride = propertySchema.xDartName;

      // Use a placeholder for empty or whitespace-only property names
      // so the context path remains valid.
      final contextPropertyName =
          propertyName.trim().isEmpty ? 'property' : propertyName;

      final property = Property(
        name: propertyName,
        model: _resolveSchemaRefForProperty(
          propertySchema,
          context.pushAll([name, contextPropertyName]),
        ),
        isRequired: schema.required?.contains(propertyName) ?? false,
        isNullable: isNullable,
        isDeprecated: isDeprecated,
        isReadOnly: isReadOnly,
        isWriteOnly: isWriteOnly,
        description: description,
      );

      if (nameOverride != null) {
        property.nameOverride = nameOverride;
      }

      properties.add(property);
    }

    shell.properties = properties;
  }

  /// Imports a schema from outside the components.schemas context.
  Model importSchema(Schema schema, Context context) {
    final model = _resolveSchemaRef(null, schema, context);
    log.fine('Importing schema $model@$context');

    if (model is! PrimitiveModel &&
        model is! AnyModel &&
        model is! NeverModel &&
        model is! AliasModel) {
      _logModelAdded(model);
      models.add(model);
    }

    return model;
  }

  /// Resolves a schema that may have a $ref field.
  Model _resolveSchemaRef(String? name, Schema schema, Context context) {
    if (schema.ref != null) {
      return _resolveReference(name, schema, context);
    }
    return _parseSchema(name, schema, context);
  }

  Model _resolveSchemaRefForProperty(Schema schema, Context context) {
    if (schema.ref != null) {
      if (_hasStructuralSiblings(schema)) {
        return _mergeRefWithStructuralSiblingsForProperty(schema, context);
      }
      return _resolveReferenceForProperty(schema.ref!, context);
    }
    return _parseSchema(null, schema, context);
  }

  Model _mergeRefWithStructuralSiblingsForProperty(
    Schema schema,
    Context context,
  ) {
    final ref = schema.ref!;

    if (!ref.startsWith('#/components/schemas/')) {
      throw UnimplementedError(
        'Only local schema references are supported, found $ref',
      );
    }

    final refName = ref.split('/').last;
    final refSchema = _schemas[refName];

    if (refSchema == null) {
      throw ArgumentError('Schema $ref not found');
    }

    final refModel =
        models.firstWhereOrNull(
          (model) => model is NamedModel && model.name == refName,
        ) ??
        _resolveWithCycleCheck(refName, refSchema);

    final modelContext = context.push('allOf');
    final modelsToMerge = <Model>[refModel];

    if (schema.allOf != null) {
      for (final allOfSchema in schema.allOf!) {
        modelsToMerge.add(_resolveSchemaRef(null, allOfSchema, modelContext));
      }
    }

    if (schema.properties != null) {
      final inlineClass = _parseClassModel(null, schema, modelContext);
      modelsToMerge.add(inlineClass);
    }

    if (schema.oneOf != null) {
      final oneOfModel = _parseOneOf(null, schema, modelContext);
      modelsToMerge.add(oneOfModel);
    }

    if (schema.anyOf != null) {
      final anyOfModel = _parseAnyOf(null, schema, modelContext);
      modelsToMerge.add(anyOfModel);
    }

    final allOfModel = AllOfModel(
      models: modelsToMerge.toSet(),
      context: modelContext,
      isDeprecated: false,
    );

    _addModelToSet(allOfModel);
    return allOfModel;
  }

  Model _resolveReferenceForProperty(String ref, Context context) {
    if (ref.contains(r'/$defs/')) {
      return _resolveDefsReferenceForProperty(ref, context);
    }

    if (!ref.startsWith('#/components/schemas/')) {
      throw UnimplementedError(
        'Only local schema references are supported, found $ref',
      );
    }

    final refName = ref.split('/').last;
    final refSchema = _schemas[refName];

    if (refSchema == null) {
      throw ArgumentError('Schema $ref not found');
    }

    return models.firstWhereOrNull(
          (model) => model is NamedModel && model.name == refName,
        ) ??
        _resolveWithCycleCheck(refName, refSchema);
  }

  Model _resolveDefsReferenceForProperty(String ref, Context context) {
    final defSchema = _defs[ref];
    if (defSchema == null) {
      throw ArgumentError('\$defs reference $ref not found');
    }

    final defName = ref.split('/').last;
    final defsContext = _contextFromDefsPath(ref);

    return _resolveSchemaRef(defName, defSchema, defsContext);
  }

  Model _resolveDefsReference(String? name, Schema schema, Context context) {
    final ref = schema.ref!;
    final defSchema = _defs[ref];

    if (defSchema == null) {
      throw ArgumentError('\$defs reference $ref not found for $name');
    }

    final defName = ref.split('/').last;

    if (_resolving.contains(ref)) {
      final existing = models.firstWhereOrNull(
        (model) => model is NamedModel && model.name == defName,
      );
      if (existing != null) {
        return existing;
      }

      // Create placeholder but do NOT add to models -- this prevents
      // shadowing the real model that will be built when resolution unwinds.
      log.fine(
        'Circular reference to $ref detected. '
        'Using placeholder until resolution completes.',
      );
      final placeholder = AliasModel(
        name: defName,
        model: AnyModel(context: _contextFromDefsPath(ref)),
        context: _contextFromDefsPath(ref),
      );
      _placeholders[ref] = placeholder;
      return placeholder;
    }

    _resolving.add(ref);
    final Model refModel;
    try {
      final defsContext = _contextFromDefsPath(ref);
      refModel = _resolveSchemaRef(defName, defSchema, defsContext);

      // If a placeholder was created during resolution, update it to
      // point to the real model so back-edge references resolve correctly.
      // Skip AliasModel results to avoid infinite loops in resolved getter.
      final placeholder = _placeholders.remove(ref);
      if (placeholder != null) {
        if (refModel is! AliasModel) {
          placeholder.model = refModel;
        } else {
          models.add(placeholder);
        }
      }
    } finally {
      _resolving.remove(ref);
    }

    if (_hasStructuralSiblings(schema)) {
      return _mergeRefWithStructuralSiblings(name, refModel, schema, context);
    }

    if (name != null || _hasAnnotationSiblings(schema)) {
      if (name != null) {
        final existing = models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == name,
        );
        if (existing != null) {
          return existing;
        }
      }

      final aliasModel = AliasModel(
        name: name,
        model: refModel,
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.isNullable ?? schema.type.contains('null'),
      );

      _logModelAdded(aliasModel);
      models.add(aliasModel);

      return aliasModel;
    }

    return refModel;
  }

  Context _contextFromDefsPath(String ref) {
    final parts = ref.substring(2).split('/'); // Remove '#/' prefix.
    return Context.initial().pushAll(parts);
  }

  /// Resolves a schema ref with cycle detection.
  ///
  /// Tracks all named schema resolutions to detect circular references.
  /// When a cycle is detected the method first checks for an
  /// early-registered model (structural schemas register before resolving
  /// members). If none is found it creates an [AliasModel] placeholder
  /// wrapping [AnyModel] (tracked in [_placeholders], NOT added to [models])
  /// so that resolution can unwind safely without shadowing the real model.
  Model _resolveWithCycleCheck(String refName, Schema refSchema) {
    if (_resolving.contains(refName)) {
      // Look up a partially-constructed model that was registered early
      // by one of the parse methods (_parseClassModel, _parseAllOf, etc.).
      final existing = models.firstWhereOrNull(
        (model) => model is NamedModel && model.name == refName,
      );
      if (existing != null) {
        return existing;
      }

      // Create placeholder but do NOT add to models -- this prevents
      // shadowing the real model that will be built when resolution unwinds.
      log.fine(
        'Circular reference to $refName detected. '
        'Using placeholder until resolution completes.',
      );
      final placeholder = AliasModel(
        name: refName,
        model: AnyModel(context: rootContext),
        context: rootContext,
      );
      _placeholders[refName] = placeholder;
      return placeholder;
    }

    _resolving.add(refName);
    try {
      final result = _resolveSchemaRef(refName, refSchema, rootContext);

      // If a placeholder was created during resolution, update it to
      // point to the real model so back-edge references resolve correctly.
      // Skip AliasModel results to avoid infinite loops in resolved getter
      // for bare $ref cycles (A->B->A).
      final placeholder = _placeholders.remove(refName);
      if (placeholder != null) {
        if (result is! AliasModel) {
          placeholder.model = result;
        } else {
          // Bare ref cycle -- add placeholder to models as the final model.
          // AnyModel terminal is correct since there's no concrete type.
          models.add(placeholder);
        }
      }

      return result;
    } finally {
      _resolving.remove(refName);
    }
  }

  bool _hasAnnotationSiblings(Schema schema) {
    return schema.description != null ||
        (schema.isDeprecated ?? false) ||
        (schema.isNullable ?? false) ||
        schema.type.contains('null');
  }

  bool _hasStructuralSiblings(Schema schema) {
    return schema.properties != null ||
        schema.allOf != null ||
        schema.oneOf != null ||
        schema.anyOf != null;
  }

  Model _resolveReference(String? name, Schema schema, Context context) {
    final ref = schema.ref!;

    if (ref.contains(r'/$defs/')) {
      return _resolveDefsReference(name, schema, context);
    }

    if (!ref.startsWith('#/components/schemas/')) {
      throw UnimplementedError(
        'Only local schema references are supported, '
        'found $ref for $name',
      );
    }

    final refName = ref.split('/').last;

    if (name == refName) {
      throw ArgumentError(
        'Schema $name has a direct self-reference which is not supported',
      );
    }

    final refSchema = _schemas[refName];

    if (refSchema == null) {
      throw ArgumentError('Schema $ref not found for $name');
    }

    final refModel =
        models.firstWhereOrNull(
          (model) => model is NamedModel && model.name == refName,
        ) ??
        _resolveWithCycleCheck(refName, refSchema);

    if (_hasStructuralSiblings(schema)) {
      return _mergeRefWithStructuralSiblings(
        name,
        refModel,
        schema,
        context,
      );
    }

    if (name != null || _hasAnnotationSiblings(schema)) {
      if (name != null) {
        final existing = models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == name,
        );
        if (existing != null) {
          return existing;
        }
      }

      final aliasModel = AliasModel(
        name: name,
        model: refModel,
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.isNullable ?? schema.type.contains('null'),
      );

      _logModelAdded(aliasModel);
      models.add(aliasModel);

      return aliasModel;
    }

    return refModel;
  }

  AllOfModel _mergeRefWithStructuralSiblings(
    String? name,
    Model refModel,
    Schema schema,
    Context context,
  ) {
    final modelContext = context.push(name ?? 'allOf');
    final modelsToMerge = <Model>[refModel];

    if (schema.allOf != null) {
      for (final allOfSchema in schema.allOf!) {
        modelsToMerge.add(_resolveSchemaRef(null, allOfSchema, modelContext));
      }
    }

    if (schema.properties != null) {
      final inlineClass = _parseClassModel(null, schema, modelContext);
      modelsToMerge.add(inlineClass);
    }

    if (schema.oneOf != null) {
      final oneOfModel = _parseOneOf(null, schema, modelContext);
      modelsToMerge.add(oneOfModel);
    }

    if (schema.anyOf != null) {
      final anyOfModel = _parseAnyOf(null, schema, modelContext);
      modelsToMerge.add(anyOfModel);
    }

    final allOfModel = AllOfModel(
      name: name,
      models: modelsToMerge.toSet(),
      context: modelContext,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isNullable: schema.isNullable ?? schema.type.contains('null'),
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );

    _addModelToSet(allOfModel);
    return allOfModel;
  }

  Model _parseSchema(String? name, Schema schema, Context context) {
    final existing = models.firstWhereOrNull(
      (model) => name != null && model is NamedModel && model.name == name,
    );
    if (existing != null) {
      return existing;
    }

    if (schema.isBooleanSchema != null) {
      return schema.isBooleanSchema!
          ? AnyModel(context: context)
          : NeverModel(context: context);
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

    // Pure map detection: schema with no named properties and
    // additionalProperties set to true or a schema.
    if ((schema.properties == null || schema.properties!.isEmpty) &&
        schema.additionalProperties != null &&
        schema.additionalProperties != false) {
      final ap = schema.additionalProperties;
      final mapContext = context.push(name ?? 'map');
      Model valueModel;
      if (ap == true) {
        valueModel = AnyModel(context: mapContext);
      } else {
        final apSchema = ap! as Schema;
        valueModel = _resolveSchemaRef(null, apSchema, mapContext);
        final apNullable =
            apSchema.isNullable ?? apSchema.type.contains('null');
        if (apNullable && !valueModel.isEffectivelyNullable) {
          valueModel = AliasModel(
            model: valueModel,
            context: mapContext,
            isNullable: true,
          );
        }
      }
      final model = MapModel(
        valueModel: valueModel,
        context: context,
        name: name,
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      if (name != null) {
        _logModelAdded(model);
        models.add(model);
      }
      return model;
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
      'string' when schema.format == 'binary' => BinaryModel(context: context),
      'string' when schema.contentEncoding != null =>
        _resolveContentEncodedModel(schema, context),
      'string' when schema.format == 'byte' => Base64Model(context: context),
      'string' when schema.enumerated != null => _parseEnum<String>(
        name,
        schema.enumerated!,
        schema.isNullable ?? hasNullType,
        context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        xDartEnum: schema.xDartEnum,
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
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        xDartEnum: schema.xDartEnum,
      ),
      'integer' => IntegerModel(context: context),
      'boolean' => BooleanModel(context: context),
      'array' => _parseArray(name, schema, context),
      _ => _parseClassModel(name, schema, context),
    };

    if (model is PrimitiveModel && name != null) {
      model = AliasModel(
        name: name,
        model: model,
        context: context,
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(model);
      models.add(model);
    }

    return model;
  }

  Model _resolveContentEncodedModel(Schema schema, Context context) {
    final mediaType = schema.contentMediaType;
    if (mediaType != null && _contentMediaTypes.containsKey(mediaType)) {
      return switch (_contentMediaTypes[mediaType]!) {
        .text => StringModel(context: context),
        .binary => BinaryModel(context: context),
      };
    }

    return BinaryModel(context: context);
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
        ref: null,
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
        xDartName: schema.xDartName,
        xDartEnum: schema.xDartEnum,
        defs: schema.defs,
        contentEncoding: schema.contentEncoding,
        contentMediaType: schema.contentMediaType,
        contentSchema: schema.contentSchema,
        additionalProperties: schema.additionalProperties,
        isReadOnly: schema.isReadOnly,
        isWriteOnly: schema.isWriteOnly,
      );
      return (
        discriminatorValue: null,
        model: _parseSchema(null, singleTypeSchema, context),
      );
    });

    final oneOfModel = OneOfModel(
      models: models.toSet(),
      name: name,
      context: context,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );

    _addModelToSet(oneOfModel);
    return oneOfModel;
  }

  ListModel _parseArray(String? name, Schema schema, Context context) {
    final items = schema.items;

    final modelContext = context.push('array');

    // Register the model early (with an AnyModel placeholder content) so
    // that circular references to a named array schema resolve to this
    // same ListModel instead of triggering a duplicate parse via
    // _resolveWithCycleCheck.
    final listModel = ListModel(
      content: AnyModel(context: modelContext),
      context: context,
      name: name,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );

    if (name != null && models.none((m) => m is NamedModel && m.name == name)) {
      _logModelAdded(listModel);
      models.add(listModel);
    }

    listModel.content = items == null
        ? AnyModel(context: modelContext)
        : _resolveSchemaRef(null, items, modelContext);

    return listModel;
  }

  AllOfModel _parseAllOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'allOf');

    // Register the model early (with an empty models set) so that
    // circular references can find it during member resolution.
    final allOfModel = AllOfModel(
      isDeprecated: schema.isDeprecated ?? false,
      models: <Model>{},
      context: modelContext,
      name: name,
      description: schema.description,
      additionalProperties: _resolveAdditionalProperties(schema, modelContext),
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      _logModelAdded(allOfModel);
      models.add(allOfModel);
    }

    final resolvedModels = schema.allOf!
        .map(
          (allOfSchema) => _resolveSchemaRef(null, allOfSchema, modelContext),
        )
        .toSet();

    allOfModel.models = resolvedModels;

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
    final alternatives = schema.oneOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    // Register the model early (with an empty models set) so that
    // circular references can find it during member resolution.
    final oneOfModel = OneOfModel(
      isDeprecated: schema.isDeprecated ?? false,
      models: <DiscriminatedModel>{},
      context: context,
      name: name,
      discriminator: effectiveDiscriminator?.propertyName,
      description: schema.description,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      _logModelAdded(oneOfModel);
      models.add(oneOfModel);
    }

    final resolvedModels = alternatives.map(
      (oneOfSchema) => (
        discriminatorValue: _getDiscriminatorValue(
          discriminator: effectiveDiscriminator,
          innerSchema: oneOfSchema,
        ),
        model: _resolveSchemaRef(null, oneOfSchema, modelContext),
      ),
    );

    oneOfModel.models = resolvedModels.toSet();

    // Add nested models to the model set now that members are resolved.
    for (final nestedModel in oneOfModel.models) {
      _addModelToSet(nestedModel.model);
    }

    return oneOfModel;
  }

  AnyOfModel _parseAnyOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'anyOf');
    final alternatives = schema.anyOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    // Register the model early (with an empty models set) so that
    // circular references can find it during member resolution.
    final anyOfModel = AnyOfModel(
      isDeprecated: schema.isDeprecated ?? false,
      models: <DiscriminatedModel>{},
      context: context,
      name: name,
      discriminator: effectiveDiscriminator?.propertyName,
      description: schema.description,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
    );

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      _logModelAdded(anyOfModel);
      models.add(anyOfModel);
    }

    final resolvedModels = alternatives.map(
      (anyOfSchema) => (
        discriminatorValue: _getDiscriminatorValue(
          discriminator: effectiveDiscriminator,
          innerSchema: anyOfSchema,
        ),
        model: _resolveSchemaRef(null, anyOfSchema, modelContext),
      ),
    );

    anyOfModel.models = resolvedModels.toSet();

    return anyOfModel;
  }

  String? _getDiscriminatorValue({
    required parse.Discriminator? discriminator,
    required Schema innerSchema,
  }) {
    if (innerSchema.ref != null && discriminator?.propertyName != null) {
      final ref = innerSchema.ref!;
      final discriminatorEntry = discriminator?.mapping?.entries
          .firstWhereOrNull((entry) => entry.value == ref);
      return discriminatorEntry?.key ?? ref.split('/').last;
    }
    return null;
  }

  /// Finds an inherited discriminator from a common parent schema.
  ///
  /// When a oneOf/anyOf has no direct discriminator, checks if all alternatives
  /// inherit from a common parent with a discriminator via allOf.
  /// Returns the parent's discriminator if found, null otherwise.
  parse.Discriminator? _findInheritedDiscriminator(List<Schema> alternatives) {
    if (alternatives.isEmpty) return null;

    final parentDiscriminators = <parse.Discriminator>[];

    for (final alternative in alternatives) {
      final parentDiscriminator = _findDiscriminatorInAllOfChain(alternative);
      if (parentDiscriminator == null) return null;

      parentDiscriminators.add(parentDiscriminator);
    }

    final firstPropertyName = parentDiscriminators.first.propertyName;
    final allSameProperty = parentDiscriminators.every(
      (d) => d.propertyName == firstPropertyName,
    );
    if (!allSameProperty) return null;

    return parentDiscriminators.first;
  }

  /// Walks an allOf chain to find a parent schema with a discriminator.
  ///
  /// Recursively descends into allOf members so that discriminators on
  /// grandparent (or deeper) schemas are found.
  parse.Discriminator? _findDiscriminatorInAllOfChain(Schema schema) {
    final resolvedSchema = _resolveSchemaToSchema(schema);
    if (resolvedSchema == null) return null;

    final allOf = resolvedSchema.allOf;
    if (allOf == null || allOf.isEmpty) return null;

    for (final member in allOf) {
      final memberSchema = _resolveSchemaToSchema(member);
      if (memberSchema == null) continue;

      if (memberSchema.discriminator != null) {
        return memberSchema.discriminator;
      }

      // Recurse into the member's own allOf chain.
      final inherited = _findDiscriminatorInAllOfChain(memberSchema);
      if (inherited != null) return inherited;
    }

    return null;
  }

  Schema? _resolveSchemaToSchema(Schema schema) {
    if (schema.ref == null) return schema;

    final ref = schema.ref!;

    if (ref.contains(r'/$defs/')) {
      return _defs[ref];
    }

    if (ref.startsWith('#/components/schemas/')) {
      return _schemas[ref.split('/').last];
    }

    return null;
  }

  AdditionalProperties? _resolveAdditionalProperties(
    Schema schema,
    Context context,
  ) {
    final ap = schema.additionalProperties;
    if (ap == null) return null;
    if (ap == false) return const NoAdditionalProperties();
    if (ap == true) return const UnrestrictedAdditionalProperties();
    if (ap is Schema) {
      // An empty schema {} matches any value in JSON Schema (like true).
      // As additionalProperties it means "any extra keys, any value type"
      // — the same as additionalProperties: true.
      if (_isEmptySchema(ap)) {
        return const UnrestrictedAdditionalProperties();
      }
      var valueModel = _resolveSchemaRef(null, ap, context);
      final isNullable = ap.isNullable ?? ap.type.contains('null');
      if (isNullable && !valueModel.isEffectivelyNullable) {
        valueModel = AliasModel(
          model: valueModel,
          context: context,
          isNullable: true,
        );
      }
      return TypedAdditionalProperties(valueModel: valueModel);
    }
    return null;
  }

  /// Returns `true` when the schema carries no meaningful constraints,
  /// i.e. it is equivalent to the JSON Schema "empty schema" `{}` which
  /// accepts any value.
  bool _isEmptySchema(Schema schema) {
    return schema.ref == null &&
        schema.type.isEmpty &&
        schema.format == null &&
        schema.enumerated == null &&
        schema.allOf == null &&
        schema.anyOf == null &&
        schema.oneOf == null &&
        schema.not == null &&
        schema.items == null &&
        (schema.properties == null || schema.properties!.isEmpty) &&
        schema.additionalProperties == null &&
        schema.isBooleanSchema == null;
  }

  ClassModel _parseClassModel(String? name, Schema schema, Context context) {
    final schemaProperties = schema.properties ?? {};
    final properties = <Property>[];

    final model = ClassModel(
      isDeprecated: schema.isDeprecated ?? false,
      name: name,
      properties: properties,
      context: context,
      description: schema.description,
      additionalProperties: _resolveAdditionalProperties(schema, context),
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
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
      final isNullable =
          propertySchema.isNullable ?? propertySchema.type.contains('null');
      final isDeprecated = propertySchema.isDeprecated ?? false;
      final isReadOnly = propertySchema.isReadOnly ?? false;
      final isWriteOnly = propertySchema.isWriteOnly ?? false;
      final description = propertySchema.description;
      final nameOverride = propertySchema.xDartName;

      // Use a placeholder for empty or whitespace-only property names
      // so the context path remains valid.
      final contextPropertyName =
          propertyName.trim().isEmpty ? 'property' : propertyName;

      final property = Property(
        name: propertyName,
        model: _resolveSchemaRefForProperty(
          propertySchema,
          context.pushAll(
            [name, contextPropertyName].whereType<String>(),
          ),
        ),
        isRequired: schema.required?.contains(propertyName) ?? false,
        isNullable: isNullable,
        isDeprecated: isDeprecated,
        isReadOnly: isReadOnly,
        isWriteOnly: isWriteOnly,
        description: description,
      );

      // Apply x-dart-name vendor extension to property.
      if (nameOverride != null) {
        property.nameOverride = nameOverride;
      }

      properties.add(property);
    }

    return model;
  }

  EnumModel<T> _parseEnum<T>(
    String? name,
    List<dynamic> values,
    bool isNullable,
    Context context, {
    required String? description,
    required bool isDeprecated,
    bool isReadOnly = false,
    bool isWriteOnly = false,
    List<String>? xDartEnum,
  }) {
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

    final enumValues = <EnumEntry<T>>{};
    final typedValuesList = typedValues.toList();

    for (var i = 0; i < typedValuesList.length; i++) {
      final value = typedValuesList[i];
      String? nameOverride;

      // Apply x-dart-enum vendor extension if available
      if (xDartEnum != null && i < xDartEnum.length) {
        nameOverride = xDartEnum[i];
      }

      enumValues.add(EnumEntry<T>(value: value, nameOverride: nameOverride));
    }

    final model = EnumModel<T>(
      isDeprecated: isDeprecated,
      values: enumValues,
      isNullable: isNullable || hasNull,
      context: context,
      name: name,
      description: description,
      isReadOnly: isReadOnly,
      isWriteOnly: isWriteOnly,
    );

    if (name == null || models.none((m) => m is NamedModel && m.name == name)) {
      _logModelAdded(model);
      models.add(model);
    }

    return model;
  }

  void _logModelAdded(Model model) {
    final name = model is NamedModel && model.name != null
        ? model.name
        : '${model.context}->${model.runtimeType}';
    log.fine('Adding model $name');
  }

  void _collectAllDefs() {
    for (final entry in _schemas.entries) {
      final path = '#/components/schemas/${entry.key}';
      _collectDefs(entry.value, path);
    }
  }

  /// Recursively collects $defs from a schema and its nested schemas.
  void _collectDefs(Schema schema, String currentPath) {
    if (schema.defs != null) {
      for (final defEntry in schema.defs!.entries) {
        final defPath = '$currentPath/\$defs/${defEntry.key}';
        _defs[defPath] = defEntry.value;
        _collectDefs(defEntry.value, defPath);
      }
    }

    if (schema.properties != null) {
      for (final propEntry in schema.properties!.entries) {
        _collectDefs(
          propEntry.value,
          '$currentPath/properties/${propEntry.key}',
        );
      }
    }

    if (schema.items != null) {
      _collectDefs(schema.items!, '$currentPath/items');
    }

    if (schema.allOf != null) {
      for (var i = 0; i < schema.allOf!.length; i++) {
        _collectDefs(schema.allOf![i], '$currentPath/allOf/$i');
      }
    }

    if (schema.anyOf != null) {
      for (var i = 0; i < schema.anyOf!.length; i++) {
        _collectDefs(schema.anyOf![i], '$currentPath/anyOf/$i');
      }
    }

    if (schema.oneOf != null) {
      for (var i = 0; i < schema.oneOf!.length; i++) {
        _collectDefs(schema.oneOf![i], '$currentPath/oneOf/$i');
      }
    }

    if (schema.not != null) {
      _collectDefs(schema.not!, '$currentPath/not');
    }

    final ap = schema.additionalProperties;
    if (ap is Schema) {
      _collectDefs(ap, '$currentPath/additionalProperties');
    }
  }
}
