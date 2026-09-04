import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:tonik_parse/tonik_parse.dart';

/// Import-only benchmark. Pass a schema count or the path to an OpenAPI JSON
/// document. Compile once with `dart compile exe` and repeat fresh processes;
/// input construction/decoding is excluded from the reported import time.
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: import_benchmark <schema-count|openapi.json>');
    exitCode = 64;
    return;
  }
  Logger.root.level = Level.OFF;
  final count = int.tryParse(arguments.single);
  if (count != null && count < 1) {
    stderr.writeln('Schema count must be positive.');
    exitCode = 64;
    return;
  }
  final spec = count == null
      ? jsonDecode(File(arguments.single).readAsStringSync())
            as Map<String, dynamic>
      : syntheticDocument(count);
  final timer = Stopwatch()..start();
  final document = Importer().import(spec);
  timer.stop();
  stdout.writeln(
    jsonEncode({
      'input': arguments.single,
      'models': document.models.length,
      'import_us': timer.elapsedMicroseconds,
    }),
  );
}

/// Each named class has eight repeated/forward references and eight anonymous
/// objects, each containing an anonymous string. References wrap around to
/// exercise recursive identity as the number of named schemas grows.
Map<String, dynamic> syntheticDocument(int count) => {
  'openapi': '3.1.0',
  'info': {'title': 'Import scaling', 'version': '1'},
  'paths': <String, dynamic>{},
  'components': {
    'schemas': {
      for (var i = 0; i < count; i++)
        'Model$i': {
          'type': 'object',
          'properties': {
            for (var j = 0; j < 8; j++)
              'ref$j': {
                r'$ref': '#/components/schemas/Model${(i + j + 1) % count}',
              },
            for (var j = 0; j < 8; j++)
              'inline$j': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                },
              },
          },
        },
    },
  },
};
