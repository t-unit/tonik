class Tag {
  Tag({required this.name, required this.description, this.xDartName});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    name: json['name'] as String,
    description: json['description'] as String?,
    xDartName: json['x-dart-name'] as String?,
  );

  final String name;
  final String? description;
  final String? xDartName;

  @override
  String toString() =>
      'Tag{name: $name, description: $description, xDartName: $xDartName}';
}
