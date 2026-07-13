import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/encodable.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

/// Recursively handles Tonik scalar wrappers and string-keyed collections.
Object? encodeUnknownJson(Object? value, {required String context}) {
  switch (value) {
    case null || String() || num() || bool():
      return value;
    case final JsonEncodable encodable:
      return encodable.toJson();
    case final DateTime dateTime:
      return dateTime.toTimeZonedIso8601String();
    case final Date date:
      return date.toJson();
    case final Uri uri:
      return uri.toString();
    case final BigDecimal decimal:
      return decimal.toString();
    // Avoid allocating when nested values are already JSON-compatible.
    case final List<Object?> list:
      List<Object?>? changed;
      for (var i = 0; i < list.length; i++) {
        final encoded = encodeUnknownJson(list[i], context: '$context[$i]');
        if (changed != null) {
          changed.add(encoded);
        } else if (!identical(encoded, list[i])) {
          changed = [...list.take(i), encoded];
        }
      }
      return changed ?? list;
    case final Map<Object?, Object?> map:
      Map<String, Object?>? changed;
      var index = 0;
      for (final entry in map.entries) {
        final key = entry.key;
        if (key is! String) {
          throw EncodingException(
            'Cannot encode map with non-string key '
            "'$key' (${key.runtimeType}) to JSON at $context",
          );
        }
        final encoded = encodeUnknownJson(
          entry.value,
          context: '$context.$key',
        );
        if (changed != null) {
          changed[key] = encoded;
        } else if (!identical(encoded, entry.value)) {
          changed = <String, Object?>{
            for (final prior in map.entries.take(index))
              prior.key! as String: prior.value,
            key: encoded,
          };
        }
        index++;
      }
      return changed ?? map;
    default:
      throw EncodingException(
        'Cannot encode ${value.runtimeType} to JSON at $context',
      );
  }
}

/// Accepts Tonik wire scalars and rejects collections and other values.
String encodeUnknownFlatScalar(Object value, {required String context}) =>
    switch (value) {
      final String string => string,
      final int number => number.toString(),
      final double number => number.toString(),
      final bool boolean => boolean.toString(),
      final DateTime dateTime => dateTime.toTimeZonedIso8601String(),
      final Date date => date.toString(),
      final Uri uri => uri.toString(),
      final BigDecimal decimal => decimal.toString(),
      _ => throw EncodingException(
        'Cannot encode ${value.runtimeType} as a flat scalar value '
        'at $context',
      ),
    };
