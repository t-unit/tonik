import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/class_generator.dart';
import 'package:tonic_generate/src/model/enum_generator.dart';
import 'package:tonic_generate/src/model/model_generator.dart';
import 'package:tonic_generate/src/model/one_of_generator.dart';
import 'package:tonic_generate/src/model/typedef_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

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

    final modelGenerator = ModelGenerator(
      classGenerator: classGenerator,
      enumGenerator: enumGenerator,
      oneOfGenerator: oneOfGenerator,
      typedefGenerator: typedefGenerator,
    );

    nameManager.prime(
      models: apiDocument.models,
      responses: apiDocument.responses,
      responseHeaders: apiDocument.responseHeaders,
      operations: apiDocument.operations,
      requestHeaders: apiDocument.requestHeaders,
      queryParameters: apiDocument.queryParameters,
      pathParameters: apiDocument.pathParameters,
      tags: apiDocument.operationsByTag.keys,
    );

    modelGenerator.writeFiles(
      apiDocument: apiDocument,
      outputDirectory: outputDirectory,
    );
  }
}
