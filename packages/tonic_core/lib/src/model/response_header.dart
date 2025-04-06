import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

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
  });

  final ResponseHeader header;

  @override
  String toString() => 'HeaderAlias{name: $name, header: $header}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseHeaderAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          header == other.header &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, header);
}

@immutable
class ResponseHeaderObject extends ResponseHeader {
  const ResponseHeaderObject({
    required super.name,
    required super.context,
    required this.description,
    required this.explode,
    required this.model,
    required this.isRequired,
    required this.isDeprecated,
    required this.encoding,
  });

  final String? description;
  final bool explode;
  final Model model;
  final bool isRequired;
  final bool isDeprecated;
  final ResponseHeaderEncoding encoding;

  @override
  String toString() =>
      'HeaderObject{name: $name, description: $description, '
      'explode: $explode, model: $model, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, encoding: $encoding, context: $context}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseHeaderObject &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          explode == other.explode &&
          model == other.model &&
          isRequired == other.isRequired &&
          isDeprecated == other.isDeprecated &&
          encoding == other.encoding &&
          context == other.context;

  @override
  int get hashCode => Object.hash(
    name,
    description,
    explode,
    model,
    isRequired,
    isDeprecated,
    encoding,
    context,
  );
}
