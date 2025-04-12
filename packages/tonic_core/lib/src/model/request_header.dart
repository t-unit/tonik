import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

/// Encoding style supported for header parameters.
enum HeaderParameterEncoding {
  /// Comma-separated values. The only style for headers.
  /// Example: X-MyHeader: 3,4,5
  simple,
}

sealed class RequestHeader {
  const RequestHeader({required this.context});

  final Context context;

  RequestHeaderObject resolve({String? name}) {
    switch (this) {
      case final RequestHeaderObject header:
        return RequestHeaderObject(
          name: name ?? header.name,
          rawName: header.rawName,
          description: header.description,
          isRequired: header.isRequired,
          isDeprecated: header.isDeprecated,
          allowEmptyValue: header.allowEmptyValue,
          explode: header.explode,
          model: header.model,
          encoding: header.encoding,
          context: context,
        );
      case final RequestHeaderAlias alias:
        return alias.header.resolve(name: name ?? alias.name);
    }
  }
}

@immutable
class RequestHeaderAlias extends RequestHeader {
  const RequestHeaderAlias({
    required this.name,
    required this.header,
    required super.context,
  });

  final String name;
  final RequestHeader header;

  @override
  String toString() => 'RequestHeaderAlias{name: $name, header: $header}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestHeaderAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          header == other.header &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, header);
}

@immutable
class RequestHeaderObject extends RequestHeader {
  const RequestHeaderObject({
    required this.name,
    required this.rawName,
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.allowEmptyValue,
    required this.explode,
    required this.model,
    required this.encoding,
    required super.context,
  });

  final String? name;

  /// The name used inside the HTTP request to identify the header.
  final String rawName;
  final String? description;
  final bool isRequired;
  final bool isDeprecated;
  final bool allowEmptyValue;
  final bool explode;
  final Model model;
  final HeaderParameterEncoding encoding;

  @override
  String toString() =>
      'RequestHeader{name: $name, rawName: $rawName, '
      'description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'explode: $explode, model: $model, encoding: $encoding}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestHeaderObject &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          isRequired == other.isRequired &&
          isDeprecated == other.isDeprecated &&
          allowEmptyValue == other.allowEmptyValue &&
          explode == other.explode &&
          model == other.model &&
          encoding == other.encoding &&
          context == other.context &&
          rawName == other.rawName;

  @override
  int get hashCode => Object.hash(
    name,
    description,
    isRequired,
    isDeprecated,
    allowEmptyValue,
    explode,
    model,
    encoding,
    context,
    rawName,
  );
}
