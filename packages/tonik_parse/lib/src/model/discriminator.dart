class Discriminator {
  Discriminator({required this.propertyName, required this.mapping});

  factory Discriminator.fromJson(Map<String, dynamic> json) => Discriminator(
    propertyName: json['propertyName'] as String,
    mapping: (json['mapping'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
  );

  final String propertyName;
  final Map<String, String>? mapping;

  @override
  String toString() =>
      'Discriminator{propertyName: $propertyName, mapping: $mapping}';
}
