void mergeJsonObject(Map<String, Object?> target, Map<String, Object?> source) {
  for (final entry in source.entries) {
    final previous = target[entry.key];
    final value = entry.value;
    if (previous is Map<String, Object?> && value is Map<String, Object?>) {
      final merged = Map<String, Object?>.of(previous);
      mergeJsonObject(merged, value);
      target[entry.key] = merged;
    } else {
      target[entry.key] = value;
    }
  }
}
