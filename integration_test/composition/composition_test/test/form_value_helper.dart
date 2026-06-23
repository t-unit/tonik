import 'package:tonik_util/tonik_util.dart';

/// Renders the form encoding of a model to the single wire value the
/// `fromX` decoders accept.
///
/// A scalar produces one entry keyed by [paramName] (or, for the body
/// convention, an empty name); either way its bare value is the wire form the
/// `fromForm` decoders consume. Multi-entry (object/exploded) encodings render
/// as `name=value` pairs joined with `&`, with an empty name denoting a bare
/// value per the production joiners.
String formValue(List<ParameterEntry> entries, String paramName) {
  if (entries.length == 1 &&
      (entries.first.name.isEmpty || entries.first.name == paramName)) {
    return entries.first.value;
  }
  return entries
      .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
      .join('&');
}
