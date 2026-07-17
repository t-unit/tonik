import 'dart:convert';

import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';

const _jsonEncoder = JsonEncoder.withIndent('  ');

List<String> formatDocsWithExamples(
  String? description,
  List<Example> examples,
) {
  final descriptionDocs = formatDocComment(description);
  final exampleDocs = formatExamplesAsDocs(examples);
  return [
    ...descriptionDocs,
    if (descriptionDocs.isNotEmpty && exampleDocs.isNotEmpty) '///',
    ...exampleDocs,
  ];
}

List<String> formatExamplesAsDocs(List<Example> examples) {
  if (examples.isEmpty) return const [];

  final entries = <List<String>>[];
  for (final example in examples) {
    final entry = _formatExample(example);
    if (entry != null) entries.add(entry);
  }

  if (entries.isEmpty) return const [];

  final result = <String>[];
  for (var i = 0; i < entries.length; i++) {
    if (i > 0) result.add('///');
    result.addAll(entries[i]);
  }
  return result;
}

List<String>? _formatExample(Example example) {
  // Lone CRs would let text escape the `///` prefix; see formatDocComment.
  final name = example.name?.replaceAll('\r', '');
  final summary = switch (example.summary?.replaceAll('\r', '')) {
    null || '' => null,
    final s => s,
  };
  final description = switch (example.description?.replaceAll('\r', '')) {
    null || '' => null,
    final s => s,
  };

  if (example.value == null &&
      name == null &&
      summary == null &&
      description == null) {
    return null;
  }

  final lines = <String>[_heading(name: name, summary: summary)];

  if (description != null) {
    for (final line in description.split('\n')) {
      if (line.isEmpty) {
        lines.add('///');
      } else {
        // Escape a line that would open a markdown fenced code block,
        // otherwise the example's own fence below would render as content.
        final escaped = line.startsWith('```') ? r'\' + line : line;
        lines.add('/// $escaped');
      }
    }
    lines.add('///');
  }

  lines.addAll(_renderValue(example.value));
  return lines;
}

String _heading({required String? name, required String? summary}) {
  final buf = StringBuffer('/// **Example**');
  if (name != null) {
    buf.write(' "$name"');
  }
  if (summary != null) {
    buf.write(' — $summary');
  }
  buf.write(':');
  return buf.toString();
}

List<String> _renderValue(Object? value) {
  final String payload;
  final String fenceLang;
  if (value is String) {
    payload = value.replaceAll('\r', '');
    fenceLang = '';
  } else {
    payload = _jsonEncoder.convert(value);
    fenceLang = 'json';
  }

  final fenceLen = _maxBacktickRun(payload) + 1;
  final fence = '`' * (fenceLen < 3 ? 3 : fenceLen);

  final lines = <String>['/// $fence$fenceLang'];
  for (final line in payload.split('\n')) {
    lines.add(line.isEmpty ? '///' : '/// $line');
  }
  lines.add('/// $fence');
  return lines;
}

int _maxBacktickRun(String s) {
  var max = 0;
  var current = 0;
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) == 0x60) {
      current++;
      if (current > max) max = current;
    } else {
      current = 0;
    }
  }
  return max;
}
