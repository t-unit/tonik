import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/library_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/model_file_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/operation_file_generator.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';
import 'package:tonik_generate/src/pubspec_generator.dart';
import 'package:tonik_generate/src/request/request_body_file_generator.dart';
import 'package:tonik_generate/src/request/request_body_generator.dart';

class Generator {
  const Generator();

  void generate({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    final fullPackage = 'package:$package/$package.dart';

    final nameGenerator = NameGenerator();
    final nameManager = NameManager(generator: nameGenerator);

    final classGenerator = ClassGenerator(
      nameManager: nameManager,
      package: fullPackage,
    );
    final enumGenerator = EnumGenerator(
      nameManager: nameManager,
      package: fullPackage,
    );
    final oneOfGenerator = OneOfGenerator(
      nameManager: nameManager,
      package: fullPackage,
    );
    final typedefGenerator = TypedefGenerator(
      nameManager: nameManager,
      package: fullPackage,
    );

    final modelGenerator = ModelFileGenerator(
      classGenerator: classGenerator,
      enumGenerator: enumGenerator,
      oneOfGenerator: oneOfGenerator,
      typedefGenerator: typedefGenerator,
    );

    final operationGenerator = OperationGenerator(
      nameManager: nameManager,
      package: fullPackage,
    );

    final operationFileGenerator = OperationFileGenerator(
      operationGenerator: operationGenerator,
    );

    final requestBodyGenerator = RequestBodyGenerator(
      nameManager: nameManager,
      package: fullPackage,
    );

    final requestBodyFileGenerator = RequestBodyFileGenerator(
      requestBodyGenerator: requestBodyGenerator,
    );

    nameManager.prime(
      models: apiDocument.models,
      responses: apiDocument.responses.toList(),
      requestBodies: apiDocument.requestBodies.toList(),
      operations: apiDocument.operations.toList(),
      tags: apiDocument.operationsByTag.keys.toList(),
    );

    generatePubspec(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );

    modelGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );

    requestBodyFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );

    operationFileGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );

    generateLibraryFile(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
      package: package,
    );
  }
}
