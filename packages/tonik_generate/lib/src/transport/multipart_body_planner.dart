import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/text_encoding_expression.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

/// Resolves serialization before native multipart containers are constructed.
class const MultipartBodyPlanner({
  required final TransportBackend backend,
  final NameManager? nameManager,
  final String? package,
  final bool useImmutableCollections = false,
}) {
  bool get _dio => backend == TransportBackend.dio;

  MultipartBodyPlan plan(
    MultipartRequestContent content, {
    required String bodyAccessor,
    required bool isRequired,
    List<MultipartHeaderParamInfo>? headerParameters,
  }) {
    final parameters =
        (headerParameters ??
                extractMultipartHeaderParamInfo(
                  content,
                  nameManager: nameManager,
                  package: package,
                ))
            .where((parameter) => identical(parameter.content, content))
            .toList();
    final emissions = <MultipartEmission>[];
    final mergeHelpers = <MultipartMergeHelper>{};
    final normalization = normalizeMultipartProperties(
      content,
      nameManager: nameManager,
      package: package,
    );
    if (normalization.runtimeEncodingError case final runtimeEncodingError?) {
      return MultipartBodyPlan(
        value: refer(bodyAccessor),
        rawContentType: content.rawContentType,
        isRequired: isRequired,
        emissions: const [],
        runtimeEncodingError: runtimeEncodingError,
      );
    }
    final dynamicSource = normalization.dynamicSource;
    final reservedNames = dynamicSource?.declaredWireNames ?? const <String>{};
    if (reservedNames.isNotEmpty) {
      emissions.add(
        MultipartCode(
          declareFinal(r'_$multipartReservedNames')
              .assign(
                literalSet(
                  reservedNames.map(specLiteralString),
                  refer('String', 'dart:core'),
                ),
              )
              .statement,
        ),
      );
    }
    final properties = normalization.properties;
    for (final property in properties) {
      final runtimeEncodingError = _incompatibleDefinitionsError(property);
      if (runtimeEncodingError != null) {
        return MultipartBodyPlan(
          value: refer(bodyAccessor),
          rawContentType: content.rawContentType,
          isRequired: isRequired,
          emissions: const [],
          runtimeEncodingError: runtimeEncodingError,
        );
      }
    }
    for (final property in properties) {
      final resolvedEncoding =
          content.encoding[property.rawName] ??
          resolveNamedMultipartEncoding(property.property.model, null);
      final accesses = [
        for (final path in property.accessPaths)
          _access(refer(bodyAccessor), path),
      ];
      final choiceModels = [
        for (final candidate in property.properties)
          if (candidate.model.resolved case final MultipartChoiceModel choice)
            choice
          else if (candidate.model.resolved case ListModel(:final content))
            if (content.resolved case final MultipartChoiceModel choice) choice,
      ];
      if (accesses.length > 1 &&
          choiceModels.length == accesses.length &&
          property.properties.every(
            (candidate) => candidate.model.resolved is MultipartChoiceModel,
          )) {
        mergeHelpers.add(MultipartMergeHelper.dynamicValues);
        _mergedChoiceProperty(
          content,
          property,
          accesses,
          choiceModels,
          parameters,
          reservedNames,
          emissions,
        );
        continue;
      }
      final mergedObjects =
          accesses.length > 1 &&
          property.properties.every(
            (candidate) =>
                candidate.model.resolved is ClassModel ||
                candidate.model.resolved is AllOfModel,
          );
      final mergedMaps =
          accesses.length > 1 &&
          property.properties.every(
            (candidate) => candidate.model.resolved is MapModel,
          );
      final mergedLists =
          accesses.length > 1 &&
          property.properties.every(
            (candidate) => candidate.model.resolved is ListModel,
          );
      final mergedObjectProperties =
          mergedObjects &&
          (resolvedEncoding.isStyleBased ||
              resolvedEncoding.contentType == ContentType.form);
      final nullable = property.isNullable || !property.isRequired;
      final Expression accessor;
      if (accesses.length == 1) {
        accessor = accesses.single;
      } else {
        final variable = '_\$${property.normalizedName}MultipartValue';
        final mergeHelper = mergedObjectProperties
            ? MultipartMergeHelper.propertyValues
            : mergedLists
            ? MultipartMergeHelper.lists
            : MultipartMergeHelper.dynamicValues;
        mergeHelpers.add(mergeHelper);
        final mergeFunction = switch (mergeHelper) {
          MultipartMergeHelper.propertyValues =>
            '_mergeMultipartPropertyValues',
          MultipartMergeHelper.lists => '_mergeMultipartLists',
          MultipartMergeHelper.dynamicValues => '_mergeMultipartValues',
        };
        var mergeExpression = refer(mergeFunction).call(
          [
            literalList([
              for (var i = 0; i < accesses.length; i++)
                if (mergedObjects)
                  _objectMergeValue(
                    accesses[i],
                    nullable: _occurrenceIsNullable(
                      property.accessPaths[i],
                      property.properties[i],
                    ),
                    asProperties: mergedObjectProperties,
                  )
                else if (useImmutableCollections &&
                    (property.properties[i].model.resolved is ListModel ||
                        property.properties[i].model.resolved is MapModel))
                  _immutableMergeValue(
                    accesses[i],
                    nullable: _occurrenceIsNullable(
                      property.accessPaths[i],
                      property.properties[i],
                    ),
                  )
                else
                  accesses[i],
            ]),
          ],
          {
            'propertyName': specLiteralString(property.rawName),
            if ((mergedObjects && !mergedObjectProperties) || mergedMaps)
              'mergeObjects': literalTrue,
          },
        );
        if (!nullable && (mergedObjectProperties || mergedLists)) {
          mergeExpression = mergeExpression.nullChecked;
        }
        emissions.add(
          MultipartCode(
            declareFinal(variable).assign(mergeExpression).statement,
          ),
        );
        accessor = refer(variable);
      }
      if (property.isRequired && property.isNullable) {
        emissions.add(
          MultipartCode(
            Block.of([
              const Code('if ('),
              accessor.code,
              const Code(' == null) { '),
              generateEncodingExceptionExpression(
                'Required multipart property "${property.rawName}" is null.',
                raw: true,
              ).code,
              const Code('; }'),
            ]),
          ),
        );
      }
      if (nullable) {
        emissions.add(
          MultipartCode(
            Block.of([
              const Code('if ('),
              accessor.code,
              const Code(' != null) {'),
            ]),
          ),
        );
      }
      final headerEmissionStart = emissions.length;
      final headers = choiceModels.isNotEmpty
          ? null
          : _headers(
              content.encoding[property.rawName],
              property.normalizedName,
              parameters,
              nullable,
              emissions,
              base64: switch (property.property.model.resolved) {
                Base64Model() => true,
                ListModel(:final content) => content.resolved is Base64Model,
                _ => false,
              },
            );
      final hasNullAwareAccess =
          accesses.length == 1 &&
          property.accessPaths.single.any(
            (segment) => segment.receiverNullable,
          );
      final input = (
        name: property.rawName,
        wireName: specLiteralString(property.rawName),
        preserveOrder: dynamicSource != null,
        normalizedName: property.normalizedName,
        value: nullable && mergedLists && accesses.length > 1
            ? accessor
            : nullable
            ? (hasNullAwareAccess ? accessor.parenthesized : accessor)
                  .nullChecked
            : accessor,
        encoding: resolvedEncoding,
        headers: headers,
        selectedContentType: null,
        choiceModels: choiceModels,
        choiceHeaders: choiceModels.isEmpty
            ? null
            : (
                encoding: content.encoding[property.rawName],
                parameters: parameters,
                nullable: nullable,
              ),
        isMergedObject: mergedObjects,
        isMergedMap: mergedMaps,
        isMergedList: mergedLists,
        isMergedObjectProperties: mergedObjectProperties,
      );
      final partEmissions = _part(input, property.property.model.resolved);
      if (!partEmissions.any((emission) => emission is MultipartAppend)) {
        emissions.removeRange(headerEmissionStart, emissions.length);
      }
      for (final emission in partEmissions) {
        if (reservedNames.isNotEmpty && emission is MultipartAppend) {
          emissions.add(
            MultipartCode(
              refer(r'_$multipartReservedNames')
                  .property('add')
                  .call([emission.name])
                  .statement,
            ),
          );
        }
        emissions.add(emission);
      }
      if (nullable) emissions.add(const MultipartCode(Code('}')));
    }
    if (dynamicSource != null) {
      emissions.addAll(
        _dynamicParts(
          dynamicSource,
          refer(bodyAccessor),
          checkCollisions: reservedNames.isNotEmpty,
        ),
      );
    }
    return MultipartBodyPlan(
      value: refer(bodyAccessor),
      rawContentType: content.rawContentType,
      isRequired: isRequired,
      emissions: emissions,
      usesCustomParts:
          !_dio &&
          (parameters.isNotEmpty ||
              emissions.whereType<MultipartAppend>().any(
                (part) => part.headers != null,
              )),
      mergeHelpers: mergeHelpers,
    );
  }

  void _mergedChoiceProperty(
    MultipartRequestContent content,
    MultipartPropertyPlan property,
    List<Expression> accesses,
    List<MultipartChoiceModel> models,
    List<MultipartHeaderParamInfo> parameters,
    Set<String> reservedNames,
    List<MultipartEmission> emissions,
  ) {
    final choicesVariable = '_\$${property.normalizedName}MultipartChoices';
    final indexVariable = '_\$${property.normalizedName}ChoiceIndex';
    final wireVariable = '_\$${property.normalizedName}WireType';
    final valueVariable = '_\$${property.normalizedName}MergedValue';
    final choices = refer(choicesVariable);
    final index = refer(indexVariable);
    final wire = refer(wireVariable);
    final value = refer(valueVariable);
    emissions.add(
      MultipartCode(
        declareFinal(choicesVariable)
            .assign(
              literalList(const <Expression>[], refer('dynamic', 'dart:core')),
            )
            .statement,
      ),
    );
    for (final access in accesses) {
      emissions.add(
        MultipartCode(
          Block.of([
            const Code('if ('),
            access.code,
            const Code(' != null) {'),
            choices.property('add').call([access]).statement,
            const Code('}'),
          ]),
        ),
      );
    }
    if (property.isRequired) {
      emissions.add(
        MultipartCode(
          Block.of([
            const Code('if ('),
            choices.property('isEmpty').code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'Required multipart property "${property.rawName}" is null.',
              raw: true,
            ).statement,
            const Code('}'),
          ]),
        ),
      );
    }
    emissions
      ..add(
        MultipartCode(
          Block.of([
            const Code('if ('),
            choices.property('isNotEmpty').code,
            const Code(') {'),
          ]),
        ),
      )
      ..add(
        MultipartCode(
          declareFinal(indexVariable)
              .assign(
                choices.property('first').property('multipartChoiceIndex'),
              )
              .statement,
        ),
      )
      ..add(
        MultipartCode(
          declareFinal(wireVariable)
              .assign(choices.property('first').property('multipartWireType'))
              .statement,
        ),
      )
      ..add(
        MultipartCode(
          Block.of([
            const Code('for (final selected in '),
            choices.code,
            const Code(') {'),
            const Code('if (selected.multipartChoiceIndex != '),
            index.code,
            const Code(' || selected.multipartWireType != '),
            wire.code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'Conflicting media choices for multipart property '
              '"${property.rawName}".',
              raw: true,
            ).statement,
            const Code('}'),
            const Code('if (selected.multipartValue == null) {'),
            generateEncodingExceptionExpression(
              'Selected media choice for multipart property '
              '"${property.rawName}" is null.',
              raw: true,
            ).statement,
            const Code('}'),
            const Code('}'),
          ]),
        ),
      )
      ..add(
        MultipartCode(
          declareFinal(valueVariable)
              .assign(
                refer('_mergeMultipartValues').call(
                  [
                    CodeExpression(
                      Block.of([
                        const Code('[for (final selected in '),
                        choices.code,
                        const Code(') selected.multipartValue]'),
                      ]),
                    ),
                  ],
                  {
                    'propertyName': specLiteralString(property.rawName),
                    'mergeObjects': choices
                        .property('first')
                        .property('multipartValue')
                        .isA(refer('Map', 'dart:core')),
                  },
                ),
              )
              .statement,
        ),
      )
      ..add(
        MultipartCode(
          Block.of([const Code('switch ('), index.code, const Code(') {')]),
        ),
      );
    final selectedModel = models.first;
    for (final (choiceIndex, member) in selectedModel.models.indexed) {
      final encoding = selectedModel.choices[choiceIndex];
      emissions.add(MultipartCode(Code('case $choiceIndex:')));
      final headers = _headers(
        content.encoding[property.rawName],
        property.normalizedName,
        parameters,
        false,
        emissions,
        base64: member.model.resolved is Base64Model,
        variableSuffix: 'Choice$choiceIndex',
      );
      if (encoding.requiresWireContentType) {
        emissions.add(
          MultipartCode(
            Block.of([
              const Code('if (!'),
              _matchingMediaChoice(wire, encoding, member.model.resolved).code,
              const Code(') {'),
              generateEncodingExceptionExpression(
                'Multipart property "${property.rawName}" requires a matching '
                'concrete Content-Type.',
                raw: true,
              ).statement,
              const Code('}'),
            ]),
          ),
        );
      }
      final part = (
        name: property.rawName,
        wireName: specLiteralString(property.rawName),
        preserveOrder: false,
        normalizedName: property.normalizedName,
        value: value,
        encoding: encoding,
        headers: headers,
        selectedContentType: encoding.requiresWireContentType ? wire : null,
        choiceModels: const <MultipartChoiceModel>[],
        choiceHeaders: null,
        isMergedObject: false,
        isMergedMap: false,
        isMergedList: false,
        isMergedObjectProperties: false,
      );
      final partEmissions =
          encoding.contentType == ContentType.json &&
              member.model.resolved is! BinaryModel &&
              member.model.resolved is! Base64Model &&
              member.model.resolved is! AnyModel &&
              member.model.resolved is! NeverModel
          ? <MultipartEmission>[_text(part, _json(value))]
          : encoding.contentType == ContentType.text &&
                (member.model.resolved is PrimitiveModel ||
                    member.model.resolved is EnumModel)
          ? <MultipartEmission>[
              _text(part, value.asA(refer('String', 'dart:core'))),
            ]
          : encoding.contentType == ContentType.form &&
                (member.model.resolved is ClassModel ||
                    member.model.resolved is CompositeModel)
          ? <MultipartEmission>[
              _text(
                part,
                refer(
                  'encodeAnyToForm',
                  'package:tonik_util/tonik_util.dart',
                ).call(
                  [value],
                  {
                    'explode': literalTrue,
                    'allowEmpty': literalTrue,
                    'useQueryComponent': literalTrue,
                    'textEncoding': textEncodingExpression(
                      encoding.textEncoding,
                    ),
                  },
                ),
                fallback: 'application/x-www-form-urlencoded',
              ),
            ]
          : _part(
              member.model.resolved is DateTimeModel
                  ? _withValue(part, value.asA(refer('DateTime', 'dart:core')))
                  : part,
              member.model.resolved,
            );
      for (final emission in partEmissions) {
        if (reservedNames.isNotEmpty && emission is MultipartAppend) {
          emissions.add(
            MultipartCode(
              refer(r'_$multipartReservedNames')
                  .property('add')
                  .call([emission.name])
                  .statement,
            ),
          );
        }
        emissions.add(emission);
      }
    }
    emissions.add(
      MultipartCode(
        Block.of([
          const Code('default:'),
          generateEncodingExceptionExpression(
            'Multipart property "${property.rawName}" has an '
            'unrecognized media choice.',
            raw: true,
          ).statement,
          const Code('}'),
          const Code('}'),
        ]),
      ),
    );
  }

  List<MultipartEmission> _dynamicParts(
    MultipartDynamicSource source,
    Expression body, {
    required bool checkCollisions,
  }) {
    final emissions = <MultipartEmission>[
      MultipartCode(
        declareFinal(r'_$multipartMap')
            .assign(_access(body, source.accessPath))
            .statement,
      ),
      if (source.receiverNullable)
        MultipartCode(
          Block.of([
            const Code(r'if (_$multipartMap == null) {'),
            generateEncodingExceptionExpression(
              'Required multipart body is null.',
              raw: true,
            ).statement,
            const Code('}'),
          ]),
        ),
    ];
    final entry = refer(r'_$multipartEntry');
    final value = refer(r'_$multipartValue');
    final loopBody = <MultipartEmission>[
      if (checkCollisions)
        MultipartCode(
          Block.of([
            const Code('if ('),
            refer(r'_$multipartReservedNames')
                .property('contains')
                .call([entry.property('key')])
                .code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'Additional property keys must not collide with declared wire '
              'keys or emitted named multipart parts.',
              raw: true,
            ).statement,
            const Code('}'),
          ]),
        ),
      MultipartCode(
        declareFinal(r'_$multipartValue')
            .assign(entry.property('value'))
            .statement,
      ),
      if (source.isValueNullable)
        const MultipartCode(Code(r'if (_$multipartValue == null) continue;')),
    ];
    final headers = _headers(
      null,
      'dynamic',
      const [],
      false,
      loopBody,
      base64: switch (source.valueModel.resolved) {
        Base64Model() => true,
        ListModel(:final content) => content.resolved is Base64Model,
        _ => false,
      },
    );
    final valueModel = source.valueModel.resolved;
    final itemModel = valueModel is ListModel
        ? valueModel.content.resolved
        : valueModel;
    final part = (
      name: 'dynamic value',
      wireName: entry.property('key'),
      normalizedName: r'_$dynamic',
      preserveOrder: true,
      value: value,
      encoding: resolveNamedMultipartEncoding(itemModel, null),
      headers: headers,
      selectedContentType: null,
      choiceModels: const <MultipartChoiceModel>[],
      choiceHeaders: null,
      isMergedObject: false,
      isMergedMap: false,
      isMergedList: false,
      isMergedObjectProperties: false,
    );
    loopBody.addAll(
      valueModel is ListModel
          ? _listItems(
              part,
              valueModel,
              _part(_withValue(part, refer('item')), itemModel),
            )
          : _part(part, itemModel),
    );
    emissions.addAll(
      _loop(
        r'_$multipartEntry',
        refer(r'_$multipartMap').property('entries'),
        loopBody,
      ),
    );
    return emissions;
  }

  List<MultipartEmission> _part(_Part part, Model model) {
    if (model is MultipartChoiceModel) {
      return _choicePart(part, model);
    }
    if (part.encoding.isStyleBased &&
        (model is BinaryModel || model is Base64Model)) {
      return _error(
        'Multipart property "${part.name}" cannot encode file content '
        'with style-based encoding.',
      );
    }
    if (part.encoding.isStyleBased && model is AnyModel) {
      return [
        _text(
          part,
          refer(
            'multipartTextValue',
            'package:tonik_util/tonik_util.dart',
          ).call([part.value]),
          contentType: 'text/plain',
        ),
      ];
    }
    final contentType = part.encoding.contentType;
    if (!part.encoding.isStyleBased) {
      if (contentType == ContentType.bytes &&
          model is! BinaryModel &&
          model is! Base64Model &&
          model is! ListModel) {
        return _error(
          'Multipart property "${part.name}" requires binary input for '
          '${part.encoding.wireContentType}.',
        );
      }
      if (model is Base64Model && contentType != ContentType.bytes) {
        return _error(
          'Multipart property "${part.name}" cannot encode base64 file '
          'content as ${part.encoding.wireContentType}.',
        );
      }
      if (contentType == ContentType.multipart &&
          model is! BinaryModel &&
          !(model is ListModel && model.content.resolved is BinaryModel)) {
        return _error(
          'Multipart property "${part.name}" cannot encode '
          '${part.encoding.wireContentType} without binary input.',
        );
      }
      if (contentType == ContentType.form &&
          (model is PrimitiveModel &&
                  model is! BinaryModel &&
                  model is! Base64Model ||
              model is EnumModel ||
              model is AnyModel)) {
        return _error(
          'Multipart property "${part.name}" cannot be encoded as '
          '${part.encoding.wireContentType} from ${model.runtimeType}.',
        );
      }
      if (contentType == ContentType.text) {
        if (model is AnyModel) {
          return [
            _text(
              part,
              refer(
                'multipartTextValue',
                'package:tonik_util/tonik_util.dart',
              ).call([part.value]),
            ),
          ];
        }
        if (model is ClassModel ||
            model is CompositeModel ||
            model is MapModel) {
          return _error(
            'Multipart property "${part.name}" cannot be encoded as '
            '${part.encoding.wireContentType}: its value is complex.',
          );
        }
      }
      if (contentType == ContentType.json) {
        if (model is StringModel) {
          return [_text(part, _json(part.value))];
        }
        if (model is EnumModel) {
          return [_text(part, _json(part.value.property('toJson').call([])))];
        }
      }
    }
    return switch (model) {
      BinaryModel() => _file(part),
      Base64Model() => [_base64(part)],
      ListModel() => _list(part, model),
      NeverModel() => _error(
        "Cannot encode NeverModel property '${part.name}' - this type does not "
        'permit any value.',
      ),
      StringModel() => [_text(part, part.value)],
      AnyModel() => [
        _text(part, _json(_anyJson(part.value)), fallback: 'application/json'),
      ],
      MapModel() => _map(part, model),
      ClassModel() || CompositeModel() => _object(part),
      EnumModel() => [_text(part, _enum(part.value, model, part.encoding))],
      PrimitiveModel() => [
        _text(part, _primitive(part.value, model, part.encoding)),
      ],
      NamedModel() => _error(
        "Cannot encode cyclic AliasModel property '${part.name}'.",
      ),
    };
  }

  Expression _matchingMediaChoice(
    Expression selected,
    PartEncoding encoding,
    Model model,
  ) {
    final textBytes =
        model is! BinaryModel &&
        model is! Base64Model &&
        (encoding.contentType == ContentType.text ||
            encoding.contentType == ContentType.json ||
            encoding.contentType == ContentType.form);
    final charset = switch (encoding.textEncoding) {
      TextEncoding.utf8 => 'utf-8',
      TextEncoding.latin1 => 'iso-8859-1',
      TextEncoding.ascii => 'us-ascii',
    };
    return refer(
      'matchesConcreteMediaTypeChoice',
      'package:tonik_util/tonik_util.dart',
    ).call(
      [
        selected,
        specLiteralString(encoding.wireContentType ?? encoding.rawContentType!),
      ],
      {
        if (textBytes) 'encodedCharset': specLiteralString(charset),
        if (encoding.contentType == ContentType.multipart)
          'requireBoundary': literalTrue,
      },
    );
  }

  List<MultipartEmission> _choicePart(_Part part, MultipartChoiceModel model) {
    final manager = nameManager;
    final packageName = package;
    if (manager == null || packageName == null) {
      return _error('Multipart media choices require generated model names.');
    }
    final models = {model, ...part.choiceModels};
    final result = <MultipartEmission>[
      MultipartCode(
        Block.of([const Code('switch ('), part.value.code, const Code(') {')]),
      ),
    ];
    for (final (modelIndex, choiceModel) in models.indexed) {
      final className = manager.modelName(choiceModel);
      final url = sourceFileUrl(packageName, 'model', className);
      for (final (index, member) in choiceModel.models.indexed) {
        final encoding = choiceModel.choices[index];
        final callerWireType = encoding.requiresWireContentType;
        final rejectsNestedText =
            encoding.contentType == ContentType.text &&
            member.model.resolved is ListModel;
        final variant = manager.generateVariantName(
          parentClassName: className,
          model: member.model,
          discriminatorValue: member.discriminatorValue,
        );
        result.add(
          MultipartCode(
            Block.of([
              const Code('case '),
              refer(variant, url).code,
              if (callerWireType && rejectsNestedText)
                const Code('(:final wireContentType):')
              else if (callerWireType)
                const Code('(:final value, :final wireContentType):')
              else if (rejectsNestedText)
                const Code('():')
              else
                const Code('(:final value):'),
            ]),
          ),
        );
        final choiceHeaders = part.choiceHeaders;
        final headers = choiceHeaders == null
            ? part.headers
            : _headers(
                choiceHeaders.encoding,
                part.normalizedName,
                choiceHeaders.parameters,
                choiceHeaders.nullable,
                result,
                base64: member.model.resolved is Base64Model,
                variableSuffix: 'Choice${modelIndex}Variant$index',
              );
        if (callerWireType) {
          result.add(
            MultipartCode(
              Block.of([
                const Code('if (!'),
                _matchingMediaChoice(
                  refer('wireContentType'),
                  encoding,
                  member.model.resolved,
                ).code,
                const Code(') {'),
                generateEncodingExceptionExpression(
                  'Multipart property "${part.name}" requires a matching '
                  'concrete Content-Type.',
                  raw: true,
                ).statement,
                const Code('}'),
              ]),
            ),
          );
        }
        if (member.model.isEffectivelyNullable) {
          result.add(
            MultipartCode(
              Block.of([
                const Code('if (value == null) {'),
                generateEncodingExceptionExpression(
                  'Selected media choice for multipart property '
                  '"${part.name}" is null.',
                  raw: true,
                ).statement,
                const Code('}'),
              ]),
            ),
          );
        }
        final selectedPart = (
          name: part.name,
          wireName: part.wireName,
          preserveOrder: part.preserveOrder,
          normalizedName: part.normalizedName,
          value: refer('value'),
          encoding: encoding,
          headers: headers,
          selectedContentType: callerWireType ? refer('wireContentType') : null,
          choiceModels: const <MultipartChoiceModel>[],
          choiceHeaders: null,
          isMergedObject: part.isMergedObject,
          isMergedMap: part.isMergedMap,
          isMergedList: part.isMergedList,
          isMergedObjectProperties: part.isMergedObjectProperties,
        );
        result.addAll(
          rejectsNestedText
              ? _error(
                  'Multipart property "${part.name}" cannot encode a nested '
                  'array as ${encoding.wireContentType}.',
                )
              : encoding.contentType == ContentType.json &&
                    member.model.resolved is ListModel
              ? _jsonPart(
                  selectedPart,
                  member.model.resolved,
                  immutable: useImmutableCollections,
                )
              : _part(selectedPart, member.model.resolved),
        );
      }
    }
    if (models.length > 1) {
      result.add(
        MultipartCode(
          Block.of([
            const Code('default:'),
            generateEncodingExceptionExpression(
              'Multipart property "${part.name}" has an '
              'unrecognized media choice.',
              raw: true,
            ).statement,
          ]),
        ),
      );
    }
    result.add(const MultipartCode(Code('}')));
    return result;
  }

  MultipartAppend _text(
    _Part part,
    Expression text, {
    String fallback = 'text/plain',
    String? contentType,
    bool omitContentType = false,
    bool field = false,
    Expression? name,
  }) {
    final encoding = part.encoding.isStyleBased
        ? TextEncoding.utf8
        : part.encoding.textEncoding;
    final plain = _dio && encoding == TextEncoding.utf8;
    return MultipartAppend(
      name: name ?? part.wireName,
      value: plain
          ? text
          : textEncodingExpression(encoding).property('encode').call([text]),
      source: plain
          ? (field && !part.preserveOrder && part.headers == null
                ? MultipartValueSource.field
                : MultipartValueSource.text)
          : MultipartValueSource.bytes,
      contentType: omitContentType
          ? null
          : part.encoding.isStyleBased
          ? (_dio ? 'text/plain' : 'text/plain; charset=utf-8')
          : contentType ?? part.encoding.wireContentType ?? fallback,
      contentTypeExpression: omitContentType ? null : part.selectedContentType,
      headers: part.headers,
    );
  }

  List<MultipartEmission> _file(_Part part) {
    final contentType =
        part.encoding.wireContentType ?? 'application/octet-stream';
    if (!_dio) {
      return [
        MultipartAppend(
          name: part.wireName,
          value: part.value,
          source: MultipartValueSource.file,
          filename: part.value.property('fileName').ifNullThen(part.wireName),
          contentType: contentType,
          contentTypeExpression: part.selectedContentType,
          headers: part.headers,
        ),
      ];
    }
    final filename = refer('fileName').ifNullThen(part.wireName);
    return [
      MultipartCode(
        Block.of([
          const Code('switch ('),
          part.value.code,
          const Code(') { case '),
          refer('TonikFileBytes', 'package:tonik_util/tonik_util.dart').code,
          const Code('(:final bytes, :final fileName):'),
        ]),
      ),
      MultipartAppend(
        name: part.wireName,
        value: refer('bytes'),
        source: MultipartValueSource.bytes,
        filename: filename,
        contentType: contentType,
        contentTypeExpression: part.selectedContentType,
        headers: part.headers,
      ),
      MultipartCode(
        Block.of([
          const Code('case '),
          refer('TonikFilePath', 'package:tonik_util/tonik_util.dart').code,
          const Code('(:final path, :final fileName):'),
        ]),
      ),
      MultipartAppend(
        name: part.wireName,
        value: refer('path'),
        source: MultipartValueSource.path,
        filename: filename,
        contentType: contentType,
        contentTypeExpression: part.selectedContentType,
        headers: part.headers,
      ),
      const MultipartCode(Code('}')),
    ];
  }

  MultipartAppend _base64(_Part part) => MultipartAppend(
    name: part.wireName,
    value: refer(
      'ascii',
      'dart:convert',
    ).property('encode').call([part.value.property('toBase64String').call([])]),
    source: MultipartValueSource.bytes,
    filename: part.value.property('fileName').ifNullThen(part.wireName),
    contentType: part.encoding.wireContentType ?? 'application/octet-stream',
    contentTypeExpression: part.selectedContentType,
    headers: part.headers,
  );

  List<MultipartEmission> _list(_Part part, ListModel model) {
    final encoding = part.encoding;
    final item = model.content.resolved;
    final itemNullable =
        model.isContentNullable || multipartModelIsNullable(model.content);
    final contentBased =
        !encoding.isStyleBased &&
        encoding.contentType != null &&
        encoding.contentType != ContentType.text;
    if (encoding.style == EncodingStyle.deepObject) {
      return _error(
        'deepObject style is not supported for array multipart '
        'properties (property: ${part.name}).',
      );
    }
    final itemPart = _withValue(part, refer('item'));
    if (item is MultipartChoiceModel) {
      return _listItems(part, model, _part(itemPart, item));
    }
    if (item is ListModel) {
      if (encoding.isStyleBased) {
        return _error(
          'Multipart property "${part.name}" cannot encode a nested array '
          'with style-based encoding.',
        );
      }
      if (contentBased && encoding.contentType == ContentType.json) {
        return _listItems(
          part,
          model,
          _jsonPart(itemPart, item, immutable: useImmutableCollections),
        );
      }
      if (!encoding.isStyleBased && encoding.contentType == ContentType.text) {
        return _error(
          'Multipart property "${part.name}" cannot encode a nested array '
          'as ${encoding.wireContentType}.',
        );
      }
      if (!_dio || contentBased) {
        return _error(
          'Arrays of arrays are not supported for multipart encoding '
          '(property: ${part.name}).',
        );
      }
    }
    if (item is AliasModel) {
      return _error(
        'Cannot encode cyclic AliasModel list items for multipart '
        "property '${part.name}'.",
      );
    }
    if (item is Base64Model) {
      if (encoding.isStyleBased) {
        return _error(
          'Multipart property "${part.name}" cannot encode file content '
          'with style-based encoding.',
        );
      }
      if (!encoding.isStyleBased && encoding.contentType != ContentType.bytes) {
        return _error(
          'Multipart property "${part.name}" cannot encode base64 file '
          'content as ${encoding.wireContentType}.',
        );
      }
      return _listItems(part, model, [_base64(itemPart)]);
    }
    if (item is BinaryModel) {
      if (encoding.isStyleBased) {
        return _error(
          'Multipart property "${part.name}" cannot encode file content '
          'with style-based encoding.',
        );
      }
      return _listItems(part, model, _file(itemPart));
    }
    if (!encoding.isStyleBased &&
        encoding.contentType == ContentType.text &&
        (item is AnyModel ||
            item is ClassModel ||
            item is CompositeModel ||
            item is MapModel)) {
      return _listItems(part, model, _part(itemPart, item));
    }
    if (contentBased) {
      if (encoding.contentType != ContentType.json &&
          encoding.contentType != ContentType.bytes) {
        return _error(
          'Unsupported contentType "${encoding.rawContentType ?? ''}" '
          'for array multipart property "${part.name}". Only application/json '
          'is supported for content-based array serialization.',
        );
      }
      return _listItems(part, model, _part(itemPart, item));
    }
    if (encoding.isStyleBased &&
        (item is ClassModel ||
            item is CompositeModel ||
            item is MapModel ||
            (item is AnyModel && (encoding.explode ?? true)))) {
      return _listItems(part, model, _part(itemPart, item));
    }
    if (!encoding.isStyleBased &&
        (item is ClassModel ||
            item is CompositeModel ||
            item is MapModel ||
            item is AnyModel)) {
      if (item is MapModel) {
        return _listItems(part, model, _map(itemPart, item));
      }
      final json = switch (item) {
        AnyModel() => _anyJson(refer('item')),
        _ => refer('item').property('toJson').call([]),
      };
      return _listItems(part, model, [
        _text(part, _json(json), fallback: 'application/json'),
      ]);
    }
    final itemText = _itemText(itemPart, item);
    if (encoding.explode ?? true) {
      return _listItems(part, model, [_listText(part, itemText)]);
    }
    final strings = itemNullable
        ? _mapped(
            part.value,
            item is StringModel
                ? refer('item').ifNullThen(literalString(''))
                : refer('item')
                      .equalTo(literalNull)
                      .conditional(literalString(''), itemText),
          )
        : item is StringModel
        ? part.value
        : _mapped(part.value, itemText);
    final delimiter = switch (encoding.style) {
      EncodingStyle.spaceDelimited => ' ',
      EncodingStyle.pipeDelimited => '|',
      _ => ',',
    };
    final serialized = strings.property('join').call([
      literalString(delimiter),
    ]);
    return [_listText(part, serialized)];
  }

  List<MultipartEmission> _listItems(
    _Part part,
    ListModel model,
    List<MultipartEmission> body,
  ) => _loop('item', part.value, [
    if (model.isContentNullable || multipartModelIsNullable(model.content))
      const MultipartCode(Code('if (item == null) continue;')),
    ...body,
  ]);

  MultipartAppend _listText(_Part part, Expression text) => _text(
    part,
    text,
    contentType: part.encoding.isStyleBased ? 'text/plain' : null,
  );

  Expression _itemText(_Part part, Model model) {
    if (model is StringModel) return part.value;
    if (model is AnyModel) {
      return refer(
        'multipartTextValue',
        'package:tonik_util/tonik_util.dart',
      ).call([part.value]);
    }
    if (model is EnumModel) {
      return _enum(part.value, model, part.encoding);
    }
    return _primitive(part.value, model, part.encoding);
  }

  Expression _enum(
    Expression value,
    EnumModel<dynamic> model,
    PartEncoding encoding,
  ) {
    final json = value.property('toJson').call([]);
    if (!_dio &&
        !encoding.isStyleBased &&
        encoding.contentType == ContentType.json) {
      return _json(json);
    }
    return model is EnumModel<String>
        ? json
        : json.property('toString').call([]);
  }

  Expression _primitive(Expression value, Model model, PartEncoding encoding) {
    if (!encoding.isStyleBased &&
        encoding.contentType == ContentType.json &&
        model is PrimitiveModel) {
      final jsonValue = switch (model) {
        DateTimeModel() => value.property('toTimeZonedIso8601String').call([]),
        DateModel() => value.property('toJson').call([]),
        DecimalModel() || UriModel() => value.property('toString').call([]),
        _ => value,
      };
      return _json(jsonValue);
    }
    return value
        .property(
          model is DateTimeModel ? 'toTimeZonedIso8601String' : 'toString',
        )
        .call([]);
  }

  List<MultipartEmission> _map(_Part part, MapModel model) {
    if (part.encoding.isStyleBased) {
      if (part.encoding.style != EncodingStyle.form &&
          part.encoding.style != EncodingStyle.deepObject) {
        return _error(
          '${part.encoding.style?.name ?? 'unknown'} style is not '
          'supported for map multipart part ${part.name}',
        );
      }
      final value = useImmutableCollections && !part.isMergedMap
          ? part.value.property('unlock')
          : part.value;
      final valueModel = model.valueModel.resolved;
      final Expression encodedValue;
      if (valueModel is ListModel) {
        final itemModel = valueModel.content.resolved;
        if (!_mapStyleSupportsText(itemModel)) {
          return _error(
            'Multipart property "${part.name}" cannot style-encode '
            'complex map array values.',
          );
        }
        final item = refer('item');
        final itemText = _mapStyleText(item, itemModel);
        final rawItems = refer('value')
            .asA(refer('Iterable', 'dart:core'))
            .property('map')
            .call([
              Method(
                (b) => b
                  ..lambda = true
                  ..requiredParameters.add(Parameter((p) => p..name = 'item'))
                  ..body = item
                      .equalTo(literalNull)
                      .conditional(literalString(''), itemText)
                      .code,
              ).closure,
            ])
            .property('toList')
            .call([]);
        encodedValue = refer(
          'PropertyValue',
          'package:tonik_util/tonik_util.dart',
        ).property('array').call([rawItems]);
      } else if (_mapStyleSupportsText(valueModel)) {
        encodedValue = refer(
          'PropertyValue',
          'package:tonik_util/tonik_util.dart',
        ).property('scalar').call([_mapStyleText(refer('value'), valueModel)]);
      } else {
        return _error(
          'Multipart property "${part.name}" cannot style-encode '
          'complex map values.',
        );
      }
      final entries =
          refer(
            'multipartMapStyleParts',
            'package:tonik_util/tonik_util.dart',
          ).call(
            [value, part.wireName],
            {
              'explode': literalBool(part.encoding.explode ?? true),
              'deepObject': literalBool(
                part.encoding.style == EncodingStyle.deepObject,
              ),
              'encodeValue': Method(
                (b) => b
                  ..lambda = true
                  ..requiredParameters.add(Parameter((p) => p..name = 'value'))
                  ..body = encodedValue.code,
              ).closure,
            },
          );
      return _loop('entry', entries, [
        _text(
          part,
          refer('entry').property('value'),
          name: refer('entry').property('name'),
          contentType: 'text/plain',
        ),
      ]);
    }
    if (!part.encoding.isStyleBased &&
        part.encoding.contentType == ContentType.form) {
      return _urlEncodedMap(part);
    }
    if (!part.isMergedMap) {
      return _jsonPart(part, model, immutable: useImmutableCollections);
    }
    return [_text(part, _json(part.value), fallback: 'application/json')];
  }

  bool _mapStyleSupportsText(Model model) => switch (model) {
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() ||
    EnumModel() ||
    AnyModel() => true,
    _ => false,
  };

  Expression _mapStyleText(Expression value, Model model) => switch (model) {
    AnyModel() || StringModel() => refer(
      'multipartTextValue',
      'package:tonik_util/tonik_util.dart',
    ).call([value]),
    DateTimeModel() =>
      value
          .asA(refer('DateTime', 'dart:core'))
          .property('toTimeZonedIso8601String')
          .call([]),
    EnumModel<String>() =>
      value.asA(refer('dynamic', 'dart:core')).property('toJson').call([]),
    EnumModel() =>
      value
          .asA(refer('dynamic', 'dart:core'))
          .property('toJson')
          .call([])
          .property('toString')
          .call([]),
    _ => value.property('toString').call([]),
  };

  List<MultipartEmission> _jsonPart(
    _Part part,
    Model model, {
    required bool immutable,
  }) {
    final encoded = buildToJsonModelExpression(
      part.value,
      model,
      nameManager:
          nameManager ??
          NameManager(
            generator: NameGenerator(),
            stableModelSorter: StableModelSorter(),
          ),
      package: package,
      useImmutableCollections: immutable,
    );
    return [
      if (encoded.inlineFunctions.isNotEmpty) const MultipartCode(Code('{')),
      for (final code in spliceInlineHelpers(encoded.inlineFunctions))
        MultipartCode(code),
      _text(part, _json(encoded.unsafeRawBody), fallback: 'application/json'),
      if (encoded.inlineFunctions.isNotEmpty) const MultipartCode(Code('}')),
    ];
  }

  List<MultipartEmission> _object(_Part part) {
    final encoding = part.encoding;
    if (encoding.style == EncodingStyle.deepObject) {
      final entries =
          (part.isMergedObjectProperties
                  ? part.value
                  : part.value.property('parameterProperties').call([], {
                      'allowEmpty': literalTrue,
                    }))
              .property('toRawDeepObjectParts')
              .call([part.wireName]);
      return _loop('entry', entries, [
        _text(
          part,
          refer('entry').property('value'),
          name: refer('entry').property('name'),
          contentType: 'text/plain',
        ),
      ]);
    }
    if (encoding.isStyleBased) {
      if (encoding.style != EncodingStyle.form &&
          (!_dio || encoding.style != null)) {
        return _error(
          '${encoding.style?.name ?? 'unknown'} style is not '
          'supported for object multipart part ${part.name}',
        );
      }
      final entries =
          (part.isMergedObjectProperties
                  ? part.value
                  : part.value.property('parameterProperties').call([], {
                      'allowEmpty': literalTrue,
                    }))
              .property('toRawStyleParts')
              .call(
                [part.wireName],
                {'explode': literalBool(encoding.explode ?? true)},
              );
      final variable = _dio ? r'_$part' : 'entry';
      final partsVariable = '${part.normalizedName}RawParts';
      return [
        if (_dio)
          MultipartCode(declareFinal(partsVariable).assign(entries).statement),
        ..._loop(variable, _dio ? refer(partsVariable) : entries, [
          _text(
            part,
            refer(variable).property('value'),
            name: refer(variable).property('name'),
            contentType: 'text/plain',
          ),
        ]),
      ];
    }
    if (encoding.contentType == ContentType.form) {
      final entries = part.value
          .property('toForm')
          .call(
            [part.wireName],
            {
              'explode': literalTrue,
              'allowEmpty': literalTrue,
              'useQueryComponent': literalTrue,
              'textEncoding': textEncodingExpression(encoding.textEncoding),
            },
          );
      final variable = '${part.normalizedName}Entries';
      final joined = (_dio ? refer(variable) : entries)
          .property('map')
          .call([
            Method(
              (b) => b
                ..lambda = true
                ..requiredParameters.add(
                  Parameter((p) => p..name = _dio ? 'e' : 'entry'),
                )
                ..body = _dio
                    ? const Code(r"'${e.name}=${e.value}'")
                    : const Code(r"'${entry.name}=${entry.value}'"),
            ).closure,
          ])
          .property('join')
          .call([literalString('&')]);
      return [
        if (_dio)
          MultipartCode(declareFinal(variable).assign(entries).statement),
        _text(part, joined, fallback: 'application/x-www-form-urlencoded'),
      ];
    }
    return [
      _text(
        part,
        _json(
          part.isMergedObject
              ? part.value
              : part.value.property('toJson').call([]),
        ),
        fallback: 'application/json',
      ),
    ];
  }

  List<MultipartEmission> _urlEncodedMap(_Part part) {
    final encoding = textEncodingExpression(part.encoding.textEncoding);
    final variable = '${part.normalizedName}Parts';
    return [
      MultipartCode(
        declareFinal(variable)
            .assign(literalList([], refer('String', 'dart:core')))
            .statement,
      ),
      MultipartCode(
        Block.of([
          const Code('for (final entry in ('),
          part.value.asA(refer('Map', 'dart:core')).code,
          const Code(').entries) {'),
          declareFinal('value')
              .assign(refer('entry').property('value'))
              .statement,
          const Code('if (value == null) continue; if (value is '),
          refer('Map', 'dart:core').code,
          const Code(' || value is '),
          refer('List', 'dart:core').code,
          const Code(') { throw '),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart').code,
          Code(
            "('Standard URL encoding does not support nested values "
            "(property: ' ${specLiteralStringCode(part.name)} "
            r"', key: ${entry.key}). "
            "Only flat key=value pairs are allowed.');}",
          ),
          refer(variable).property('add').call([
            literalList([
              refer('entry')
                  .property('key')
                  .property('toString')
                  .call([])
                  .property('uriEncode')
                  .call([], {
                    'allowEmpty': literalTrue,
                    'useQueryComponent': literalTrue,
                    'textEncoding': encoding,
                  }),
              refer(
                'encodeAnyToForm',
                'package:tonik_util/tonik_util.dart',
              ).call(
                [refer('value')],
                {
                  'explode': literalTrue,
                  'allowEmpty': literalTrue,
                  'useQueryComponent': literalTrue,
                  'textEncoding': encoding,
                },
              ),
            ]).property('join').call([literalString('=')]),
          ]).statement,
          const Code('}'),
        ]),
      ),
      _text(
        part,
        refer(variable).property('join').call([literalString('&')]),
        fallback: 'application/x-www-form-urlencoded',
      ),
    ];
  }

  Expression? _headers(
    PartEncoding? encoding,
    String normalizedName,
    List<MultipartHeaderParamInfo> parameters,
    bool nullable,
    List<MultipartEmission> emissions, {
    required bool base64,
    String variableSuffix = '',
  }) {
    final headers = encoding?.headers?.entries
        .where((entry) => entry.key.toLowerCase() != 'content-type')
        .toList();
    if (!base64 && (headers == null || headers.isEmpty)) return null;
    final variable = '_\$${normalizedName}Headers$variableSuffix';
    emissions.add(
      MultipartCode(
        declareFinal(variable)
            .assign(
              literalMap(
                {
                  if (base64)
                    specLiteralString('Content-Transfer-Encoding'): _dio
                        ? literalList([specLiteralString('base64')])
                        : specLiteralString('base64'),
                },
                refer('String', 'dart:core'),
                _dio
                    ? TypeReference(
                        (b) => b
                          ..symbol = 'List'
                          ..url = 'dart:core'
                          ..types.add(refer('String', 'dart:core')),
                      )
                    : refer('String', 'dart:core'),
              ),
            )
            .statement,
      ),
    );
    for (final entry in headers ?? <MapEntry<String, ResponseHeader>>[]) {
      final header = entry.value.resolve();
      final parameter = parameters.firstWhere(
        (parameter) =>
            parameter.normalizedPropertyName == normalizedName &&
            parameter.rawHeaderName == entry.key,
      );
      final parameterValue = nullable && header.isRequired
          ? refer(parameter.name).nullChecked
          : refer(parameter.name);
      final serialized = buildSimpleValueExpression(
        parameterValue,
        header.model,
        explode: header.explode,
        allowEmpty: true,
      );
      final assignment =
          base64 && entry.key.toLowerCase() == 'content-transfer-encoding'
          ? Block.of([
              const Code('if ('),
              serialized.unsafeRawBody.parenthesized
                  .property('toLowerCase')
                  .call([])
                  .code,
              const Code(" != 'base64') {"),
              generateEncodingExceptionExpression(
                'Multipart property "$normalizedName" requires '
                'Content-Transfer-Encoding: base64.',
                raw: true,
              ).statement,
              const Code('}'),
            ])
          : refer(variable)
                .index(specLiteralString(entry.key))
                .assign(
                  _dio
                      ? literalList([serialized.expression])
                      : serialized.unsafeRawBody,
                )
                .statement;
      emissions.add(
        MultipartCode(
          header.isRequired
              ? assignment
              : Block.of([
                  Code('if (${parameter.name} != null) {'),
                  assignment,
                  const Code('}'),
                ]),
        ),
      );
    }
    return refer(variable);
  }

  String? _incompatibleDefinitionsError(MultipartPropertyPlan property) {
    final first = property.properties.first.model;
    for (final candidate in property.properties.skip(1)) {
      if (!_compatibleModels(first, candidate.model, <(Model, Model)>{})) {
        return 'Multipart property "${property.rawName}" has incompatible '
            'definitions (${first.runtimeType} and '
            '${candidate.model.runtimeType}).';
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
      if (left is MultipartChoiceModel && right is MultipartChoiceModel) {
        return left.choices.length == right.choices.length &&
            left.models.length == right.models.length &&
            left.choices.indexed.every(
              (entry) => entry.$2 == right.choices[entry.$1],
            ) &&
            left.models.indexed.every(
              (entry) => _compatibleChoiceMembers(
                entry.$2.model,
                right.models[entry.$1].model,
                left.choices[entry.$1].contentType,
                active,
              ),
            );
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
                  leftProperty.isNullable ||
                  multipartModelIsNullable(leftProperty.model);
              final rightNullable =
                  rightProperty.isNullable ||
                  multipartModelIsNullable(rightProperty.model);
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

  bool _compatibleChoiceMembers(
    Model left,
    Model right,
    ContentType? contentType,
    Set<(Model, Model)> active,
  ) {
    final leftModel = left.resolved;
    final rightModel = right.resolved;
    if (leftModel is BinaryModel ||
        rightModel is BinaryModel ||
        leftModel is Base64Model ||
        rightModel is Base64Model) {
      return leftModel.runtimeType == rightModel.runtimeType;
    }
    final leftScalar = leftModel is PrimitiveModel || leftModel is EnumModel;
    final rightScalar = rightModel is PrimitiveModel || rightModel is EnumModel;
    if ((contentType == ContentType.json || contentType == ContentType.text) &&
        leftScalar &&
        rightScalar) {
      return true;
    }
    return _compatibleModels(left, right, active);
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
    return multipartModelIsNullable(leftAllowed.valueModel) ==
            multipartModelIsNullable(rightAllowed.valueModel) &&
        _compatibleModels(
          leftAllowed.valueModel,
          rightAllowed.valueModel,
          active,
        );
  }
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

typedef _ChoiceHeaders = ({
  PartEncoding? encoding,
  List<MultipartHeaderParamInfo> parameters,
  bool nullable,
});

typedef _Part = ({
  String name,
  Expression wireName,
  bool preserveOrder,
  String normalizedName,
  Expression value,
  PartEncoding encoding,
  Expression? headers,
  Expression? selectedContentType,
  List<MultipartChoiceModel> choiceModels,
  _ChoiceHeaders? choiceHeaders,
  bool isMergedObject,
  bool isMergedMap,
  bool isMergedList,
  bool isMergedObjectProperties,
});

_Part _withValue(_Part part, Expression value) => (
  name: part.name,
  wireName: part.wireName,
  preserveOrder: part.preserveOrder,
  normalizedName: part.normalizedName,
  value: value,
  encoding: part.encoding,
  headers: part.headers,
  selectedContentType: part.selectedContentType,
  choiceModels: part.choiceModels,
  choiceHeaders: part.choiceHeaders,
  isMergedObject: part.isMergedObject,
  isMergedMap: part.isMergedMap,
  isMergedList: part.isMergedList,
  isMergedObjectProperties: part.isMergedObjectProperties,
);

Expression _objectMergeValue(
  Expression value, {
  required bool nullable,
  required bool asProperties,
}) {
  final member = asProperties ? 'parameterProperties' : 'toJson';
  return nullable
      ? value
            .nullSafeProperty(member)
            .call([], asProperties ? {'allowEmpty': literalTrue} : const {})
      : value
            .property(member)
            .call([], asProperties ? {'allowEmpty': literalTrue} : const {});
}

Expression _immutableMergeValue(Expression value, {required bool nullable}) =>
    nullable ? value.nullSafeProperty('unlock') : value.property('unlock');

Expression _access(Expression root, List<MultipartAccessSegment> path) {
  var result = root;
  for (final segment in path) {
    result = segment.receiverNullable
        ? result.nullSafeProperty(segment.name)
        : result.property(segment.name);
  }
  return result;
}

bool _occurrenceIsNullable(
  List<MultipartAccessSegment> path,
  Property property,
) =>
    path.any((segment) => segment.receiverNullable) ||
    property.isNullable ||
    multipartModelIsNullable(property.model) ||
    !property.isRequired ||
    property.isWriteOnly;

Expression _json(Expression value) =>
    refer('jsonEncode', 'dart:convert').call([value]);
Expression _anyJson(Expression value) => refer(
  'encodeAnyToJson',
  'package:tonik_util/tonik_util.dart',
).call([value]);
Expression _mapped(
  Expression value,
  Expression item, {
  String variable = 'item',
}) => value
    .property('map')
    .call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p..name = variable))
          ..body = item.code,
      ).closure,
    ])
    .property('toList')
    .call([]);

List<MultipartEmission> _error(String message) => [
  MultipartCode(
    generateEncodingExceptionExpression(message, raw: true).statement,
  ),
];

List<MultipartEmission> _loop(
  String variable,
  Expression values,
  List<MultipartEmission> body,
) => [
  MultipartCode(
    Block.of([
      Code('for (final $variable in '),
      values.code,
      const Code(') {'),
    ]),
  ),
  ...body,
  const MultipartCode(Code('}')),
];
