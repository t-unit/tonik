import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/data_method_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
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

/// Generates exact request body bytes for ordinary `package:http` requests.
class HttpBodyGenerator {
  const HttpBodyGenerator({
    required this.nameManager,
    required this.package,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final bool useImmutableCollections;

  Method generateBodyMethod(Operation operation, {RequestBodyPlan? bodyPlan}) {
    final requestBody = operation.requestBody;
    if (requestBody == null || requestBody.resolvedContent.isEmpty) {
      return buildDataMethod(statements: [const Code('return null;')]);
    }

    final content = requestBody.resolvedContent.toList();
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];
    final isRequired = requestBody.isRequired;
    final headerParameters = buildMultipartHeaderParameters(
      extractOperationMultipartHeaderParamInfo(operation),
      nameManager,
      package,
      useImmutableCollections: useImmutableCollections,
    );
    bodyPlan ??= const OperationRequestPlanner(
      backend: TransportBackend.http,
    ).planBody(operation);

    if (content.length > 1) {
      final (baseName, subclassNames) = nameManager.requestBodyNames(
        requestBody,
      );
      final requestBodyUrl = sourceFileUrl(package, 'request_body', baseName);
      final cases = <Code>[];
      for (final item in content) {
        final variantName = subclassNames[item.rawContentType]!;
        final isMultipart = item is MultipartRequestContent;
        final multipartPlan = isMultipart
            ? (bodyPlan as BodySelectionPlan).variants.firstWhere(
                    (variant) => variant.rawContentType == item.rawContentType,
                  )
                  as MultipartBodyPlan
            : null;
        final built = isMultipart
            ? null
            : _bodyBytesExpression(
                operation: operation,
                content: item as ModelRequestContent,
                valueName: 'value.value',
                helperContext: helperContext,
                receiverIsPromotedNonNull: false,
              );
        if (built != null) inlineHelpers.addAll(built.inlineFunctions);
        cases.add(
          Block.of([
            const Code('final '),
            refer(variantName, requestBodyUrl).code,
            Code(
              multipartPlan?.emissions.isEmpty ?? false
                  ? ' _ => '
                  : ' value => ',
            ),
            if (isMultipart)
              Method(
                (builder) => builder
                  ..modifier = MethodModifier.async
                  ..lambda = false
                  ..body = Block.of(
                    buildHttpMultipartBodyStatements(multipartPlan!),
                  ),
              ).closure.call([]).awaited.code
            else
              built!.unsafeRawBody.code,
            const Code(','),
          ]),
        );
      }

      if (!isRequired) {
        cases.add(const Code('null => null,'));
      }

      final hasMultipart = content.any(
        (item) => item.contentType == ContentType.multipart,
      );
      return buildDataMethod(
        bodyType: TypeReference(
          (type) => type
            ..symbol = baseName
            ..url = requestBodyUrl
            ..isNullable = !isRequired,
        ),
        isRequired: isRequired,
        isAsync: hasMultipart,
        headerParameters: headerParameters,
        statements: [
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
        headerParameters: headerParameters,
        statements: [
          if (!isRequired) const Code('if (body == null) return null;'),
          ...buildHttpMultipartBodyStatements(bodyPlan as MultipartBodyPlan),
        ],
      );
    }
    item as ModelRequestContent;
    final built = _bodyBytesExpression(
      operation: operation,
      content: item,
      valueName: 'body',
      helperContext: helperContext,
      receiverIsPromotedNonNull: !isRequired,
    );
    inlineHelpers.addAll(built.inlineFunctions);

    return buildDataMethod(
      bodyType: bodyType,
      isRequired: isRequired,
      statements: [
        if (!isRequired) const Code('if (body == null) return null;'),
        ...spliceInlineHelpers(inlineHelpers),
        const Code('return '),
        built.unsafeRawBody.code,
        const Code(';'),
      ],
    );
  }

  BuiltExpression _bodyBytesExpression({
    required Operation operation,
    required ModelRequestContent content,
    required String valueName,
    required InlineHelperContext helperContext,
    required bool receiverIsPromotedNonNull,
  }) {
    final value = refer(valueName);
    switch (content.contentType) {
      case ContentType.json:
        final json = buildToJsonPropertyExpression(
          valueName,
          Property(
            name: 'body',
            model: content.model,
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
          receiverIsPromotedNonNull: receiverIsPromotedNonNull,
        );
        return BuiltExpression(
          body: refer('utf8', 'dart:convert').property('encode').call([
            refer('jsonEncode', 'dart:convert').call([json.unsafeRawBody]),
          ]),
          inlineFunctions: json.inlineFunctions,
        );
      case ContentType.text:
        return BuiltExpression.simple(
          requestTextBytesExpression(content.textEncoding, value),
        );
      case ContentType.bytes:
        final resolved = content.model.resolved;
        if (resolved is BinaryModel) {
          return BuiltExpression.simple(value.property('toBytes').call([]));
        }
        if (resolved is PrimitiveModel) {
          return BuiltExpression.simple(value);
        }
        return BuiltExpression.simple(
          generateEncodingExceptionExpression(
            'Unsupported model for bytes content type.',
          ),
        );
      case ContentType.form:
        final form = buildToFormValueExpression(
          valueName,
          content.model,
          useQueryComponent: true,
          textEncoding: content.textEncoding,
          encoding: content.formEncoding,
        );
        return BuiltExpression(
          body: refer(
            'utf8',
            'dart:convert',
          ).property('encode').call([form.unsafeRawBody]),
          inlineFunctions: form.inlineFunctions,
        );
      case ContentType.multipart:
        throw StateError('Multipart content must own parts.');
    }
  }
}
