import 'package:dart_style/dart_style.dart';

extension FormatWithHeader on DartFormatter {
  String formatWithHeader(String code) {
    return format('''
// Generated code - do not modify by hand

$code''');
  }
}
