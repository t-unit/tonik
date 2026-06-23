/// A record representing a parameter name and value pair.
///
/// This is used by encoders to return multiple parameter entries.
/// Unlike [MapEntry], this record type properly implements equality.
///
/// An empty `name` denotes a bare value rendered as just `value` with no
/// `name=` prefix; real names are never empty.
typedef ParameterEntry = ({String name, String value});
