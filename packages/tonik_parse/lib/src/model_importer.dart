import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/local_json_pointer.dart';
import 'package:tonik_parse/src/model/components.dart' as parse;
import 'package:tonik_parse/src/model/discriminator.dart' as parse;
import 'package:tonik_parse/src/model/encoding.dart' as parse;
import 'package:tonik_parse/src/model/header.dart' as parse;
import 'package:tonik_parse/src/model/media_type.dart' as parse;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/operation.dart' as parse;
import 'package:tonik_parse/src/model/parameter.dart' as parse;
import 'package:tonik_parse/src/model/path_item.dart' as parse;
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart' as parse;
import 'package:tonik_parse/src/model/response.dart' as parse;
import 'package:tonik_parse/src/model/schema.dart';

class ModelImporter._(
  final ExampleImporter exampleImporter,
  final Map<String, SchemaContentType> _contentMediaTypes,
  final Map<String, Schema> _schemas,
  final OpenApiObject _openApiObject,
) {
  new(
    OpenApiObject openApiObject, {
    required ExampleImporter exampleImporter,
    Map<String, SchemaContentType> contentMediaTypes = const {},
  }) : this._(
         exampleImporter,
         contentMediaTypes,
         openApiObject.components?.schemas ?? {},
         openApiObject,
       );

  final Map<String, Schema> _schemaReferences = {};
  final Map<Schema, Schema> _schemaAliases = {};
  final Set<Schema> _nestedReferenceSchemas = {};
  final Map<Schema, Model> _nestedReferenceModels = {};
  final Set<String> _resolving = {};
  final Map<String, AliasModel> _placeholders = {};

  // A component reused by multipart keeps the same nested schema identities.
  final _propertyModels = <(Schema, Context), Model>{};
  final _additionalProperties =
      <(Schema, Context), AdditionalPropertiesPolicy>{};

  /// Set of named schemas whose composite shells have been populated.
  ///
  /// Used during pass 2 to determine whether a referenced model's composite
  /// sub-models have already been filled in (and thus can be checked for
  /// back-edges).
  final Set<String> _populatedComposites = {};

  late Set<Model> models;

  final Map<String, Set<Model>> _modelsByName = {};
  // The parsed schema identifies the exact reference target, even when
  // multiple definitions or components share the same display name.
  final Map<Model, Schema> _modelSchemas = {};

  Model? _findNamedModel(String? name, [Schema? schema]) {
    final referenced = _nestedReferenceModels[schema];
    if (referenced != null) return referenced;
    if (name == null) return null;
    final target = schema ?? _schemas[name];
    return _modelsByName[name]?.firstWhereOrNull(
      (model) => identical(_modelSchemas[model], target),
    );
  }

  Schema _canonicalSchema(Schema schema) => _schemaAliases[schema] ?? schema;

  void _rememberSchemaModel(Model model, Schema schema) {
    final canonical = _canonicalSchema(schema);
    _modelSchemas[model] = canonical;
    if (_nestedReferenceSchemas.contains(canonical)) {
      _nestedReferenceModels[canonical] = model;
    }
  }

  void _registerModel(Model model, [Schema? schema]) {
    if (schema != null) _rememberSchemaModel(model, schema);
    models.add(model);
    if (model is NamedModel) {
      final name = model.name;
      if (name != null) {
        (_modelsByName[name] ??= <Model>{}).add(model);
      }
    }
  }

  void _removeModel(Model model) {
    if (!models.remove(model)) return;
    final schema = _modelSchemas.remove(model);
    if (identical(_nestedReferenceModels[schema], model)) {
      _nestedReferenceModels.remove(schema);
    }
    if (model is NamedModel) {
      final name = model.name;
      if (name != null) {
        final bucket = _modelsByName[name]!..remove(model);
        if (bucket.isEmpty) _modelsByName.remove(name);
      }
    }
  }

  final log = Logger('ModelImporter');

  static const _unknownEnumCaseName = 'unknown';

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
    _modelsByName.clear();
    _modelSchemas.clear();
    _placeholders.clear();
    _propertyModels.clear();
    _additionalProperties.clear();
    _populatedComposites.clear();
    _schemaReferences.clear();
    _schemaAliases.clear();
    _nestedReferenceSchemas.clear();
    _nestedReferenceModels.clear();
    _resolving.clear();
    _indexSchemas(_openApiObject, const []);

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
    if (_findNamedModel(name, schema) != null) {
      return;
    }

    // If it's a $ref, create an alias shell.
    if (schema.ref != null) {
      // Direct self-reference check.
      final ref = schema.ref!;
      if (!isExternalReference(ref) &&
          name == LocalJsonPointer.parse(ref).componentName('schemas')) {
        // Will be caught during pass 2 with proper error.
        return;
      }

      final aliasModel = AliasModel(
        name: name,
        model: AnyModel(context: context),
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.isNullable ?? schema.hasNullType,
        defaultValue: schema.rawDefault,
        examples: const [],
        nameOverride: null,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );
      _logModelAdded(aliasModel);
      _registerModel(aliasModel, schema);
      return;
    }

    if (schema.isBooleanSchema != null ||
        _isEmptySchema(schema) ||
        _isUnsupportedTypelessSchema(schema)) {
      final model = schema.isBooleanSchema != false
          ? AnyModel(context: context)
          : NeverModel(context: context, isNullable: false);
      final aliasModel = AliasModel(
        name: name,
        model: model,
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        defaultValue: schema.rawDefault,
        examples: const [],
        nameOverride: null,
      );
      _logModelAdded(aliasModel);
      _registerModel(aliasModel, schema);
      return;
    }

    if (schema.allOf != null || _hasAnyOfObjectSiblings(schema)) {
      final modelContext = context.push(name);
      final allOfModel = AllOfModel(
        defaultValue: schema.rawDefault,
        isDeprecated: schema.isDeprecated ?? false,
        models: <Model>[],
        context: modelContext,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: const [],
        nameOverride: null,
        additionalPropertiesPolicy: null,
      );
      _logModelAdded(allOfModel);
      _registerModel(allOfModel, schema);
      return;
    }

    if (schema.oneOf != null) {
      final oneOfModel = OneOfModel(
        defaultValue: schema.rawDefault,
        isDeprecated: schema.isDeprecated ?? false,
        models: <DiscriminatedModel>[],
        context: context,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: const [],
        nameOverride: null,
        discriminator: null,
      );
      _logModelAdded(oneOfModel);
      _registerModel(oneOfModel, schema);
      return;
    }

    if (schema.anyOf != null) {
      final anyOfModel = AnyOfModel(
        defaultValue: schema.rawDefault,
        isDeprecated: schema.isDeprecated ?? false,
        models: <DiscriminatedModel>[],
        context: context,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: const [],
        nameOverride: null,
        discriminator: null,
      );
      _logModelAdded(anyOfModel);
      _registerModel(anyOfModel, schema);
      return;
    }

    final hasNullType = schema.hasNullType;
    final types = _schemaTypes(schema);

    if (hasNullType && types.isEmpty) {
      final aliasModel = AliasModel(
        name: name,
        model: NeverModel(context: context, isNullable: true),
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        defaultValue: schema.rawDefault,
        examples: const [],
        nameOverride: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      _logModelAdded(aliasModel);
      _registerModel(aliasModel, schema);
      return;
    }

    if (types.length > 1) {
      // Multi-type becomes OneOfModel — create shell.
      final oneOfModel = OneOfModel(
        defaultValue: schema.rawDefault,
        isDeprecated: schema.isDeprecated ?? false,
        models: <DiscriminatedModel>[],
        context: context,
        name: name,
        description: schema.description,
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: const [],
        nameOverride: null,
        discriminator: null,
      );
      _logModelAdded(oneOfModel);
      _registerModel(oneOfModel, schema);
      return;
    }

    if (isOpenMapSchema(schema, types)) {
      final model = MapModel(
        valueModel: AnyModel(context: context),
        context: context,
        name: name,
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: const [],
        nameOverride: null,
        isValueNullable: false,
      );
      _logModelAdded(model);
      _registerModel(model, schema);
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
          defaultValue: schema.rawDefault,
          examples: const [],
          nameOverride: null,
          description: schema.description,
          isDeprecated: schema.isDeprecated ?? false,
        );
        _logModelAdded(aliasModel);
        _registerModel(aliasModel, schema);
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
        isNullable: schema.isNullable ?? hasNullType,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: const [],
        nameOverride: null,
        isContentNullable: false,
      );
      _logModelAdded(listModel);
      _registerModel(listModel, schema);
      return;
    }

    // Default: ClassModel (object type or untyped with properties).
    final model = ClassModel(
      isDeprecated: schema.isDeprecated ?? false,
      name: name,
      properties: <Property>[],
      context: context,
      description: schema.description,
      isNullable: schema.isNullable ?? (hasNullType && firstType == 'object'),
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: const [],
      nameOverride: null,
      additionalPropertiesPolicy: null,
    );
    _logModelAdded(model);
    _registerModel(model, schema);
  }

  List<String> _schemaTypes(Schema schema) {
    final types = schema.nonNullTypes;
    if (schema.type.isNotEmpty || schema.enumerated == null) return types;

    final values = schema.enumerated!.nonNulls;
    if (values.isEmpty) return types;
    if (values.every((value) => value is String)) return const ['string'];
    if (values.every((value) => value is int)) return const ['integer'];
    return types;
  }

  bool _isUnsupportedTypelessSchema(Schema schema) {
    if (schema.type.isNotEmpty ||
        schema.ref != null ||
        schema.allOf != null ||
        schema.oneOf != null ||
        schema.anyOf != null) {
      return false;
    }
    // Unsupported enum shapes and items without a type must still accept
    // scalar values. AnyModel approximates their constraints permissively.
    if (schema.enumerated != null) return _schemaTypes(schema).isEmpty;
    return schema.items != null &&
        (schema.properties == null || schema.properties!.isEmpty) &&
        schema.additionalProperties == null;
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
  Model? _createPrimitiveModel(String? type, Schema schema, Context context) {
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
      'string' when schema.contentEncoding != null =>
        _resolveContentEncodedModel(schema, context),
      'string' when schema.format == 'binary' => BinaryModel(context: context),
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
    final existingModel = _findNamedModel(name, schema);

    // For schemas that didn't get a shell in pass 1 (e.g. direct
    // self-references that were skipped, enums), run the full parse.
    if (existingModel == null) {
      var model = _resolveSchemaRef(name, schema, context);

      if (model is PrimitiveModel || model is AnyModel || model is NeverModel) {
        model = AliasModel(
          name: name,
          model: model,
          context: context,
          defaultValue: schema.rawDefault,
          examples: const [],
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
      }

      if (schema.xDartName != null) {
        if (model is NamedModel) {
          model.nameOverride = schema.xDartName;
        }
      }

      applyExamples(model, exampleImporter.fromSchema(schema));

      if (_findNamedModel(name, schema) == null) {
        log.fine('Adding model $name');
        _registerModel(model, schema);
      }
      return;
    }

    if (schema.xDartName != null) {
      if (existingModel is NamedModel) {
        existingModel.nameOverride = schema.xDartName;
      }
    }

    final examples = exampleImporter.fromSchema(schema);

    if (schema.ref != null) {
      _populateAliasShell(name, schema, context, existingModel as AliasModel);
      applyExamples(existingModel, examples);
      return;
    }

    if (schema.isBooleanSchema != null ||
        _isEmptySchema(schema) ||
        _isUnsupportedTypelessSchema(schema)) {
      // Already fully populated in pass 1.
      applyExamples(existingModel, examples);
      return;
    }

    if (_hasAnyOfObjectSiblings(schema)) {
      _populateAnyOfObjectSiblings(
        name,
        schema,
        context,
        existingModel as AllOfModel,
      );
      applyExamples(existingModel, examples);
      return;
    }

    if (schema.allOf != null) {
      _populateAllOfShell(name, schema, context, existingModel as AllOfModel);
      applyExamples(existingModel, examples);
      return;
    }

    if (schema.oneOf != null) {
      _populateOneOfShell(name, schema, context, existingModel as OneOfModel);
      applyExamples(existingModel, examples);
      return;
    }

    if (schema.anyOf != null) {
      _populateAnyOfShell(name, schema, context, existingModel as AnyOfModel);
      applyExamples(existingModel, examples);
      return;
    }

    final hasNullType = schema.hasNullType;
    final types = _schemaTypes(schema);

    if (hasNullType && types.isEmpty) {
      // Already fully populated in pass 1.
      applyExamples(existingModel, examples);
      return;
    }

    if (types.length > 1) {
      _populateMultiTypeShell(
        schema,
        hasNullType,
        context,
        existingModel as OneOfModel,
      );
      applyExamples(existingModel, examples);
      return;
    }

    if (isOpenMapSchema(schema, types)) {
      _populateMapShell(name, schema, context, existingModel as MapModel);
      applyExamples(existingModel, examples);
      return;
    }

    final firstType = types.firstOrNull;

    // Primitives are already fully populated.
    if (_isPrimitiveType(firstType, schema)) {
      applyExamples(existingModel, examples);
      return;
    }

    if (firstType == 'array') {
      _populateArrayShell(name, schema, context, existingModel as ListModel);
      applyExamples(existingModel, examples);
      return;
    }

    if (existingModel is ClassModel) {
      _populateClassShell(name, schema, context, existingModel);
      applyExamples(existingModel, examples);
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

    // Structural `$ref` siblings are represented as an allOf wrapper.
    if (_hasStructuralSiblings(schema)) {
      _removeModel(shell);
      final allOfModel = _mergeRefWithStructuralSiblings(name, schema, context);
      // Carry any examples assigned to the shell over to the replacement so
      // they survive the swap.
      applyExamples(allOfModel, shell.examples);
      // Update shell to point to the allOf so existing references still work.
      shell.model = allOfModel;
      // The allOfModel is already registered by
      // _mergeRefWithStructuralSiblings.
      // We don't re-add the shell since the allOfModel replaces it.
      return;
    }

    final refModel = _resolveReferenceTarget(ref, name: name);

    // Bare `$ref` cycles keep the AnyModel terminal to avoid an infinite
    // alias chain.
    if (_wouldCreateAliasCycle(shell, refModel)) {
      shell
        ..description = schema.description
        ..isDeprecated = (schema.isDeprecated ?? false)
        ..isNullable = (schema.isNullable ?? schema.hasNullType)
        ..isReadOnly = (schema.isReadOnly ?? false)
        ..isWriteOnly = (schema.isWriteOnly ?? false);
      return;
    }

    shell
      ..model = refModel
      ..description = schema.description
      ..isDeprecated = (schema.isDeprecated ?? false)
      ..isNullable = (schema.isNullable ?? schema.hasNullType)
      ..isReadOnly = (schema.isReadOnly ?? false)
      ..isWriteOnly = (schema.isWriteOnly ?? false);
  }

  /// Attaches schema-level [examples] to an already-constructed [model].
  ///
  /// Models that cannot carry examples (primitives, AnyModel, NeverModel)
  /// are silent no-ops. Models that already have examples are left alone
  /// so callers cannot overwrite earlier population.
  void applyExamples(Model model, List<Example> examples) {
    if (examples.isEmpty) return;
    switch (model) {
      case final ClassModel m when m.examples.isEmpty:
        m.examples = examples;
      case final ClassModel m:
        _logSkippedExamples('ClassModel', m.name, m.examples, examples);
      case final AliasModel m when m.examples.isEmpty:
        m.examples = examples;
      case final AliasModel m:
        _logSkippedExamples('AliasModel', m.name, m.examples, examples);
      case final ListModel m when m.examples.isEmpty:
        m.examples = examples;
      case final ListModel m:
        _logSkippedExamples('ListModel', m.name, m.examples, examples);
      case final MapModel m when m.examples.isEmpty:
        m.examples = examples;
      case final MapModel m:
        _logSkippedExamples('MapModel', m.name, m.examples, examples);
      case final EnumModel<dynamic> m when m.examples.isEmpty:
        m.examples = examples;
      case final EnumModel<dynamic> m:
        _logSkippedExamples('EnumModel', m.name, m.examples, examples);
      case final AllOfModel m when m.examples.isEmpty:
        m.examples = examples;
      case final AllOfModel m:
        _logSkippedExamples('AllOfModel', m.name, m.examples, examples);
      case final OneOfModel m when m.examples.isEmpty:
        m.examples = examples;
      case final OneOfModel m:
        _logSkippedExamples('OneOfModel', m.name, m.examples, examples);
      case final AnyOfModel m when m.examples.isEmpty:
        m.examples = examples;
      case final AnyOfModel m:
        _logSkippedExamples('AnyOfModel', m.name, m.examples, examples);
      case PrimitiveModel():
      case AnyModel():
      case NeverModel():
      default:
        break;
    }
  }

  void _logSkippedExamples(
    String modelKind,
    String? modelName,
    List<Example> existing,
    List<Example> dropped,
  ) {
    log.fine(
      'Skipping applyExamples on $modelKind ${modelName ?? '(unnamed)'} '
      '(${existing.length} existing, ${dropped.length} new dropped).',
    );
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

  bool _hasAnyOfObjectSiblings(Schema schema) =>
      schema.allOf == null &&
      schema.oneOf == null &&
      schema.anyOf != null &&
      schema.nonNullTypes.singleOrNull == 'object' &&
      schema.properties != null;

  void _populateAnyOfObjectSiblings(
    String? name,
    Schema schema,
    Context context,
    AllOfModel shell,
  ) {
    final modelContext = context.push(name ?? 'allOf');
    final siblings = _parseClassModel(
      null,
      schema,
      modelContext,
      cacheSchema: false,
    );
    final union = _parseAnyOf(
      null,
      schema,
      modelContext,
      cacheSchema: false,
      enclosingModel: shell,
    );
    shell
      ..models = [siblings, union]
      ..isNullable =
          siblings.isEffectivelyNullable && union.isEffectivelyNullable;
    if (name != null) _populatedComposites.add(name);
  }

  /// Populates an allOf shell's models.
  void _populateAllOfShell(
    String name,
    Schema schema,
    Context context,
    AllOfModel shell,
  ) {
    final modelContext = context.push(name);

    shell.additionalPropertiesPolicy = importAdditionalProperties(
      schema,
      modelContext,
    );

    final resolvedModels = <Model>[];
    for (final allOfSchema in schema.allOf!) {
      final model = _resolveCompositeSubModel(allOfSchema, modelContext, shell);
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

    if (alternatives.isEmpty) {
      log.warning(
        'oneOf for $name is empty. Per JSON Schema, oneOf must be a '
        'non-empty array. The generated $name class will throw on all '
        'encode and decode operations.',
      );
    }

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    shell
      ..discriminator = effectiveDiscriminator?.propertyName
      ..discriminatorAliases = _getDiscriminatorAliases(effectiveDiscriminator);

    final resolvedModels = <DiscriminatedModel>[];
    for (final oneOfSchema in alternatives) {
      if (_isNullOnlySchema(oneOfSchema)) {
        shell.isNullable = true;
        continue;
      }
      final model = _resolveCompositeSubModel(oneOfSchema, modelContext, shell);
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

    // Nested composite members enter the global model set after resolution.
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

    shell
      ..discriminator = effectiveDiscriminator?.propertyName
      ..discriminatorAliases = _getDiscriminatorAliases(effectiveDiscriminator);

    final resolvedModels = <DiscriminatedModel>[];
    for (final anyOfSchema in alternatives) {
      if (_isNullOnlySchema(anyOfSchema)) {
        shell.isNullable = true;
        continue;
      }
      final model = _resolveCompositeSubModel(anyOfSchema, modelContext, shell);
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
  /// If the resolved model already (transitively) contains [currentShell]
  /// in its composite sub-models,
  /// returns `null` to skip the back-edge and prevent a cycle.
  Model? _resolveCompositeSubModel(
    Schema schema,
    Context context,
    Model currentShell,
  ) {
    final model = _resolveSchemaRef(null, schema, context);
    if (_compositeContains(model, currentShell, <Model>{})) {
      log.fine(
        'Skipping back-edge during composite population to prevent cycle.',
      );
      return null;
    }
    return model;
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
    Schema schema,
    bool hasNullType,
    Context context,
    OneOfModel shell,
  ) {
    final models = schema.nonNullTypes.map((type) {
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
        rawDefault: schema.rawDefault,
        example: schema.example,
        examples: schema.examples,
      );
      return (
        discriminatorValue: null,
        model: _parseSchema(null, singleTypeSchema, context),
      );
    });

    shell.models = models.toList();
    for (final member in shell.models) {
      _addModelToSet(member.model);
    }
  }

  void _populateMapShell(
    String name,
    Schema schema,
    Context context,
    MapModel shell,
  ) {
    final ap = schema.additionalProperties;
    final mapContext = context.push(name);
    if (ap is Schema && !_isEmptySchema(ap)) {
      shell
        ..valueModel = _resolveSchemaRef(null, ap, mapContext)
        ..isValueNullable = ap.isNullable ?? ap.hasNullType;
    } else {
      shell.valueModel = AnyModel(context: mapContext);
    }
  }

  // Bare objects need maps to preserve unknown members.
  bool isOpenMapSchema(Schema schema, List<String> types) {
    if (schema.type.isEmpty && schema.enumerated != null) return false;
    if (schema.properties != null && schema.properties!.isNotEmpty) {
      return false;
    }
    final ap = schema.additionalProperties;
    if (ap == false) return false;
    return ap != null || types.contains('object');
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
    if (items == null) {
      shell.content = AnyModel(context: modelContext);
      return;
    }

    shell
      ..content = _resolveSchemaRef(null, items, modelContext)
      ..isContentNullable = items.isNullable ?? items.hasNullType;
  }

  /// Populates a ClassModel shell.
  void _populateClassShell(
    String name,
    Schema schema,
    Context context,
    ClassModel shell,
  ) {
    shell.additionalPropertiesPolicy = importAdditionalProperties(
      schema,
      context,
    );

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
          propertySchema.isNullable ?? propertySchema.hasNullType;
      final isDeprecated = propertySchema.isDeprecated ?? false;
      final (:isReadOnly, :isWriteOnly) = _propertyAccessFlags(propertySchema);
      final description = propertySchema.description;
      final nameOverride = propertySchema.xDartName;

      // Empty property names need a placeholder so the context path remains
      // valid.
      final contextPropertyName = propertyName.trim().isEmpty
          ? 'property'
          : propertyName;

      final property = Property(
        name: propertyName,
        model: importPropertySchema(
          propertySchema,
          context.pushAll([name, contextPropertyName]),
        ),
        isRequired: schema.required?.contains(propertyName) ?? false,
        isNullable: isNullable,
        isDeprecated: isDeprecated,
        isReadOnly: isReadOnly,
        isWriteOnly: isWriteOnly,
        description: description,
        defaultValue: propertySchema.rawDefault,
        examples: exampleImporter.fromSchema(propertySchema),
        nameOverride: null,
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
    var model = _resolveSchemaRef(null, schema, context);
    log.fine('Importing schema $model@$context');

    // Inline primitives have no container to carry `nullable: true`, so wrap
    // them in an anonymous alias — the same shape a $ref to the schema yields.
    if (model is PrimitiveModel && (schema.isNullable ?? schema.hasNullType)) {
      model = AliasModel(
        model: model,
        context: context,
        isNullable: true,
        defaultValue: schema.rawDefault,
        examples: const [],
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
    }

    if (model is! PrimitiveModel &&
        model is! AnyModel &&
        model is! NeverModel &&
        model is! AliasModel) {
      _logModelAdded(model);
      _registerModel(model);
    }

    return model;
  }

  ({bool isReadOnly, bool isWriteOnly}) _propertyAccessFlags(Schema schema) {
    var current = schema;
    var isReadOnly = false;
    var isWriteOnly = false;
    final visited = <String>{};

    while (true) {
      isReadOnly = isReadOnly || (current.isReadOnly ?? false);
      isWriteOnly = isWriteOnly || (current.isWriteOnly ?? false);
      final ref = current.ref;
      if (ref == null || !visited.add(ref)) break;
      final resolved = resolveSchemaReference(current);
      if (resolved == null) break;
      current = resolved;
    }

    return (isReadOnly: isReadOnly, isWriteOnly: isWriteOnly);
  }

  Model importPropertySchema(Schema schema, Context context) {
    final canonical = _canonicalSchema(schema);
    return _propertyModels[(canonical, context)] ??=
        _resolveSchemaRefForProperty(canonical, context);
  }

  /// Resolves a schema that may have a $ref field.
  Model _resolveSchemaRef(String? name, Schema schema, Context context) {
    final canonical = _canonicalSchema(schema);
    final existing = _nestedReferenceModels[canonical];
    if (existing != null) return existing;
    if (canonical.ref != null) {
      return _resolveReference(name, canonical, context);
    }
    return _parseSchema(name, canonical, context);
  }

  Model _resolveSchemaRefForProperty(Schema schema, Context context) {
    final existing = _nestedReferenceModels[schema];
    if (existing != null) return existing;
    if (schema.ref != null) {
      if (_hasStructuralSiblings(schema)) {
        return _mergeRefWithStructuralSiblings(null, schema, context);
      }
      final refModel = _resolveReferenceTarget(schema.ref!);
      if (schema.rawDefault != null ||
          (schema.isReadOnly ?? false) ||
          (schema.isWriteOnly ?? false)) {
        final aliasModel = AliasModel(
          model: refModel,
          context: context,
          description: schema.description,
          isDeprecated: schema.isDeprecated ?? false,
          isNullable: schema.isNullable ?? schema.hasNullType,
          defaultValue: schema.rawDefault,
          examples: exampleImporter.fromSchema(schema),
          name: null,
          nameOverride: null,
          isReadOnly: schema.isReadOnly ?? false,
          isWriteOnly: schema.isWriteOnly ?? false,
        );
        _addModelToSet(aliasModel, schema);
        return aliasModel;
      }
      return refModel;
    }
    return _parseSchema(null, schema, context);
  }

  Model _resolveReferenceTarget(String ref, {String? name}) {
    final pointer = LocalJsonPointer.parse(ref);
    final refName = pointer.componentName('schemas');
    if (refName != null) {
      if (name == refName) {
        throw ArgumentError(
          'Schema $name has a direct self-reference which is not supported',
        );
      }
      final refSchema = _schemas[refName];
      if (refSchema == null) {
        throw ArgumentError('Schema $ref not found');
      }
      return _findNamedModel(refName, refSchema) ??
          _resolveWithCycleCheck(refName, refSchema);
    }
    return _resolveNestedSchemaTarget(pointer, _schemaForPointer(pointer));
  }

  Schema _schemaForPointer(LocalJsonPointer pointer) {
    final existing = _schemaReferences[pointer.reference];
    if (existing != null) return existing;
    final source = _openApiObject.source;
    if (source == null) {
      throw ArgumentError('Schema ${pointer.reference} not found');
    }
    final schema = Schema.fromJson(pointer.resolve(source));
    _indexSchemas(schema, pointer.tokens);
    return schema;
  }

  Model? _existingSchemaModel(Schema schema) =>
      _nestedReferenceModels[schema] ??
      _modelSchemas.entries
          .where((entry) => identical(entry.value, schema))
          .lastOrNull
          ?.key;

  Model _resolveNestedSchemaTarget(LocalJsonPointer pointer, Schema schema) {
    final ref = pointer.reference;
    final name = pointer.tokens.lastOrNull;
    final modelName = name == null || name.isEmpty ? 'schema' : name;
    final context = pointer.tokens.isEmpty
        ? Context.initial()
        : Context.initial().pushAll(
            pointer.tokens.map((token) => token.isEmpty ? 'schema' : token),
          );
    var existing = _existingSchemaModel(schema);
    _nestedReferenceSchemas.add(schema);
    if (existing is PrimitiveModel ||
        existing is AnyModel ||
        existing is NeverModel) {
      existing = _annotateSchemaValue(modelName, existing!, schema, context);
    }
    // Referenced collections need typedef names for recursive type recovery.
    // Promote the existing shell so owner properties keep the same identity.
    switch (existing) {
      case ListModel(name: null):
        existing.name = modelName;
        _registerModel(existing, schema);
      case MapModel(name: null):
        existing.name = modelName;
        _registerModel(existing, schema);
      default:
        break;
    }
    if (existing != null) {
      _nestedReferenceModels[schema] = existing;
      return existing;
    }

    if (_resolving.contains(ref)) {
      return _placeholders.putIfAbsent(
        ref,
        () => AliasModel(
          // Resolution placeholders must delegate to the registered target,
          // rather than introduce a separate generated type.
          name: null,
          model: AnyModel(context: context),
          context: context,
          defaultValue: null,
          examples: const [],
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        ),
      );
    }

    _resolving.add(ref);
    try {
      final model = _resolveSchemaRef(modelName, schema, context);
      _nestedReferenceModels[schema] = model;
      final placeholder = _placeholders.remove(ref);
      if (placeholder != null && !_wouldCreateAliasCycle(placeholder, model)) {
        placeholder.model = model;
      }
      return model;
    } finally {
      _resolving.remove(ref);
    }
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
      final existing = _findNamedModel(refName);
      if (existing != null) {
        return existing;
      }

      // Placeholders stay out of models so they do not shadow the real model
      // built when resolution unwinds.
      log.fine(
        'Circular reference to $refName detected. '
        'Using placeholder until resolution completes.',
      );
      final placeholder = AliasModel(
        name: refName,
        model: AnyModel(context: rootContext),
        context: rootContext,
        defaultValue: null,
        examples: const [],
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
          _registerModel(placeholder, refSchema);
        }
      }

      return result;
    } finally {
      _resolving.remove(refName);
    }
  }

  bool hasAnnotationSiblings(Schema schema) {
    return schema.description != null ||
        (schema.isDeprecated ?? false) ||
        (schema.isNullable ?? false) ||
        schema.hasNullType ||
        (schema.isReadOnly ?? false) ||
        (schema.isWriteOnly ?? false) ||
        schema.rawDefault != null;
  }

  bool _hasStructuralSiblings(Schema schema) {
    return schema.properties != null ||
        schema.allOf != null ||
        schema.oneOf != null ||
        schema.anyOf != null;
  }

  Model _resolveReference(String? name, Schema schema, Context context) {
    final ref = schema.ref!;

    if (_hasStructuralSiblings(schema)) {
      return _mergeRefWithStructuralSiblings(name, schema, context);
    }

    final refModel = _resolveReferenceTarget(
      ref,
      name: identical(_schemas[name], schema) ? name : null,
    );

    if (name != null || hasAnnotationSiblings(schema)) {
      if (name != null) {
        final existing = _findNamedModel(name, schema);
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
        isNullable: schema.isNullable ?? schema.hasNullType,
        defaultValue: schema.rawDefault,
        examples: exampleImporter.fromSchema(schema),
        nameOverride: null,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
      );

      _logModelAdded(aliasModel);
      _registerModel(aliasModel, schema);

      return aliasModel;
    }

    return refModel;
  }

  AllOfModel _mergeRefWithStructuralSiblings(
    String? name,
    Schema schema,
    Context context,
  ) {
    final modelContext = context.push(name ?? 'allOf');
    final model = AllOfModel(
      defaultValue: schema.rawDefault,
      name: name,
      models: <Model>[],
      context: modelContext,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isNullable: schema.isNullable ?? schema.hasNullType,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
      additionalPropertiesPolicy: null,
    );
    _addModelToSet(model, schema);

    final members = <Model>[];
    final base = _resolveReferenceTarget(
      schema.ref!,
      name: identical(_schemas[name], schema) ? name : null,
    );
    if (!_compositeContains(base, model, <Model>{})) members.add(base);
    if (schema.allOf != null) {
      for (final member in schema.allOf!) {
        final resolved = _resolveCompositeSubModel(member, modelContext, model);
        if (resolved != null) members.add(resolved);
      }
    }
    if (schema.properties != null) {
      members.add(
        _parseClassModel(null, schema, modelContext, cacheSchema: false),
      );
    }
    if (schema.oneOf != null) {
      final member = _parseOneOf(
        null,
        schema,
        modelContext,
        cacheSchema: false,
      );
      if (!_compositeContains(member, model, <Model>{})) members.add(member);
    }
    if (schema.anyOf != null) {
      final member = _parseAnyOf(
        null,
        schema,
        modelContext,
        cacheSchema: false,
      );
      if (!_compositeContains(member, model, <Model>{})) members.add(member);
    }
    model.models = members;
    return model;
  }

  Model _parseSchema(String? name, Schema schema, Context context) {
    final existing = _findNamedModel(name, schema);
    if (existing != null) {
      return existing;
    }

    if (schema.isBooleanSchema != null ||
        _isEmptySchema(schema) ||
        _isUnsupportedTypelessSchema(schema)) {
      final model = schema.isBooleanSchema != false
          ? AnyModel(context: context)
          : NeverModel(context: context, isNullable: false);
      return _annotateSchemaValue(name, model, schema, context);
    }

    if (schema.allOf != null || _hasAnyOfObjectSiblings(schema)) {
      return _parseAllOf(name, schema, context);
    }

    if (schema.oneOf != null) {
      return _parseOneOf(name, schema, context);
    }

    if (schema.anyOf != null) {
      return _parseAnyOf(name, schema, context);
    }

    // OpenAPI 3.1 null types become Tonik nullability.
    final hasNullType = schema.hasNullType;
    final types = _schemaTypes(schema);

    if (hasNullType && types.isEmpty) {
      return _annotateSchemaValue(
        name,
        NeverModel(context: context, isNullable: true),
        schema,
        context,
      );
    }

    if (types.length > 1) {
      return _parseMultiType(schema, hasNullType, context, name);
    }

    if (isOpenMapSchema(schema, types)) {
      final ap = schema.additionalProperties;
      final mapContext = context.push(name ?? 'map');
      final model = MapModel(
        valueModel: AnyModel(context: mapContext),
        context: context,
        name: name,
        isNullable: schema.isNullable ?? hasNullType,
        isValueNullable: false,
        isReadOnly: schema.isReadOnly ?? false,
        isWriteOnly: schema.isWriteOnly ?? false,
        examples: exampleImporter.fromSchema(schema),
        nameOverride: null,
      );
      _rememberSchemaModel(model, schema);
      if (name != null) {
        _logModelAdded(model);
        _registerModel(model, schema);
      }
      if (ap is Schema && !_isEmptySchema(ap)) {
        model
          ..valueModel = _resolveSchemaRef(null, ap, mapContext)
          ..isValueNullable = ap.isNullable ?? ap.hasNullType;
      }
      return model;
    }

    var model = switch (types.firstOrNull) {
      'string' when schema.type.isEmpty && schema.enumerated != null =>
        _parseStringEnum(name, schema, context),
      'string' when schema.format == 'date-time' && schema.enumerated != null =>
        _parseStringEnum(name, schema, context),
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
      'string' when schema.contentEncoding != null =>
        _resolveContentEncodedModel(schema, context),
      'string' when schema.format == 'binary' => BinaryModel(context: context),
      'string' when schema.format == 'byte' => Base64Model(context: context),
      'string' when schema.enumerated != null => _parseStringEnum(
        name,
        schema,
        context,
      ),
      'string' => StringModel(context: context),
      'number' when schema.format == 'float' || schema.format == 'double' =>
        DoubleModel(context: context),
      'number' => NumberModel(context: context),
      'integer' when schema.enumerated != null => _parseIntegerEnum(
        name,
        schema,
        context,
      ),
      'integer' => IntegerModel(context: context),
      'boolean' => BooleanModel(context: context),
      'array' => _parseArray(name, schema, context),
      _ => _parseClassModel(name, schema, context),
    };

    if (model is PrimitiveModel && name != null) {
      model = _annotateSchemaValue(name, model, schema, context);
    }

    if (model is EnumModel &&
        (name == null || _findNamedModel(name, schema) == null)) {
      _logModelAdded(model);
      _registerModel(model, schema);
    }

    _rememberSchemaModel(model, schema);
    return model;
  }

  Model _annotateSchemaValue(
    String? name,
    Model model,
    Schema schema,
    Context context,
  ) {
    final isNullable = schema.isNullable ?? schema.hasNullType;
    if (name == null &&
        schema.rawDefault == null &&
        !(schema.isReadOnly ?? false) &&
        !(schema.isWriteOnly ?? false) &&
        (!isNullable || model.isEffectivelyNullable)) {
      _rememberSchemaModel(model, schema);
      return model;
    }
    final alias = AliasModel(
      name: name,
      model: model,
      context: context,
      isNullable: isNullable,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      defaultValue: schema.rawDefault,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
    );
    _logModelAdded(alias);
    _registerModel(alias, schema);
    return alias;
  }

  Model _resolveContentEncodedModel(Schema schema, Context context) {
    final mediaType = schema.contentMediaType;
    if (mediaType != null && _contentMediaTypes.containsKey(mediaType)) {
      return switch (_contentMediaTypes[mediaType]!) {
        .text => StringModel(context: context),
        .binary => _contentEncodedBinaryModel(schema, context),
      };
    }

    return _contentEncodedBinaryModel(schema, context);
  }

  Model _contentEncodedBinaryModel(Schema schema, Context context) =>
      switch (schema.contentEncoding?.toLowerCase()) {
        'base64' => Base64Model(context: context),
        _ => BinaryModel(context: context),
      };

  OneOfModel _parseMultiType(
    Schema schema,
    bool hasNullType,
    Context context,
    String? name,
  ) {
    final oneOfModel = OneOfModel(
      defaultValue: schema.rawDefault,
      models: <DiscriminatedModel>[],
      name: name,
      context: context,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
      discriminator: null,
      isNullable: schema.isNullable ?? hasNullType,
    );

    _addModelToSet(oneOfModel, schema);
    _populateMultiTypeShell(schema, hasNullType, context, oneOfModel);
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
      isNullable: schema.isNullable ?? schema.hasNullType,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
      isContentNullable: false,
    );

    final register = name != null && _findNamedModel(name, schema) == null;
    _rememberSchemaModel(listModel, schema);

    if (register) {
      _logModelAdded(listModel);
      _registerModel(listModel, schema);
    }

    if (items == null) {
      listModel.content = AnyModel(context: modelContext);
      return listModel;
    }

    listModel
      ..content = _resolveSchemaRef(null, items, modelContext)
      ..isContentNullable = items.isNullable ?? items.hasNullType;

    return listModel;
  }

  AllOfModel _parseAllOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'allOf');

    // Register the model early (with an empty member list) so that
    // circular references can find it during member resolution.
    final allOfModel = AllOfModel(
      defaultValue: schema.rawDefault,
      isDeprecated: schema.isDeprecated ?? false,
      models: <Model>[],
      context: modelContext,
      name: name,
      description: schema.description,
      additionalPropertiesPolicy: null,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
    );

    if (name == null || _findNamedModel(name, schema) == null) {
      _logModelAdded(allOfModel);
      _registerModel(allOfModel, schema);
    }

    if (_hasAnyOfObjectSiblings(schema)) {
      _populateAnyOfObjectSiblings(name, schema, context, allOfModel);
      return allOfModel;
    }

    allOfModel.additionalPropertiesPolicy = importAdditionalProperties(
      schema,
      modelContext,
    );

    final resolvedModels = <Model>[];
    for (final allOfSchema in schema.allOf!) {
      final member = _resolveCompositeSubModel(
        allOfSchema,
        modelContext,
        allOfModel,
      );
      if (member != null) resolvedModels.add(member);
    }

    allOfModel.models = resolvedModels;

    return allOfModel;
  }

  void _addModelToSet(Model model, [Schema? schema]) {
    if (model is! PrimitiveModel) {
      final alreadyRegistered = models.contains(model);
      _logModelAdded(model);
      _registerModel(model, schema);

      if (model is OneOfModel && !alreadyRegistered) {
        for (final nestedModel in model.models) {
          _addModelToSet(nestedModel.model);
        }
      }
    }
  }

  OneOfModel _parseOneOf(
    String? name,
    Schema schema,
    Context context, {
    bool cacheSchema = true,
  }) {
    final modelContext = context.push(name ?? 'oneOf');
    final alternatives = schema.oneOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    // Register the model early (with an empty member list) so that
    // circular references can find it during member resolution.
    final oneOfModel = OneOfModel(
      defaultValue: schema.rawDefault,
      isDeprecated: schema.isDeprecated ?? false,
      models: <DiscriminatedModel>[],
      context: context,
      name: name,
      discriminator: effectiveDiscriminator?.propertyName,
      discriminatorAliases: _getDiscriminatorAliases(effectiveDiscriminator),
      description: schema.description,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
    );

    if (name == null || _findNamedModel(name, schema) == null) {
      _logModelAdded(oneOfModel);
      _registerModel(oneOfModel, cacheSchema ? schema : null);
    }

    final resolvedModels = <DiscriminatedModel>[];
    for (final oneOfSchema in alternatives) {
      if (_isNullOnlySchema(oneOfSchema)) {
        oneOfModel.isNullable = true;
        continue;
      }
      final member = _resolveCompositeSubModel(
        oneOfSchema,
        modelContext,
        oneOfModel,
      );
      if (member != null) {
        resolvedModels.add((
          discriminatorValue: _getDiscriminatorValue(
            discriminator: effectiveDiscriminator,
            innerSchema: oneOfSchema,
          ),
          model: member,
        ));
      }
    }

    oneOfModel.models = resolvedModels;

    // Nested composite members enter the global model set after resolution.
    for (final nestedModel in oneOfModel.models) {
      _addModelToSet(nestedModel.model);
    }

    return oneOfModel;
  }

  AnyOfModel _parseAnyOf(
    String? name,
    Schema schema,
    Context context, {
    bool cacheSchema = true,
    Model? enclosingModel,
  }) {
    final modelContext = context.push(name ?? 'anyOf');
    final alternatives = schema.anyOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    // Register the model early (with an empty member list) so that
    // circular references can find it during member resolution.
    final anyOfModel = AnyOfModel(
      defaultValue: schema.rawDefault,
      isDeprecated: schema.isDeprecated ?? false,
      models: <DiscriminatedModel>[],
      context: context,
      name: name,
      discriminator: effectiveDiscriminator?.propertyName,
      discriminatorAliases: _getDiscriminatorAliases(effectiveDiscriminator),
      description: schema.description,
      isNullable: schema.isNullable ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
    );

    if (name == null || _findNamedModel(name, schema) == null) {
      _logModelAdded(anyOfModel);
      _registerModel(anyOfModel, cacheSchema ? schema : null);
    }

    final resolvedModels = <DiscriminatedModel>[];
    for (final anyOfSchema in alternatives) {
      if (_isNullOnlySchema(anyOfSchema)) {
        anyOfModel.isNullable = true;
        continue;
      }
      final member = _resolveCompositeSubModel(
        anyOfSchema,
        modelContext,
        enclosingModel ?? anyOfModel,
      );
      if (member != null) {
        resolvedModels.add((
          discriminatorValue: _getDiscriminatorValue(
            discriminator: effectiveDiscriminator,
            innerSchema: anyOfSchema,
          ),
          model: member,
        ));
      }
    }

    anyOfModel.models = resolvedModels;

    return anyOfModel;
  }

  String _discriminatorTarget(String value) {
    if (_schemas.containsKey(value)) {
      return LocalJsonPointer.fromTokens(['components', 'schemas', value])
          .reference;
    }
    if (value.startsWith('#') &&
        Uri.decodeComponent(value.substring(1)).startsWith('/')) {
      return LocalJsonPointer.parse(value).reference;
    }
    return value;
  }

  Map<String, String> _getDiscriminatorAliases(
    parse.Discriminator? discriminator,
  ) {
    final canonicalValues = <String, String>{};
    final aliases = <String, String>{};
    for (final entry
        in discriminator?.mapping?.entries ?? <MapEntry<String, String>>[]) {
      final canonical = canonicalValues.putIfAbsent(
        _discriminatorTarget(entry.value),
        () => entry.key,
      );
      if (entry.key != canonical) aliases[entry.key] = canonical;
    }
    return aliases;
  }

  String? _getDiscriminatorValue({
    required parse.Discriminator? discriminator,
    required Schema innerSchema,
  }) {
    if (innerSchema.ref != null && discriminator?.propertyName != null) {
      final ref = innerSchema.ref!;
      final pointer = LocalJsonPointer.parse(ref);
      final discriminatorEntry = discriminator?.mapping?.entries
          .firstWhereOrNull(
            (entry) => _discriminatorTarget(entry.value) == pointer.reference,
          );
      if (discriminatorEntry != null) return discriminatorEntry.key;
      final implicitValue = pointer.tokens.lastOrNull;
      // Explicit mappings take precedence over implicit schema-name lookup.
      if (discriminator?.mapping?.containsKey(implicitValue) ?? false) {
        return null;
      }
      return implicitValue;
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
      final parentDiscriminator = _findDiscriminatorInAllOfChain(
        alternative,
        <Schema>{},
      );
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
  parse.Discriminator? _findDiscriminatorInAllOfChain(
    Schema schema,
    Set<Schema> visited,
  ) {
    final resolvedSchema = resolveSchemaReference(schema);
    if (resolvedSchema == null ||
        !visited.add(_canonicalSchema(resolvedSchema))) {
      return null;
    }

    final allOf = resolvedSchema.allOf;
    if (allOf == null || allOf.isEmpty) return null;

    for (final member in allOf) {
      final memberSchema = resolveSchemaReference(member);
      if (memberSchema == null) continue;

      if (memberSchema.discriminator != null) {
        return memberSchema.discriminator;
      }

      // Recurse into the member's own allOf chain.
      final inherited = _findDiscriminatorInAllOfChain(memberSchema, visited);
      if (inherited != null) return inherited;
    }

    return null;
  }

  /// Returns true if [schema] permits only the JSON literal `null`,
  /// i.e. its type — possibly behind `$ref`s — is exactly `"null"`.
  bool _isNullOnlySchema(Schema schema) {
    var current = schema;
    final seenRefs = <String>{};
    while (current.ref != null) {
      if (!seenRefs.add(current.ref!)) {
        return false;
      }
      final resolved = resolveSchemaReference(current);
      if (resolved == null) {
        return false;
      }
      current = resolved;
    }
    return current.type.isNotEmpty && current.nonNullTypes.isEmpty;
  }

  Schema? resolveSchemaReference(Schema schema) {
    if (schema.ref == null) return schema;
    if (isExternalReference(schema.ref!)) return null;
    try {
      return _schemaForPointer(LocalJsonPointer.parse(schema.ref!));
      // Missing targets remain nullable for the existing inspection helper;
      // actual model resolution reports the reference failure.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }

  AdditionalPropertiesPolicy importAdditionalProperties(
    Schema schema,
    Context context,
  ) => _additionalProperties[(schema, context)] ??= _importAdditionalProperties(
    schema,
    context,
  );

  AdditionalPropertiesPolicy _importAdditionalProperties(
    Schema schema,
    Context context,
  ) {
    final ap = schema.additionalProperties;
    if (ap == false) return const ForbiddenAdditionalProperties();
    if (ap is Schema && !_isEmptySchema(ap)) {
      var valueModel = _resolveSchemaRef(null, ap, context);
      final isNullable = ap.isNullable ?? ap.hasNullType;
      if (isNullable && !valueModel.isEffectivelyNullable) {
        valueModel = AliasModel(
          model: valueModel,
          context: context,
          isNullable: true,
          defaultValue: null,
          examples: const [],
          name: null,
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
      }
      return AllowedAdditionalProperties(
        valueModel: valueModel,
        origin: AdditionalPropertiesOrigin.explicit,
      );
    }
    return AllowedAdditionalProperties(
      valueModel: AnyModel(context: context),
      origin: ap == null
          ? AdditionalPropertiesOrigin.implicitDefault
          : AdditionalPropertiesOrigin.explicit,
    );
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

  ClassModel _parseClassModel(
    String? name,
    Schema schema,
    Context context, {
    bool cacheSchema = true,
  }) {
    final schemaProperties = schema.properties ?? {};
    final properties = <Property>[];

    final model = ClassModel(
      isDeprecated: schema.isDeprecated ?? false,
      name: name,
      properties: properties,
      context: context,
      description: schema.description,
      additionalPropertiesPolicy: null,
      isNullable:
          schema.isNullable ??
          (schema.type.contains('object') && schema.hasNullType),
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
    );

    if (schema.not != null) {
      log.warning(
        'Found not schema for $name. The not keyword is not '
        'supported and will be ignored.',
      );
    }

    if (name == null || _findNamedModel(name, schema) == null) {
      // Recursive properties need the model registered before property
      // parsing.
      _logModelAdded(model);
      _registerModel(model, cacheSchema ? schema : null);
    }

    model.additionalPropertiesPolicy = importAdditionalProperties(
      schema,
      context,
    );

    for (final MapEntry(key: propertyName, value: propertySchema)
        in schemaProperties.entries) {
      final isNullable =
          propertySchema.isNullable ?? propertySchema.hasNullType;
      final isDeprecated = propertySchema.isDeprecated ?? false;
      final (:isReadOnly, :isWriteOnly) = _propertyAccessFlags(propertySchema);
      final description = propertySchema.description;
      final nameOverride = propertySchema.xDartName;

      // Empty property names need a placeholder so the context path remains
      // valid.
      final contextPropertyName = propertyName.trim().isEmpty
          ? 'property'
          : propertyName;

      final property = Property(
        name: propertyName,
        model: importPropertySchema(
          propertySchema,
          context.pushAll([name, contextPropertyName].whereType<String>()),
        ),
        isRequired: schema.required?.contains(propertyName) ?? false,
        isNullable: isNullable,
        isDeprecated: isDeprecated,
        isReadOnly: isReadOnly,
        isWriteOnly: isWriteOnly,
        description: description,
        defaultValue: propertySchema.rawDefault,
        examples: exampleImporter.fromSchema(propertySchema),
        nameOverride: null,
      );

      if (nameOverride != null) {
        property.nameOverride = nameOverride;
      }

      properties.add(property);
    }

    return model;
  }

  EnumModel<String> _parseStringEnum(
    String? name,
    Schema schema,
    Context context,
  ) {
    final parsed = _parseEnumValues<String>(
      name,
      schema,
      context,
      emptyFallbackValue: _unknownEnumCaseName,
    );
    final createEnum = schema.format == 'date-time'
        ? DateTimeEnumModel.new
        : EnumModel<String>.new;
    return createEnum(
      name: name,
      nameOverride: null,
      values: parsed.values,
      isNullable: parsed.isNullable,
      fallbackValue: parsed.fallbackValue,
      context: context,
      defaultValue: schema.rawDefault,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
    );
  }

  EnumModel<int> _parseIntegerEnum(
    String? name,
    Schema schema,
    Context context,
  ) {
    final parsed = _parseEnumValues<int>(
      name,
      schema,
      context,
      emptyFallbackValue: -1,
    );
    return EnumModel<int>(
      name: name,
      values: parsed.values,
      isNullable: parsed.isNullable,
      fallbackValue: parsed.fallbackValue,
      context: context,
      defaultValue: schema.rawDefault,
      description: schema.description,
      isDeprecated: schema.isDeprecated ?? false,
      isReadOnly: schema.isReadOnly ?? false,
      isWriteOnly: schema.isWriteOnly ?? false,
      examples: exampleImporter.fromSchema(schema),
      nameOverride: null,
    );
  }

  ({Set<EnumEntry<T>> values, bool isNullable, EnumEntry<T>? fallbackValue})
  _parseEnumValues<T>(
    String? name,
    Schema schema,
    Context context, {
    required T emptyFallbackValue,
  }) {
    final values = schema.enumerated!;
    final xDartEnum = schema.xDartEnum;
    log.fine('Parsing enum $name<$T> for $context with values $values');
    final location = switch (name) {
      final name? when name.isNotEmpty => context.push(name).toString(),
      _ when context.path.isNotEmpty => context.toString(),
      _ => '<anonymous>',
    };

    final typedValues = values.whereType<T>().toSet();
    final hasNull = values.any((value) => value == null);

    // Null enum entries are represented through isNullable.
    if (!hasNull && typedValues.length != values.length ||
        hasNull && (typedValues.length + 1) != values.length) {
      log.warning(
        'Found non-matching values in enum for $location. '
        'Ignoring non-matching values.',
      );
    }

    final enumValues = <EnumEntry<T>>{};
    final typedValuesList = typedValues.toList();

    for (var i = 0; i < typedValuesList.length; i++) {
      final value = typedValuesList[i];
      String? nameOverride;

      if (xDartEnum != null && i < xDartEnum.length) {
        nameOverride = xDartEnum[i];
      }

      enumValues.add(EnumEntry<T>(value: value, nameOverride: nameOverride));
    }

    EnumEntry<T>? fallbackValue;
    if (enumValues.isEmpty) {
      log.warning(
        'Enum $location has no values. Adding an unknown fallback case.',
      );
      fallbackValue = EnumEntry<T>(
        value: emptyFallbackValue,
        nameOverride: _unknownEnumCaseName,
      );
    }

    return (
      values: enumValues,
      isNullable: (schema.isNullable ?? schema.hasNullType) || hasNull,
      fallbackValue: fallbackValue,
    );
  }

  void _logModelAdded(Model model) {
    final name = model is NamedModel && model.name != null
        ? model.name
        : '${model.context}->${model.runtimeType}';
    log.fine('Adding model $name');
  }

  void registerLocalPathItem(
    ReferenceWrapper<parse.PathItem> wrapper,
    LocalJsonPointer pointer,
  ) => _indexSchemas(wrapper, pointer.tokens, referenced: true);

  void registerReferencedMediaType(parse.MediaType mediaType) =>
      _indexSchemas(mediaType, null, referenced: true);

  void _indexSchemas(
    Object? value,
    List<String>? path, {
    bool referenced = false,
  }) {
    if (value is Schema) {
      final canonical = path == null
          ? _canonicalSchema(value)
          : _schemaReferences.putIfAbsent(
              LocalJsonPointer.fromTokens(path).reference,
              () => value,
            );
      if (!identical(canonical, value)) _schemaAliases[value] = canonical;
      if (referenced) {
        _nestedReferenceSchemas.add(canonical);
        final existing = _existingSchemaModel(canonical);
        if (existing != null) _nestedReferenceModels[canonical] = existing;
      }
    } else if (value is InlinedObject<Object?>) {
      _indexSchemas(value.object, path, referenced: referenced);
      return;
    } else if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        _indexSchemas(
          entry.value,
          path == null ? null : [...path, entry.key],
          referenced: referenced,
        );
      }
      return;
    } else if (value is List<Object?>) {
      for (var index = 0; index < value.length; index++) {
        _indexSchemas(
          value[index],
          path == null ? null : [...path, '$index'],
          referenced: referenced,
        );
      }
      return;
    }

    final children = switch (value) {
      OpenApiObject() => <String, Object?>{
        'components': value.components,
        'paths': value.paths,
      },
      parse.Components() => <String, Object?>{
        'schemas': value.schemas,
        'parameters': value.parameters,
        'headers': value.headers,
        'requestBodies': value.requestBodies,
        'responses': value.responses,
        'pathItems': value.pathItems,
        'mediaTypes': value.mediaTypes,
      },
      parse.PathItem() => <String, Object?>{
        'get': value.get,
        'put': value.put,
        'post': value.post,
        'delete': value.delete,
        'patch': value.patch,
        'head': value.head,
        'options': value.options,
        'trace': value.trace,
        'parameters': value.parameters,
      },
      parse.Operation() => <String, Object?>{
        'parameters': value.parameters,
        'requestBody': value.requestBody,
        'responses': value.responses,
      },
      parse.Parameter() => <String, Object?>{
        'schema': value.schema,
        'content': value.content,
      },
      parse.Header() => <String, Object?>{
        'schema': value.schema,
        'content': value.content,
      },
      parse.RequestBody() => <String, Object?>{'content': value.content},
      parse.Response() => <String, Object?>{
        'headers': value.headers,
        'content': value.content,
      },
      parse.MediaType() => <String, Object?>{
        'schema': value.schema,
        'itemSchema': value.itemSchema,
        'encoding': value.encoding,
      },
      parse.Encoding() => <String, Object?>{'headers': value.headers},
      Schema() => <String, Object?>{
        r'$defs': value.defs,
        'properties': value.properties,
        'items': value.items,
        'allOf': value.allOf,
        'oneOf': value.oneOf,
        'anyOf': value.anyOf,
        'not': value.not,
        'additionalProperties': value.additionalProperties,
        'contentSchema': value.contentSchema,
      },
      _ => const <String, Object?>{},
    };
    for (final entry in children.entries) {
      if (entry.value != null) {
        _indexSchemas(
          entry.value,
          path == null ? null : [...path, entry.key],
          referenced: referenced,
        );
      }
    }
  }
}
