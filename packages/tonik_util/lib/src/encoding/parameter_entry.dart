/// A record representing a parameter name and value pair.
///
/// This is used by encoders to return multiple parameter entries.
/// Unlike [MapEntry], this record type properly implements equality.
///
/// An empty `name` denotes a bare value: the entry renders as just `value`
/// with no `name=` prefix. This is how scalar form bodies (a top-level
/// primitive/string urlencoded body) are emitted, and the body/string joiners
/// honor it explicitly. Real parameter and property names are never empty, so
/// the query and cookie joiners assume a non-empty `name`.
typedef ParameterEntry = ({String name, String value});
