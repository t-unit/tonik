import 'package:change_case/change_case.dart';

/// Derives the generated file name for a class name.
///
/// `toSnakeCase` strips `$`, so a leading `$` leaves a leading `_` that
/// reads as a private file; strip it. Digit-leading names keep the `_`
/// because bare digit-leading file names violate the `file_names` lint.
String fileNameForClass(String className) {
  final snake = className.toSnakeCase();
  final stripped = snake.replaceFirst(RegExp('^_+'), '');
  if (stripped.isEmpty || RegExp(r'^\d').hasMatch(stripped)) {
    return '$snake.dart';
  }
  return '$stripped.dart';
}
