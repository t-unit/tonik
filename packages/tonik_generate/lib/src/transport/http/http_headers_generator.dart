import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/request_headers_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Generates the exact string header map applied to a `package:http` request.
class const HttpHeadersGenerator({
  required final NameManager nameManager,
  required final String package,
  final bool useImmutableCollections = false,
}) {
  Method generateHeadersMethod(
    Operation operation,
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
    List<({String normalizedName, CookieParameterObject parameter})>
    cookieParameters,
  ) {
    final stringType = refer('String', 'dart:core');
    final generated = RequestHeadersGenerator(
      nameManager: nameManager,
      package: package,
      headerValueType: stringType,
      useImmutableCollections: useImmutableCollections,
    ).generate(operation, headers, cookieParameters);
    final statements = <Code>[...generated.statements];
    final requestBody = operation.requestBody;
    final content = requestBody?.resolvedContent.toList() ?? const [];

    if (generated.contentType != null &&
        content.isNotEmpty &&
        content.singleOrNull?.contentType != ContentType.multipart) {
      final assignContentType = refer(r'_$headers')
          .index(specLiteralString('Content-Type'))
          .assign(generated.contentType!)
          .statement;
      final contentTypeIsRequired =
          requestBody!.isRequired &&
          content.every((item) => item.contentType != ContentType.multipart);
      if (contentTypeIsRequired) {
        statements.add(assignContentType);
      } else {
        statements.add(
          Block.of([
            const Code(r'if (_$contentType != null) {'),
            refer(r'_$headers')
                .index(specLiteralString('Content-Type'))
                .assign(refer(r'_$contentType'))
                .statement,
            const Code('}'),
          ]),
        );
      }
    }

    statements.add(refer(r'_$headers').returned.statement);

    return Method(
      (b) => b
        ..name = '_options'
        ..returns = TypeReference(
          (t) => t
            ..symbol = 'Map'
            ..url = 'dart:core'
            ..types.addAll([stringType, stringType]),
        )
        ..optionalParameters.addAll(generated.parameters)
        ..lambda = false
        ..body = Block.of(statements),
    );
  }
}
