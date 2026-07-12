import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/encodable.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

/// Encodes a runtime value of unknown type to a JSON-compatible value.
///
/// JSON primitives pass through, [JsonEncodable] values use their `toJson`,
/// the scalar convenience types ([DateTime], [Date], [Uri], [BigDecimal])
/// use their canonical string forms, and maps and lists are converted
/// recursively. Map keys must be strings.
///
/// [context] names the value's location and grows with `.key` and `[index]`
/// segments while descending, so failures name the offending path.
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
    // Both collection branches are copy-on-write: an untouched subtree keeps
    // its identity so round-tripped values stay reference-equal.
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

/// Encodes a runtime value of unknown type occupying one flat property slot
/// to its scalar wire string.
///
/// Supports the safe scalar runtime types; lists, maps, generated values,
/// and other custom types throw an [EncodingException] naming [context].
///
/// Null is intentionally not accepted: schema-aware callers treat a null
/// entry as RFC 6570 undefined and omit it before constructing a
/// `PropertyValue`. An empty string is a defined empty scalar.
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
