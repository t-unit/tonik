import 'dart:io';
import 'package:path/path.dart' as path;

void generateAnalysisOptions({
  required String outputDirectory,
  required String package,
}) {
  final packageDir = path.join(outputDirectory, package);
  final analysisOptionsFile = File(
    path.join(packageDir, 'analysis_options.yaml'),
  );

  if (!analysisOptionsFile.parent.existsSync()) {
    analysisOptionsFile.parent.createSync(recursive: true);
  }

  const content = '''
include: package:lints/recommended.yaml

analyzer:
  errors:
    lines_longer_than_80_chars: ignore
    unnecessary_raw_strings: ignore
    unnecessary_brace_in_string_interps: ignore
    no_leading_underscores_for_local_identifiers: ignore
    cascade_invocations: ignore
    deprecated_member_use_from_same_package: ignore
    no_leading_underscores_for_library_prefixes: ignore
    unused_import: ignore
    prefer_is_empty: ignore
    unnecessary_nullable_for_final_variable_declarations: ignore
    dead_code: ignore
''';

  analysisOptionsFile.writeAsStringSync(content);
}
