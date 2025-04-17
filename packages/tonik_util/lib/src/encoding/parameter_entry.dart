/// A record representing a parameter name and value pair.
///
/// This is used by encoders to return multiple parameter entries.
/// Unlike [MapEntry], this record type properly implements equality.
typedef ParameterEntry = ({String name, String value});
