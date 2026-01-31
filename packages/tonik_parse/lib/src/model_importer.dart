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

  late Set<Model> models;
  final log = Logger('ModelImporter');

  static Context get rootContext =>
      Context.initial().pushAll(['components', 'schemas']);

  void import() {
    models = <Model>{};
    _collectAllDefs();

    final context = rootContext;

    for (final MapEntry(key: name, value: schema) in _schemas.entries) {
      log.fine('Importing schema $name');
      var model = _resolveSchemaRef(name, schema, context);

      if (model is PrimitiveModel || model is AnyModel || model is NeverModel) {
        model = AliasModel(
          name: name,
          model: model,
          context: context,
        );
      }

      // Apply x-dart-name vendor extension to schema.
      if (schema.xDartName != null) {
        if (model is NamedModel) {
          model.nameOverride = schema.xDartName;
        }
      }

      if (models.none((m) => m is NamedModel && m.name == name)) {
        log.fine('Adding model $name');
        models.add(model);
      }
    }
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
        _resolveSchemaRef(refName, refSchema, rootContext);

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
        _resolveSchemaRef(refName, refSchema, rootContext);
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
    final defsContext = _contextFromDefsPath(ref);
    final refModel = _resolveSchemaRef(defName, defSchema, defsContext);

    if (_hasStructuralSiblings(schema)) {
      return _mergeRefWithStructuralSiblings(name, refModel, schema, context);
    }

    if (name != null || _hasAnnotationSiblings(schema)) {
      final aliasModel = AliasModel(
        name: name,
        model: refModel,
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.type.contains('null'),
      );

      if (name == null) {
        _logModelAdded(aliasModel);
        models.add(aliasModel);
      }

      return aliasModel;
    }

    return refModel;
  }

  Context _contextFromDefsPath(String ref) {
    final parts = ref.substring(2).split('/'); // Remove '#/' prefix.
    return Context.initial().pushAll(parts);
  }

  bool _hasAnnotationSiblings(Schema schema) {
    return schema.description != null ||
        (schema.isDeprecated ?? false) ||
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
        _resolveSchemaRef(refName, refSchema, rootContext);

    if (_hasStructuralSiblings(schema)) {
      return _mergeRefWithStructuralSiblings(
        name,
        refModel,
        schema,
        context,
      );
    }

    if (name != null || _hasAnnotationSiblings(schema)) {
      final aliasModel = AliasModel(
        name: name,
        model: refModel,
        context: context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
        isNullable: schema.type.contains('null'),
      );

      if (name == null) {
        _logModelAdded(aliasModel);
        models.add(aliasModel);
      }

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
      isNullable: schema.type.contains('null'),
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
      'string' when schema.format == 'byte' => StringModel(context: context),
      'string' when schema.enumerated != null => _parseEnum<String>(
        name,
        schema.enumerated!,
        schema.isNullable ?? hasNullType,
        context,
        description: schema.description,
        isDeprecated: schema.isDeprecated ?? false,
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
    );

    _addModelToSet(oneOfModel);
    return oneOfModel;
  }

  ListModel _parseArray(String? name, Schema schema, Context context) {
    final items = schema.items;
    if (items == null) {
      throw ArgumentError('Array schema $schema has no items');
    }

    final modelContext = context.push('array');
    final content = _resolveSchemaRef(null, items, modelContext);
    return ListModel(
      content: content,
      context: context,
      name: name,
      isNullable: schema.isNullable ?? false,
    );
  }

  AllOfModel _parseAllOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'allOf');
    final models = schema.allOf!
        .map(
          (allOfSchema) => _resolveSchemaRef(null, allOfSchema, modelContext),
        )
        .toList();

    final allOfModel = AllOfModel(
      isDeprecated: schema.isDeprecated ?? false,
      models: models.toSet(),
      context: modelContext,
      name: name,
      description: schema.description,
      isNullable: schema.isNullable ?? false,
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
    final alternatives = schema.oneOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    final models = alternatives.map(
      (oneOfSchema) => (
        discriminatorValue: _getDiscriminatorValue(
          discriminator: effectiveDiscriminator,
          innerSchema: oneOfSchema,
        ),
        model: _resolveSchemaRef(null, oneOfSchema, modelContext),
      ),
    );

    final oneOfModel = OneOfModel(
      isDeprecated: schema.isDeprecated ?? false,
      models: models.toSet(),
      context: context,
      name: name,
      discriminator: effectiveDiscriminator?.propertyName,
      description: schema.description,
      isNullable: schema.isNullable ?? false,
    );

    _addModelToSet(oneOfModel);
    return oneOfModel;
  }

  AnyOfModel _parseAnyOf(String? name, Schema schema, Context context) {
    final modelContext = context.push(name ?? 'anyOf');
    final alternatives = schema.anyOf!;

    final effectiveDiscriminator =
        schema.discriminator ?? _findInheritedDiscriminator(alternatives);

    final models = alternatives.map(
      (anyOfSchema) => (
        discriminatorValue: _getDiscriminatorValue(
          discriminator: effectiveDiscriminator,
          innerSchema: anyOfSchema,
        ),
        model: _resolveSchemaRef(null, anyOfSchema, modelContext),
      ),
    );
    final anyOfModel = AnyOfModel(
      isDeprecated: schema.isDeprecated ?? false,
      models: models.toSet(),
      context: context,
      name: name,
      discriminator: effectiveDiscriminator?.propertyName,
      description: schema.description,
      isNullable: schema.isNullable ?? false,
    );

    _addModelToSet(anyOfModel);
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
    }

    return null;
  }

  Schema? _resolveSchemaToSchema(Schema schema) {
    if (schema.ref == null) return schema;

    final ref = schema.ref!;

    if (ref.startsWith('#/components/schemas/')) {
      return _schemas[ref.split('/').last];
    }

    if (ref.contains(r'/$defs/')) {
      return _defs[ref.split('/').last];
    }

    return null;
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
      isNullable: schema.isNullable ?? false,
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
      final description = propertySchema.description;
      final nameOverride = propertySchema.xDartName;

      final property = Property(
        name: propertyName,
        model: _resolveSchemaRefForProperty(
          propertySchema,
          context.pushAll([name, propertyName].whereType<String>()),
        ),
        isRequired: schema.required?.contains(propertyName) ?? false,
        isNullable: isNullable,
        isDeprecated: isDeprecated,
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
  }
}
