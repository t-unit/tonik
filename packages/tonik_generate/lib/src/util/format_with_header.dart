import 'package:dart_style/dart_style.dart';

extension FormatWithHeader on DartFormatter {
  static const _ignores = [
    'lines_longer_than_80_chars',
    'unnecessary_raw_strings',
    'unnecessary_brace_in_string_interps',
    'no_leading_underscores_for_local_identifiers',
    'cascade_invocations',
  ];

  String formatWithHeader(String code) {
    return format('''
// Generated code - do not modify by hand
${_ignores.map((i) => '// ignore_for_file: $i').join('\n')}
$code''');
  }
}
