import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/dio/dio_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_planner.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/text_encoding_expression.dart';
import 'package:tonik_generate/src/util/to_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating data method for operations.
class DioDataGenerator {
  const DioDataGenerator({
    required this.nameManager,
    required this.package,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final bool useImmutableCollections;

  /// Generates a data expression for the operation.
  Method generateDataMethod(Operation operation, {RequestBodyPlan? bodyPlan}) {
    final requestBody = operation.requestBody;
    if (requestBody == null || requestBody.resolvedContent.isEmpty) {
      return Method(
        (b) => b
          ..name = '_data'
          ..returns = refer('Object?', 'dart:core')
          ..lambda = false
          ..body = const Code('return null;'),
      );
    }

    final content = requestBody.resolvedContent;
    final hasMultipleContent = content.length > 1;
    final isRequired = requestBody.isRequired;
    final multipartHeaderInfo = extractOperationMultipartHeaderParamInfo(
      operation,
    );
    bodyPlan ??= const OperationRequestPlanner(
      backend: TransportBackend.dio,
    ).planBody(operation);

    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];

    if (hasMultipleContent) {
      final hasMultipartArm = content.any(
        (c) => c.contentType == ContentType.multipart,
      );

      final requestBodyBaseName = nameManager.requestBodyNames(requestBody).$1;
      final parameterType = TypeReference(
        (b) => b
          ..symbol = requestBodyBaseName
          ..url = sourceFileUrl(package, 'request_body', requestBodyBaseName)
          ..isNullable = !isRequired,
      );

      final switchCases = <Code>[];
      for (final c in content) {
        final variantName = nameManager
            .requestBodyNames(requestBody)
            .$2[c.rawContentType]!;

        final requestBodyUrl = sourceFileUrl(
          package,
          'request_body',
          nameManager.requestBodyNames(requestBody).$1,
        );
        switchCases
          ..add(const Code('final '))
          ..add(refer(variantName, requestBodyUrl).code);

        switch (c) {
          case ModelRequestContent(contentType: .text):
            switchCases
              ..add(const Code(' value => '))
              ..add(
                requestTextBytesExpression(
                  c.textEncoding,
                  const CodeExpression(Code('value')).property('value'),
                ).code,
              )
              ..add(const Code(','));
          case ModelRequestContent(contentType: .bytes):
            switch (c.model) {
              case BinaryModel():
                switchCases.add(const Code(' value => value.value.toBytes(),'));
              case PrimitiveModel():
                switchCases.add(const Code(' value => value.value,'));
              case AliasModel() ||
                  ListModel() ||
                  ClassModel() ||
                  EnumModel() ||
                  AllOfModel() ||
                  OneOfModel() ||
                  AnyOfModel() ||
                  AnyModel() ||
                  NeverModel() ||
                  NamedModel() ||
                  CompositeModel():
                switchCases
                  ..add(const Code(' _ => '))
                  ..add(
                    generateEncodingExceptionExpression(
                      'Unsupported model for bytes content type.',
                    ).code,
                  )
                  ..add(const Code(','));
            }
          case ModelRequestContent(contentType: .json):
            final jsonBuilt = buildToJsonPropertyExpression(
              'value.value',
              Property(
                name: 'value',
                model: c.model,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                defaultValue: null,
                examples: const [],
              ),
              nameManager: nameManager,
              package: package,
              helperContext: helperContext,
              contextClass: operation.operationId,
              contextProperty: 'body',
            );
            inlineHelpers.addAll(jsonBuilt.inlineFunctions);
            switchCases
              ..add(const Code(' value => '))
              ..add(_jsonRequestBodyExpression(jsonBuilt, c.model).code)
              ..add(const Code(','));
          case ModelRequestContent(contentType: .form):
            switchCases
              ..add(const Code(' value => '))
              ..add(
                buildToFormValueExpression(
                  'value.value',
                  c.model,
                  useQueryComponent: true,
                  textEncoding: c.textEncoding,
                  encoding: c.formEncoding,
                ).code,
              )
              ..add(const Code(','));
          case MultipartRequestContent():
            final multipartPlan =
                (bodyPlan as BodySelectionPlan).variants.firstWhere(
                      (variant) => variant.rawContentType == c.rawContentType,
                    )
                    as MultipartBodyPlan;
            switchCases
              ..add(
                Code(multipartPlan.emissions.isEmpty ? ' _ => ' : ' value => '),
              )
              ..add(
                buildMultipartBodyExpression(multipartPlan).code,
              )
              ..add(const Code(','));
          case ModelRequestContent(contentType: .multipart):
            throw StateError('Multipart content must own parts.');
        }
      }

      final multipartHeaderParams = <Parameter>[];
      for (final info in multipartHeaderInfo) {
        multipartHeaderParams.add(
          Parameter(
            (b) => b
              ..name = info.name
              ..type = typeReference(
                info.model,
                nameManager,
                package,
                isNullableOverride: !info.isRequired,
                useImmutableCollections: useImmutableCollections,
              )
              ..named = true
              ..required = info.isRequired,
          ),
        );
      }

      return Method(
        (b) => b
          ..name = '_data'
          ..returns = hasMultipartArm
              ? TypeReference(
                  (b) => b
                    ..symbol = 'Future'
                    ..url = 'dart:async'
                    ..types.add(refer('Object?', 'dart:core')),
                )
              : refer('Object?', 'dart:core')
          ..modifier = hasMultipartArm ? MethodModifier.async : null
          ..optionalParameters.add(
            Parameter(
              (b) => b
                ..name = 'body'
                ..type = parameterType
                ..named = true
                ..required = isRequired,
            ),
          )
          ..optionalParameters.addAll(multipartHeaderParams)
          ..lambda = false
          ..body = Block.of([
            if (!isRequired) const Code('if (body == null) return null;\n'),
            ...spliceInlineHelpers(inlineHelpers),
            const Code('return switch (body) {'),
            ...switchCases,
            const Code('\n};'),
          ]),
      );
    }

    final item = content.first;
    if (item is MultipartRequestContent) {
      return Method(
        (b) => b
          ..name = '_data'
          ..returns = TypeReference(
            (t) => t
              ..symbol = 'Future'
              ..url = 'dart:async'
              ..types.add(refer('Object?', 'dart:core')),
          )
          ..modifier = MethodModifier.async
          ..optionalParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = requestContentTypeReference(
                  item,
                  nameManager,
                  package,
                  isNullableOverride: !isRequired,
                  useImmutableCollections: useImmutableCollections,
                )
                ..named = true
                ..required = isRequired,
            ),
          )
          ..optionalParameters.addAll(
            multipartHeaderInfo.map(
              (info) => Parameter(
                (p) => p
                  ..name = info.name
                  ..type = typeReference(
                    info.model,
                    nameManager,
                    package,
                    isNullableOverride: !info.isRequired,
                  )
                  ..named = true
                  ..required = info.isRequired,
              ),
            ),
          )
          ..lambda = false
          ..body = Block.of([
            if (!isRequired) const Code('if (body == null) return null;'),
            ...buildMultipartBodyStatements(
              bodyPlan! as MultipartBodyPlan,
            ).statements,
          ]),
      );
    }
    item as ModelRequestContent;
    final model = item.model;
    final contentType = item.contentType;
    final parameterType = typeReference(
      model,
      nameManager,
      package,
      isNullableOverride: !isRequired,
      useImmutableCollections: useImmutableCollections,
    );

    final property = Property(
      name: 'body',
      model: model,
      isRequired: isRequired,
      isNullable: !isRequired,
      isDeprecated: false,
      defaultValue: null,
      examples: const [],
    );

    final bodyCode = [const Code('return ')];
    switch (contentType) {
      case ContentType.text:
        bodyCode
          ..clear()
          ..addAll([
            if (!isRequired) const Code('if (body == null) return null;\n'),
            const Code('return '),
            requestTextBytesExpression(
              content.first.textEncoding,
              const CodeExpression(Code('body')),
            ).code,
            const Code(';'),
          ]);
      case ContentType.bytes:
        switch (model) {
          case BinaryModel():
            if (isRequired) {
              bodyCode.add(const Code('body.toBytes();'));
            } else {
              bodyCode.add(const Code('body?.toBytes();'));
            }
          case PrimitiveModel():
            bodyCode.add(const Code('body;'));
          case AliasModel() ||
              ListModel() ||
              ClassModel() ||
              EnumModel() ||
              AllOfModel() ||
              OneOfModel() ||
              AnyOfModel() ||
              AnyModel() ||
              NeverModel() ||
              NamedModel() ||
              CompositeModel():
            bodyCode
              ..add(
                generateEncodingExceptionExpression(
                  'Unsupported model for bytes content type.',
                ).code,
              )
              ..add(const Code(';'));
        }
      case ContentType.json:
        final encodesJsonRoot = _encodesJsonRoot(model);
        final jsonBuilt = buildToJsonPropertyExpression(
          'body',
          encodesJsonRoot && !isRequired
              ? Property(
                  name: 'body',
                  model: model,
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  defaultValue: null,
                  examples: const [],
                )
              : property,
          nameManager: nameManager,
          package: package,
          helperContext: helperContext,
          contextClass: operation.operationId,
          contextProperty: 'body',
        );
        inlineHelpers.addAll(jsonBuilt.inlineFunctions);
        if (encodesJsonRoot && !isRequired) {
          bodyCode.insert(0, const Code('if (body == null) return null;\n'));
        }
        bodyCode
          ..add(_jsonRequestBodyExpression(jsonBuilt, model).code)
          ..add(const Code(';'));
      case ContentType.form:
        final formExpr = buildToFormValueExpression(
          'body',
          model,
          useQueryComponent: true,
          textEncoding: content.first.textEncoding,
          encoding: item.formEncoding,
        );
        bodyCode
          ..clear()
          ..addAll([
            if (!isRequired) const Code('if (body == null) return null;\n'),
            const Code('return '),
            formExpr.code,
            const Code(';'),
          ]);
      case ContentType.multipart:
        throw StateError('Multipart content must own parts.');
    }

    return Method(
      (b) => b
        ..name = '_data'
        ..returns = refer('Object?', 'dart:core')
        ..optionalParameters.add(
          Parameter(
            (b) => b
              ..name = 'body'
              ..type = parameterType
              ..named = true
              ..required = isRequired,
          ),
        )
        ..lambda = false
        ..body = Block.of([
          ...spliceInlineHelpers(inlineHelpers),
          ...bodyCode,
        ]),
    );
  }
}

Expression _jsonRequestBodyExpression(BuiltExpression built, Model model) {
  final expression = built.unsafeRawBody;
  if (!_encodesJsonRoot(model)) return expression;
  return refer('jsonEncode', 'dart:convert').call([expression]);
}

bool _encodesJsonRoot(Model model) {
  final resolved = model.resolved;
  return switch (resolved) {
    StringModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel<String>() ||
    AnyModel() => true,
    final CompositeModel m => m.containedModels.any(_encodesJsonRoot),
    _ => false,
  };
}
