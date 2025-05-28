import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';

class ModelFileGenerator {
  ModelFileGenerator({
    required this.classGenerator,
    required this.enumGenerator,
    required this.oneOfGenerator,
    required this.typedefGenerator,
    required this.allOfGenerator,
  });

  final ClassGenerator classGenerator;
  final EnumGenerator enumGenerator;
  final OneOfGenerator oneOfGenerator;
  final TypedefGenerator typedefGenerator;
  final AllOfGenerator allOfGenerator;

  final log = Logger('ModelGenerator');

  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing ${apiDocument.models.length} model files');

    final modelDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'model',
    ]);

    for (final model in apiDocument.models) {
      final name = classGenerator.nameManager.modelName(model);
      log.fine('Generating model $name');

      ({String code, String filename})? result;

      switch (model) {
        case ClassModel():
          result = classGenerator.generate(model);
        case EnumModel<int>():
          result = enumGenerator.generate<int>(model);
        case EnumModel<String>():
          result = enumGenerator.generate<String>(model);
        case OneOfModel():
          result = oneOfGenerator.generate(model);
        case AllOfModel():
          result = allOfGenerator.generate(model);
        case AliasModel():
          result = typedefGenerator.generateAlias(model);
        case ListModel():
          result = typedefGenerator.generateList(model);
        default:
          log.fine('Ignoring model: $model');
          continue;
      }

      log.fine('Writing file ${result.filename}');
      final file = File(path.join(modelDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
  }
}
