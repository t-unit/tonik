import 'dart:convert';

import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';

const _jsonEncoder = JsonEncoder.withIndent('  ');

/// Joins [description] doc lines with [examples] doc lines, inserting a
/// blank `///` separator between them when both are non-empty.
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

/// Renders [examples] as `/// …` doc-comment lines for an Examples block.
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
  final hasSummary =
      example.summary != null && example.summary!.isNotEmpty;
  final hasDescription =
      example.description != null && example.description!.isNotEmpty;
  final hasHeadingContent =
      example.name != null || hasSummary || hasDescription;

  if (example.value == null && !hasHeadingContent) return null;

  final lines = <String>[_heading(example, hasSummary: hasSummary)];

  if (hasDescription) {
    for (final line in example.description!.split('\n')) {
      lines.add(line.isEmpty ? '///' : '/// $line');
    }
    lines.add('///');
  }

  lines.addAll(_renderValue(example.value));
  return lines;
}

String _heading(Example example, {required bool hasSummary}) {
  final buf = StringBuffer('/// **Example**');
  if (example.name != null) {
    buf.write(' "${example.name}"');
  }
  if (hasSummary) {
    buf.write(' — ${example.summary}');
  }
  buf.write(':');
  return buf.toString();
}

List<String> _renderValue(Object? value) {
  final isString = value is String;
  final payload = isString ? value : _jsonEncoder.convert(value);
  final fenceLang = isString ? '' : 'json';

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
