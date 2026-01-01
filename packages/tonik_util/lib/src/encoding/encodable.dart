import 'package:tonik_util/src/encoding/parameter_entry.dart';

/// Marker interface for types that support matrix-style encoding
/// (RFC 6570 Section 3.2.7).
abstract interface class MatrixEncodable {
  /// Encodes this value using matrix style parameter encoding.
  ///
  /// The [paramName] is the parameter name used in the path.
  /// When [explode] is true, object properties become separate parameters.
  /// When [allowEmpty] is false, empty values throw an exception.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  });
}

/// Marker interface for types that support label-style encoding
/// (RFC 6570 Section 3.2.5).
abstract interface class LabelEncodable {
  /// Encodes this value using label style parameter encoding.
  ///
  /// When [explode] is true, object properties become key=value pairs.
  /// When [allowEmpty] is false, empty values throw an exception.
  String toLabel({
    required bool explode,
    required bool allowEmpty,
  });
}

/// Marker interface for types that support simple-style encoding
/// (RFC 6570 Section 3.2.2).
abstract interface class SimpleEncodable {
  /// Encodes this value using simple style parameter encoding.
  ///
  /// When [explode] is true, object properties become key=value pairs.
  /// When [allowEmpty] is false, empty values throw an exception.
  String toSimple({
    required bool explode,
    required bool allowEmpty,
  });
}

/// Marker interface for types that support form-style encoding
/// (RFC 6570 Section 3.2.8).
abstract interface class FormEncodable {
  /// Encodes this value using form style parameter encoding.
  ///
  /// When [explode] is true, object properties become separate parameters.
  /// When [allowEmpty] is false, empty values throw an exception.
  /// When [useQueryComponent] is true, uses '+' for spaces
  /// (application/x-www-form-urlencoded encoding).
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  });
}

/// Marker interface for types that support deep object encoding.
abstract interface class DeepObjectEncodable {
  /// Encodes this value using deepObject style parameter encoding.
  ///
  /// The [paramName] is the base parameter name used for nested keys.
  /// The [explode] parameter must be true; deepObject style always explodes.
  /// When [allowEmpty] is false, empty values throw an exception.
  ///
  /// Returns a list of parameter entries where each entry has:
  /// - name: `paramName[key]`
  /// - value: the encoded value
  List<ParameterEntry> toDeepObject(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  });
}

/// Marker interface for types that support JSON encoding.
abstract interface class JsonEncodable {
  /// Converts this value to a JSON-compatible representation.
  ///
  /// Returns a value that can be serialized to JSON:
  /// - For primitives: the primitive value
  /// - For objects: a [Map] with string keys
  /// - For arrays: a [List]
  Object? toJson();
}

/// Combined interface for types that support all standard parameter
/// encoding styles.
abstract interface class ParameterEncodable
    implements
        MatrixEncodable,
        LabelEncodable,
        SimpleEncodable,
        FormEncodable,
        DeepObjectEncodable,
        JsonEncodable {}
