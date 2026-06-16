import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';

class ModelFileGenerator {
  ModelFileGenerator({
    required this.classGenerator,
    required this.enumGenerator,
    required this.anyOfGenerator,
    required this.oneOfGenerator,
    required this.typedefGenerator,
    required this.allOfGenerator,
  });

  final ClassGenerator classGenerator;
  final EnumGenerator enumGenerator;
  final AnyOfGenerator anyOfGenerator;
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

    for (final model in apiDocument.models) {
      writeOne(model, outputDirectory: outputDirectory, package: package);
    }
  }

  void writeOne(
    Model model, {
    required String outputDirectory,
    required String package,
  }) {
    final result = switch (model) {
      ClassModel() => classGenerator.generate(model),
      EnumModel<int>() => enumGenerator.generate<int>(model),
      EnumModel<String>() => enumGenerator.generate<String>(model),
      AnyOfModel() => anyOfGenerator.generate(model),
      OneOfModel() => oneOfGenerator.generate(model),
      AllOfModel() => allOfGenerator.generate(model),
      AliasModel() => typedefGenerator.generateAlias(model),
      ListModel() => typedefGenerator.generateList(model),
      MapModel() => typedefGenerator.generateMap(model),
      _ => null,
    };

    if (result == null) {
      log.fine('Ignoring model: $model');
      return;
    }

    log
      ..fine('Generating model ${classGenerator.nameManager.modelName(model)}')
      ..fine('Writing file ${result.filename}');

    final modelDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'model',
    ]);
    final file = File(path.join(modelDirectory, result.filename));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(result.code);
  }
}
