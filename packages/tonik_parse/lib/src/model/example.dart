class Example {
  Example({
    this.summary,
    this.description,
    this.value,
    this.dataValue,
    this.serializedValue,
    this.externalValue,
    this.hasExplicitValue = false,
    this.hasExplicitDataValue = false,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    final hasValue = json.containsKey('value');
    final hasDataValue = json.containsKey('dataValue');
    return Example(
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      value: hasValue ? json['value'] : null,
      dataValue: hasDataValue ? json['dataValue'] : null,
      serializedValue: json['serializedValue'] as String?,
      externalValue: json['externalValue'] as String?,
      hasExplicitValue: hasValue,
      hasExplicitDataValue: hasDataValue,
    );
  }

  final String? summary;
  final String? description;
  final Object? value;
  final Object? dataValue;
  final String? serializedValue;
  final String? externalValue;

  /// Whether the source JSON contained an explicit `value` key (even if its
  /// value was `null`). Used by the example importer to distinguish an
  /// empty Example object from one whose value is intentionally null.
  final bool hasExplicitValue;
  final bool hasExplicitDataValue;

  @override
  String toString() =>
      'Example{summary: $summary, description: $description, '
      'value: $value, dataValue: $dataValue, '
      'serializedValue: $serializedValue, externalValue: $externalValue}';
}
