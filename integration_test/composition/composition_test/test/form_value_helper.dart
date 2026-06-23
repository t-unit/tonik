import 'package:tonik_util/tonik_util.dart';

/// A lone scalar stays an unkeyed bare value — that is what the `fromForm`
/// decoders consume; keying it as `name=value` would corrupt the round-trip.
String formValue(List<ParameterEntry> entries, String paramName) {
  if (entries.length == 1 &&
      (entries.first.name.isEmpty || entries.first.name == paramName)) {
    return entries.first.value;
  }
  return entries
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
      .join('&');
}
