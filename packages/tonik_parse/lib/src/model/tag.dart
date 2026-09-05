class Tag({
  required final String name,
  required final String? description,
  final String? xDartName,
}) {
  factory fromJson(Map<String, dynamic> json) => Tag(
    name: json['name'] as String,
    description: json['description'] as String?,
    xDartName: json['x-dart-name'] as String?,
  );

  @override
  String toString() =>
      'Tag{name: $name, description: $description, xDartName: $xDartName}';
}
