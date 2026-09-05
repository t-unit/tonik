class Discriminator({
  required final String propertyName,
  required final Map<String, String>? mapping,
}) {
  factory fromJson(Map<String, dynamic> json) => Discriminator(
    propertyName: json['propertyName'] as String,
    mapping: (json['mapping'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
  );

  @override
  String toString() =>
      'Discriminator{propertyName: $propertyName, mapping: $mapping}';
}
