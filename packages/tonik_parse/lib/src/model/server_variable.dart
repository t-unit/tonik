class ServerVariable({
  required final String defaultValue,
  final List<String>? enumValues,
  final String? description,
}) {
  factory fromJson(Map<String, dynamic> json) => ServerVariable(
    defaultValue: json['default'] as String,
    enumValues: (json['enum'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    description: json['description'] as String?,
  );

  @override
  String toString() =>
      'ServerVariable{'
      'defaultValue: $defaultValue, '
      'enumValues: $enumValues, '
      'description: $description}';
}
