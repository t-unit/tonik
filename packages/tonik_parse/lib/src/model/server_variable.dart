class ServerVariable({
  required final String defaultValue,
  final List<String>? enumValues,
  final String? description,
}) {
  factory fromJson(Map<String, dynamic> json, {String? name}) {
    final value = json['default'];
    if (value is! String) {
      final field = name == null
          ? 'server variable default'
          : 'server.variables.$name.default';
      throw FormatException('$field must be a string. Quote numeric defaults.');
    }
    return ServerVariable(
      defaultValue: value,
      enumValues: (json['enum'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
    );
  }

  @override
  String toString() =>
      'ServerVariable{'
      'defaultValue: $defaultValue, '
      'enumValues: $enumValues, '
      'description: $description}';
}
