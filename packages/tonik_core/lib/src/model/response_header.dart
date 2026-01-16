import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding style supported for response headers .
enum ResponseHeaderEncoding {
  /// Comma-separated values. The only style for headers.
  /// Example: `X-MyHeader: 3,4,5`
  simple,
}

sealed class ResponseHeader {
  const ResponseHeader({required this.context, required this.name});

  final Context context;
  final String? name;

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
        );
      case final ResponseHeaderAlias alias:
        return alias.header.resolve(name: name ?? alias.name);
    }
  }
}

@immutable
class ResponseHeaderAlias extends ResponseHeader {
  const ResponseHeaderAlias({
    required super.name,
    required this.header,
    required super.context,
    this.description,
  });

  final ResponseHeader header;

  @override
  final String? description;

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
  int get hashCode => Object.hash(name, header, description);
}

class ResponseHeaderObject extends ResponseHeader {
  ResponseHeaderObject({
    required super.name,
    required super.context,
    required this.description,
    required this.explode,
    required this.model,
    required this.isRequired,
    required this.isDeprecated,
    required this.encoding,
  });

  @override
  final String? description;

  bool explode;
  Model model;
  bool isRequired;
  bool isDeprecated;
  ResponseHeaderEncoding encoding;

  @override
  String toString() =>
      'HeaderObject{name: $name, description: $description, '
      'explode: $explode, model: $model, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, encoding: $encoding, context: $context}';
}
