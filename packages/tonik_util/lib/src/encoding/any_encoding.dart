import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/deep_object_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/encodable.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/label_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/matrix_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/simple_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/unknown_value_encoding.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Encodes any value to matrix-style. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// Primitives use extension methods.
String encodeAnyToMatrix(
  Object? value,
  String paramName, {
  required bool explode,
  required bool allowEmpty,
}) {
  if (value == null) {
    return allowEmpty ? ';$paramName' : '';
  }
  if (value is ParameterEncodable) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is String) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is int) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is double) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is bool) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is DateTime) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is Uri) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  if (value is BigDecimal) {
    return value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to matrix style',
  );
}

/// Encodes any value to label-style. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// Primitives use extension methods.
String encodeAnyToLabel(
  Object? value, {
  required bool explode,
  required bool allowEmpty,
}) {
  if (value == null) {
    return allowEmpty ? '.' : '';
  }
  if (value is ParameterEncodable) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is String) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is int) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is double) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is bool) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is DateTime) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is Uri) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is BigDecimal) {
    return value.toLabel(explode: explode, allowEmpty: allowEmpty);
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to label style',
  );
}

/// Encodes any value to simple-style. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// Primitives use extension methods.
///
/// `List` values are encoded comma-separated (at the immediate list level —
/// explode still propagates into nested maps/lists, where it can affect
/// their internal rendering). `Map` values are encoded as `k1=v1,k2=v2`
/// when explode=true and `k1,v1,k2,v2` when explode=false, with each
/// element pre-encoded recursively via [encodeAnyToSimple] so nested lists
/// / maps / primitives all work.
///
/// [allowEmpty] applies to the whole structure: when `false`, an empty inner
/// list / map / null value at any depth raises [EmptyValueException]. The
/// flag is threaded through the recursion so that `{'k': []}` with
/// `allowEmpty: false` throws rather than silently producing `'k,'`.
///
/// Note: when an unsupported nested element raises [EncodingException], the
/// message identifies only the inner type — no path / key context is attached
/// to indicate where in the structure the failure originated.
///
/// When [literal] is true, values are sent without URI encoding (HTTP header
/// field-values), including nested map/list elements.
String encodeAnyToSimple(
  Object? value, {
  required bool explode,
  required bool allowEmpty,
  bool literal = false,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return '';
  }
  if (value is ParameterEncodable) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is String) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is int) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is double) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is bool) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is DateTime) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is Uri) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is BigDecimal) {
    return value.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    );
  }
  if (value is Map<String, dynamic>) {
    if (value.isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    final encoded = <String, String>{
      for (final entry in value.entries)
        entry.key: encodeAnyToSimple(
          entry.value,
          explode: explode,
          allowEmpty: allowEmpty,
          literal: literal,
        ),
    };
    return encoded.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
      literal: literal,
    );
  }
  if (value is List<dynamic>) {
    if (value.isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    final encoded = value
        .map(
          (item) => encodeAnyToSimple(
            item,
            explode: explode,
            allowEmpty: allowEmpty,
            literal: literal,
          ),
        )
        .toList();
    return encoded.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
      literal: literal,
    );
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to simple style',
  );
}

/// Encodes any value to form-style. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// Primitives use extension methods.
///
/// `List` values are always encoded comma-separated within this helper,
/// regardless of explode. The repeated-key form for explode=true is
/// applied at the parameter-encoder layer above, not here. `Map` values
/// are encoded as `k1=v1&k2=v2` when explode=true and `k1,v1,k2,v2` when
/// explode=false, with each element pre-encoded recursively via
/// [encodeAnyToForm] so nested collections work.
///
/// [allowEmpty] applies to the whole structure: when `false`, an empty inner
/// list / map / null value at any depth raises [EmptyValueException]. The
/// flag is threaded through the recursion so that `{'k': []}` with
/// `allowEmpty: false` throws rather than silently producing `'k,'`.
///
/// When [useQueryComponent] is true, primitives use
/// `Uri.encodeQueryComponent` (spaces become `+`) instead of
/// `Uri.encodeComponent` (spaces become `%20`); the same flag is threaded
/// into recursive list/map element encoding.
///
/// When [allowReserved] is true, most reserved characters in primitive
/// values are kept literal; the flag is threaded into recursive list/map
/// element encoding and forwarded to the [ParameterEncodable] branch so those
/// models honor it in their own value encoding.
///
/// Note: when an unsupported nested element raises [EncodingException], the
/// message identifies only the inner type — no path / key context is attached
/// to indicate where in the structure the failure originated.
String encodeAnyToForm(
  Object? value, {
  required bool explode,
  required bool allowEmpty,
  bool useQueryComponent = false,
  bool allowReserved = false,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return '';
  }
  if (value is ParameterEncodable) {
    return _formEntriesToString(
      value.toForm(
        '',
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
      explode: explode,
    );
  }
  if (value is String) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is int) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is double) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is bool) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is DateTime) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is Uri) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is BigDecimal) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is Map<String, dynamic>) {
    if (value.isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    final encoded = <String, String>{
      for (final entry in value.entries)
        entry.key: encodeAnyToForm(
          entry.value,
          explode: explode,
          allowEmpty: allowEmpty,
          useQueryComponent: useQueryComponent,
          allowReserved: allowReserved,
        ),
    };
    return _formEntriesToString(
      encoded.toForm(
        '',
        explode: explode,
        allowEmpty: allowEmpty,
        alreadyEncoded: true,
        useQueryComponent: useQueryComponent,
      ),
      explode: explode,
    );
  }
  if (value is List<dynamic>) {
    if (value.isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    // Lists render comma-separated regardless of explode; the repeated-key
    // form is applied at the parameter layer above, not here.
    final encoded = value
        .map(
          (item) => encodeAnyToForm(
            item,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          ),
        )
        .toList();
    return encoded.uriEncode(
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
      useQueryComponent: useQueryComponent,
    );
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to form style',
  );
}

/// Encodes a top-level form query parameter whose runtime value has an unknown
/// type, omitting an empty list or map so the parameter is absent from the
/// query.
List<ParameterEntry> encodeAnyToFormEntries(
  Object? value, {
  required String name,
  required bool explode,
  required bool allowEmpty,
  bool useQueryComponent = false,
  bool allowReserved = false,
}) {
  if ((value is List && value.isEmpty) ||
      (value is Map<String, dynamic> && value.isEmpty)) {
    return const [];
  }
  return [
    (
      name: name,
      value: encodeAnyToForm(
        value,
        explode: explode,
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

String _formEntriesToString(
  List<ParameterEntry> entries, {
  required bool explode,
}) => explode
    ? entries
          .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
          .join('&')
    : entries.map((e) => e.value).join(',');

/// Encodes any value to deep object style. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// `Map<String, String>` values use extension methods.
///
/// When [allowReserved] is true, most reserved characters in the map
/// VALUES are kept literal (keys stay `Uri.encodeComponent`-encoded); the flag
/// is forwarded to the [ParameterEncodable] branch so those models honor it in
/// their own value encoding.
///
/// Note: DeepObject style only makes sense for objects, not primitives.
List<ParameterEntry> encodeAnyToDeepObject(
  Object? value,
  String paramName, {
  required bool explode,
  required bool allowEmpty,
  bool allowReserved = false,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return [];
  }
  if (value is ParameterEncodable) {
    return value.toDeepObject(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }
  if (value is Map<String, String>) {
    return value.toDeepObject(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    );
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to deepObject style. '
    'DeepObject only supports objects and Map<String, String>.',
  );
}

/// Encodes any value to a URI-encoded string. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// Primitives use extension methods.
///
/// When [allowReserved] is true, reserved characters are kept literal except
/// the form delimiters `& = +`; the flag is forwarded to the [UriEncodable]
/// branch and every primitive branch.
String encodeAnyToUri(
  Object? value, {
  required bool allowEmpty,
  bool useQueryComponent = false,
  bool allowReserved = false,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return '';
  }
  if (value is UriEncodable) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is String) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is int) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is double) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is bool) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is DateTime) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is Uri) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  if (value is BigDecimal) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to URI',
  );
}

/// Returns an empty string for an allowed null and rejects non-scalar values.
String encodeAnyValueToString(
  Object? value, {
  required bool allowEmpty,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return '';
  }
  return encodeUnknownFlatScalar(value, context: 'map parameter value');
}

/// Rejects unsupported runtime types and maps with non-string keys.
Object? encodeAnyToJson(Object? value) =>
    encodeUnknownJson(value, context: 'value');
