import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';

extension FormatWithHeader on DartFormatter {
  static final _logger = Logger('formatting');

  String formatWithHeader(String code) {
    final codeWithHeader = '// Generated code - do not modify by hand\n\n$code';

    try {
      return format(codeWithHeader);
    } catch (e) {
      _logger.fine('Failed to format code:\n$codeWithHeader');
      rethrow;
    }
  }
}
