import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding style supported for response headers .
enum ResponseHeaderEncoding() {
  /// Comma-separated values. The only style for headers.
  /// Example: `X-MyHeader: 3,4,5`
  simple,
}

sealed class const ResponseHeader({
  required final Context context,
  required final String? name,
}) {
  /// The description of the header.
  /// For aliases, this may override the referenced header's description.
  String? get description;

  ResponseHeaderObject resolve({String? name}) {
    switch (this) {
      case final ResponseHeaderObject header:
        return ResponseHeaderObject(
          name: name ?? header.name,
          description: header.description,
          explode: header.explode,
          model: header.model,
          isRequired: header.isRequired,
          isDeprecated: header.isDeprecated,
          encoding: header.encoding,
          context: context,
          examples: header.examples,
        );
      case final ResponseHeaderAlias alias:
        return alias.header.resolve(name: name ?? alias.name);
    }
  }
}

@immutable
class const ResponseHeaderAlias({
  required super.name,
  required final ResponseHeader header,
  required super.context,
  @override final String? description,
}) extends ResponseHeader {
  @override
  String toString() =>
      'HeaderAlias{name: $name, header: $header, description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseHeaderAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          header == other.header &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, header, description, context);
}

class ResponseHeaderObject({
  required super.name,
  required super.context,
  @override required final String? description,
  required var bool explode,
  required var Model model,
  required var bool isRequired,
  required var bool isDeprecated,
  required var ResponseHeaderEncoding encoding,
  required var List<Example> examples,
}) extends ResponseHeader {
  @override
  String toString() =>
      'HeaderObject{name: $name, description: $description, '
      'explode: $explode, model: $model, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, encoding: $encoding, context: $context, '
      'examples: $examples}';
}
