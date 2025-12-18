import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding style supported for header parameters.
enum HeaderParameterEncoding {
  /// Comma-separated values. The only style for headers.
  /// Example: X-MyHeader: 3,4,5
  simple,
}

sealed class RequestHeader {
  const RequestHeader({required this.context});

  final Context context;

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

class RequestHeaderObject extends RequestHeader {
  RequestHeaderObject({
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
    this.nameOverride,
  });

  final String? name;

  /// The name used inside the HTTP request to identify the header.
  final String rawName;

  String? nameOverride;
  String? description;
  bool isRequired;
  bool isDeprecated;
  bool allowEmptyValue;
  bool explode;
  Model model;
  HeaderParameterEncoding encoding;

  @override
  String toString() =>
      'RequestHeader{name: $name, nameOverride: $nameOverride, '
      'rawName: $rawName, description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'explode: $explode, model: $model, encoding: $encoding}';
}
