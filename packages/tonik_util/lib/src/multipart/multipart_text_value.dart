import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/property_value_style_encoders.dart';

String multipartTextValue(Object? value) => switch (value) {
  final String value => value,
  final num value => value.toString(),
  final bool value => value.toString(),
  _ => throw EncodingException(
    'Cannot encode ${value.runtimeType} as a text/plain multipart part.',
  ),
};

List<ParameterEntry> multipartMapStyleParts(
  Map<String, Object?> value,
  String name, {
  required bool explode,
  required bool deepObject,
  PropertyValue Function(Object)? encodeValue,
}) {
  final properties = <String, PropertyValue>{};
  for (final entry in value.entries) {
    if (entry.value == null) continue;
    properties[entry.key] =
        encodeValue?.call(entry.value!) ??
        PropertyValue.scalar(multipartTextValue(entry.value));
  }
  return deepObject
      ? properties.toRawDeepObjectParts(name)
      : properties.toRawStyleParts(name, explode: explode);
}
