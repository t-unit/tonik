import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Generator for creating data method for operations.
class DataGenerator {
  const DataGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates a data expression for the operation.
  Method generateDataMethod(Operation operation) {
    return Method(
      (b) =>
          b
            ..name = '_data'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = false
            ..body = const Code('return null;'),
    );
  }
}
