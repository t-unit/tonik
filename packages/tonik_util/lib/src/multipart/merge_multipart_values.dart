import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/property_value.dart';

/// Combines repeated list-valued multipart properties while preserving both
/// contribution order and element order.
List<T>? mergeMultipartLists<T>(
  List<Iterable<T>?> values, {
  required String propertyName,
}) {
  final present = values.whereType<Iterable<T>>().toList();
  if (present.isEmpty) return null;
  return [for (final value in present) ...value];
}

/// Combines the style-neutral property maps emitted by generated object
/// encoders. Keeping the concrete generic type lets generated code invoke the
/// style encoder extensions without falling back to `dynamic` dispatch.
Map<String, PropertyValue>? mergeMultipartPropertyValues(
  List<Map<String, PropertyValue>?> values, {
  required String propertyName,
}) {
  final present = values.whereType<Map<String, PropertyValue>>().toList();
  if (present.isEmpty) return null;

  final result = <String, PropertyValue>{};
  for (final value in present) {
    for (final entry in value.entries) {
      final current = result[entry.key];
      if (current == null) {
        result[entry.key] = entry.value;
        continue;
      }
      result[entry.key] = _mergePropertyValue(
        current,
        entry.value,
        propertyName,
        entry.key,
      );
    }
  }
  return result;
}

/// Combines values contributed by repeated properties in an `allOf` multipart
/// body. Conflicts are detected before a transport starts sending the request.
dynamic mergeMultipartValues(
  List<dynamic> values, {
  required String propertyName,
  bool mergeObjects = false,
}) {
  final present = values.where((value) => value != null).toList();
  if (present.isEmpty) return null;

  if (mergeObjects) {
    final result = <String, dynamic>{};
    for (final value in present) {
      if (value is! Map) {
        throw EncodingException(
          'Conflicting values for multipart property "$propertyName": '
          'expected object values.',
        );
      }
      _mergeMap(result, value, propertyName);
    }
    return result;
  }

  if (present.every((value) => value is Iterable)) {
    return [for (final value in present) ...(value as Iterable)];
  }

  final first = present.first;
  for (final value in present.skip(1)) {
    if (value != first) {
      throw EncodingException(
        'Conflicting values for multipart property "$propertyName".',
      );
    }
  }
  return first;
}

PropertyValue _mergePropertyValue(
  PropertyValue current,
  PropertyValue incoming,
  String propertyName,
  String key,
) => switch ((current, incoming)) {
  (
    ScalarPropertyValue(value: final left),
    ScalarPropertyValue(value: final right),
  )
      when left == right =>
    current,
  (
    ArrayPropertyValue(values: final left),
    ArrayPropertyValue(values: final right),
  ) =>
    PropertyValue.array([...left, ...right]),
  _ => throw EncodingException(
    'Conflicting values for multipart property "$propertyName" at "$key".',
  ),
};

void _mergeMap(
  Map<String, dynamic> target,
  Map<dynamic, dynamic> incoming,
  String propertyName,
) {
  for (final entry in incoming.entries) {
    final key = entry.key;
    if (key is! String) {
      throw EncodingException(
        'Conflicting values for multipart property "$propertyName": '
        'object keys must be strings.',
      );
    }
    if (!target.containsKey(key) || target[key] == null) {
      target[key] = entry.value;
      continue;
    }
    if (entry.value == null) continue;
    final current = target[key];
    if (current is Map && entry.value is Map) {
      final nested = <String, dynamic>{};
      _mergeMap(nested, current, propertyName);
      _mergeMap(nested, entry.value as Map, propertyName);
      target[key] = nested;
      continue;
    }
    if (current is Iterable && entry.value is Iterable) {
      target[key] = [...current, ...(entry.value as Iterable)];
      continue;
    }
    if (current != entry.value) {
      throw EncodingException(
        'Conflicting values for multipart property "$propertyName" '
        'at "$key".',
      );
    }
  }
}
