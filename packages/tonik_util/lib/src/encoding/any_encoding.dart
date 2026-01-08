import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/deep_object_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/encodable.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/label_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/matrix_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/simple_encoder_extensions.dart';
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
String encodeAnyToSimple(
  Object? value, {
  required bool explode,
  required bool allowEmpty,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return '';
  }
  if (value is ParameterEncodable) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is String) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is int) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is double) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is bool) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is DateTime) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is Uri) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is BigDecimal) {
    return value.toSimple(explode: explode, allowEmpty: allowEmpty);
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
String encodeAnyToForm(
  Object? value, {
  required bool explode,
  required bool allowEmpty,
}) {
  if (value == null) {
    if (!allowEmpty) {
      throw const EmptyValueException();
    }
    return '';
  }
  if (value is ParameterEncodable) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is String) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is int) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is double) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is bool) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is DateTime) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is Uri) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  if (value is BigDecimal) {
    return value.toForm(explode: explode, allowEmpty: allowEmpty);
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to form style',
  );
}

/// Encodes any value to deep object style. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [ParameterEncodable] encode themselves.
/// `Map<String, String>` values use extension methods.
///
/// Note: DeepObject style only makes sense for objects, not primitives.
List<ParameterEntry> encodeAnyToDeepObject(
  Object? value,
  String paramName, {
  required bool explode,
  required bool allowEmpty,
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
    );
  }
  if (value is Map<String, String>) {
    return value.toDeepObject(
      paramName,
      explode: explode,
      allowEmpty: allowEmpty,
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
String encodeAnyToUri(
  Object? value, {
  required bool allowEmpty,
  bool useQueryComponent = false,
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
    );
  }
  if (value is String) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  if (value is int) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  if (value is double) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  if (value is bool) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  if (value is DateTime) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  if (value is Uri) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  if (value is BigDecimal) {
    return value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to URI',
  );
}

/// Encodes any value to JSON. Used for AnyModel fields.
///
/// Handles runtime type detection for values of unknown type.
/// Generated models implementing [JsonEncodable] call toJson().
/// Primitives pass through as-is.
/// Collections are recursively encoded.
Object? encodeAnyToJson(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is JsonEncodable) {
    return value.toJson();
  }

  if (value is String || value is num || value is bool) {
    return value;
  }

  if (value is DateTime) {
    return value.toTimeZonedIso8601String();
  }

  if (value is List) {
    return value.map(encodeAnyToJson).toList();
  }

  if (value is Map) {
    return value.map((key, val) => MapEntry(key, encodeAnyToJson(val)));
  }
  throw EncodingException(
    'Cannot encode ${value.runtimeType} to JSON',
  );
}
