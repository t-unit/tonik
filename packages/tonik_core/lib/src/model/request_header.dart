import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/effective_default.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding style supported for header parameters.
enum HeaderParameterEncoding() {
  /// Comma-separated values. The only style for headers.
  /// Example: X-MyHeader: 3,4,5
  simple,
}

sealed class const RequestHeader({required final Context context}) {
  /// The description of the header.
  /// For aliases, this may override the referenced header's description.
  String? get description;

  RequestHeaderObject resolve({String? name, String? nameOverride}) {
    switch (this) {
      case final RequestHeaderObject header:
        return RequestHeaderObject(
          name: name ?? header.name,
          nameOverride: nameOverride ?? header.nameOverride,
          rawName: header.rawName,
          description: header.description,
          isRequired: header.isRequired,
          isDeprecated: header.isDeprecated,
          allowEmptyValue: header.allowEmptyValue,
          explode: header.explode,
          model: header.model,
          encoding: header.encoding,
          context: context,
          examples: header.examples,
          defaultValue: header.defaultValue,
        );
      case final RequestHeaderAlias alias:
        return alias.header.resolve(
          name: name ?? alias.name,
          nameOverride: nameOverride,
        );
    }
  }
}

@immutable
class const RequestHeaderAlias({
  required final String name,
  required final RequestHeader header,
  required super.context,
  @override final String? description,
}) extends RequestHeader {
  @override
  String toString() =>
      'RequestHeaderAlias{name: $name, header: $header, '
      'description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestHeaderAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          header == other.header &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, header, description, context);
}

class RequestHeaderObject({
  required final String? name,

  /// The name used inside the HTTP request to identify the header.
  required final String rawName,
  @override required var String? description,
  required var bool isRequired,
  required var bool isDeprecated,
  required var bool allowEmptyValue,
  required var bool explode,
  required var Model model,
  required var HeaderParameterEncoding encoding,
  required super.context,
  required var List<Example> examples,
  required var Object? defaultValue,
  var String? nameOverride,
}) extends RequestHeader {
  Object? get effectiveDefaultValue => effectiveDefault(defaultValue, model);

  @override
  String toString() =>
      'RequestHeader{name: $name, nameOverride: $nameOverride, '
      'rawName: $rawName, description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'explode: $explode, model: $model, encoding: $encoding, '
      'defaultValue: $defaultValue, examples: $examples}';
}
