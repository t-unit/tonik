import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/data_method_generator.dart';
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

  Method generateDataMethod(Operation operation, {RequestBodyPlan? bodyPlan}) {
    final requestBody = operation.requestBody;
    if (requestBody == null || requestBody.resolvedContent.isEmpty) {
      return buildDataMethod(statements: [const Code('return null;')]);
    }

    final content = requestBody.resolvedContent;
    final isRequired = requestBody.isRequired;
    final headerInfo = extractOperationMultipartHeaderParamInfo(operation);
    bodyPlan ??= OperationRequestPlanner(
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
      backend: TransportBackend.dio,
    ).planBody(operation);
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];

    if (content.length > 1) {
      final (baseName, subclassNames) = nameManager.requestBodyNames(
        requestBody,
      );
      final requestBodyUrl = sourceFileUrl(package, 'request_body', baseName);
      final cases = <Code>[];
      for (final item in content) {
        final BuiltExpression built;
        final bool bindsValue;
        switch (item) {
          case MultipartRequestContent():
            final plan =
                (bodyPlan as BodySelectionPlan).variants.firstWhere(
                      (variant) =>
                          variant.rawContentType == item.rawContentType,
                    )
                    as MultipartBodyPlan;
            built = buildMultipartBodyExpression(plan);
            bindsValue = plan.emissions.isNotEmpty;
          case ModelRequestContent():
            built = _bodyExpression(
              operation: operation,
              content: item,
              valueName: 'value.value',
              propertyName: 'value',
              isRequired: true,
              helperContext: helperContext,
            );
            bindsValue =
                item.contentType != ContentType.bytes ||
                item.model is PrimitiveModel;
        }
        inlineHelpers.addAll(built.inlineFunctions);
        cases.addAll([
          const Code('final '),
          refer(subclassNames[item.rawContentType]!, requestBodyUrl).code,
          Code(bindsValue ? ' value => ' : ' _ => '),
          built.unsafeRawBody.code,
          const Code(','),
        ]);
      }
      return buildDataMethod(
        bodyType: TypeReference(
          (type) => type
            ..symbol = baseName
            ..url = requestBodyUrl
            ..isNullable = !isRequired,
        ),
        isRequired: isRequired,
        isAsync: content.any((item) => item is MultipartRequestContent),
        headerParameters: buildMultipartHeaderParameters(
          headerInfo,
          nameManager,
          package,
          useImmutableCollections: useImmutableCollections,
        ),
        statements: [
          if (!isRequired) const Code('if (body == null) return null;'),
          ...spliceInlineHelpers(inlineHelpers),
          const Code('return switch (body) {'),
          ...cases,
          const Code('};'),
        ],
      );
    }

    final item = content.single;
    final bodyType = requestContentTypeReference(
      item,
      nameManager,
      package,
      isNullableOverride: !isRequired,
      useImmutableCollections: useImmutableCollections,
    );
    if (item is MultipartRequestContent) {
      return buildDataMethod(
        bodyType: bodyType,
        isRequired: isRequired,
        isAsync: true,
        headerParameters: buildMultipartHeaderParameters(
          headerInfo,
          nameManager,
          package,
          useImmutableCollections: false,
        ),
        statements: [
          if (!isRequired) const Code('if (body == null) return null;'),
          ...buildMultipartBodyStatements(
            bodyPlan as MultipartBodyPlan,
          ).statements,
        ],
      );
    }
    item as ModelRequestContent;
    final guardNull =
        !isRequired &&
        switch (item.contentType) {
          ContentType.text || ContentType.form => true,
          ContentType.json => _encodesJsonRoot(item.model),
          _ => false,
        };
    final built = _bodyExpression(
      operation: operation,
      content: item,
      valueName: 'body',
      propertyName: 'body',
      isRequired: isRequired || guardNull,
      helperContext: helperContext,
    );
    return buildDataMethod(
      bodyType: bodyType,
      isRequired: isRequired,
      statements: [
        ...spliceInlineHelpers(built.inlineFunctions),
        if (guardNull) const Code('if (body == null) return null;'),
        const Code('return '),
        built.unsafeRawBody.code,
        const Code(';'),
      ],
    );
  }

  BuiltExpression _bodyExpression({
    required Operation operation,
    required ModelRequestContent content,
    required String valueName,
    required String propertyName,
    required bool isRequired,
    required InlineHelperContext helperContext,
  }) {
    final value = refer(valueName);
    switch (content.contentType) {
      case ContentType.json:
        final json = buildToJsonPropertyExpression(
          valueName,
          Property(
            name: propertyName,
            model: content.model,
            isRequired: isRequired,
            isNullable: !isRequired,
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
        return BuiltExpression(
          body: _encodesJsonRoot(content.model)
              ? refer('jsonEncode', 'dart:convert').call([json.unsafeRawBody])
              : json.unsafeRawBody,
          inlineFunctions: json.inlineFunctions,
        );
      case ContentType.text:
        return BuiltExpression.simple(
          requestTextBytesExpression(content.textEncoding, value),
        );
      case ContentType.bytes:
        return BuiltExpression.simple(switch (content.model) {
          BinaryModel() =>
            (isRequired
                    ? value.property('toBytes')
                    : value.nullSafeProperty('toBytes'))
                .call([]),
          PrimitiveModel() => value,
          _ => generateEncodingExceptionExpression(
            'Unsupported model for bytes content type.',
          ),
        });
      case ContentType.form:
        return buildToFormValueExpression(
          valueName,
          content.model,
          useQueryComponent: true,
          textEncoding: content.textEncoding,
          encoding: content.formEncoding,
        );
      case ContentType.multipart:
        throw StateError('Multipart content must own parts.');
    }
  }
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
    final CompositeModel model => model.containedModels.any(_encodesJsonRoot),
    _ => false,
  };
}
