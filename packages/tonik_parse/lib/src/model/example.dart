class Example {
  Example({
    this.summary,
    this.description,
    this.value,
    this.externalValue,
    this.hasExplicitValue = false,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    final hasValue = json.containsKey('value');
    return Example(
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      value: hasValue ? json['value'] : null,
      externalValue: json['externalValue'] as String?,
      hasExplicitValue: hasValue,
    );
  }

  final String? summary;
  final String? description;
  final Object? value;
  final String? externalValue;

  /// Whether the source JSON contained an explicit `value` key (even if its
  /// value was `null`). Used by the example importer to distinguish an
  /// empty Example object from one whose value is intentionally null.
  final bool hasExplicitValue;

  @override
  String toString() =>
      'Example{summary: $summary, description: $description, '
      'value: $value, externalValue: $externalValue}';
}
