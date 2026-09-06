import 'dart:convert';

import 'package:tonik_util/src/encoding/encodable.dart';
import 'package:tonik_util/src/encoding/form_field_encoding.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/property_value_form_encoder.dart';
import 'package:tonik_util/src/encoding/property_value_style_encoders.dart';

/// Shared parameter encoding for object models with typed property values.
///
/// Subclasses supply their property values and JSON representation. Each
/// encoding call obtains its property map through [parameterProperties].
abstract class const ObjectParameterEncodable() implements ParameterEncodable {
  /// Returns raw property values for the requested empty-value policy.
  Map<String, PropertyValue> parameterProperties({bool allowEmpty = true});

  @override
  String toSimple({
    required bool explode,
    required bool allowEmpty,
    bool literal = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty)
        .toSimple(explode: explode, allowEmpty: allowEmpty, literal: literal);
  }

  @override
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    required Encoding textEncoding,
    bool useQueryComponent = false,
    bool allowReserved = false,
    Map<String, FormFieldEncoding> fieldEncodings = const {},
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toForm(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
      fieldEncodings: fieldEncodings,
      textEncoding: textEncoding,
    );
  }

  @override
  String toLabel({required bool explode, required bool allowEmpty}) {
    return parameterProperties(allowEmpty: allowEmpty)
        .toLabel(explode: explode, allowEmpty: allowEmpty);
  }

  @override
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) {
    return parameterProperties(allowEmpty: allowEmpty)
        .toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }

  @override
  List<ParameterEntry> toDeepObject(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool allowReserved = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toDeepObject(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }

  @override
  List<ParameterEntry> toPipeDelimited(
    String paramName, {
    required bool allowEmpty,
    bool allowReserved = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toPipeDelimited(
      paramName,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }

  @override
  List<ParameterEntry> toSpaceDelimited(
    String paramName, {
    required bool allowEmpty,
    bool allowReserved = false,
  }) {
    return parameterProperties(allowEmpty: allowEmpty).toSpaceDelimited(
      paramName,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }
}
