enum SerializationStyle {
  matrix,
  label,
  form,
  simple,
  spaceDelimited,
  pipeDelimited,
  deepObject;

  static SerializationStyle fromJson(Object? value) => switch (value) {
    'matrix' => SerializationStyle.matrix,
    'label' => SerializationStyle.label,
    'form' => SerializationStyle.form,
    'simple' => SerializationStyle.simple,
    'spaceDelimited' => SerializationStyle.spaceDelimited,
    'pipeDelimited' => SerializationStyle.pipeDelimited,
    'deepObject' => SerializationStyle.deepObject,
    _ => throw FormatException('Invalid SerializationStyle: $value'),
  };
}
