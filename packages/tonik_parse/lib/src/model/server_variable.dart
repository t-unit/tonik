class ServerVariable {
  ServerVariable({
    required this.defaultValue,
    this.enumValues,
    this.description,
  });

  factory ServerVariable.fromJson(Map<String, dynamic> json) => ServerVariable(
    defaultValue: json['default'] as String,
    enumValues: (json['enum'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    description: json['description'] as String?,
  );

  final String defaultValue;
  final List<String>? enumValues;
  final String? description;

  @override
  String toString() =>
      'ServerVariable{'
      'defaultValue: $defaultValue, '
      'enumValues: $enumValues, '
      'description: $description}';
}
