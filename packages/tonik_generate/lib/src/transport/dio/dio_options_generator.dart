import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/request_headers_generator.dart';

/// Generator for creating Dio options methods for operations.
class const DioOptionsGenerator({
  required final NameManager nameManager,
  required final String package,
  final bool useImmutableCollections = false,
}) {
  Method generateOptionsMethod(
    Operation operation,
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
    List<({String normalizedName, CookieParameterObject parameter})>
    cookieParameters,
  ) {
    final generated = RequestHeadersGenerator(
      nameManager: nameManager,
      package: package,
      headerValueType: refer('dynamic', 'dart:core'),
      useImmutableCollections: useImmutableCollections,
    ).generate(operation, headers, cookieParameters);

    final options = refer('Options', 'package:dio/dio.dart').call([], {
      'method': literalString(_methodName(operation.method)),
      'headers': refer(r'_$headers'),
      'contentType': ?generated.contentType,
      'responseType': refer(
        'ResponseType',
        'package:dio/dio.dart',
      ).property('bytes'),
      'validateStatus': _validateStatus(),
    });

    return Method(
      (b) => b
        ..name = '_options'
        ..returns = refer('Options', 'package:dio/dio.dart')
        ..optionalParameters.addAll(generated.parameters)
        ..lambda = false
        ..body = Block.of([
          ...generated.statements,
          options.returned.statement,
        ]),
    );
  }

  String _methodName(HttpMethod method) => switch (method) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.delete => 'DELETE',
    HttpMethod.patch => 'PATCH',
    HttpMethod.head => 'HEAD',
    HttpMethod.options => 'OPTIONS',
    HttpMethod.trace => 'TRACE',
  };

  Expression _validateStatus() => Method(
    (b) => b
      ..lambda = true
      ..requiredParameters.add(Parameter((b) => b..name = '_'))
      ..body = literalBool(true).code,
  ).closure;
}
