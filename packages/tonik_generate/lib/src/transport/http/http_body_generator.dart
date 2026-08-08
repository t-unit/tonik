import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
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

  Method generateBodyMethod(Operation operation) {
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

    final content = requestBody.resolvedContent.toList();
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];
    final isRequired = requestBody.isRequired;

    if (content.length > 1) {
      final (baseName, subclassNames) = nameManager.requestBodyNames(
        requestBody,
      );
      final requestBodyUrl = sourceFileUrl(package, 'request_body', baseName);
      final cases = <Code>[];
      final multipartHeaderInfos = extractOperationMultipartHeaderParamInfo(
        operation,
      );

      for (final item in content) {
        final variantName = subclassNames[item.rawContentType]!;
        final isMultipart = item.contentType == ContentType.multipart;
        final bindsValue = !isMultipart || item.model.resolved is ClassModel;
        final built = isMultipart
            ? null
            : _bodyBytesExpression(
                operation: operation,
                content: item,
                valueName: 'value.value',
                helperContext: helperContext,
                receiverIsPromotedNonNull: false,
              );
        if (built != null) inlineHelpers.addAll(built.inlineFunctions);
        cases.add(
          Block.of([
            if (bindsValue) const Code('final '),
            refer(variantName, requestBodyUrl).code,
            Code(bindsValue ? ' value => ' : ' _ => '),
            if (isMultipart)
              Method(
                (builder) => builder
                  ..modifier = MethodModifier.async
                  ..lambda = false
                  ..body = Block.of(
                    buildHttpMultipartBodyStatements(
                      item,
                      'value.value',
                      headerParameters: multipartHeaderInfos,
                    ),
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

      final multipartHeaderParameters = _multipartHeaderParameters(operation);
      final hasMultipart = content.any(
        (item) => item.contentType == ContentType.multipart,
      );
      return Method(
        (b) => b
          ..name = '_data'
          ..returns = hasMultipart
              ? TypeReference(
                  (t) => t
                    ..symbol = 'Future'
                    ..url = 'dart:async'
                    ..types.add(refer('Object?', 'dart:core')),
                )
              : refer('Object?', 'dart:core')
          ..optionalParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = TypeReference(
                  (t) => t
                    ..symbol = baseName
                    ..url = requestBodyUrl
                    ..isNullable = !isRequired,
                )
                ..named = true
                ..required = isRequired,
            ),
          )
          ..optionalParameters.addAll(multipartHeaderParameters)
          ..modifier = hasMultipart ? MethodModifier.async : null
          ..lambda = false
          ..body = Block.of([
            ...spliceInlineHelpers(inlineHelpers),
            const Code('return switch (body) {'),
            ...cases,
            const Code('};'),
          ]),
      );
    }

    final item = content.single;
    if (item.contentType == ContentType.multipart) {
      final multipartHeaderParameters = _multipartHeaderParameters(operation);
      final multipartHeaderInfos = extractOperationMultipartHeaderParamInfo(
        operation,
      );
      return Method(
        (b) => b
          ..name = '_data'
          ..returns = TypeReference(
            (t) => t
              ..symbol = 'Future'
              ..url = 'dart:async'
              ..types.add(refer('Object?', 'dart:core')),
          )
          ..optionalParameters.add(
            Parameter(
              (p) => p
                ..name = 'body'
                ..type = typeReference(
                  item.model,
                  nameManager,
                  package,
                  isNullableOverride: !isRequired,
                  useImmutableCollections: useImmutableCollections,
                )
                ..named = true
                ..required = isRequired,
            ),
          )
          ..optionalParameters.addAll(multipartHeaderParameters)
          ..modifier = MethodModifier.async
          ..lambda = false
          ..body = Block.of([
            if (!isRequired) const Code('if (body == null) return null;'),
            ...buildHttpMultipartBodyStatements(
              item,
              'body',
              headerParameters: multipartHeaderInfos,
            ),
          ]),
      );
    }
    final built = _bodyBytesExpression(
      operation: operation,
      content: item,
      valueName: 'body',
      helperContext: helperContext,
      receiverIsPromotedNonNull: !isRequired,
    );
    inlineHelpers.addAll(built.inlineFunctions);

    return Method(
      (b) => b
        ..name = '_data'
        ..returns = refer('Object?', 'dart:core')
        ..optionalParameters.add(
          Parameter(
            (p) => p
              ..name = 'body'
              ..type = typeReference(
                item.model,
                nameManager,
                package,
                isNullableOverride: !isRequired,
                useImmutableCollections: useImmutableCollections,
              )
              ..named = true
              ..required = isRequired,
          ),
        )
        ..lambda = false
        ..body = Block.of([
          if (!isRequired) const Code('if (body == null) return null;'),
          ...spliceInlineHelpers(inlineHelpers),
          const Code('return '),
          built.unsafeRawBody.code,
          const Code(';'),
        ]),
    );
  }

  BuiltExpression _bodyBytesExpression({
    required Operation operation,
    required RequestContent content,
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
        final encoding = _textEncoding(content.rawContentType);
        if (encoding == null) {
          final charset = _charset(content.rawContentType);
          return BuiltExpression.simple(
            generateEncodingExceptionExpression(
              'Unsupported text encoding: $charset.',
            ),
          );
        }
        return BuiltExpression.simple(
          encoding.property('encode').call([value]),
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
        throw StateError('Multipart bodies are handled by HTTP-09.');
    }
  }

  Expression? _textEncoding(String rawContentType) {
    final charset = _charset(rawContentType);

    return switch (charset) {
      'utf-8' || 'utf8' => refer('utf8', 'dart:convert'),
      'iso-8859-1' || 'latin1' => refer('latin1', 'dart:convert'),
      'us-ascii' || 'ascii' => refer('ascii', 'dart:convert'),
      _ => null,
    };
  }

  String _charset(String rawContentType) =>
      RegExp(
        r'(?:^|;)\s*charset\s*=\s*"?([^";\s]+)',
        caseSensitive: false,
      ).firstMatch(rawContentType)?.group(1)?.toLowerCase() ??
      'utf-8';

  List<Parameter> _multipartHeaderParameters(Operation operation) => [
    for (final info in extractOperationMultipartHeaderParamInfo(operation))
      Parameter(
        (parameter) => parameter
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
  ];
}
