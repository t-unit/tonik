import 'package:tonik_util/tonik_util.dart';

/// Renders the form encoding of a model to the single wire value the
/// `fromX` decoders accept: a single entry keyed by [paramName] yields its
/// value, while exploded objects render as `name=value` pairs.
///
/// Mirrors the production joiners: an empty-name entry denotes a bare value
/// and renders as just its value with no `name=` prefix.
String formValue(List<ParameterEntry> entries, String paramName) {
  if (entries.length == 1 && entries.first.name == paramName) {
    return entries.first.value;
  }
  return entries
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
      .join('&');
}
