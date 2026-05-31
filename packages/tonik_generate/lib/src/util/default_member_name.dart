/// Picks a `static const`/`static get` member name for the default value of
/// the property [propertyName], avoiding collisions with any name in
/// [reservedNames].
///
/// Appends a numeric suffix starting at `2` when the base name
/// `<propertyName>Default` collides — mirrors the collision-avoidance
/// scheme used for additional-properties field names.
String pickDefaultMemberName({
  required String propertyName,
  required Set<String> reservedNames,
}) {
  final base = '${propertyName}Default';
  if (!reservedNames.contains(base)) return base;
  var counter = 2;
  while (reservedNames.contains('$base$counter')) {
    counter++;
  }
  return '$base$counter';
}
