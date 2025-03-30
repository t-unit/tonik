import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/class_generator.dart';
import 'package:tonic_generate/src/model/enum_generator.dart';
import 'package:tonic_generate/src/model/one_of_generator.dart';
import 'package:tonic_generate/src/model/typedef_generator.dart';

class ModelGenerator {
  const ModelGenerator({
    required this.classGenerator,
    required this.enumGenerator,
    required this.oneOfGenerator,
    required this.typedefGenerator,
  });

  final ClassGenerator classGenerator;
  final EnumGenerator enumGenerator;
  final OneOfGenerator oneOfGenerator;
  final TypedefGenerator typedefGenerator;

  Future<void> writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
  }) async {
    for (final model in apiDocument.models) {
      ({String code, String filename})? result;

      switch (model) {
        case ClassModel():
          result = classGenerator.generate(model);
        case EnumModel<Object>():
          result = enumGenerator.generate(model);
        case OneOfModel():
          result = oneOfGenerator.generate(model);
        case AliasModel():
          result = typedefGenerator.generateAlias(model);
        case ListModel():
          result = typedefGenerator.generateList(model);
        default:
          // Ignore unsupported models
          continue;
      }

      final file = File(path.join(outputDirectory, result.filename));
      await file.parent.create(recursive: true);
      await file.writeAsString(result.code);
    }
  }
}
